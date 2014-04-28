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
		bypassEcho : in std_logic;
		bypassFlanger : in std_logic;
		bypassReverb : in std_logic;
		bypassDistortion : in std_logic;
		bypassEQ : in std_logic;

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

	signal decimatorMuxedOutputb : std_logic_vector(15 downto 0); -- Buffer Signals
    signal effectInputFlangerb : std_logic_vector(15 downto 0);
    signal effectInputReverbb : std_logic_vector(15 downto 0);
    signal effectInputDistortionb : std_logic_vector(15 downto 0);
    signal effectOutputDistortionb : std_logic_vector(15 downto 0);


    signal temp_eq_in  : std_logic_vector(15 downto 0);
    signal temp_eq_out : std_logic_vector(15 downto 0);
	
	signal toPWM : std_logic_vector(8 downto 0);
	signal clkPWM : std_logic;

	signal testSignal : std_logic_vector(19 downto 0);
begin

	pwm_amp <= '1';
	leds <= effectInputEcho;

	sampleClkGenerator : entity work.ClockDivider
	generic map (
		-- divider => 128 --2^11*44.1 k to 705.6 k
		divider => 64 -- 2^10*44.1k 100 MHz to 705.6 kHz.
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
	decimatorInput <= 	sampleOutput & x"0" when muteInput = '0' else
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

	Reverb: entity work.EffectReverb
	generic map(
		IO_length => 16,
		c_length => 16,
		addr_length  => 12)
	port map(
		input => effectInputReverbb,
		output => effectOutputReverb,

		clk =>echoClk,
		reset =>reset
	);

	effectInputDistortion <= effectOutputReverb when bypassReverb = '0' else
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
	generic map(DATA_WIDTH => 16,
              ADDR_WIDTH => 16)
	port map(
		addr =>effectInputDistortionb,
		output=>effectOutputDistortion,
		clk => echoClk
	);		     

buf_afterDist: entity work.VectorRegister  
 		generic map(wordLength => 16 			-- buffer after Distortion
 			)
 		port map(
 		input =>temp_eq_in, 
		output=>temp_eq_out,

		clk => throughputClk,
		reset =>reset

 			);
temp_eq_in <= effectOutputDistortion when bypassDistortion = '0' else
			      effectInputDistortionb;


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

end architecture ; -- arch