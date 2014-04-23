library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;
	use ieee.math_real.all;

entity MemoryInterfaceFoo is
	generic (
		dataWidth : natural := 16;
		addressWidth : natural := 23
	);
	port (
		dataRead : in std_logic;
		dataWrite : in std_logic;
		dataOut : out std_logic_vector(dataWidth-1 downto 0);
		dataIn : in std_logic_vector(dataWidth-1 downto 0);
		address : in std_logic_vector(addressWidth-1 downto 0);

		outputReady : out std_logic;

		-- Serial flash ports
		CS : out std_logic;
		SCLK : out std_logic;
		SI : out std_logic;
		SO : in std_logic;

		clk : in std_logic;
		reset : in std_logic
	);
end entity ; -- MemoryInterfaceFoo

architecture arch of MemoryInterfaceFoo is

begin
	dataOut <= dataIn;
end architecture ; -- arch