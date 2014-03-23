library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity SerialInterface is
	port (
		msg : out std_Logic_vector(7 downto 0);
		payload : out std_logic_vector(15 downto 0);
		dataOk : out std_logic;
		msgReady : out std_logic;

		serialIn : in std_logic;
		serialOut : out std_logic;

		serialClk : in std_logic;
		reset : in std_logic
	);
end entity ; -- SerialInterface

architecture arch of SerialInterface is
	constant MSG_HANDSHAKE : std_logic_vector(7 downto 0) := x"00";
	constant MSG_HANDSHAKE2 : std_logic_vector(7 downto 0) := x"01";

	type state_type is (ready, r_data, r_parity, r_stop, r_error, r_ok,
						t_start, t_data, t_parity, t_stop);

	type reg_type is record
		-- State
		state : state_type;
		bitCounter : natural range 0 to 7;
		
		-- Data
		dataOk : std_logic;
		data : std_logic_vector(7 downto 0);
		
		-- Output
		serialOut : std_logic;
		msg : std_logic_vector(7 downto 0);
		msgReady : std_logic;
	end record;

	signal r, rin : reg_type;

	signal dataParity : std_logic;
begin

	-- Provides the data parity from the state machine's data values.
	dataParity <= r.data(0) xor r.data(1) xor r.data(2) xor r.data(3)
			  xor r.data(4) xor r.data(5) xor r.data(6) xor r.data(7);

	dataOk <= r.dataOk;
	serialOut <= r.serialOut;
	msg <= r.msg;
	msgReady <= r.msgReady;

	clk_proc : process(serialClk, reset)
	begin
		if(reset = '1') then
			r.state <= ready;
			r.msg <= (others => '0');
			r.data <= (others => '0');
			r.dataOk <= '0';
			r.msgReady <= '0';
			r.serialOut <= '1';
		elsif(rising_edge(serialClk)) then
			r <= rin;
		end if;
	end process ; -- clk_proc


	comb_proc : process(r, rin, serialIn)
		variable v : reg_type;
	begin
		v := r;

		v.msgReady := '0';
		v.serialOut := '1';

		case r.state is
			when ready =>
				
				v.msgReady := '0';

				-- Check if start bit was received
				if(serialIn = '0') then
					v.state := r_data;
					v.bitCounter := 0;
				end if;

			when r_data =>

				v.data(r.bitCounter) := serialIn;

				if(r.bitCounter = 7) then
					v.state := r_parity;
				else
					v.bitCounter := r.bitCounter+1;
				end if;

			when r_parity =>

				-- serialIn is parity bit, make sure it's the same as dataParity
				v.dataOk := not(dataParity xor serialIn);
				v.state := r_stop;

			when r_stop =>

				-- Store the message.
				v.msg := r.data;

				if(r.dataOk = '1') then
					v.state := r_ok;
				else
					v.state := r_error;
				end if;

			when r_ok =>

				-- @TODO: don't handle payloads here
				if(r.msg = MSG_HANDSHAKE) then
					-- Received hanshake, complete it.
					v.data := MSG_HANDSHAKE2;
					v.state := t_start;
				else
					v.state := ready;
				end if;

				-- Parity check OK, message is ready.
				v.msgReady := '1'; 

			when r_error =>

				-- Handle error
				v.state := ready;

			when t_start =>

				-- Send start bit
				v.serialOut := '0';

				v.bitCounter := 0;
				v.state := t_data;

			when t_data =>

				-- Send current data bit.
				v.serialOut := r.data(r.bitCounter);

				if(r.bitCounter = 7) then
					v.state := t_parity;
				else
					v.bitCounter := r.bitCounter+1;
				end if;

			when t_parity =>

				-- Send parity
				v.serialOut := dataParity;

				v.state := t_stop;

			when t_stop =>

				-- Stop bit
				v.serialOut := '1';
				v.state := ready;

			when others =>
				-- Don't care
		end case;

		rin <= v;
	end process ; -- comb_proc

end architecture ; -- arch