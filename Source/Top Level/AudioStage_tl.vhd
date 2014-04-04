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
		bypassEffects : in std_logic;

		clk : in std_logic;
		reset : in std_logic
	) ;
end entity ; -- AudioStage_tl

architecture arch of AudioStage_tl is
	signal sampleInputClk : std_logic;
	signal sampleOutput : std_logic_vector(11 downto 0);
	
	signal decimatorInput : std_logic_vector(11 downto 0);
	signal decimatorOutput : std_logic_vector(15 downto 0);
	signal decimatorMuxedOutput : std_logic_vector(15 downto 0);
	
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

	decimatorInput <= 	sampleOutput when muteInput = '0' else
						(others => '0');


	decimator: entity work.StructuralDecimator
	port map (
		input => decimatorInput,
		output => decimatorOutput,

		clk => clk,
		reset => reset
	);


	decimatorMuxedOutput <=	decimatorOutput when bypassLP = '0' else
							decimatorInput & "0000";



	-- EFFECTS

	effectInput <= decimatorMuxedOutput;

	echoClkGenerator : entity work.ClockDivider
	generic map (
		divider => 256 -- Clock at 8*44.1 kHz (Echo has 8 states per sample)
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

	toPWM <= effectOutput(15 downto 7) when bypassEffects = '0' else
			 effectInput(15 downto 7);

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