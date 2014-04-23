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

		writeConfiguration : in std_logic;
		readConfiguration : in std_logic;
		configurationAddress : in std_logic_vector(15 downto 0);
		configurationData : in std_logic_vector(15 downto 0);

		-- Serial flash ports
		CS : out std_logic;
		SI : out std_logic;
		SO : in std_logic;

		clk : in std_logic;
		reset : in std_logic
	);
end entity ; -- MemoryController

architecture arch of MemoryController is
	
	type state_type is (res, readMem, writeMem, writeRegPropagate, writeReg, ready);

	type reg_type is record
		state : state_type;
		registerBus : configurableRegisterBus;
		looping : std_logic;
		dataRead : std_logic;
		dataWrite : std_logic;

		iterator : natural range 0 to numberRegisters;
	end record;

	signal r, rin : reg_type;

	signal MI_dataRead : std_logic;
	signal MI_dataWrite : std_logic;
	signal MI_dataOut : std_logic_vector(15 downto 0);
	signal MI_dataIn : std_logic_vector(15 downto 0);
	signal MI_address : std_logic_vector(15 downto 0);
	signal MI_address_padded : std_logic_vector(22 downto 0);
	signal MI_outputReady : std_logic;
begin
	registerBus <= r.registerBus;
	MI_address <= r.registerBus.address;
	MI_address_padded <= "0000000" & MI_address;
	MI_dataIn <= r.registerBus.data;
	MI_dataRead <= r.dataRead;
	MI_dataWrite <= r.dataWrite;

	MI: entity work.MemoryInterface
	port map(
		dataRead => MI_dataRead,
		dataWrite => MI_dataWrite,
		dataOut => MI_dataOut,
		dataIn => MI_dataIn,
		address => MI_address_padded,
		outputReady => MI_outputReady,

		CS => CS,
		SI => SI,
		SO => SO,

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

	comb_proc : process(r, rin, MI_outputReady, MI_dataOut, writeConfiguration, readConfiguration, configurationData, configurationAddress )
		variable v : reg_type;
	begin
		v := r;

		case r.state is
			when res =>

				-- Just go to ready for now
				v.state := ready;

				v.dataWrite := '0';
				v.dataRead := '0';

				-- Prepare to loop through all memory locations and write to registers
--				v.iterator := 0;
--				v.address := (others => '0');
--				v.registerBus.address := (others => '0'); 
--				v.state := readMem;
--				v.dataRead := '1';

			when readMem =>
				v.dataRead := '0';

				if(MI_outputReady = '1') then
					-- Propagate the data to the current register.
					v.state := writeRegPropagate;
					v.registerBus.data := MI_dataOut;
					v.registerBus.writeEnable := '1';
				end if;

			when writeMem =>
				v.dataWrite := '0';

				--v.state := writeReg;
				--v.registerBus.writeEnable := '1';

			when writeRegPropagate =>
				v.registerBus.writeEnable := '0';

				v.state := ready;

--				if(r.iterator = numberRegisters-1) then
--					-- All registers have been written to.
--					v.state := ready;
--				else
--					v.iterator := r.iterator+1;
--					v.registerBus.address := std_logic_vector(to_unsigned(v.iterator, 16));
--					v.state := readMem;
--				end if;

			when ready =>

				if(writeConfiguration = '1') then
					v.state := writeMem;

					v.registerBus.data := configurationData;
					v.registerBus.address := configurationAddress;
					v.dataWrite := '1';
--					v.state := writeReg;
--					v.registerBus.writeEnable := '1';
				end if;

				if(readConfiguration = '1') then
					v.state := readMem;

					v.registerBus.address := configurationAddress;
					v.dataRead := '1';
				end if;

			when writeReg =>

				v.registerBus.writeEnable := '0';
				v.state := ready;

			when others =>
				-- Don't care
				
		end case;

		rin <= v;
	end process ; -- comb_proc
end architecture ; -- arch