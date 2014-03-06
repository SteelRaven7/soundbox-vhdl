library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity AudioStage_tl is
	port (
		vauxn : in std_logic;
		vauxp : in std_logic;

		pwm_out : out std_logic;
		pwm_amp : out std_logic;
		leds : out std_logic_vector(15 downto 0);

		muteInput : in std_logic;
		bypassLP : in std_logic;

		clk : in std_logic;
		reset : in std_logic
	) ;
end entity ; -- AudioStage_tl

architecture arch of AudioStage_tl is
	signal sampleInputClk : std_logic;
	signal sampleOutput : std_logic_vector(11 downto 0);

	signal decimatorInput : std_logic_vector(15 downto 0);
	signal decimatorOutput : std_logic_vector(15 downto 0);
	signal decimatorMuxedOutput : std_logic_vector(15 downto 0);
	signal decimatorPipelinedOutput : std_logic_vector(15 downto 0);

	signal sampleClk : std_logic;
	signal echoClk : std_logic;
	signal effectInput : std_logic_vector(15 downto 0);
	signal effectOutput : std_logic_vector(15 downto 0);

	signal toPWM : std_logic_vector(8 downto 0);
	signal clkPWM : std_logic;
begin

	pwm_amp <= '1';
	leds <= effectInput;

	sampleClkGenerator : entity work.ClockDivider
	generic map (
		divider => 128 --2^11*44.1 k to 705.6 k
		--divider => 142 --100 MHz to 705.6 kHz.
	)
	port map (
		clk => clk,
		clkOut => sampleInputClk,
		reset => reset
	);

	-- INPUT

	ADC : entity work.ADSampler
	port map (
		vauxn => vauxn,
		vauxp => vauxp,

		output => sampleOutput,

		sampleClk => sampleInputClk,
		clk => clk,
		reset => reset
	);

	-- Concatenate 0's to create 16 bit input.
	--decimatorInput <= sampleOutput & "0000";
	--decimatorInput <= sampleOutput and (others => muteInput);

	decimatorInput <= 	sampleOutput & "0000" when muteInput = '0' else
						(others => '0');





	LP : entity work.FIR
	generic map (
		wordLength => 16,
		coeffWordLength => 16,
		outputWordLength => 16,

		fractionalBits => 15,
		coeffFractionalBits => 15,
		outputFractionalBits => 15,


		order => 40,

		coefficients => (
			0.000035, 
			0.000067, 
			0.000111, 
			0.000166, 
			0.000233, 
			0.000313, 
			0.000404, 
			0.000506, 
			0.000618, 
			0.000737, 
			0.000860, 
			0.000986, 
			0.001111, 
			0.001231, 
			0.001344, 
			0.001445, 
			0.001533, 
			0.001605, 
			0.001658, 
			0.001690, 
			0.001701, 
			0.001690, 
			0.001658, 
			0.001605, 
			0.001533, 
			0.001445, 
			0.001344, 
			0.001231, 
			0.001111, 
			0.000986, 
			0.000860, 
			0.000737, 
			0.000618, 
			0.000506, 
			0.000404, 
			0.000313, 
			0.000233, 
			0.000166, 
			0.000111, 
			0.000067, 
			0.000035
		)
	)
	port map (
		input => decimatorInput,
		output => decimatorOutput,

		clk => sampleInputClk,
		reset => reset
	);

	decimatorMuxedOutput <= decimatorOutput;

--	decimatorMuxedOutput <=	decimatorOutput when bypassLP = '0' else
--							decimatorInput;




	internalSampleClock : entity work.ClockDivider
	generic map (
		divider => 2048 -- To 44.1 kHz
	)
	port map (
		clk => clk,
		clkOut => sampleClk,
		reset => reset
	);

	-- Path delay at this point is ~10 ns, insert pipeline stage.
	PipelineRegister : entity work.VectorRegister
	generic map (
		wordLength => 16
	)
	port map (
		input => decimatorOutput,
		output => decimatorPipelinedOutput,

		clk => sampleClk,
		reset => reset
	);


	-- EFFECTS

	effectInput <= decimatorPipelinedOutput;
	effectOutput <= effectInput;

--	echoClkGenerator : entity work.ClockDivider
--	generic map (
--		divider => 
--		--divider => 324 -- Clock at 7*44.1 kHz = 308.7 kHz (Echo has 7 states per sample)
--	)
--	port map (
--		clk => clk,
--		clkOut => echoClk,
--		reset => reset
--	);
--
--	Echo: entity work.EffectEcho
--	port map (
--		input => effectInput,
--		output => effectOutput,
--
--		clk => echoClk,
--		reset => reset
--	);

	-- OUTPUT

	toPWM <= effectOutput(15 downto 7);

	-- Output freq: 195.3 kHz
	PWM: entity work.DAPwm
	generic map(
		wordLength => 9 -- 512 values -> 195.3 kHz @ 100MHz
	)
	port map(
		input => toPWM,
		output => pwm_out,

		clk => clk,
		reset => reset
	);

end architecture ; -- arch