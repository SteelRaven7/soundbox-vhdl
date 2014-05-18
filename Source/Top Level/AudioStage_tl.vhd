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
		switches : in std_logic_vector(15 downto 0);

		cs: out std_logic;
		sclk: out std_logic;
		toDA: out std_logic;
		tempclock : out std_logic;

		-- Serial interface (RS-232/UART @ 9600 Hz)
		SI_serialIn : in std_logic;
		SI_serialOut : out std_logic;

		-- Serial flash ports
		MCU_CS : out std_logic;
		MCU_SI : out std_logic;
		MCU_SO : in std_logic;

		clk : in std_logic;
		reset : in std_logic;
		eq1 :in std_logic;
		eq2 : in std_logic
		
	) ;
end entity ; -- AudioStage_tl

architecture arch of AudioStage_tl is

	-- Clocking constants (@ 100 MHz)
	constant clk10MHzDivider : natural := 10;
	constant clk9600HzDivider : natural := 10417;
	--constant clk705KHzDivider : natural := 142;
	constant clk1410KHzDivider : natural := 71;  -- 2*705.6 KHz

	--constant maxConfigRegisterAddress : natural := 1000;
	constant maxConfigRegisterAddress : natural := 10;

 constant bitvec1 : std_logic_vector(3 downto 0) := "1111";
 constant bitvec0 : std_logic_vector(3 downto 0) := "0000";
	-- Switches
	signal muteInput : std_logic;
	signal bypassLP : std_logic;
	signal bypassEcho : std_logic;
	signal bypassFlanger : std_logic;
	signal bypassReverb : std_logic;
	signal bypassDistortionSelect : std_logic;
	signal bypassDistortionEnable : std_logic;
	signal bypassEQ : std_logic;

	signal ledReg : std_logic_vector(15 downto 0);

	signal sampleInputClk : std_logic;
	signal sampleOutput : std_logic_vector(11 downto 0);
	
	signal decimatorInput : std_logic_vector(15 downto 0);
	signal decimatorOutput : std_logic_vector(15 downto 0);
	signal decimatorInputb : std_logic_vector(15 downto 0);
	signal decimatorInputbb : std_logic_vector(15 downto 0);
	signal decimatorMuxedOutput : std_logic_vector(15 downto 0);
	
	
	signal controlClk : std_logic;
	signal softwareSerialClk : std_logic;

	signal throughputClk : std_logic;
	signal sampleClk : std_logic;
	signal ledClk : std_logic;
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

	--signal decimatorMuxedOutputb : std_logic_vector(15 downto 0); -- Buffer Signals
	signal decimatorOutputb : std_logic_vector(15 downto 0);
	signal equalizerIn : std_logic_vector(15 downto 0);
	signal equalizerOut: std_logic_vector(15 downto 0);
	signal temptoDA : std_logic_vector(15 downto 0);
	signal DistortionSwitchb : std_logic_vector(15 downto 0);
    signal effectInputFlangerb : std_logic_vector(15 downto 0);
    signal effectInputReverbb : std_logic_vector(15 downto 0);
    signal effectInputDistortionb : std_logic_vector(15 downto 0);
    signal effectOutputDistortionb : std_logic_vector(15 downto 0);
    signal effectOutputDistortionSoft: std_logic_vector(15 downto 0);
    signal effectOutputDistortionHard: std_logic_vector(15 downto 0);
    signal bufferbeforeDA : std_logic_vector(15 downto 0);
   

    signal temp_eq_in  : std_logic_vector(15 downto 0);
    signal temp_eq_out : std_logic_vector(15 downto 0);
    signal temp_check : std_logic_vector(15 downto 0);
    signal eq_gain_1 : std_logic_vector(2 downto 0);
    signal eq_gain_2 : std_logic_vector(2 downto 0);
    signal eq_gain_3 : std_logic_vector(2 downto 0);
    signal eq_gain_4 : std_logic_vector(2 downto 0);
    signal eq_gain_5 : std_logic_vector(2 downto 0);


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

	signal debugAddress : std_logic_vector(15 downto 0);
begin

	muteInput <= switches(0);
	bypassLP <= switches(1);
	bypassEcho <= switches(2);
	bypassFlanger <= switches(3);
	bypassReverb <= switches(4);
	bypassDistortionEnable <= switches(5);
	bypassDistortionSelect <= switches(6);
	bypassEQ <= switches(7);

