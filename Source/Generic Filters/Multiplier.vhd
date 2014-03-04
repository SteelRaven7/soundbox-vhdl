------------------------------------------------------
------------------------------------------------------
-- Description:                                     --
-- Implementation of a simple multiplier            --
--                                                  --
-- Generics:                                        --
-- X_WIDTH     - Width of the input x               --
-- X_FRACTION  - Width of the fractional part of x  --
-- Y_WIDTH     - Width of the input y               --
-- Y_FRACTION  - Width of the fractional part of y  --
-- S_WIDTH     - Desired width of the output s      --
-- S_FRACTION  - Desired width of the fractional    --
--               part of s                          --
--                                                  --
-- Input/Output:                                    --
-- x           - First factor                       --
-- y           - Second factor                      --
-- s           - Product                            --
--                                                  --
------------------------------------------------------
------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

entity Multiplier is
   generic (X_WIDTH    : integer := 16;
            X_FRACTION : integer := 14;
            Y_WIDTH    : integer := 16;
            Y_FRACTION : integer := 14;
            S_WIDTH    : integer := 16;
            S_FRACTION : integer := 13);
   port(x : in  std_logic_vector(X_WIDTH-1 downto 0);
        y : in  std_logic_vector(Y_WIDTH-1 downto 0);
        s : out std_logic_vector(S_WIDTH-1 downto 0));
end Multiplier;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

architecture behaviour of Multiplier is
  
  -- Constants -----------------------------------------------------------------
  constant UPPER_LIMIT : integer := X_FRACTION+Y_FRACTION-S_FRACTION+S_WIDTH-1;
  constant LOWER_LIMIT : integer := X_FRACTION+Y_FRACTION-S_FRACTION;
  
  -- Signals -------------------------------------------------------------------
  signal product : std_logic_vector(X_WIDTH + Y_WIDTH - 1 downto 0);
  
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

begin
  
  -- Multiply and cast result into appropriate size
  product <= std_logic_vector(signed(x) * signed(y));
  s <= product(UPPER_LIMIT downto LOWER_LIMIT);

end architecture;