library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;
	use work.memory_pkg.all;

entity AudioStage_tl is
	port (
		vauxn : in std_logic;
		vauxp : in std_logic;

		pwm_out : out std_logic;
		pwm_amp : out std_logic;
		leds : out std_logic_vector(15 downto 0);

		muteInput : in std_logic;
		bypassLP : in std_logic;
		bypassEcho : in std_logic;
		bypassFlanger : in std_logic;
		bypassReverb : in std_logic;
		bypassDistortionSelect : in std_logic;
		bypassDistortionEnable : in std_logic;
		bypassEQ : in std_logic;

		cs: out std_logic;
		sclk: out std_logic;
		toDA: out std_logic;

		-- Serial interface (RS-232/UART @ 9600 Hz)
		SI_serialIn : in std_logic;
		SI_serialOut : out std_logic;

		-- Serial flash ports
		MCU_CS : out std_logic;
		MCU_SI : out std_logic;
		MCU_SO : in std_logic;

		clk : in std_logic;
		reset : in std_logic
	) ;
end entity ; -- AudioStage_tl

architecture arch of AudioStage_tl is

	-- Clocking constants (@ 100 MHz)
	constant clk10MHzDivider : natural := 10;
	constant clk9600HzDivider : natural := 10417;
	constant clk705KHzDivider : natural := 142; -- 705.6 KHz

	

	constant maxConfigRegisterAddress : natural := 2;
	constant uggabugga : std_logic_vector(15 downto 0) := "1000000000000000";

	signal sampleInputClk : std_logic;
	signal sampleOutput : std_logic_vector(11 downto 0);
	
	signal decimatorInput : std_logic_vector(15 downto 0);
	signal decimatorOutput : std_logic_vector(15 downto 0);
	signal decimatorInputb : std_logic_vector(15 downto 0);
	signal decimatorMuxedOutput : std_logic_vector(15 downto 0);
	
	
	signal controlClk : std_logic;
	signal softwareSerialClk : std_logic;

	signal throughputClk : std_logic;
	signal sampleClk : std_logic;
	-- signal decimatorClk : std_logic;
	signal echoClk : std_logic;
	signal effectInputEcho : std_logic_vector(15 downto 0);
	signal effectOutputEcho : std_logic_vector(15 downto 0);
    signal effectInputFlanger : std_logic_vector(15 downto 0);
	signal effectOutputFlanger : std_logic_vector(15 downto 0);
	signal effectInputReverb : std_logic_vector(15 downto 0);
	signal effectOutputReverb : std_logic_vector(15 downto 0);
	signal effectInputDistortion : std_logic_vector(15 downto 0);
	signal effectOutputDistortion : std_logic_vector(15 downto 0);
	signal DistortionSwitch : std_logic_vector(15 downto 0);

	signal decimatorMuxedOutputb : std_logic_vector(15 downto 0); -- Buffer Signals
    signal effectInputFlangerb : std_logic_vector(15 downto 0);
    signal effectInputReverbb : std_logic_vector(15 downto 0);
    signal effectInputDistortionb : std_logic_vector(15 downto 0);
    signal effectOutputDistortionb : std_logic_vector(15 downto 0);
    signal effectOutputDistortionSoft: std_logic_vector(15 downto 0);
    signal effectOutputDistortionHard: std_logic_vector(15 downto 0);

    signal temp_eq_in  : std_logic_vector(15 downto 0);
    signal temp_eq_out : std_logic_vector(15 downto 0);
    signal temp_check : std_logic_vector(15 downto 0);


	signal toPWM : std_logic_vector(8 downto 0);
	signal clkPWM : std_logic;
	signal serialClock_temp: std_logic;
	signal testSignal : std_logic_vector(19 downto 0);


	-- Control unit signals
	signal configRegisterBus : configurableRegisterBus;

	signal SI_msgCommand : std_logic_vector(15 downto 0);
	signal SI_msgPayload : std_logic_vector(15 downto 0);
	signal SI_dataOk : std_logic;
	signal SI_msgReady : std_logic;
	signal SI_clearDone : std_logic;
	signal MCU_execute : std_logic;
	signal MCU_clearDone : std_logic;
