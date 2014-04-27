library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity PulseLimiter is
	port (
		input : in std_logic;
		output : out std_logic;

		clk : in std_logic;
		reset : in std_logic
	) ;
end entity ; -- PulseLimiter

architecture arch of PulseLimiter is
	type reg_type is record
		output : std_logic;
		triggered : std_logic;
	end record;

	signal r, rin : reg_type;
begin

	clk_proc : process( clk, reset )
	begin
		if(reset = '1') then
			r.output <= '0';
			r.triggered <= '0';
		elsif(rising_edge(clk)) then
			r <= rin;
		end if;
	end process ; -- clk_proc

	comb_proc : process( r, rin, input )
		variable v : reg_type;
	begin
		v := r;

		if(r.triggered = '0') then
			if(input = '1') then
				v.output := '1';
				v.triggered := '1';
			end if;
		else
			v.output := '0';

			if(input = '0') then
				v.triggered := '0';
			end if;
		end if;

		rin <= v;
	end process ; -- comb_proc

end architecture ; -- arch