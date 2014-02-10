library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity Delay is
	generic (
		wordLength : natural := 8
	);
	port (
		input : in std_logic_vector(wordLength-1 downto 0);
		output : out std_logic_vector(wordLength-1 downto 0);

		clk : in std_logic;
		reset : in std_logic
	) ;
end entity ; -- Delay

architecture arch of Delay is
	signal delayedSignal : std_logic_vector(wordLength-1 downto 0);
begin
	
	output <= delayedSignal;

	clk_proc : process( clk, reset )
	begin
		if(reset = '1') then
			delayedSignal <= (others => '0');
		elsif(rising_edge(clk)) then
			delayedSignal <= input;
		end if;
	end process ; -- clk_proc

end architecture ; -- arch