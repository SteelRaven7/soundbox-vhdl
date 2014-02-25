------------------------------------------------------
-------------------------------------------------------
-- Description:                                      --
-- Implementation of a generic direct FIR-filter     --
-- Note that the lower N_WIDTH-1 bits will be        --
-- binals                                            --
--                                                   --
-- Input/Output:                                     --
-- WIDTH      - Width of input and output            --
-- N          - Number of coefficients               --
-- clk        - Clock                                --
-- clk_en     - Clock enable, takes input when high  --
-- x          - Input, WIDTH bits                    --
-- y          - Output, WIDTH bits                 --
--                                                   --
-- Internal Constants                                --
-- N_WIDTH    - Width of the coefficients            --
-- N_BINALS   - Number of binals in the coefficients --
-------------------------------------------------------
-------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

entity Generic_FIR is
   generic (WIDTH : integer := 8;
            N     : integer := 10);
   port(clk    : in  std_logic;
        clk_en : in  std_logic;
        x      : in  std_logic_vector(WIDTH-1 downto 0);
        y      : out std_logic_vector(WIDTH-1 downto 0));
end Generic_FIR;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

architecture behaviour of Generic_FIR is
  -- Constants
  constant N_WIDTH  : integer := 8;
  constant N_BINALS : integer := 6;
  
  -- Type declarations
  type array_input       is array(0 to N-1) of std_logic_vector(WIDTH-1           downto 0);
  type array_coeffecient is array(0 to N-1) of std_logic_vector(        N_WIDTH-1 downto 0);
  type array_result      is array(0 to N-1) of signed          (WIDTH + N_WIDTH-1 downto 0);
  
  -- Koefficients
  constant coefficients : array_coeffecient := ("01000000",
                                                "01000000",
                                                "01000000",
                                                "01000000",
                                                "01000000",
                                                "01000000",
                                                "01000000",
                                                "01000000",
                                                "01000000",
                                                "01000000");
  
  -- Signal Declarations
  signal my_inputs   : array_input  := (others => (others => '0'));
  signal my_mults    : array_result := (others => (others => '0'));
  signal my_sum      : array_result := (others => (others => '0'));
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
begin

  -- Shift the input registers
  p_shift_inputs : process(clk)
  begin
    if(rising_edge(clk)) then
      if(clk_en = '1') then
        my_inputs(0) <= x;
        my_inputs(1 to N-1) <= my_inputs(0 to N-2);
      end if;
    end if;
  end process p_shift_inputs;
  
  
  -- Multiply the input with coefficients
  gen_mults: 
  for i in 0 to N-1 generate
    my_mults(i) <= signed(my_inputs(i)) * signed(coefficients(i));
  end generate gen_mults;
  
  
  -- Add the multiplications together
  my_sum(N-1) <= my_mults(N-1);
  gen_adds: 
  for i in 0 to N-2 generate
    my_sum(i) <= my_sum(i+1) + my_mults(i);
  end generate gen_adds;
  
  
  -- Output the result
  y <= std_logic_vector(my_sum(0)(WIDTH+N_BINALS-1 downto N_BINALS));
  
  
end behaviour;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------