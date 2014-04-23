library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity SerialTest_tl is
	port (
		button : in std_logic;

		leds : out std_logic_vector(15 downto 0);

		serialIn : in std_logic;
		serialOut : out std_logic;

		clk : in std_logic;
		reset : in std_logic
	) ;
end entity ; -- SerialTest_tl

architecture arch of SerialTest_tl is
	signal msgCommand : std_logic_vector(7 downto 0);
	signal msgPayload : std_logic_vector(15 downto 0);
	signal dataOk : std_logic;
	signal msgReady : std_logic;

	signal serialReggedSignal : std_logic;

	signal serialClk : std_logic;

	signal regMsgCommand : std_logic_vector(7 downto 0);
	signal regMsgPayload : std_logic_vector(15 downto 0);
begin

	leds <= msgPayload;

	serialClkGenerator: entity work.ClockDivider
	generic map (
		divider => 10417
	)
	port map(
		reset => reset,
		clk => clk,
		clkOut => serialClk
	);

	SI: entity work.Serialinterface
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

	MsgCommandReg: entity work.VectorRegister
	generic map (
		wordLength => 8
	)
	port map (
		input => msgCommand,
		output => regMsgCommand,

		clk => msgReady,
		reset => reset
	);

	clk_proc : process(clk, serialReggedSignal, serialIn)
	begin
		if(reset = '1') then
			serialReggedSignal <= '0';
		elsif(rising_edge(clk)) then
			if(serialIn = '0') then
				serialReggedSignal <= '1';
			end if;

			if(button = '1') then
				serialReggedSignal <= '1';
			end if;
		end if;
	end process ; -- clk_proc

end architecture ; -- arch