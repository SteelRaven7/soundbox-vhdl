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
	generic (
		X_WIDTH    : natural := 16;
		X_FRACTION : natural := 14;
		Y_WIDTH    : natural := 16;
		Y_FRACTION : natural := 14;
		S_WIDTH    : natural := 16;
		S_FRACTION : natural := 13
	);
	port(
		x : in  std_logic_vector(X_WIDTH-1 downto 0);
		y : in  std_logic_vector(Y_WIDTH-1 downto 0);
		s : out std_logic_vector(S_WIDTH-1 downto 0)
	);
end Multiplier;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

architecture behaviour of Multiplier is
	-- Functions -----------------------------------------------------------------
	function paddedLength(old_width : integer ;upper_limit : integer) return integer is
	begin
		if(upper_limit > old_width) then
		return upper_limit;
	else
			return old_width;
	end if;
	end paddedLength;
	
	-- Constants -----------------------------------------------------------------
	constant UPPER_LIMIT : integer := X_FRACTION+Y_FRACTION-S_FRACTION+S_WIDTH-1;
	constant LOWER_LIMIT : integer := X_FRACTION+Y_FRACTION-S_FRACTION;
	constant X_LENGTH    : integer := paddedLength(X_WIDTH, UPPER_LIMIT);
	constant Y_LENGTH    : integer := paddedLength(Y_WIDTH, UPPER_LIMIT);
	
	-- Signals -------------------------------------------------------------------
	signal x_padded : std_logic_vector(X_LENGTH-1 downto 0);
	signal y_padded : std_logic_vector(Y_LENGTH-1 downto 0);
	signal product  : std_logic_vector(X_LENGTH + Y_LENGTH - 1 downto 0);
	
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

begin
	-- Fill upper bits if necessary
	x_padder:
	if(UPPER_LIMIT > X_WIDTH) generate
		x_padded(UPPER_LIMIT-1 downto X_WIDTH) <= (others => x(X_WIDTH-1));
	end generate;
	
	y_padder:
	if(UPPER_LIMIT > Y_WIDTH) generate
		y_padded(UPPER_LIMIT-1 downto Y_WIDTH) <= (others => y(Y_WIDTH-1));
	end generate;
	
	-- Put the input onto the multiplier
	x_padded(X_WIDTH-1 downto 0) <= x;
	y_padded(Y_WIDTH-1 downto 0) <= y;
	
	-- Multiply and cast result into appropriate size
	product <= std_logic_vector(signed(x_padded) * signed(y_padded));
	s <= product(UPPER_LIMIT downto LOWER_LIMIT);

end architecture;