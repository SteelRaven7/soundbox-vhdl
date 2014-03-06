-- Does not saturate currently, only provides built in VHDL addition.

library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity AdderSat is

	generic (
		wordLength : natural := 12
	);
	port (
		a : in std_logic_vector(wordLength-1 downto 0);
		b : in std_logic_vector(wordLength-1 downto 0);

		s : out std_logic_vector(wordLength-1 downto 0)
	);
end entity ; -- AdderSat

architecture arch of AdderSat is
	constant MAX : std_logic_vector(wordLength-1 downto 0) := "0" & ((wordLength-2 downto 0) => '1');
	constant MIN : std_logic_vector(wordLength-1 downto 0) := "1" & ((wordLength-2 downto 0) => '0');

	signal sum : std_logic_vector(wordLength-1 downto 0);
	signal overflow : std_logic;
	signal s_a : std_logic;
	signal s_b : std_logic;
	signal s_s : std_logic;

	signal muxControl : std_logic_vector(1 downto 0);
begin
	sum <= std_logic_vector(signed(a) + signed(b));

	s_a <= a(wordLength-1);
	s_b <= b(wordLength-1);
	s_s <= s(wordLength-1);

	-- Signs of a and b are the same, but not equal to sign of s means overflow.
	overflow <= ((s_a and s_b) and not(s_s)) or ((not(s_a) and not(s_b)) and s_s);

	muxControl <= overflow & s_a;

	s <=	sum when muxControl = "0-" else -- No overflow
			MAX when muxControl = "10" else -- Overflow positive
			MIN when muxControl = "11";		-- Overflow negative


end architecture ; -- arch