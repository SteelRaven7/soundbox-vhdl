--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Description:                                                               --
-- This components takes two inputs ,x and y, and outputs their signed        --
-- product on the output s. This component also allows width-scaling of the   --
-- output in any direction and size. This sclaling may leed to overflow in    --
-- the output. In that case, the output is saturated.                         --
--                                                                            --
-- Generics:                                                                  --
-- X_WIDTH       - Bitwidth of the input x                                    --
-- X_FRACTION    - Fractional width of the input x                            --
-- Y_WIDTH       - Bitwidth of the input y                                    --
-- Y_FRACTION    - Fractional width of the input y                            --
-- S_WIDTH       - Bitwidth of the output s                                   --
-- S_FRACTION    - Fractional width of the output s                           --
--                                                                            --
-- Input/Output:                                                              --
-- x             - First term.                                                --
-- y             - Second term                                                --
-- overflow      - Overflow indicator                                         --
-- s             - Product                                                    --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

entity Multiplier_Saturate is
   generic (X_WIDTH    : natural := 16;
            X_FRACTION : natural := 15;
            Y_WIDTH    : natural := 16;
            Y_FRACTION : natural := 15;
            S_WIDTH    : natural := 16;
            S_FRACTION : natural := 15);
   port(x        : in  std_logic_vector(X_WIDTH-1 downto 0);
        y        : in  std_logic_vector(Y_WIDTH-1 downto 0);
        overflow : out std_logic;
        s        : out std_logic_vector(S_WIDTH-1 downto 0));
end Multiplier_Saturate;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

architecture behaviour of Multiplier_Saturate is

  -- Constants
  constant RESULT_WIDTH : integer := X_WIDTH+Y_WIDTH;
  constant LSB          : integer := X_FRACTION+Y_FRACTION-S_FRACTION;
  constant MSB          : integer := X_FRACTION+Y_FRACTION-S_FRACTION+S_WIDTH;

  -- Signal Declarations
  signal overflow_copy : std_logic;
  signal s_product     : std_logic_vector(RESULT_WIDTH-1 downto 0);
  signal s_output      : std_logic_vector(S_WIDTH-1      downto 0);

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

begin

  -- Calculate product
  s_product <= std_logic_vector(signed(x) * signed(y));

  -- Map to output
  gen_mapping :
  for i in 0 to S_WIDTH-1 generate
    if_inside :
    if(((LSB+i) <= (RESULT_WIDTH-1)) and ((LSB+i) >= (0))) generate
      s_output(i) <= s_product(LSB+i);
    end generate;

    if_above:
    if((LSB+i) > (RESULT_WIDTH-1)) generate
      s_output(i) <= s_product(RESULT_WIDTH-1);
    end generate;
    if_under:
    if((LSB+i) < (0)) generate
      s_output(i) <= '0';
    end generate;
  end generate;

  -- Check for overflow
  gen_overflow:
  if(MSB < RESULT_WIDTH) generate
    process(s_product)
      constant ones   : std_logic_vector(RESULT_WIDTH downto MSB) := (others => '1');
      constant zeroes : std_logic_vector(RESULT_WIDTH downto MSB) := (others => '0');
    begin
      if((s_product(RESULT_WIDTH-1 downto MSB-1) = zeroes) or (s_product(RESULT_WIDTH-1 downto MSB-1) = ones))  then
        overflow_copy <= '0';
      else
        overflow_copy <= '1';
      end if;
    end process;
  end generate;

  gen_no_overflow:
  if(MSB >= RESULT_WIDTH) generate
    overflow_copy <= '0';
  end generate;
  overflow <= overflow_copy;

  -- Saturate output
  process(s_product, overflow_copy, s_output)
  begin
    if(overflow_copy = '1') then
      if(s_product(RESULT_WIDTH-1) = '1') then
        s            <= (others => '0');
        s(S_WIDTH-1) <= '1';
      else
        s            <= (others => '1');
        s(S_WIDTH-1) <= '0';
      end if;
    else
      s <= s_output;
    end if;
  end process;

end behaviour;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------