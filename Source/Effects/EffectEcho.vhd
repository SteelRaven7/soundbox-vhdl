library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity EffectEcho is
	generic (
		wordLength : natural := 16;
		constantsWordLength : natural := 16
	);
	port (
		input : in std_logic_vector(wordLength-1 downto 0);
		output : out std_logic_vector(wordLength-1 downto 0);

		clk : in std_logic;
		reset : in std_logic
	);
end entity ; -- EffectEcho

architecture arch of EffectEcho is
	constant delayDuration : natural := 2;
	constant decayGain : std_logic_vector(wordLength-1 downto 0) := (others => '0');
	constant directGain : std_logic_vector(wordLength-1 downto 0) := (others => '0');
	constant echoGain : std_logic_vector(wordLength-1 downto 0) := (others => '0');

	signal feedback : std_logic_vector(wordLength-1 downto 0);
	signal direct : std_logic_vector(wordLength-1 downto 0);
	signal delayedGained : std_logic_vector(wordLength-1 downto 0);
	signal delayed : std_logic_vector(wordLength-1 downto 0);
	signal feedbackDirectSum : std_logic_vector(wordLength-1 downto 0);
begin

	feedbackSum : entity work.AdderSat
	generic map (
		wordLength => wordLength
	)
	port map (
		a => input,
		b => feedback,

		s => feedbackDirectSum
	);

	outputSum : entity work.AdderSat
	generic map (
		wordLength => wordLength
	)
	port map (
		a => direct,
		b => delayedGained,

		s => feedbackDirectSum
	);

	

end architecture ; -- arch