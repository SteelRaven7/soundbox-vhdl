--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   11:43:17 02/10/2014
-- Design Name:   
-- Module Name:   C:/SoundboxProject/Source/soundbox-vhdl/Source/AudioIO/DAPwm_tb.vhd
-- Project Name:  SoundboxProject
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: DAPwm
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
use ieee.numeric_std.all ;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY DAPwm_tb IS
END DAPwm_tb;
 
ARCHITECTURE behavior OF DAPwm_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT DAPwm
    PORT(
         input : IN  std_logic_vector(11 downto 0);
         output : OUT  std_logic;
         clk : IN  std_logic;
         reset : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal input : std_logic_vector(11 downto 0) := (others => '0');
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal inputNumber : natural := 0;

 	--Outputs
   signal output : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
   constant sample_period : time := 40960 ns;
 
BEGIN
 
  input <= std_logic_vector(to_unsigned(inputNumber, input'high+1));

	-- Instantiate the Unit Under Test (UUT)
   uut: DAPwm PORT MAP (
          input => input,
          output => output,
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

      wait for 20000 ns;

      inputNumber <= 5;
      wait for sample_period;

      inputNumber <= 4095;
      wait for sample_period;

      inputNumber <= 4094;
      wait for sample_period;

      inputNumber <= 4095;
      wait for sample_period;

      inputNumber <= 5;
      wait for sample_period;

      -- insert stimulus here 

      wait;
   end process;

END;
