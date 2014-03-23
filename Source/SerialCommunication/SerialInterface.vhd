library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity SerialInterface is
	port (
		msgCommand : out std_Logic_vector(7 downto 0);
		msgPayload : out std_logic_vector(15 downto 0);
		dataOk : out std_logic;
		msgReady : out std_logic;

		serialIn : in std_logic;
		serialOut : out std_logic;

		serialClk : in std_logic;
		reset : in std_logic
	);
end entity ; -- SerialInterface

architecture arch of SerialInterface is
	constant payload_bytes : natural := 2;

	constant MSG_HANDSHAKE : std_logic_vector(7 downto 0) := x"00";
	constant MSG_HANDSHAKE2 : std_logic_vector(7 downto 0) := x"01";

	type state_type is (ready, r_data, r_parity, r_stop, r_nextByte, r_handleMessage,
						t_start, t_data, t_parity, t_stop);

	type data_type is (command, payload);

	type payload_array is array(payload_bytes-1 downto 0) of std_logic_vector(7 downto 0);

	type reg_type is record
		-- State
		state : state_type;
		dataType : data_type;
		bitCounter : natural range 0 to 7;
		payloadNumber : natural range 0 to 3;
		
		-- Data
		dataOk : std_logic;
		msgOk : std_logic;
		data : std_logic_vector(7 downto 0);
		
		-- Output
		serialOut : std_logic;
		command : std_logic_vector(7 downto 0);
		msgReady : std_logic;
		payload : payload_array;
	end record;

	signal r, rin : reg_type;

	signal dataParity : std_logic;
begin

	-- Provides the data parity from the state machine's data values.
	dataParity <= r.data(0) xor r.data(1) xor r.data(2) xor r.data(3)
			  xor r.data(4) xor r.data(5) xor r.data(6) xor r.data(7);

	dataOk <= r.dataOk;
	serialOut <= r.serialOut;
	msgCommand <= r.command;
	msgPayload <= r.payload(1) & r.payload(0);
	msgReady <= r.msgReady;

	clk_proc : process(serialClk, reset)
	begin
		if(reset = '1') then
			r.state <= ready;
			r.command <= (others => '0');
			r.data <= (others => '0');
			r.dataOk <= '0';
			r.msgOk <= '0';
			r.msgReady <= '0';
			r.serialOut <= '1';
			r.payloadNumber <= 0;
			r.dataType <= command;

			payload_reset : for i in 0 to payload_bytes-1 loop
				r.payload(i) <= (others => '0');
			end loop ; -- payload_reset
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
				v.dataType := command;
				v.msgOk := '1';

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

				if(r.dataOk = '0') then
					-- Parity check failed, message cannot be used.
					v.msgOk := '0';					
				end if;

				v.state := r_nextByte;

			when r_nextByte =>

				if(r.dataType = command) then
					-- Store the command
					v.command := r.data;

					-- We received a command, await payload_bytes more bytes as payloads
					v.payloadNumber := payload_bytes;
					v.dataType := payload;
				else
					if(r.payloadNumber /= 0) then
						v.payloadNumber :=  r.payloadNumber-1;
					end if;
					
					v.payload(v.payloadNumber) := r.data;
				end if;

				if(v.payloadNumber = 0) then
					-- No more payloads, we're ready for the next command.
					v.dataType := command;
					
					if(r.msgOk = '1') then
						v.state := r_handleMessage;
					else
						v.state := ready;
					end if;
				else
					-- Receive the next payload.
					v.bitCounter := 0;
					v.state := r_data;
				end if;

			when r_handleMessage =>

				v.msgReady := '1';

				if(r.command = MSG_HANDSHAKE) then
					-- Automatically reply to handshake.
					v.data := MSG_HANDSHAKE2;
					v.state := t_start;
				else
					v.state := ready;
				end if;

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

				-- @TODO: Support multi-byte message transmission?

				-- Stop bit
				v.serialOut := '1';
				v.state := ready;

			when others =>
				-- Don't care
		end case;

		rin <= v;
	end process ; -- comb_proc

end architecture ; -- arch