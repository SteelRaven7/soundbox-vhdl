library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity dac_interface is
	generic(
		DATA_WIDTH : natural := 12
	);
	port(
		reset : in std_logic;
		clk : in std_logic;

		data_input : in std_logic_vector(DATA_WIDTH-1 downto 0);
		write_data : in std_logic;

		serial_data : out std_logic; -- SDI
		latch_data : out std_logic; -- LDAC'
		hardware_shutdown : out std_logic; -- SHDN'

		finished : out std_logic;

		chip_select : out std_logic
	);
end entity;

architecture behavioural of dac_interface is
	
	type state_t is (sleep, config, data);

	type reg_t is record
		
		state : state_t;

		counter : natural range 0 to DATA_WIDTH;

		data_input : std_logic_vector(DATA_WIDTH-1 downto 0);

		serial_data : std_logic;
		chip_select : std_logic;

		finished : std_logic;
	end record;

	signal r, rin : reg_t;
begin
	
	clocked_proc: process(reset, clk)
	begin
		if reset = '1' then
			r.state <= sleep;
			r.counter <= 0;
			r.chip_select <= '1';
			r.serial_data <= '0';
			r.finished <= '0';
		elsif falling_edge(clk) then
			r <= rin;
		end if;
	end process; 

	combinatoric_proc: process(r, rin, write_data, data_input)
		variable v : reg_t;
	begin
		v := r;
		case r.state is
			when sleep =>
				
				v.chip_select := '1';

				if(write_data='1') then
					v.data_input := data_input; 
					v.counter:=0;
					v.state:=config;
					v.finished := '0';
				end if;
			when config =>
				v.counter := r.counter +1;

				if(r.counter=0) then
					-- Enable the chip select.
					v.chip_select:='0';
					v.serial_data:='0'; -- Write to channel A

				-- r.counter = 1 is don't care.
				elsif(r.counter=2)then
					v.serial_data:='0'; -- Select 2x gain.

				elsif(r.counter=3)then
					v.serial_data:='1'; -- Output power-down control bit.
					v.counter:=0;
					v.state:=data;
			end if;
			when data =>
				v.counter := r.counter +1;
				v.serial_data := r.data_input(DATA_WIDTH-1-r.counter);
				if r.counter=11 then
					v.state:= sleep;
					v.finished := '1';
				end if ;
			when others =>
				v.state := sleep;
				v.counter := 0;
				v.chip_select := '1';
				v.serial_data := '0';
				v.data_input := (others => '0');
				v.finished := '0';

		end case;

		rin <= v;
	end process;
	
	finished <= r.finished;
	serial_data <= r.serial_data;
	chip_select <= r.chip_select;

	latch_data <='0';
	hardware_shutdown <= '1';

end architecture;


