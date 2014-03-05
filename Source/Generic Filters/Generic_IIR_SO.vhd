--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Description:                                                               --
-- Implementation of a discrete-time, second-order, direct-form I IIR filter. --
-- This filter uses fixed point arithmetic to do it's calculations and can be --
-- described by the following mathematical formula:                           --
-- Y[k] = B0*X[k] + B1*X[k-1] + B2*X[k-2] + A1*Y[k-1] + A2*Y[k-1]             --
--                                                                            --
--                                                                            --
-- Generic:                                                                   --
-- IN_WIDTH          - The width of the input signal                          --
-- IN_FRACT          - The width of the fractional part of the input signal   --
-- COEFFICIENT_WIDTH - The width of the filter coefficients                   --
-- COEFFICIENT_FRACT - The width of the fractional part of the filter         --
--                     coefficients                                           --
-- INTERNAL_WIDTH    - The width of internal states of the filter             --
-- INTERNAL_FRACT    - The width of the fractional part of internal states in --
--                     the filter                                             --
-- OUT_WIDTH         - The width of the output signal                         --
-- OUT_FRACT         - The width of the fractional part of the output signal  --
--                                                                            --
--                                                                            --
-- Input/Output:                                                              --
-- clk               - System clock                                           --
-- clk_en            - Clock enable signal, enabled when high                 --
-- reset             - Asynchronous reset that resets when high               --
-- x                 - Input signal to be filtered                            --
-- B0                - Coefficient                                            --
-- B1                - Coefficient                                            --
-- B2                - Coefficient                                            --
-- A1                - Coefficient                                            --
-- A2                - Coefficient                                            --
-- y                 - Output signal                                          --
--                                                                            --
--                                                                            --
-- Internal Constants:                                                        --
-- N                 - Number of coefficients, this number is three for a     --
--                     second order filter and should not be changed. The     --
--                     constant is mearly there to simplify creation of       --
--                     higher order filters. Note that for this to be done    --
--                     successfully, you have to increase the number of       --
--                     coefficients as well.                                  --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fixed_pkg.all;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

entity Generic_IIR_SO is
   generic (IN_WIDTH          : natural := 16;
            IN_FRACT          : natural := 15;
            COEFFICIENT_WIDTH : natural := 16;
            COEFFICIENT_FRACT : natural := 15;
			INTERNAL_WIDTH    : natural := 32;
			INTERNAL_FRACT    : natural := 30;
			OUT_WIDTH         : natural := 16;
			OUT_FRACT         : natural := 15);
   port(clk    : in  std_logic;
		reset  : in  std_logic;
        x      : in  std_logic_vector(IN_WIDTH-1          downto 0);
        B0     : in  std_logic_vector(COEFFICIENT_WIDTH-1 downto 0);
        B1     : in  std_logic_vector(COEFFICIENT_WIDTH-1 downto 0);
        B2     : in  std_logic_vector(COEFFICIENT_WIDTH-1 downto 0);
        A1     : in  std_logic_vector(COEFFICIENT_WIDTH-1 downto 0);
        A2     : in  std_logic_vector(COEFFICIENT_WIDTH-1 downto 0);
        y      : out std_logic_vector(OUT_WIDTH-1         downto 0));
end Generic_IIR_SO;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

architecture behaviour of Generic_IIR_SO is

  -- Constants
  constant N : natural := 3; -- Filter order
  constant IN_INT          : natural := IN_WIDTH          - IN_FRACT;
  constant COEFFICIENT_INT : natural := COEFFICIENT_WIDTH - COEFFICIENT_FRACT;
  constant INTERNAL_INT    : natural := INTERNAL_WIDTH    - INTERNAL_FRACT;
  constant OUT_INT         : natural := OUT_WIDTH         - OUT_FRACT;
  constant PRODUCT_WIDTH   : natural := COEFFICIENT_WIDTH + INTERNAL_WIDTH;
  constant PRODUCT_FRACT   : natural := COEFFICIENT_FRACT + INTERNAL_FRACT;
  constant PRODUCT_INT     : natural := PRODUCT_WIDTH     - PRODUCT_FRACT;
  
  -- Type declarations
  type array_input       is array(0 to N-1) of std_logic_vector(IN_WIDTH-1          downto 0);
  type array_coeffecient is array(0 to N-1) of std_logic_vector(COEFFICIENT_WIDTH-1 downto 0);
  type array_internal    is array(0 to N-1) of std_logic_vector(INTERNAL_WIDTH-1    downto 0);
  type array_product     is array(0 to N-1) of signed          (PRODUCT_WIDTH-1     downto 0);
  
  -- Coefficients
  signal coefficients_b : array_coeffecient;
  signal coefficients_a : array_coeffecient;
  
  -- Signal Declarations
  signal input_copy   : std_logic_vector(INTERNAL_WIDTH-1 downto 0);
  signal my_inputs    : array_internal := (others => (others => '0'));
  signal my_outputs   : array_internal := (others => (others => '0'));
  signal my_temp_in   : array_product  := (others => (others => '0'));
  signal my_mults_in  : array_internal := (others => (others => '0'));
  signal my_temp_out  : array_product  := (others => (others => '0'));
  signal my_mults_out : array_internal := (others => (others => '0'));
  signal my_sum_in    : array_internal := (others => (others => '0'));
  signal my_sum_out   : array_internal := (others => (others => '0'));
  
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

