
------------------------------------------------------
------------------------------------------------------
-- Description:                                     --
-- Implementation of a generic direct IIR-filter    --
-- Note that the lower bits will be binals          --
--                                                  --
-- Input/Output:                                    --
-- WIDTH      - Width of input and output           --
-- N          - Number of coefficients              --
-- clk        - Clock                               --
-- clk_en     - Clock enable, takes input when high --
-- x          - Input, WIDTH bits                   --
-- y          - Output, WIDTH bits                  --
--                                                  --
-- Internal Constants                               --
-- N_WIDTH    - Width of the coefficients           --
-- N_BINALS   - Number of binals in the coefficients--
------------------------------------------------------
------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

entity Generic_IIR is
   generic (WIDTH : integer := 16;
            N     : integer := 2);
   port(clk    : in  std_logic;
        clk_en : in  std_logic;
        x      : in  std_logic_vector(WIDTH-1 downto 0);
        y      : out std_logic_vector(WIDTH-1 downto 0));
end Generic_IIR;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

architecture behaviour of Generic_IIR is
  -- Constants
  constant N_WIDTH  : integer := 24;
  constant N_BINALS : integer := 22;
  
  -- Type declarations
  type array_input       is array(0 to N-1) of std_logic_vector(WIDTH-1           downto 0);
  type array_coeffecient is array(0 to N-1) of std_logic_vector(        N_WIDTH-1 downto 0);
  type array_result      is array(0 to N-1) of signed          (WIDTH + N_WIDTH-1 downto 0);
  
  -- Koefficients
  constant coefficients_b : array_coeffecient := ("000000000000000000000000",
                                                  "000000010000000100000001");
  constant coefficients_a : array_coeffecient := ("000000000000000000000000",
                                                  "000000010000000100000001");
  
  -- Signal Declarations
  signal my_inputs    : array_input  := (others => (others => '0'));
  signal my_outputs   : array_input  := (others => (others => '0'));
  signal my_mults_in  : array_result := (others => (others => '0'));
  signal my_mults_out : array_result := (others => (others => '0'));
  signal my_sum_in    : array_result := (others => (others => '0'));
  signal my_sum_out   : array_result := (others => (others => '0'));
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
begin

  -- Shift the delay registers
  my_outputs(0) <= std_logic_vector(my_sum_out(0)(WIDTH + N_BINALS-1 downto N_BINALS));
  p_shift_inputs : process(clk)
  begin
    if(rising_edge(clk)) then
      if(clk_en = '1') then
        my_inputs(0)         <= x;
        my_inputs(1 to N-1)  <= my_inputs(0 to N-2);
        my_outputs(1 to N-1) <= my_outputs(0 to N-2);
      end if;
    end if;
  end process p_shift_inputs;
  
  
  -- Multiply the input with coefficients
  gen_mults_in:
  for i in 0 to N-1 generate
    my_mults_in(i) <= signed(my_inputs(i)) * signed(coefficients_b(i));
  end generate gen_mults_in;
  
  
  -- Add the input multiplications together
  my_sum_in(N-1) <= my_mults_in(N-1);
  gen_adds_in:
  for i in 0 to N-2 generate
    my_sum_in(i) <= my_mults_in(i) + my_sum_in(i+1);
  end generate gen_adds_in;

  
  -- Add the output multiplications together
  my_sum_out(0)   <= my_sum_in(0) + my_sum_out(1);
  my_sum_out(N-1) <= my_mults_out(N-1);
  gen_adds_out:
  for i in 1 to N-2 generate
    my_sum_out(i) <= my_sum_out(i+1) + my_mults_out(i);
  end generate gen_adds_out;
  
  
  -- Multiply the output with coefficients
  gen_mults_out:
  for i in 1 to N-1 generate
    my_mults_out(i) <= signed(my_outputs(i)) * signed(coefficients_a(i));
  end generate gen_mults_out;
  
  
  -- Output the result
  y <= my_outputs(0);
end behaviour;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
