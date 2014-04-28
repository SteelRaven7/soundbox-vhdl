library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity PulseKeeper is
	generic (
		duration : natural := 10
	);
	port (
		input : in std_logic;
		output : out std_logic;

		clk : in std_logic;
		reset : in std_logic
	) ;
end entity ; -- PulseKeeper

architecture arch of PulseKeeper is
	type reg_type is record
		output : std_logic;
		incrementor : natural range 0 to duration;
	end record;

	signal r, rin : reg_type;
begin
	output <= r.output;

	clk_proc : process( clk, reset )
	begin
		if(reset = '1') then
			r.output <= '0';
			r.incrementor <= 0;
		elsif(rising_edge(clk)) then
			r <= rin;
		end if;
	end process ; -- clkIn_proc

	comb_proc : process( r, rin, input )
		variable v : reg_type;
	begin
		v := r;

		if(r.incrementor = 0) then
			if(input = '1') then
				v.output := '1';
				v.incrementor := 1;
			end if;
		elsif(r.incrementor < duration) then
			v.incrementor := r.incrementor+1;
		else
			v.output := '0';
			v.incrementor := 0;
		end if;

		rin <= v;
	end process; -- clkOut_proc

end architecture ; -- arch