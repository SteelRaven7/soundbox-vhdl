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

begin
	s <= std_logic_vector(signed(a) + signed(b));
end architecture ; -- arch