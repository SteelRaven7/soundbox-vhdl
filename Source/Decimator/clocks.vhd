----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/23/2014 08:47:07 PM
-- Design Name: 
-- Module Name: clocks - arch_clocks
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- ----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity clocks is
     GENERIC(c1:INTEGER :=2);-- 1133.7868/2 for 44100x16 Hz
             -- c2:INTEGER :=1134;--  2267.57
             -- c3:INTEGER :=2268;--  4535.147
             -- c4:INTEGER :=9070);-- 9070.29 
    Port ( clk : in STD_LOGIC;
    	   reset : in STD_LOGIC;
           sample_clk1 : out STD_LOGIC;
           sample_clk2 : out STD_LOGIC;
           sample_clk3 : out STD_LOGIC;
           sample_clk4 : out STD_LOGIC);
end clocks;

architecture arch_clocks of clocks is
signal sample_clk1_temp : STD_LOGIC:='0';
signal sample_clk2_temp : STD_LOGIC:='0';
signal sample_clk3_temp : STD_LOGIC:='0';
signal sample_clk4_temp : STD_LOGIC:='0';

begin
process(clk,reset)
variable counter,c2,c3,c4: INTEGER:= 0;
	begin
	if(reset='1') then
	sample_clk1 <= '0';
	sample_clk2 <= '0';
	sample_clk3 <= '0';
	sample_clk4 <='0';
elsif clk ='1' and rising_edge(clk) then
		if (counter=c1) then
		sample_clk1 <= sample_clk1_temp;
		sample_clk1_temp <= not sample_clk1_temp;
		counter := 0;
        c2 := c2 +1;
        	if c2 =2 then
        	sample_clk2 <= sample_clk2_temp;
			sample_clk2_temp <= not sample_clk2_temp;
			c3 := c3 +1;
			c2 := 0; 
				if c3=2 then
				sample_clk3 <= sample_clk3_temp;
			    sample_clk3_temp <= not sample_clk3_temp;
			    c4 := c4 +1;
			    c3 := 0; 
                	if c4=2 then 
                		sample_clk4 <= sample_clk4_temp;
			    		sample_clk4_temp <= not sample_clk4_temp;
			    		c4 := 0; 
                	end if;
            	end if;
        	end if;
    	end if;
	counter := counter +1;
end if;
	end process;

end arch_clocks;
