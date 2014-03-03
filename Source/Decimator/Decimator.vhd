library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity Decimator is
generic(wordLength : natural := 16);
  port (
	clk: in std_logic;
	reset: in std_logic;
	input: in std_logic_vector(wordLength-1 downto 0);
	output: out std_logic_vector(wordLength-1 downto 0)
  );
end entity ; -- Decimator

architecture arch of Decimator is

signal out_stage1: std_logic_vector(wordLength-1 downto 0);
signal out_stage2: std_logic_vector(wordLength-1 downto 0);
signal out_stage3: std_logic_vector(wordLength-1 downto 0);
signal out_stage4: std_logic_vector(wordLength-1 downto 0);
signal clk1: std_logic;
signal clk2: std_logic;
signal clk3: std_logic;
signal clk4: std_logic;

begin


--Stage 1
clk_1:entity work.ClockDivider 
	generic map(divider => 71) -- 50M/(44100*16)=70.861
	port map(
		reset => reset,
		clk => clk,
		clkOut=>clk1
		);
fiter_1:entity work.FIR
	generic map( wordLength=>wordLength,
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
		output=> out_stage1,
		clk => clk1,
		reset => reset
		);


--Stage 2
clk_2:entity work.ClockDivider 
	generic map(divider => 2)
	port map(
		reset => reset,
		clk => clk1,
		clkOut=>clk2
		);

fiter_2:entity work.FIR
		generic map( wordLength=>wordLength,
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
			output=> out_stage2,
			clk => clk2,
			reset => reset
			);

--Stage 3
clk_3:entity work.ClockDivider 
	generic map(divider => 2)
	port map(
		reset => reset,
		clk => clk2,
		clkOut=>clk3
		);
fiter_3:entity work.FIR
		generic map( wordLength=>wordLength,
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
			output=> out_stage3,
			clk => clk3,
			reset => reset
			);

--Stage 4
clk_4:entity work.ClockDivider 
	generic map(divider => 2)
	port map(
		reset => reset,
		clk => clk3,
		clkOut=>clk4
		);
fiter_4:entity work.FIR
		generic map( wordLength=>wordLength,
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
			output=> out_stage4,
			clk => clk4,
			reset => reset
			);
output<= out_stage4;

end architecture ; -- arch
