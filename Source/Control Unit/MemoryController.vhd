library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;
	use work.memory_pkg.all;

entity MemoryController is
	generic (
		numberRegisters : natural := 2
	);
	port (
		registerBus : out configurableRegisterBus;

		-- Signals from 
		command : in std_logic_vector(15 downto 0);
		payload : in std_logic_vector(15 downto 0);
		executeCommand : in std_logic;
		clearDone : out std_logic;

		-- Serial flash ports
		CS : out std_logic;
		SI : out std_logic;
		SO : in std_logic;

		clk : in std_logic;
		reset : in std_logic
	);
end entity ; -- MemoryController

architecture arch of MemoryController is
	
	constant commandClear : std_logic_vector(15 downto 0) := x"0000";

	type state_type is (res,
		clearMemory,
		pollMemoryReady,
		pollMemoryReady2,
		pollMemoryReady3,
		readMem,
		readMem2,
		writeMem,
		writeRegPropagate,
		writeReg,
		ready
	);

	type reg_type is record
		state : state_type;
		registerBus : configurableRegisterBus;
		memAddress : std_logic_vector(15 downto 0);
		memData : std_logic_vector(15 downto 0);
		looping : std_logic;
		dataRead : std_logic;
		dataWrite : std_logic;
		dataClear : std_logic;
		waitStart : std_logic;
		pollStatusRegisters : std_logic;
		clearDone : std_logic;

		iterator : natural range 1 to numberRegisters;
	end record;

	signal r, rin : reg_type;

	signal MI_dataRead : std_logic;
	signal MI_dataWrite : std_logic;
	signal MI_dataClear : std_logic;
	signal MI_dataOut : std_logic_vector(15 downto 0);
	signal MI_dataIn : std_logic_vector(15 downto 0);
	signal MI_address : std_logic_vector(15 downto 0);
	signal MI_address_padded : std_logic_vector(22 downto 0);
	signal MI_outputReady : std_logic;
	signal MI_done : std_logic;

	signal waitDone : std_logic;
begin
	registerBus <= r.registerBus;
	registerBus.clk <= clk;
	
	clearDone <= r.clearDone;

	MI_address <= r.memAddress;
	MI_address_padded <= "0000000" & MI_address;
	MI_dataIn <= r.memData;
	--MI_dataIn <= r.registerBus.data;
	MI_dataRead <= r.dataRead;
	MI_dataWrite <= r.dataWrite;
	MI_dataClear <= r.dataClear;

	MI: entity work.MemoryInterface
	port map(
		dataRead => MI_dataRead,
		dataWrite => MI_dataWrite,
		dataClear => MI_dataClear,
		dataOut => MI_dataOut,
		dataIn => MI_dataIn,
		address => MI_address_padded,
		outputReady => MI_outputReady,
		done => MI_done,
		pollStatusRegisters => r.pollStatusRegisters,

		CS => CS,
		SI => SI,
		SO => SO,

		clk => clk,
		reset => reset
	);

	Delay : entity work.Delay
	generic map (
		counter => 10000000 -- 1 sec on 10MHz
	)
	port map (
		input => r.waitStart,
		output => waitDone,

		clk => clk,
		reset => reset
	);

	clk_proc : process( clk, reset )
	begin
		if(reset = '1') then
			r.state <= res;
			r.registerBus.writeEnable <= '0';
		elsif(rising_edge(clk)) then
			r <= rin;
		end if;
	end process ; -- clk_proc

	comb_proc : process(r, rin, MI_done, MI_outputReady, MI_dataOut, command, payload, executeCommand, waitDone)
		variable v : reg_type;
	begin
		v := r;

		case r.state is
			when res =>

				v.dataWrite := '0';
				v.dataRead := '0';
				v.registerBus.address := (others => '0');
				v.registerBus.data := (others => '0');
				v.registerBus.writeEnable := '0';
				v.waitStart := '0';
				v.clearDone := '0';

				if(MI_done = '1') then
					-- Loop through all memory locations and write to registers
					v.iterator := 1;
					v.state := readMem;
				end if;

			when clearMemory =>
				v.dataClear := '0';

				if(MI_done = '1') then
					v.state := pollMemoryReady;
				end if;

			when pollMemoryReady =>
				v.waitStart := '1';
				v.state := pollMemoryReady2;

			when pollMemoryReady2 =>
				v.waitStart := '0';

				if(waitDone = '1') then
					v.pollStatusRegisters := '1';
					v.state := pollMemoryReady3;
				end if;

			when pollMemoryReady3 =>
				v.pollStatusRegisters := '0';

				if(MI_done = '1') then

					if(MI_dataOut(0) = '1') then
						-- Memory is still being cleared.
						v.state := pollMemoryReady;
					else
						v.clearDone := '1';
						v.state := ready;
					end if;
				end if;

			when readMem =>

				v.dataRead := '1';
				v.memAddress := std_logic_vector(to_unsigned(r.iterator, v.memAddress'length));

				v.state := readMem2;

			when readMem2 =>

				v.dataRead := '0';

				if(MI_done = '1') then
					-- Propagate the data to the current register.
					v.state := writeRegPropagate;
					v.registerBus.address := r.memAddress;
					v.registerBus.data := MI_dataOut;
					v.registerBus.writeEnable := '1';
				end if;

			when writeRegPropagate =>
				v.registerBus.writeEnable := '0';

				if(r.iterator < numberRegisters) then
					v.iterator := r.iterator+1;
					v.state := readMem;
				else
					v.state := ready;
				end if;

			when writeMem =>
				v.dataWrite := '0';

				if(MI_done = '1') then
					-- Also write to the config registers.
					v.registerBus.data := r.memData;
					v.registerBus.address := r.memAddress;
					v.registerBus.writeEnable := '1';
					v.state := writeReg;
				end if;

			when ready =>

				v.clearDone := '0';

				if(executeCommand = '1') then
					if(command = commandClear) then
						v.state := clearMemory;
						v.dataClear := '1';
					else
						-- Write new configuration
						v.state := writeMem;
						v.memData := payload;
						v.memAddress := command;
						v.dataWrite := '1';
					end if;
				end if;

--				if(writeConfiguration = '1') then
--					v.state := writeMem;
--
--					v.memData := configurationData;
--					v.memAddress := configurationAddress;
--					v.dataWrite := '1';
--				end if;
--
--				if(readConfiguration = '1') then
--					v.state := readMem;
--
--					v.memAddress := configurationAddress;
--					v.dataRead := '1';
--				end if;

			when writeReg =>

				v.registerBus.writeEnable := '0';
				v.state := ready;

			when others =>
				-- Don't care
				
		end case;

		rin <= v;
	end process ; -- comb_proc
end architecture ; -- arch