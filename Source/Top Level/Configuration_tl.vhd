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

		-- Serial interface (RS-232/UART @ 9600 Hz)
		SI_serialIn : in std_logic;
		SI_serialOut : out std_logic;

		-- Serial flash ports
		CS : out std_logic;
		SI : out std_logic;
		SO : in std_logic;

		clk : std_logic;
		reset_n : std_logic
	) ;
end entity ; -- Configuration_tl

architecture arch of Configuration_tl is

	constant clk10MHzDivider : natural := 10;
	constant clk9600HzDivider : natural := 10417;

	signal configRegisterBus : configurableRegisterBus;

	signal SI_msgCommand : std_logic_vector(15 downto 0);
	signal SI_msgPayload : std_logic_vector(15 downto 0);
	signal SI_dataOk : std_logic;
	signal SI_msgReady : std_logic;
	signal SI_clearDone : std_logic;
	signal MCU_execute : std_logic;
	signal MCU_clearDone : std_logic;

	signal serialReggedSignal : std_logic;

	signal serialClk : std_logic;
	signal serialSIClk : std_logic;

	signal config : std_logic_vector(15 downto 0);
	signal config2 : std_logic_vector(15 downto 0);

	signal buttonRead_D : std_logic;
	signal buttonWrite_D : std_logic;

	signal reset : std_logic;
begin

	-- Input

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



	-- Serial interfaces

	serialClkGenerator: entity work.ClockDivider
	generic map (
		divider => 10 -- 10 MHz
	)
	port map(
		reset => reset,
		clk => clk,
		clkOut => serialClk
	);

	serialSIClkGenerator: entity work.ClockDivider
	generic map (
		divider => 10417 -- SoftwareInterfaceClock @ 9600 Hz
	)
	port map(
		reset => reset,
		clk => clk,
		clkOut => serialSIClk
	);

	SIU: entity work.SoftwareInterface
	port map (
		msgCommand => SI_msgCommand,
		msgPayload => SI_msgPayload,
		dataOk => SI_dataOk,
		msgReady => SI_msgReady,
		clearDone => SI_clearDone,
		serialIn => SI_serialIn,
		serialOut => SI_serialOut,
		serialClk => serialSIClk,
		reset => reset
	);

	MCU_PL : entity work.PulseLimiter
	port map (
		input => SI_msgReady,
		output => MCU_execute,

		clk => serialClk,
		reset => reset
	);

	MCU_PK : entity work.PulseKeeper
	generic map (
		duration => clk9600HzDivider/clk10MHzDivider
	)
	port map (
		input => MCU_clearDone,
		output => SI_clearDone,

		clk => serialClk,
		reset => reset
	);



	MCU: entity work.MemoryController
	generic map (
		numberRegisters => 2
	)
	port map (
		registerBus => configRegisterBus,

		command => SI_msgCommand,
		payload => SI_msgPayload,
		executeCommand => MCU_execute,
		clearDone => MCU_clearDone,

		CS => CS,
		SI => SI,
		SO => SO,

		clk => serialClk,
		reset => reset
	);

	--leds <= configRegisterBus.data;
	leds <= config2;

	-- Configuration registers

	confReg: entity work.ConfigRegister
	generic map (
		address => x"0001"
	)
	port map (
		input => configRegisterBus,
		output => config,

		reset => reset
	);

	confReg2: entity work.ConfigRegister
	generic map (
		address => x"0002"
	)
	port map (
		input => configRegisterBus,
		output => config2,

		reset => reset
	);


end architecture ; -- arch