--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:40:27 02/07/2014
-- Design Name:   
-- Module Name:   C:/SoundboxProject/Source/soundbox-vhdl/Source/Utilities/Decimator_tb.vhd
-- Project Name:  SoundboxProject
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: Decimator
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY Decimator_tb IS
END Decimator_tb;
 
ARCHITECTURE behavior OF Decimator_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
    

   --Inputs
   signal input : std_logic_vector(7 downto 0) := (others => '0');
   signal reset : std_logic := '0';
   signal clk : std_logic := '0';

 	--Outputs
   signal output : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: entity work.Decimator 
   generic map(
      divider => 4
    )
   port map(
          input => input,
          output => output,
          reset => reset,
          clk => clk
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      reset <= '1';
      wait for 100 ns;	
      reset <= '0';

      input <= (others => '0');

      wait for clk_period*10;

      input <= (others => '1');

      wait for clk_period*10;

      input <= (others => '0');

      wait for clk_period;
      input <= x"F1";
      wait for clk_period;
      input <= x"F2";
      wait for clk_period;
      input <= x"F3";
      wait for clk_period;
      input <= x"F4";
      wait for clk_period;
      input <= x"F5";
      wait for clk_period;
      input <= x"F6";
      wait for clk_period;
      input <= x"F7";
      wait for clk_period;
      input <= x"F8";
      wait for clk_period;
      input <= x"F9";

      -- insert stimulus here 

      wait;
   end process;

END;