begin

	-- Control unit

	controlClkGenerator: entity work.ClockDivider
	generic map (
		divider => clk10MHzDivider -- 10 MHz
	)
	port map(
		reset => reset,
		clk => clk,
		clkOut => controlClk
	);

	softwareSerialGenerator: entity work.ClockDivider
	generic map (
		divider => clk9600HzDivider -- SoftwareInterfaceClock @ 9600 Hz
	)
	port map(
		reset => reset,
		clk => clk,
		clkOut => softwareSerialClk
	);

	SIU: entity work.SoftwareInterface
	port map (
		msgCommand => SI_msgCommand,
		msgPayload => SI_msgPayload,
		dataOk => SI_dataOk,
		msgReady => SI_msgReady,
		clearDone => SI_clearDone,
		serialIn => SI_serialIn,
		serialOut => SI_serialOut,
		serialClk => softwareSerialClk,
		reset => reset
	);

	MCU_PL : entity work.PulseLimiter
	port map (
		input => SI_msgReady,
		output => MCU_execute,

		clk => controlClk,
		reset => reset
	);

	MCU_PK : entity work.PulseKeeper
	generic map (
		duration => clk9600HzDivider/clk10MHzDivider
	)
	port map (
		input => MCU_clearDone,
		output => SI_clearDone,

		clk => controlClk,
		reset => reset
	);

	MCU: entity work.MemoryController
	generic map (
		numberRegisters => maxConfigRegisterAddress
	)
	port map (
		registerBus => configRegisterBus,

		command => SI_msgCommand,
		payload => SI_msgPayload,
		executeCommand => MCU_execute,
		clearDone => MCU_clearDone,

		CS => MCU_CS,
		SI => MCU_SI,
		SO => MCU_SO,

		clk => controlClk,
		reset => reset
	);


	-- Audio

	pwm_amp <= '1';
	leds <= temp_eq_out;

	sampleClkGenerator : entity work.ClockDivider
	generic map (
		divider => clk705KHzDivider
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
--------------------------DECIMATOR---------------------------------
	-- Concatenate 0's to create 16 bit input.
	--decimatorInput <= sampleOutput & "0000";
	--decimatorInput <= sampleOutput and (others => muteInput);
    -- testSignal <= (others => sampleOutput(11));
    decimatorInput <= sampleOutput & "0000" when sampleOutput(11) = '0' else
    					sampleOutput & "1111";

	decimatorInputb <= 	decimatorInput when muteInput = '0' else
						(others => '0');

	decimator: entity work.StructuralDecimator
	port map (
		input => decimatorInput,
		output => decimatorOutput,

		clk => clk,
		reset => reset
	);


	 decimatorMuxedOutput <=	decimatorOutput when bypassLP = '0' else
	 						decimatorInput;


	-- decimatorMuxedOutput <=	decimatorOutput(31 downto 16) when bypassLP = '0' else
	-- 						decimatorInput(31 downto 16);


	-- EFFECTS

	------------------------------------ECHO---------------------------------------------
buf_Dec2Echo: entity work.VectorRegister  
 			generic map(wordLength => 16 			-- buffer between Decimator and echo
 				)
 			port map(
 			input =>decimatorMuxedOutput, 
			output=>decimatorMuxedOutputb,
	
			clk => throughputClk,
			reset =>reset
	
 				);



	effectInputEcho <= decimatorMuxedOutputb;

	echoClkGenerator : entity work.ClockDivider
	generic map (
		--divider => 256 -- Clock at 8*44.1 kHz (Echo has 8 states per sample)
		divider => 128
	)
	port map (
		clk => clk,
		clkOut => echoClk,
		reset => reset
	);

	Echo: entity work.EffectEcho
	port map (
		input => effectInputEcho,
		output => effectOutputEcho,

		clk => echoClk,
		reset => reset
	);

effectInputFlanger <= effectOutputEcho when bypassEcho = '0' else
			      decimatorMuxedOutputb;

----------------------------FLANGER-----------------------------------------------
 buf_Echo2Fla: entity work.VectorRegister  
 		generic map(wordLength => 16 			-- buffer between echo and flanger
 			)
 		port map(
 		input =>effectInputFlanger, 
		output=>effectInputFlangerb,

		clk => throughputClk,
		reset =>reset

 			);



	Flanger: entity work.EffectFlanger
	generic map(
		wordLength =>16,
		constantsWordLength => 16,
		Depth => 440,
		sweepLength => 1000
		)
	port map (
		input => effectInputFlangerb,
		output => effectOutputFlanger,

		clk => echoClk,
		reset => reset
	);

	-- OUTPUT
    

	effectInputReverb <= effectOutputFlanger when bypassFlanger = '0' else
			      effectInputFlangerb;

--------------------------------REVERB----------------------------------------------
	buf_Fla2Rev: entity work.VectorRegister  
 		generic map(wordLength => 16 			-- buffer between flanger and reverb
 			)
 		port map(
 		input =>effectInputReverb, 
		output=>effectInputReverbb,

		clk => throughputClk,
		reset =>reset

 			);

	-- Reverb: entity work.EffectReverb
	-- generic map(
	-- 	IO_length => 16,
	-- 	c_length => 16,
	-- 	addr_length  => 12)
	-- port map(
	-- 	input => effectInputReverbb,
	-- 	output => effectOutputReverb,

	-- 	clk =>echoClk,
	-- 	reset =>reset
	-- );

	-- effectInputDistortion <= effectOutputReverb when bypassReverb = '0' else
	-- 					effectInputReverbb;
effectInputDistortion <= effectInputReverbb when bypassReverb = '0' else
						effectInputReverbb;

----------------------------DISTORTION-----------------------------------------------


buf_beforeDist: entity work.VectorRegister  
 		generic map(wordLength => 16 			-- buffer before Distortion
 			)
 		port map(
 		input =>effectInputDistortion, 
		output=>effectInputDistortionb,

		clk => throughputClk,
		reset =>reset

 			);	

	Distortion: entity work.EffectDistortion
	generic map( DATA_WIDTH => 16,
                 ADDR_WIDTH => 16
               )
	port map(
		ADDR =>effectInputDistortionb,
		output=>effectOutputDistortionSoft,
		clk => throughputClk
		-- reset =>reset
	);		     
DistortionSwitch <= effectOutputDistortionSoft when bypassDistortionSelect = '0' else
			      effectOutputDistortionHard;


Distortion2: entity work.hard_dist
	generic map(wordlength => 16,
			coeff_address => 13)
	port map(
		input =>effectInputDistortionb,
		output=>effectOutputDistortionHard,
		clk => throughputClk,
		reset =>reset
	);

temp_eq_in <= DistortionSwitch when bypassDistortionEnable = '0' else
			      effectInputDistortionb;

buf_afterDist: entity work.VectorRegister  
 		generic map(wordLength => 16 			-- buffer after Distortion
 			)
 		port map(
 		input =>temp_eq_in, 
		output=>temp_eq_out,

		clk => throughputClk,
		reset =>reset

 			);



----------------------------EQUALIZER----------------------------------------------

	EqualizerClkGenerator : entity work.ClockDivider
	generic map (
		-- divider => 2048 -- Clock at 1*44.1 kHz(2^11) (Recommended Clock for Equalizer)
		divider => 1024 -- Clock at 1*44.1 kHz (2^10)(Recommended Clock for Equalizer)
	)
	port map (
		clk => clk,
		clkOut => throughputClk,
		reset => reset 
	);

	-- temp_eq_out <= temp_eq_in;

	-- EQ: entity work.Generic_Equalizer_Low_Pass
	-- port map(
	-- 	clk => throughputClk,
	-- 	reset => reset,
	-- 	input  => temp_eq_in, 
	-- 	output => temp_eq_out
	-- );

   toPWM <= temp_eq_out(15 downto 7);
 
	-- toPWM <= temp_eq_out(15 downto 7) when bypassEQ = '0' else
	-- 	     temp_eq_in(15 downto 7);

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


	clockSerial : entity work.ClockDivider
	generic map (
		-- divider => 128 --2^11*44.1 k to 705.6 k
		-- divider => 76 -- 2^10*44.1k 100 MHz to 705.6 kHz.
		divider => 32
	)
	port map (
		clk => clk,
		clkOut => serialClock_temp,
		reset => reset
	);

	temp_check <= std_logic_vector(signed(temp_eq_out)+signed(uggabugga));
	sclk <= serialClock_temp;
	-- tempclock <= throughputClk;
	da:entity work.DA
	generic map(
		width => 16
		)
	port map(
	   clk =>serialClock_temp,
       reset =>reset,
       sample_clk => throughputClk,
       data => temp_check,
       CS =>cs,
       SDI =>toDA
	);

end architecture ; -- arch
