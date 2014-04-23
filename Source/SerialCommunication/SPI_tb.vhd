library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;
	use ieee.math_real.all;

entity SPI_tb is
	generic (
		maxInputWidth : natural := 16;
		maxOutputWidth : natural := 16
	);
end entity ; -- SPI_tb

architecture arch of SPI_tb is
	constant clk_period : time := 10 ns;
	signal clk : std_logic := '0';

	signal input : std_logic_vector(maxInputWidth-1 downto 0);
	signal inputMSB : std_logic_vector(natural(ceil(log2(real(maxInputWidth))))-1 downto 0);
	signal writeEnable : std_logic;
	signal output : std_logic_vector(maxOutputWidth-1 downto 0);
	signal outputMSB : std_logic_vector(natural(ceil(log2(real(maxOutputWidth))))-1 downto 0);
	signal outputReady : std_logic;
	signal serialInput : std_logic;
	signal serialOutput : std_logic;
	signal cs : std_logic;
	signal sclk : std_logic;
	signal reset : std_logic;
begin

	clk_proc : process
	begin
		wait for clk_period/2;
		clk <= not(clk);
	end process ; -- clk_proc

	UUT : entity work.SPI
	generic map (
		maxInputWidth => maxInputWidth,
		maxOutputWidth => maxOutputWidth
	)
	port map (
		input => input,
		inputMSB => inputMSB,
		writeEnable => writeEnable,
		output => output,
		outputMSB => outputMSB,
		outputReady => outputReady,
		serialInput => serialInput,
		serialOutput => serialOutput,
		cs => cs,
		sclk => sclk,
		serialClk => clk,
		reset => reset
	);

	stimuli : process
	begin
		
		reset <= '1';
		wait for clk_period*5;
		reset <= '0';

		input <= x"00aa";
		inputMSB <= x"7";
		outputMSB <= x"7";
		writeEnable <= '0';
		serialOutput <= '0';

		wait for clk_period;

		writeEnable <= '1';
		wait for clk_period;
		writeEnable <= '0';

		wait for 7.5*clk_period;

		-- Introduce some skew.
		wait for 0.1*clk_period;

		serialOutput <= '1';

		wait for clk_period;
		serialOutput <= '0';

		wait for clk_period;
		serialOutput <= '1';

		wait for 3*clk_period;
		serialOutput <= '0';

		wait for clk_period;
		serialOutput <= '1';

		wait;
	end process ; -- stimuli

end architecture ; -- arch