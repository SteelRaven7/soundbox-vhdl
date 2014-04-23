library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity VectorCERegister is
	generic (
		wordLength : natural := 8
	);
	port (
		input : in std_logic_vector(wordLength-1 downto 0);
		output : out std_logic_vector(wordLength-1 downto 0);

		clkEnable : in std_logic;
		clk : in std_logic;
		reset : in std_logic
	);
end entity ; -- VectorCERegister

architecture arch of VectorCERegister is
	signal delayedSignal : std_logic_vector(wordLength-1 downto 0);
begin
	
	output <= delayedSignal;

	clk_proc : process( clk, reset, clkEnable )
	begin
		if(reset = '1') then
			delayedSignal <= (others => '0');
		elsif(rising_edge(clk) and clkEnable = '1') then
			delayedSignal <= input;
		end if;
	end process ; -- clk_proc

end architecture ; -- arch