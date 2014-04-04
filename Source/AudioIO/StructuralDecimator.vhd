library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all ;

entity StructuralDecimator is
	port (
		clk: in std_logic;
		reset: in std_logic;
		input: in std_logic_vector(11 downto 0);
		output: out std_logic_vector(15 downto 0)
	);
end entity ; -- StructuralDecimator

architecture arch of StructuralDecimator is
	constant internalWordLength : natural := 20;
	constant internalFractions : natural := 18;

	signal out_stage1: std_logic_vector(internalWordLength-1 downto 0);
	signal out_stage2: std_logic_vector(internalWordLength-1 downto 0);
	signal out_stage3: std_logic_vector(internalWordLength-1 downto 0);
	signal out_stage4: std_logic_vector(15 downto 0);
	signal fir1_out : std_logic_vector(internalWordLength-1 downto 0);
	signal fir2_out : std_logic_vector(internalWordLength-1 downto 0);
	signal fir3_out : std_logic_vector(internalWordLength-1 downto 0);
	signal fir4_out : std_logic_vector(15 downto 0);

	signal clk1: std_logic;
	signal clk2: std_logic;
	signal clk3: std_logic;
	signal clk4: std_logic;
	signal clk5: std_logic;
begin
	
	
	clk_1: entity work.ClockDivider
	generic map(
		divider => 128 -- 44100*2^11/(44100*2^4)=2^7
	)
	port map(
		reset => reset,
		clk => clk,	
		clkOut=>clk1 --(44100*2^4)
	);

	clk_2: entity work.ClockDivider
	generic map(
		divider => 2
	)
	port map(
		reset => reset,
		clk => clk1,	-- (44100*2^4)
		clkOut=>clk2 	-- (44100*2^3)
	);

	clk_3: entity work.ClockDivider
	generic map(
		divider => 2
	)
	port map(
		reset => reset,
		clk => clk2,	--(44100*2^3)
		clkOut=>clk3 --(44100*2^2)
	);

	clk_4: entity work.ClockDivider
	generic map(
		divider => 2
	)
	port map(
		reset => reset,
		clk => clk3,	--(44100*2^2)
		clkOut=>clk4 --(44100*2^1)
	);

	clk_5: entity work.ClockDivider
	generic map(
		divider => 2
	)
	port map(
		reset => reset,
		clk => clk4,	--(44100*2^1)
		clkOut=>clk5 --(44100*2^0)
	);




	
	downsampler1: entity work.VectorRegister
	generic map(
		wordLength => internalWordLength
	)
	port map(
		input=> fir1_out,
		output=> out_stage1,
		clk=>clk2,	--(44100*2^3)
		reset=> reset
	);

	downsampler2: entity work.VectorRegister
	generic map(
		wordLength => internalWordLength
	)
	port map(
		input=> fir2_out,
		output=> out_stage2,
		clk=>clk3,	--(44100*2^2)
		reset=> reset
	);

	downsampler3: entity work.VectorRegister
	generic map(
		wordLength => internalWordLength
	)
	port map(
		input=> fir3_out,
		output=> out_stage3,
		clk=>clk4,	--(44100*2^1)
		reset=> reset
	);

	downsampler4: entity work.VectorRegister
	generic map(
		wordLength => 16
	)
	port map(
		input=> fir4_out,
		output=> out_stage4,
		clk=>clk5,	--(44100*2^0)
		reset=> reset
	);
	
	
	
	fiter_1: entity work.FIR
	generic map(
		
		wordLength => 12,
		fractionalBits => 11,

		coeffWordLength => 12,
		coeffFractionalBits => 11,

		sumWordLength => internalWordLength,
		sumFractionalBits => internalFractions,

		outputWordLength => internalWordLength,
		outputFractionalBits => internalFractions,

		order => 6,
		coefficients => (
			-0.03173828125,
			0.0,
			0.28173828125,
			0.5,
			0.28173828125,
			0.0,
			-0.03173828125
		)
	)
	port map(
		input=> input,
		output=> fir1_out,
		clk => clk1,	--(44100*2^4)
		reset => reset
	);



	--Stage 2
	fiter_2: entity work.FIR
	generic map(
		
		wordLength => internalWordLength,
		fractionalBits => internalFractions,

		coeffWordLength => 12,
		coeffFractionalBits => 11,

		sumWordLength => internalWordLength,
		sumFractionalBits => internalFractions,

		outputWordLength => internalWordLength,
		outputFractionalBits => internalFractions,

		order => 6,
		coefficients => (
			-0.033203125,
			0.0,
			0.28271484375,
			0.5,
			0.28271484375,
			0.0,
			-0.033203125
		)
	)

	port map(
		input=> out_stage1,
		output=> fir2_out,
		clk => clk2, -- (44100*2^3)
		reset => reset
	);
	


	--Stage 3
	fiter_3: entity work.FIR
	generic map(
		wordLength => internalWordLength,
		fractionalBits => internalFractions,

		coeffWordLength => 12,
		coeffFractionalBits => 11,

		sumWordLength => internalWordLength,
		sumFractionalBits => internalFractions,

		outputWordLength => internalWordLength,
		outputFractionalBits => internalFractions,

		order => 6,
		coefficients => (
			-0.0390625,
			0.0,
			0.28759765625,
			0.5,
			0.28759765625,
			0.0,
			-0.0390625
		)
	)
	port map(
		input=> out_stage2,
		output=> fir3_out,
		clk => clk3,	--(44100*2^2)
		reset => reset
	);



	--Stage 4
	fiter_4: entity work.FIR
	generic map(
		wordLength => internalWordLength,
		fractionalBits => internalFractions,

		coeffWordLength => 12,
		coeffFractionalBits => 11,

		sumWordLength => internalWordLength,
		sumFractionalBits => internalFractions,

		outputWordLength => 16,
		outputFractionalBits => 15,

		order => 14,
		coefficients => (
			-0.01025390625,
			0.0,
			0.03173828125,
			0.0,
			-0.083984375,
			0.0,
			0.31005859375,
			0.5,
			0.31005859375,
			0.0,
			-0.083984375,
			0.0,
			0.03173828125,
			0.0,
			-0.01025390625
		)
	)
	port map(
		input=> out_stage3,
		output=> fir4_out,
		clk => clk4,
		reset => reset
	);

	output<= out_stage4;

end architecture ; -- arch