-------------------------------------Multiplexers---------------------------------------------------------

decimatorInputb <= 	decimatorInput when muteInput = '0' else                   -- Enable or Disable Input
						(others => '0');


effectInputDistortion <= decimatorOutputb when bypassLP = '0' else              -- Bypass Decimator
						decimatorInputb;



equalizerIn <= DistortionSwitchb when bypassDistortionEnable = '0' else          -- Bypass Distortion
					effectInputDistortion ;

DistortionSwitch <= effectOutputDistortionSoft when bypassDistortionSelect = '0' else    -- Select between hard and soft distortion
			      effectOutputDistortionHard;


effectInputFlanger <= equalizerOut when bypassEQ ='0' else                          -- Bypass equalizer
					equalizerIn ;

effectInputEcho <= effectOutputFlanger when bypassFlanger = '0' else          -- Bypass flanger
			      effectInputFlangerb;		      

effectInputReverb <= effectOutputEcho when bypassEcho = '0' else               -- Bypass echo
			      effectInputEcho;
				
bufferbeforeDA <= effectOutputReverb when bypassReverb = '0' else                -- Bypass reverb
				effectInputReverbb;

	-- Control unit

	------------------------------------Software Interface----------------------------------------------------

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

--debugAddress<= x"00" & switches(15 downto 8);
--DebugConfig : entity work.DebugConfigRegister
--port map (
--	input => configRegisterBus,
--	output => leds,
--	address => debugAddress,
--	reset => reset
--);
	-- Audio

	pwm_amp <= '1';

	ledregister: entity work.VectorRegister  
 		generic map(wordLength => 16 
 		)                            			-- buffer before DA
 		port map(
 		input =>ledReg, 
		output=>leds,

		clk => ledclk,
		reset =>reset

 			);

	ledReg <= temptoDA when temptoDA(15) = '0' else
			not temptoDA;


	--------------------------CLOCKS-------------------------------------
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

	sampleSPIGenerator : entity work.ClockDivider 
	generic map (                                -- SPI clock for DA
		divider => clk1410KHzDivider             --71
	)
	port map (
		clk => clk,
		clkOut => serialClock_temp,
		reset => reset
	);

	sampleClkGenerator : entity work.ClockDivider
	generic map (
		divider => 2                               -- 142
	)
	port map (
		clk => serialClock_temp,
		clkOut => sampleInputClk,
		reset => reset
	);

	clkThroughPut: entity work.ClockDivider
	generic map (
		divider => 16                               -- 2272 for 44.1KHz
	)
	port map (
		clk => sampleInputClk,
		clkOut => throughputClk,
		reset => reset
	);

	clkLEDs: entity work.ClockDivider
	generic map (
		divider => 10
	)
	port map (
		clk => throughputClk,
		clkOut => ledclk,
		reset => reset
	);

	------------- INPUT XADC --------------------------

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
	
    decimatorInput <= sampleOutput & bitvec0 when sampleOutput(11) = '0' else
    				sampleOutput & bitvec1 ;

    buf_beforeDEC: entity work.VectorRegister  
 		generic map(wordLength => 16 
 		)                            			-- buffer before DA
 		port map(
 		input =>decimatorInputb, 
		output=>decimatorInputbb,

		clk => sampleInputClk,
		reset =>reset

 			);

	
	decimator: entity work.Decimator_test
	port map (
		clk => sampleInputClk,
		clkS => throughputClk,
		reset=> reset,
		input=> decimatorInputbb,
		output=>decimatorOutput
	);


	


	
	-- EFFECTS

	------------------------------------ECHO---------------------------------------------
buf_Dec2Echo: entity work.VectorRegister  
 			generic map(wordLength => 16 			-- buffer between Decimator and echo
 				)
 			port map(
 			input =>decimatorOutput, 
			output=>decimatorOutputb,
	
			clk => throughputClk,
			reset =>reset
	
 				);



	

	echoClkGenerator : entity work.ClockDivider
	generic map (
	
		divider => 2
	)
	port map (
		clk => sampleInputClk,
		clkOut => echoClk,
		reset => reset
	);

	Echo: entity work.EffectEcho
	port map (
		input => effectInputEcho,
		output => effectOutputEcho,
		configBus => configRegisterBus,

		clk => echoClk,
		reset => reset
	);


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
		constantsWordLength => 16
