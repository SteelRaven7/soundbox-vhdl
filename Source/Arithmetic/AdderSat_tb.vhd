--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   09:58:41 03/07/2014
-- Design Name:   
-- Module Name:   Z:/SourceSim/Source/Arithmetic/AdderSat_tb.vhd
-- Project Name:  SoundboxSim
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: AdderSat
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
 
ENTITY AdderSat_tb IS
END AdderSat_tb;
 
ARCHITECTURE behavior OF AdderSat_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT AdderSat
    PORT(
         a : IN  std_logic_vector(11 downto 0);
         b : IN  std_logic_vector(11 downto 0);
         s : OUT  std_logic_vector(11 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal a : std_logic_vector(11 downto 0) := (others => '0');
   signal b : std_logic_vector(11 downto 0) := (others => '0');

 	--Outputs
   signal s : std_logic_vector(11 downto 0);
   -- No clocks detected in port list. Replace <clock> below with 
   -- appropriate port name 
 
   constant clock_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: AdderSat PORT MAP (
          a => a,
          b => b,
          s => s
        );
 

   -- Stimulus process
   stim_proc: process
   begin		

      a <= x"000";
      b <= x"000";

      wait for clock_period;
      b <= x"00f";

      wait for clock_period;
      a <= x"7ff";

      wait for clock_period;
      b <= x"001";

      wait for clock_period;
      a <= x"7fe";

      wait for clock_period;
      a <= x"800";
      b <= x"000";

      wait for clock_period;
      b <= x"005";

      wait for clock_period;
      b <= x"fff";

      -- insert stimulus here 

      wait;
   end process;

END;
