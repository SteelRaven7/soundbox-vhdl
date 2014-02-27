
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

entity Multiplier is
   generic (X_WIDTH    : integer := 16;
            X_FRACTION : integer := 15;
            Y_WIDTH    : integer := 16;
            Y_FRACTION : integer := 15;
            S_WIDTH    : integer := 16;
            S_FRACTION : integer := 15);
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