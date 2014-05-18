library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.memory_pkg.all;

entity hard_dist is
	generic(wordlength : integer := 16;
			coeff_address : integer := 13);
	port(input : in std_logic_vector(wordlength-1 downto 0);
		output : out std_logic_vector(wordlength-1 downto 0);
		config : in configurableRegisterBus;
		reset : in std_logic;
		clk : in std_logic);
end hard_dist;

architecture behav of hard_dist is
	
	signal cutoff : std_logic_vector(wordlength-1 downto 0);
	signal cutoff_int : integer := 20000;
	signal neg_cutoff : integer := -20000;
	signal outReg : std_logic_vector(wordlength-1 downto 0);
	signal input_int : integer;
	
	begin
	
	confReg: entity work.ConfigRegister
	generic map(
		wordLength => 16,
		address => std_logic_vector(to_unsigned(coeff_address,16))
	)
	port map(
		input => config,
		output => cutoff,

		reset => reset
	);
	
	cutoff_int <= to_integer(signed(cutoff));
	neg_cutoff <= -cutoff_int;
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
		
		
		
		