library ieee ;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use work.fixed_pkg.all;
	use work.filter_pkg.all;


entity FIR is
	generic (
		wordLength : natural := 16;
		coeffWordLength : natural := 16;

		fractionalBits : natural := 15;
		coeffFractionalBits : natural := 15;

		outputWordLength : natural := 16;
		outputFractionalBits : natural := 15;

		order : natural := 3;

		coefficients : coefficient_array := (0.0, 0.0, 0.0, 0.0)
	);
	port (
		input : in std_logic_vector(wordLength-1 downto 0);
		output : out std_logic_vector(outputWordLength-1 downto 0);

		clk : in std_logic;
		reset : in std_logic
	);
end entity ; -- FIR


architecture arch of FIR is
	type signalArray is array(0 to order) of std_logic_vector(wordLength-1 downto 0);
	type sumArray is array(0 to order) of std_logic_vector(outputWordLength-1 downto 0);

	signal inputs : signalArray		:= (others => (others => '0'));
	signal gainedInputs : sumArray	:= (others => (others => '0'));
	signal sums : sumArray			:= (others => (others => '0'));
begin

	inputs(0) <= input;
	output <= sums(0);
	sums(order) <= gainedInputs(order);

	delays : for i in 0 to order-1 generate
		
		-- Delay stages
		delay : entity work.VectorRegister
		generic map (
			wordLength => wordLength
		)
		port map (
			input => inputs(i),
			output => inputs(i+1),
			clk => clk,
			reset => reset
		);

		-- Output summation
		adder : entity work.AdderSat
		generic map (
			wordLength => outputWordLength
		)
		port map (
			a => gainedInputs(i),
			b => sums(i+1),

			s => sums(i)
		);
	end generate ; -- delays

	multiplication : for i in 0 to order generate
		
		-- Coefficient multiplication
		mult : entity work.Mult
		generic map (
			wordLengthA => wordLength,
			wordLengthB => coeffWordLength,
			wordLengthP => outputWordLength,

			fractionalBitsA => fractionalBits,
			fractionalBitsB => coeffFractionalBits,
			fractionalBitsP => outputFractionalBits
		)
		port map (
			a => inputs(i),
			b => real_to_fixed(coefficients(i), wordLength),

			p => gainedInputs(i)
		);
	end generate;

end architecture ; -- arch