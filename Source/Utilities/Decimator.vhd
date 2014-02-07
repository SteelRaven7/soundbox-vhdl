library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity Decimator is
	generic (
		wordLength : natural := 8;
		divider : natural := 2
	);
	port (
		input : in std_logic_vector(wordLength-1 downto 0);
		output : out std_logic_vector(wordLength-1 downto 0);

		reset : in std_logic;
		clk : in std_logic
	);
end entity ; -- Decimator

architecture arch of Decimator is
	type reg_type is record
		vector : std_logic_vector(wordLength-1 downto 0);
	end record;

	signal r, rin : reg_type;

	signal decimatedClk : std_logic;
begin
	output <= r.vector;

	-- Create a decimated (slow) clock via ClockDivider:
	decimator : entity work.ClockDivider
	generic map(
		divider => divider
	)
	port map(
		reset => reset,
		clk => clk,
		clkOut => decimatedClk
	);


	-- Let the clocked process trigger on the slow clock.
	clk_proc : process( decimatedClk )
	begin
		if(rising_edge(decimatedClk)) then
			r <= rin;
		end if;
	end process ; -- clk_proc

	comb_proc : process( r, rin, input )
		variable v : reg_type;
	begin
		v := r;

		v.vector := input;

		rin <= v;
	end process ; -- comb_proc

end architecture ; -- arch