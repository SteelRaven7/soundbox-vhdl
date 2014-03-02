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

		clk : in std_logic;
		reset : in std_logic
	) ;
end entity ; -- AudioStage_tl

architecture arch of AudioStage_tl is
	signal sampleInputClk : std_logic;
	signal sampleOutput : std_logic_vector(11 downto 0);

	signal decimatorInput : std_logic_vector(11 downto 0);
	signal decimatorOutput : std_logic_vector(11 downto 0);
	signal decimatorPipelinedOutput : std_logic_vector(11 downto 0);

	signal echoClk : std_logic;
	signal effectInput : std_logic_vector(15 downto 0);
	signal effectOutput : std_logic_vector(15 downto 0);

	signal toPWM : std_logic_vector(8 downto 0);
	signal clkPWM : std_logic;
begin

	pwm_amp <= '1';
	leds <= effectInput;

	sampleClk : entity work.ClockDivider
	generic map (
		divider => 142 --100 MHz to 705.6 kHz.
		--divider => 50000 --100 MHz to 2.0 kHz.
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

	decimatorInput <= 	sampleOutput when muteInput = '0' else
						(others => '0');

	decimatorOutput <= decimatorInput;

--	LP : entity work.FIR
--	generic map (
--		wordLength => 12,
--		order => 20,
--
--		coefficients => (
--			-0.020104118828858014,
--			-0.058427980043525354,
--			-0.06117840364782169,
--			-0.01093939338533849,
--			0.051250964435349884,
--			0.03322086767894797,
--			-0.05655276971833931,
--			-0.08565500737264502,
--			0.06337959966054495,
--			0.3108544036566358,
--			0.4344309124179416,
--			0.3108544036566358,
--			0.06337959966054495,
--			-0.08565500737264502,
--			-0.05655276971833931,
--			0.03322086767894797,
--			0.051250964435349884,
--			-0.01093939338533849,
--			-0.06117840364782169,
--			-0.058427980043525354,
--			-0.020104118828858014
--		)
--	)
--	port map (
--		input => decimatorInput,
--		output => decimatorOutput,
--
--		clk => sampleInputClk,
--		reset => reset
--	);

	-- Path delay at this point is ~10 ns, insert pipeline stage.
	PipelineRegister : entity work.VectorRegister
	generic map (
		wordLength => 12
	)
	port map (
		input => decimatorOutput,
		output => decimatorPipelinedOutput,

		clk => sampleInputClk,
		reset => reset
	);



--	Decimator : entity work.IPFIRDecimator
--	port map (
--		input => sampleOutput,
--		output => effectInput,
--
--		clk => clk,
--		reset => reset
--	);


--	Decimator : entity work.decimator
--	port map (
--		input_signal => sampleOutput,
--		output_signal => decimatorOutput,
--		clk => clk,
--		reset => reset
--    );


	-- EFFECTS

	effectInput <= decimatorPipelinedOutput & "0000";
	--effectOutput <= effectInput;

	echoClkGenerator : entity work.ClockDivider
	generic map (
		divider => 324 -- Clock at 7*44.1 kHz = 308.7 kHz (Echo has 7 states per sample)
	)
	port map (
		clk => clk,
		clkOut => echoClk,
		reset => reset
	);

	Echo: entity work.EffectEcho
	port map (
		input => effectInput,
		output => effectOutput,

		clk => echoClk,
		reset => reset
	);

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