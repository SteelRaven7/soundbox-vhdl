--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   11:41:06 02/07/2014
-- Design Name:   
-- Module Name:   C:/SoundboxProject/Source/soundbox-vhdl/ISEProject/Soundbox/Source/AudioIO/ADSampler_tb.vhd
-- Project Name:  Soundbox
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ADSampler
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
 
ENTITY ADSampler_tb IS
END ADSampler_tb;
 
ARCHITECTURE behavior OF ADSampler_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ADSampler
    PORT(
         DRP_output : IN  std_logic_vector(15 downto 0);
         DRP_dataReady : IN  std_logic;
         DRP_input : OUT  std_logic_vector(15 downto 0);
         DRP_address : OUT  std_logic_vector(6 downto 0);
         DRP_enable : OUT  std_logic;
         DRP_writeEnable : OUT  std_logic;
         DRP_clk : OUT  std_logic;
         XADC_reset : OUT  std_logic;
         XADC_convst : OUT  std_logic;
         XADC_convstclk : OUT  std_logic;
         clk : IN  std_logic;
         reset : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal DRP_output : std_logic_vector(15 downto 0) := (others => '0');
   signal DRP_dataReady : std_logic := '0';
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';

 	--Outputs
   signal DRP_input : std_logic_vector(15 downto 0);
   signal DRP_address : std_logic_vector(6 downto 0);
   signal DRP_enable : std_logic;
   signal DRP_writeEnable : std_logic;
   signal DRP_clk : std_logic;
   signal XADC_reset : std_logic;
   signal XADC_convst : std_logic;
   signal XADC_convstclk : std_logic;

   -- Clock period definitions
   constant DRP_clk_period : time := 10 ns;
   constant XADC_convstclk_period : time := 10 ns;
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ADSampler PORT MAP (
          DRP_output => DRP_output,
          DRP_dataReady => DRP_dataReady,
          DRP_input => DRP_input,
          DRP_address => DRP_address,
          DRP_enable => DRP_enable,
          DRP_writeEnable => DRP_writeEnable,
          DRP_clk => DRP_clk,
          XADC_reset => XADC_reset,
          XADC_convst => XADC_convst,
          XADC_convstclk => XADC_convstclk,
          clk => clk,
          reset => reset
        );

   -- Clock process definitions
   DRP_clk_process :process
   begin
		DRP_clk <= '0';
		wait for DRP_clk_period/2;
		DRP_clk <= '1';
		wait for DRP_clk_period/2;
   end process;
 
   XADC_convstclk_process :process
   begin
		XADC_convstclk <= '0';
		wait for XADC_convstclk_period/2;
		XADC_convstclk <= '1';
		wait for XADC_convstclk_period/2;
   end process;
 
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

      wait for DRP_clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
