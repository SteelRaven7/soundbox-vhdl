library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity Mult is
	generic (
		wordLengthA : natural := 8;
		wordLengthB : natural := 8;

		wordLengthP : natural := 16
	);
	port (
		a : in std_logic_vector(wordLengthA-1 downto 0);
		b : in std_logic_vector(wordLengthB-1 downto 0);

		p : out std_logic_vector(wordLengthP-1 downto 0)
	);
end entity ; -- Mult

architecture arch of Mult is
	signal product : signed(wordLengthA+wordLengthB-1 downto 0);
	signal pEntire : std_logic_vector(wordLengthA+wordLengthB-1 downto 0);
begin
	product <= (signed(a)*signed(b));

	pEntire <= std_logic_vector(shift_left(product, 1));

	p <= pEntire(wordLengthA+wordLengthB-1 downto wordLengthA+wordLengthB-wordLengthP);
end architecture ; -- arch