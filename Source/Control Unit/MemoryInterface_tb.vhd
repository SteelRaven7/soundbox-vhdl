library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity MemoryInterface_tb is
	generic (
		dataWidth : natural := 16;
		addressWidth : natural := 23
	);
end entity ; -- MemoryInterface_tb

architecture arch of MemoryInterface_tb is
	signal dataRead : std_logic := '0';
	signal dataWrite : std_logic := '0';
	signal dataOut : std_logic_vector(dataWidth-1 downto 0);
	signal dataIn : std_logic_vector(dataWidth-1 downto 0);
	signal address : std_logic_vector(addressWidth-1 downto 0);
	signal outputReady : std_logic;
	signal CS : std_logic;
	signal SCLK : std_logic;
	signal SI : std_logic;
	signal SO : std_logic := '0';
	signal clk : std_logic := '0';
	signal reset : std_logic;

	constant clkPeriod : time := 10 ns;
begin

	uut: entity work.MemoryInterface
	port map (
		dataRead => dataRead,
		dataWrite => dataWrite,
		dataOut => dataOut,
		dataIn => dataIn,
		address => address,
		outputReady => outputReady,
		CS => CS,
		SCLK => SCLK,
		SI => SI,
		SO => SO,
		clk => clk,
		reset => reset
	);

	clk_gen : process
	begin
		clk <= not(clk);
		wait for clkPeriod/2;
	end process ; -- clk_gen

	stimuli : process
	begin
		reset <= '1';
		wait for clkPeriod*5;
		reset <= '0';

		wait for clkPeriod*20;

		address <= (others => '0');
		dataIn <= x"f001";
		dataWrite <= '1';

		wait for clkPeriod;

		dataWrite <= '0';

		wait for clkPeriod*60;

		address(2) <= '1';
		dataIn <= x"ffa0";
		dataWrite <= '1';

		wait for clkPeriod;

		dataWrite <= '0';

		wait for clkPeriod*60;

		address(0) <= '1';
		dataRead <= '1';

		wait for clkPeriod;

		dataRead <= '0';

		wait for clkPeriod*42;

		SO <= '1';
		wait for clkPeriod;
		SO <= '0';
		wait for clkPeriod;
		SO <= '1';
		wait for clkPeriod;
		SO <= '0';
		wait for clkPeriod*7;
		SO <= '1';

		wait for clkPeriod*100;

		wait;
	end process ; -- stimuli

end architecture ; -- arch