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

		clk : in std_logic;
		reset : in std_logic
	) ;
end entity ; -- AudioStage_tl

architecture arch of AudioStage_tl is
	signal sampleOutput : std_logic_vector(11 downto 0);

	signal decimatorOutput : std_logic_vector(31 downto 0);

	signal echoClk : std_logic;
	signal effectInput : std_logic_vector(15 downto 0);
	signal effectOutput : std_logic_vector(15 downto 0);

	signal toPWM : std_logic_vector(8 downto 0);
	signal clkPWM : std_logic;
begin

	pwm_amp <= '1';
	leds <= decimatorOutput(31 downto 16);

	-- INPUT

	ADC : entity work.ADSampler
	port map (
		vauxn => vauxn,
		vauxp => vauxp,

		output => sampleOutput,

		clk => clk,
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

	-- Skip da decimator >:D
	effectInput <= sampleOutput & "0000";

	-- EFFECTS

	echoClkGenerator : entity work.ClockDivider
	generic map (
		divider => 324 -- Clock at 7*44.1 kHz = 308.7 kHz (Echo has 7 states per sample)
	)
	port map (
		clk => clk,
		clkOut => echoClk,
		reset => reset
	);

	effectInput <= decimatorOutput(31 downto 16);
	toPWM <= effectOutput(15 downto 7);

	Echo: entity work.EffectEcho
	port map (
		input => effectInput,
		output => effectOutput,

		clk => echoClk,
		reset => reset
	);

	-- OUTPUT

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