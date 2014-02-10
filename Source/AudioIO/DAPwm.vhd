library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity DAPwm is
	generic (
		wordLength : natural := 12
	);
	port (
		input : in std_logic_vector(wordLength-1 downto 0);
		output : out std_logic;

		clk : in std_logic;
		reset : in std_logic
	) ;
end entity ; -- DAPwm

architecture arch of DAPwm is
	signal sampleClk : std_logic;

	type reg_type is record
		countdown : natural range 0 to (2**wordLength)-1;
		bit : std_logic;
	end record;

	signal r, rin : reg_type;
begin

	output <= r.bit;


	sampleClkGenerator : entity work.ClockDivider
	generic map (
		divider => 2**wordLength -- 4096 for 12 bits
	)
	port map (
		clk => clk,
		clkOut => sampleClk,
		reset => reset
	);

	clk_proc : process( clk, reset )
	begin
		if(reset = '1') then
			r.countdown <= 0;
			r.bit <= '0';
		elsif(rising_edge(clk)) then
			r <= rin;
		end if;
	end process ; -- clk_proc

	comb_proc : process( r, rin, input, sampleClk )
		variable v : reg_type;
	begin
		v := r;

		if(sampleClk = '1') then
			v.countdown := to_integer(unsigned(input));
			-- We assume that the counter isn't 0.
			v.bit := '1';
		elsif(r.countdown = 0) then
			v.bit := '0';
		else
			v.countdown := r.countdown-1;
		end if;

		rin <= v;
	end process ; -- comb_proc

end architecture ; -- arch