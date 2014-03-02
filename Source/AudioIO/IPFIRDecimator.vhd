library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity IPFIRDecimator is
	port (
		input : in std_logic_vector(11 downto 0);
		output : out std_logic_vector(15 downto 0);

		clk : in std_logic;
		reset : in std_logic
	);
end entity ; -- IPFIRDecimator

architecture arch of IPFIRDecimator is

	COMPONENT fir_compiler_0
	PORT (
		aclk : IN STD_LOGIC;
		aresetn : IN STD_LOGIC;
		s_axis_data_tvalid : IN STD_LOGIC;
		s_axis_data_tready : OUT STD_LOGIC;
		s_axis_data_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		m_axis_data_tvalid : OUT STD_LOGIC;
		m_axis_data_tdata : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
	END COMPONENT;

	signal inputValid : std_logic;
	signal inputReady : std_logic;

	signal filterOutput : std_logic_vector(15 downto 0);
	signal outputValid : std_logic;

	signal resetn : std_logic;

begin

	inputValid <= clk and inputReady;
	resetn <= not(reset);

	FIR : fir_compiler_0
	port map (

		aclk => clk,
		aresetn => resetn,

		s_axis_data_tvalid => inputValid,
		s_axis_data_tready => inputReady,

		s_axis_data_tdata => input,
		m_axis_data_tdata => filterOutput,
		m_axis_data_tvalid => outputValid
	);

	OutputReg : entity work.Delay
	port map (
		input => filterOutput,
		output => output,

		clk => outputValid,
		reset => reset
	);

end architecture ; -- arch