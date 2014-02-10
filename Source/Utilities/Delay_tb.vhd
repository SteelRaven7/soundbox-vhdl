--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   11:06:25 02/10/2014
-- Design Name:   
-- Module Name:   C:/SoundboxProject/Source/soundbox-vhdl/Source/Utilities/Delay_tb.vhd
-- Project Name:  SoundboxProject
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: Delay
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
 
ENTITY Delay_tb IS
END Delay_tb;
 
ARCHITECTURE behavior OF Delay_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT Delay
    PORT(
         input : IN  std_logic_vector(7 downto 0);
         output : OUT  std_logic_vector(7 downto 0);
         clk : IN  std_logic;
         reset : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal input : std_logic_vector(7 downto 0) := (others => '0');
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';

 	--Outputs
   signal output : std_logic_vector(7 downto 0);
   signal output2 : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: Delay PORT MAP (
          input => input,
          output => output,
          clk => clk,
          reset => reset
        );

   uut2: Delay PORT MAP (
          input => output,
          output => output2,
          clk => clk,
          reset => reset
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

      wait for clk_period*10;

      input <= x"FF";
      wait for clk_period*2;
      input <= x"0F";
      wait for clk_period*2;
      input <= x"01";
      wait for clk_period;
      input <= x"02";
      wait for clk_period;
      input <= x"11";
      wait for clk_period;
      input <= x"21";
      wait for clk_period;

      -- insert stimulus here 

      wait;
   end process;

END;