begin

  -- Assign coefficients
  coefficients_b(0) <= B0;
  coefficients_b(1) <= B1;
  coefficients_b(2) <= B2;
  coefficients_a(1) <= A1;
  coefficients_a(2) <= A2;


  input_copy(INTERNAL_WIDTH-1 downto INTERNAL_FRACT + IN_INT)            <= (others => x(IN_WIDTH-1));
  input_copy(INTERNAL_FRACT + IN_INT-1 downto INTERNAL_FRACT - IN_FRACT) <= x;
  input_copy(INTERNAL_FRACT - IN_FRACT-1 downto 0)                       <= (others => x(IN_WIDTH-1));
  
  my_outputs(0) <= my_sum_out(0);
  VectorRegisterIn0 : entity work.VectorRegister
  generic map (
    wordLength => INTERNAL_WIDTH)
  port map (
    input  => input_copy,
    output => my_inputs(0),
    clk    => clk,
    reset  => reset);
	
  gen_shifts:
  for i in 0 to N-2 generate
    VectorRegisterIn : entity work.VectorRegister
	  generic map (
	    wordLength => INTERNAL_WIDTH)
	  port map (
	    input  => my_inputs(i),
	    output => my_inputs(i+1),
        clk    => clk,
	    reset  => reset);
	  
    VectorRegisterOut : entity work.VectorRegister
	  generic map (
	    wordLength => INTERNAL_WIDTH)
	  port map (
	    input  => my_outputs(i),
	    output => my_outputs(i+1),
        clk    => clk,
	    reset  => reset);
  end generate gen_shifts;
  
  
  -- Multiply the input with coefficients
  gen_mults_in:
  for i in 0 to N-1 generate
    my_temp_in(i) <= signed(my_inputs(i)) * signed(coefficients_b(i));
	my_mults_in(i) <= std_logic_vector(my_temp_in(i)(PRODUCT_FRACT + INTERNAL_INT-1 downto COEFFICIENT_FRACT));
  end generate gen_mults_in;
  
  
  -- Add the input multiplications together
  my_sum_in(N-1) <= my_mults_in(N-1);
  gen_adds_in:
  for i in 0 to N-2 generate
    my_sum_in(i) <= std_logic_vector(signed(my_mults_in(i)) + signed(my_sum_in(i+1)));
  end generate gen_adds_in;

  
  -- Subtract the output multiplications together
  my_sum_out(0)   <= std_logic_vector(signed(my_sum_in(0)) - signed(my_sum_out(1)));
  my_sum_out(N-1) <= my_mults_out(N-1);
  gen_subs_out:
  for i in 1 to N-2 generate
    my_sum_out(i) <= std_logic_vector(signed(my_sum_out(i+1)) - signed(my_mults_out(i)));
  end generate gen_subs_out;
  
  
  -- Multiply the output with coefficients
  gen_mults_out:
  for i in 1 to N-1 generate
    my_temp_out(i) <= signed(my_outputs(i)) * signed(coefficients_a(i));
	my_mults_out(i) <= std_logic_vector(my_temp_out(i)(PRODUCT_FRACT + INTERNAL_INT-1 downto COEFFICIENT_FRACT));
  end generate gen_mults_out;
  
  
  -- Output the result
  y <= std_logic_vector(my_outputs(0)(INTERNAL_FRACT + OUT_INT-1 downto INTERNAL_FRACT - OUT_FRACT));
end behaviour;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
