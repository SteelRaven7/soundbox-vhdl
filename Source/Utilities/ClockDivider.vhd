library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity ClockDivider is
	generic (
		divider : natural := 2
	);
	port (
		reset : in std_logic;
		clk : in std_logic;
		clkOut : out std_logic
	);

end entity ; -- ClockDivider

architecture arch of ClockDivider is
	type reg_type is record
		value : natural range 0 to divider-1;
		output : std_logic;
	end record;

	signal r, rin : reg_type;
begin
	clkOut <= r.output;

	clk_proc : process( clk, reset )
	begin
		if(reset = '1') then
			r.value <= 0;
			r.output <= '0';
		elsif(rising_edge(clk)) then
			r <= rin;
		end if;
	end process ; -- clk_proc

	comb_proc : process( r, rin )
		variable v : reg_type;
	begin
		v := r;

		if(r.value = 0) then
			v.output := '1';
		else
			v.output := '0';
		end if;

		if(v.value = divider-1) then
			v.value := 0;
		else
			v.value := r.value + 1;
		end if;

		rin <= v;
	end process ; -- comb_proc
end architecture ; -- arch