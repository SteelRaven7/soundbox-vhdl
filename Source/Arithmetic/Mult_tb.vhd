--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:26:19 03/07/2014
-- Design Name:   
-- Module Name:   Z:/SourceSim/Source/Arithmetic/Mult_tb.vhd
-- Project Name:  SoundboxSim
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: Mult
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
  use ieee.math_real.all;
use work.fixed_pkg.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY Mult_tb IS
  generic (
    X_WIDTH    : natural := 14;
	X_FRACTION : natural := 8;
	Y_WIDTH    : natural := 16;
	Y_FRACTION : natural := 7;
	S_WIDTH    : natural := 17;
	S_FRACTION : natural := 6
  );
END entity;
 
ARCHITECTURE behavior OF Mult_tb IS 
    
   --Inputs
   signal a : std_logic_vector(X_WIDTH-1 downto 0) := (others => '0');
   signal b : std_logic_vector(Y_WIDTH-1 downto 0) := (others => '0');

 	--Outputs
   signal p : std_logic_vector(S_WIDTH-1 downto 0);
 
   constant clock_period : time := 50 ns;

   signal a_real_in : real;
   signal b_real_in : real;

   signal a_real : real;
   signal b_real : real;
   signal p_real : real;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: entity work.Multiplier
   generic map (
		X_WIDTH    => X_WIDTH,
		X_FRACTION => X_FRACTION,
		Y_WIDTH    => Y_WIDTH,
		Y_FRACTION => Y_FRACTION,
		S_WIDTH    => S_WIDTH,
		S_FRACTION => S_FRACTION
  )
    port map (
      x => a,
      y => b,
      s => p
    );
 

	-- Stimulus process
	stim_proc: process
	begin		

		a_real_in <= 0.0;
		b_real_in <= 0.0;

		wait for clock_period;
		a_real_in <= 1.0;
		b_real_in <= 0.5;

		wait for clock_period;
		a_real_in <= 0.5;
		b_real_in <= 0.5;

		wait for clock_period;
		a_real_in <= -0.5;
		b_real_in <= 0.1;

		wait for clock_period;
		a_real_in <= -0.5;
		b_real_in <= -0.25;

		wait for clock_period;
		a_real_in <= fixed_to_real(x"ffff", X_FRACTION);
		b_real_in <= fixed_to_real(x"ffff", Y_FRACTION);

		wait;

   end process;

   a_real <= fixed_to_real(a, X_FRACTION);
   b_real <= fixed_to_real(b, Y_FRACTION);
   p_real <= fixed_to_real(p, S_FRACTION);

   a <= real_to_fixed(a_real_in, X_WIDTH, X_FRACTION);
   b <= real_to_fixed(b_real_in, Y_WIDTH, Y_FRACTION);

END;
