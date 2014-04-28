library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity AudioIO_tl is
	port (

		sampleButton : in std_logic;

		vauxn : in std_logic;
		vauxp : in std_logic;

		leds : out std_logic_vector(15 downto 0);

		clk : in std_logic;
		reset : in std_logic
	) ;
end entity ; -- AudioIO_tl

architecture arch of AudioIO_tl is
	signal registerOutput : std_logic_vector(15 downto 0);
	signal sampleOutput : std_logic_vector(15 downto 0);
begin
	leds(14 downto 0) <= sampleOutput(14 downto 0);
	leds(15) <= sampleButton;

	sampler : entity work.ADSampler
	port map (

		vauxn => vauxn,
		vauxp => vauxp,

		output => sampleOutput,

		clk => clk,
		reset => reset
	);

--	reg : entity work.Delay
--	generic map (
--		wordLength => 12
--	)
--	port map (
--		input => sampleOutput,
--		output => registerOutput,
--
--		clk => sampleButton,
--		reset => reset
--	);
	
end architecture ; -- arch