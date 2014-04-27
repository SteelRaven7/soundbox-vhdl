library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity ButtonDebouncer is
	port (
		input : in std_logic;
		output : out std_logic;

		clk : in std_logic;
		reset : in std_logic
	) ;
end entity ; -- ButtonDebouncer

architecture arch of ButtonDebouncer is
	--constant MAX : natural := 2000000; -- 20ms on 100MHz
	constant MAX : natural := 200000; -- 20ms on 10MHz

	type reg_type is record
		incrementor : natural range 0 to MAX;
		done : std_logic;
		output : std_logic;
	end record;

	signal r, rin : reg_type;

begin

	output <= r.output;

	clk_proc : process( clk, reset )
	begin
		if(reset = '1') then
			r.output <= '0';
			r.done <= '0';
			r.incrementor <= 0;
		elsif(rising_edge(clk)) then
			r <= rin;
		end if;
	end process ; -- clk_proc

	comb_proc : process( input )
		variable v : reg_type;
	begin
		v := r;

		v.output := '0';

		if(r.done = '0') then
			if(input = '1') then
				v.done := '1';
				v.incrementor := 0;
			end if;
		else
			if(r.incrementor < MAX) then
				if(input = '1') then
					v.incrementor := r.incrementor+1;
				else
					v.incrementor := 0;
				end if;
			else
				-- Wait until button is released
				if(input = '0') then
					v.output := '1';
					v.done := '0';
				end if;
			end if;
		end if;

		rin <= v;
	end process ; -- comb_proc
end architecture ; -- arch