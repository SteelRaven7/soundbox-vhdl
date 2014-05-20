--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Description:                                                               --
-- This file initiates a soft distortion. The memory is instantiated using    --
-- the LUT_Distortion.coe file.                                               --
--                                                                            --
-- Generic:                                                                   --
-- wordlength        - Wordlength of the input/output signals.				  --
--                                                                            --
-- Input/Output:                                                              --
-- input             - Input signal                                           --
-- output            - Output signal                                          --
-- config            - Bus from the control unit.                             --
-- reset             - resets the effect.                        			  --
-- CLK               - The clock, fs.                                         --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.memory_pkg.all;

entity hard_dist is
	generic(wordlength : integer := 16);
	port(input : in std_logic_vector(wordlength-1 downto 0);
		output : out std_logic_vector(wordlength-1 downto 0);
		config : in configurableRegisterBus;
		reset : in std_logic;
		clk : in std_logic);
end hard_dist;

architecture behav of hard_dist is
	
	signal cutoff : std_logic_vector(wordlength-1 downto 0);
	signal cutoff_int : integer;
	signal neg_cutoff : integer;
	signal outReg : std_logic_vector(wordlength-1 downto 0);
	signal input_int : integer;
	
	begin
	
	confReg: entity work.ConfigRegister
	generic map(
		wordLength => 16,
		address => std_logic_vector(to_unsigned(11,16))
	)
	port map(
		input => config,
		output => cutoff,

		reset => reset
	);
	
	cutoff_int <= to_integer(signed(cutoff));
	neg_cutoff <= 0-cutoff_int;
	input_int <= to_integer(signed(input));
	output <= outReg;
	
	------ COMPARE PROCESS ------
	
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
		
		
		
		