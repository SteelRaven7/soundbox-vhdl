library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.filter_pkg.all;

entity Decimator_test is
	port (
		clk: in std_logic;
		clkS : in std_logic;
		reset: in std_logic;
		input: in std_logic_vector(15 downto 0);
		output: out std_logic_vector(15 downto 0)
	);
end entity ;

architecture behav of Decimator_test is

	signal fir1_out : std_logic_vector(15 downto 0);

	--signal clk5: std_logic;
begin
	

--	clk_5: entity work.ClockDivider
--	generic map(
--		divider => 16
--	)
--	port map(
--		reset => reset,
--		clk => clk,	--(44100*2^1)
--		clkOut=>clk5 --(44100*2^0)
--	);
--



	
	downsampler1: entity work.VectorRegister
	generic map(
		wordLength => 16
	)
	port map(
		input=> fir1_out,
		output=> output,
		clk=>clkS,	--(44100*2^3)
		reset=> reset
	);

	
	filter1: entity work.FIR_test
	generic map(Order => 50,
          IO_length => 16,
          M_length => 32,
		  coeffs => (-1,
					-3,
					-7,
					-15,
					-28,
					-47,
					-74,
					-107,
					-144,
					-179,
					-206,
					-214,
					-192,
					-129,
					-12,
					166,
					407,
					710,
					1062,
					1449,
					1845,
					2224,
					2557,
					2817,
					2983,
					3040,
					2983,
					2817,
					2557,
					2224,
					1845,
					1449,
					1062,
					710,
					407,
					166,
					-12,
					-129,
					-192,
					-214,
					-206,
					-179,
					-144,
					-107,
					-74,
					-47,
					-28,
					-15,
					-7,
					-3,
					-1))
	port map(RESET => reset,
       CLK => clk,
       input => input,
       output => fir1_out
	   );
	
	
	
end behav;