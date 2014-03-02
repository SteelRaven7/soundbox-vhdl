library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity FIR is
	generic (
		wordLength : natural := 16;
		order : natural := 3
	);
	port (
		input : in std_logic_vector(wordLength-1 downto 0);
		output : out std_logic_vector(wordLength-1 downto 0);

		clk : in std_logic;
		reset : in std_logic
	);
end entity ; -- FIR

architecture arch of FIR is
	type signalArray is array(0 to order) of std_logic_vector(wordLength-1 downto 0);
	type sumArray is array(0 to order) of std_logic_vector((wordLength*2)-1 downto 0);

	signal inputs : signalArray := (others => (others => '0'));
	signal gainedInputs : sumArray := (others => (others => '0'));
	signal sums : sumArray := (others => (others => '0'));
begin

	inputs(0) <= input;
	output <= sums(0)(wordLength*2-1 downto wordLength);
	sums(3) <= gainedInputs(3);

	delays : for i in 0 to order-1 generate
		delay : entity work.Delay
		generic map (
			wordLength => wordLength
		)
		port map (
			input => inputs(i),
			output => inputs(i+1),
			clk => clk,
			reset => reset
		);

		adder : entity work.AdderSat
		generic map (
			wordLength => wordLength*2
		)
		port map (
			a => gainedInputs(i),
			b => sums(i+1),

			s => sums(i)
		);
	end generate ; -- delays

	summing : for i in 0 to order generate
		mult : entity work.Mult
		generic map (
			wordLengthA => wordLength,
			wordLengthB => wordLength,
			wordLengthP => wordLength*2
		)
		port map (
			a => inputs(i),
			b => (others => '0'),

			p => gainedInputs(i)
		);
	end generate;

end architecture ; -- arch