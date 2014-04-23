library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;
	use work.memory_pkg.all;

entity Configuration_tl is
	port (
		button : in std_logic;
		button2 : in std_logic;

		leds : out std_logic_vector(15 downto 0);
		switches : in std_logic_vector(15 downto 0);

		serialIn : in std_logic;
		serialOut : out std_logic;

		-- Serial flash ports
		CS : out std_logic;
		SI : out std_logic;
		SO : in std_logic;

		clk : std_logic;
		reset : std_logic
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
begin

	serialClkGenerator: entity work.ClockDivider
	generic map (
		--divider => 10417 -- SoftwareInterfaceClock
		divider => 5 -- 20 MHz
	)
	port map(
		reset => reset,
		clk => clk,
		clkOut => serialClk
	);

	SWI: entity work.SoftwareInterface
	port map (
		msgCommand => msgCommand,
		msgPayload => msgPayload,
		msgReady => msgReady,
		dataOk => dataOk,

		serialIn => serialIn,
		serialOut => serialOut,

		serialClk => serialClk,
		reset => reset
	);

	leds <= registerBus.data;

	--address <= x"00" & regMsgCommand;
	address <= x"0000";
	MCU: entity work.MemoryController
	generic map (
		numberRegisters => 1
	)
	port map (
		registerBus => registerBus,

		writeConfiguration => button,
		readConfiguration => button2,
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