--		Depth => 440,
--		sweepLength => 1000
		)
	port map (
		input => effectInputFlangerb,
		output => effectOutputFlanger,

		configBus => configRegisterBus,
		clk => echoClk,
		reset => reset
	);

	-- OUTPUT
    


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

	Reverb: entity work.EffectReverb
	generic map(
		IO_length => 16,
		c_length => 16,
		addr_length  => 12)
	port map(
		input => effectInputReverbb,
		output => effectOutputReverb,
		configBus => configRegisterBus,

		clk =>echoClk,
		reset =>reset
	);


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


Distortion2: entity work.hard_dist
	generic map(wordlength => 16,
			coeff_address => 11)
	port map(
		input =>effectInputDistortionb,
		output=>effectOutputDistortionHard,
		config => configRegisterBus,
		reset =>reset,
		clk => throughputCLK
	);


buf_afterDist: entity work.VectorRegister  
 		generic map(wordLength => 16 			-- buffer after Distortion
 			)
 		port map(
 		input =>DistortionSwitch, 
		output=>DistortionSwitchb,

		clk => throughputClk,
		reset =>reset

 			);



----------------------------EQUALIZER----------------------------------------------
  eq_process: process(throughputClk)
    begin
    	if rising_edge(throughputClk) then -- 000 = 12db, 001 = 6db, 010 = 0db, 011 = -6db, 100 = -12db, 
        if((eq1 = '0') and (eq2 = '0')) then
            eq_gain_1 <= "000";                   -- Lowest band
            eq_gain_2 <= "000";                   -- Low band
            eq_gain_3 <= "010";                   -- Mid band
            eq_gain_4 <= "010";                   -- high band
            eq_gain_5 <= "010";                   -- Highest band
        elsif((eq1 = '0') and (eq2 = '1')) then  
            eq_gain_1 <= "010";
            eq_gain_2 <= "010";
            eq_gain_3 <= "100";
            eq_gain_4 <= "000";
            eq_gain_5 <= "010";
        elsif((eq1 = '1') and (eq2 = '0')) then          
            eq_gain_1 <= "000";
            eq_gain_2 <= "000";
            eq_gain_3 <= "000";
            eq_gain_4 <= "000";
            eq_gain_5 <= "000";
        else
            eq_gain_1 <= "010";
            eq_gain_2 <= "010";
            eq_gain_3 <= "010";
            eq_gain_4 <= "010";
            eq_gain_5 <= "010";
        end if;
    end if;
    end process;


	
	
	 EQ: entity work.Equalizer
	 generic map(NO_SECTIONS  => 16, 

                 INPUT_WIDTH    => 16,
                 INPUT_FRACT    => 16,
                 OUTPUT_WIDTH   => 16,
                 OUTPUT_FRACT   => 16,
    
                 SCALE_WIDTH    => 20,
                 SCALE_FRACT    => (16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16),
    
                 INTERNAL_WIDTH => 20,
                 INTERNAL_FRACT => 16,
    
                 COEFF_WIDTH_B  => 20,
                 COEFF_FRACT_B  => (16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16),
                 COEFF_WIDTH_A  => 20,
                 COEFF_FRACT_A  => (16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16)
            )
	 port map(clk    => throughputClk,
	 	        reset  => reset,
	 	        x      => equalizerIn, 
    
              b_1_gain => eq_gain_1,
              b_2_gain => eq_gain_2,
              b_3_gain => eq_gain_3,
              b_4_gain => eq_gain_4,
              b_5_gain => eq_gain_5,
    
	          y      => equalizerOut
	          );



-----------------------------------------------DAC---------------------------------------------------

  toPWM <= temptoDA(15 downto 7);
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

buf_beforeDA: entity work.VectorRegister  
 		generic map(wordLength => 16 
 		)                            			-- buffer before DA
 		port map(
 		input =>bufferbeforeDA, 
		output=>temptoDA,

		clk => throughputClk,
		reset =>reset

 			);




	temp_check <= not temptoDA(15) & temptoDA(14 downto 0);
	sclk <= serialClock_temp;
   tempclock <= throughputClk;
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
