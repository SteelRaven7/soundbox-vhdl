library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;
	use work.memory_pkg.all;

entity Configuration_tl is
	port (
		buttonRead : in std_logic;
		buttonWrite : in std_logic;

		leds : out std_logic_vector(15 downto 0);
		switches : in std_logic_vector(15 downto 0);

		serialIn : in std_logic;
		serialOut : out std_logic;

		-- Serial flash ports
		CS : out std_logic;
		SI : out std_logic;
		SO : in std_logic;

		clk : std_logic;
		reset_n : std_logic
	) ;
end entity ; -- Configuration_tl

architecture arch of Configuration_tl is
	signal registerBus : configurableRegisterBus;

	signal msgCommand : std_logic_vector(7 downto 0);
	signal msgPayload : std_logic_vector(15 downto 0);
	signal dataOk : std_logic;
	signal msgReady : std_logic;

	signal serialReggedSignal : std_logic;

	signal serialClk : std_logic;

	signal regMsgCommand : std_logic_vector(7 downto 0);
	signal regMsgPayload : std_logic_vector(15 downto 0);
	signal address : std_logic_vector(15 downto 0);

	signal config : std_logic_vector(15 downto 0);
	signal config2 : std_logic_vector(15 downto 0);

	signal buttonRead_D : std_logic;
	signal buttonWrite_D : std_logic;

	signal reset : std_logic;
begin

	reset <= not(reset_n);

	BR : entity work.ButtonDebouncer
	port map (
		input => buttonRead,
		output => buttonRead_D,

		clk => serialClk,
		reset => reset
	);

	BW : entity work.ButtonDebouncer
	port map (
		input => buttonWrite,
		output => buttonWrite_D,

		clk => serialClk,
		reset => reset
	);

--	serialClkGenerator: entity work.ClockDivider
--	generic map (
--		--divider => 10417 -- SoftwareInterfaceClock
--		divider => 10 -- 10 MHz
--	)
--	port map(
--		reset => reset,
--		clk => clk,
--		clkOut => serialClk
--	);

	serialClk <= clk;


	leds <= registerBus.data;

	address <= x"0000";
	MCU: entity work.MemoryController
	generic map (
		numberRegisters => 1
	)
	port map (
		registerBus => registerBus,

		writeConfiguration => buttonWrite_D,
		readConfiguration => buttonRead_D,
		configurationAddress => address,
		configurationData => switches,

		CS => CS,
		SI => SI,
		SO => SO,

		clk => serialClk,
		reset => reset
	);

	commandReg : entity work.VectorCERegister
	generic map (
		wordLength => 8
	)
	port map (
		input => msgCommand,
		output => regMsgCommand,

		clk => serialClk,
		clkEnable => dataOk,
		reset => reset
	);

	payloadReg : entity work.VectorCERegister
	generic map (
		wordLength => 16
	)
	port map (
		input => msgPayload,
		output => regMsgPayload,

		clk => serialClk,
		clkEnable => dataOk,
		reset => reset
	);

	confReg: entity work.ConfigRegister
	generic map (
		address => x"0000"
	)
	port map (
		input => registerBus,
		output => config,

		clk => serialClk,
		reset => reset
	);

	confReg2: entity work.ConfigRegister
	generic map (
		address => x"0001"
	)
	port map (
		input => registerBus,
		output => config2,

		clk => serialClk,
		reset => reset
	);


end architecture ; -- arch