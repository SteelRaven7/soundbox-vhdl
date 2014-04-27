library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity Delay is
	generic (
		counter : natural := 10000
	);
	port (

		input : in std_logic;
		output : out std_logic;

		clk : in std_logic;
		reset : in std_logic
	) ;
end entity ; -- Delay

architecture arch of Delay is
	type reg_type is record
		incrementor : natural range 0 to counter;
		output : std_logic;
	end record;

	signal r, rin : reg_type;
begin

	output <= r.output;

	clk_proc : process( clk, reset )
	begin
		if(reset = '1') then
			r.incrementor <= 0;
			r.output <= '0';
		elsif(rising_edge(clk)) then
			r <= rin;
		end if;
	end process ; -- clk_proc

	comb_proc : process( r, rin, input )
		variable v : reg_type;
	begin
		v := r;

		if(r.incrementor = 0) then
			v.output := '0';
			if(input = '1') then
				v.incrementor := 1;
			end if;
		elsif(r.incrementor < counter) then
			v.incrementor := r.incrementor+1;
		else
			v.incrementor := 0;
			v.output := '1';
		end if;

		rin <= v;
	end process ; -- comb_proc
end architecture ; -- arch