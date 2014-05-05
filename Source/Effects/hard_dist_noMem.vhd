library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--use work.memory_pkg.all;

entity hard_dist is
	generic(wordlength : integer := 16;
			coeff_address : integer := 13);
	port(input : in std_logic_vector(wordlength-1 downto 0);
		output : out std_logic_vector(wordlength-1 downto 0);
		clk : in std_logic;
		reset : in std_logic
		);
end hard_dist;

architecture behav of hard_dist is
	
	constant cutoff_int : integer := 10000;
	constant neg_cutoff : integer := -10000;
	signal outReg : std_logic_vector(wordlength-1 downto 0);
	signal input_int : integer;
	
	begin
	
	input_int <= to_integer(signed(input));
	output <= outReg;
	
	process(clk,reset)
		begin
			if reset = '1' then
				outReg <= (others => '0');
			elsif rising_edge(clk) then
				if input_int > cutoff_int then
					outReg <= std_logic_vector(to_signed(cutoff_int,16));
				elsif input_int < neg_cutoff then
					outReg <= std_logic_vector(to_signed(neg_cutoff,16));
				else
					outReg <= input;
				end if;
			else
			end if;
	end process;
end behav;
		
		
		
		