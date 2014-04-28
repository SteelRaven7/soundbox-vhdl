library ieee ;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use work.memory_pkg.all;

entity ConfigRegister is
	generic (
		wordLength : natural := 16;
		address : std_logic_vector(15 downto 0) := x"0000"
	);
	port (
		input : in configurableRegisterBus;
		output : out std_logic_vector(wordLength-1 downto 0);

		reset : in std_logic
	);
end entity ; -- ConfigRegister

architecture arch of ConfigRegister is
	signal reg_input : std_logic_vector(wordLength-1 downto 0);
	signal reg_clkEnable : std_logic;
	signal addressMatch : std_logic;
begin
	
	reg_input <= input.data(wordLength-1 downto 0);
	
	addressMatch <= '1' when address = input.address else '0';
	
	reg_clkEnable <= addressMatch and input.writeEnable;

	reg: entity work.VectorCERegister
	generic map (
		wordLength => wordLength
	)
	port map (
		input => reg_input,
		output => output,

		clkEnable => reg_clkEnable,
		clk => input.clk,
		reset => reset
	);

end architecture ; -- arch