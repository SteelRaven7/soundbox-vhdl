library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity ADSampler is
	port (

		--http://www.xilinx.com/support/documentation/user_guides/ug480_7Series_XADC.pdf

		DRP_output : in std_logic_vector(15 downto 0);
		DRP_dataReady : in std_logic;
		
		DRP_input : out std_logic_vector(15 downto 0);
		DRP_address : out std_logic_vector(6 downto 0);
		DRP_enable : out std_logic;
		DRP_writeEnable : out std_logic;
		DRP_clk : out std_logic;

		XADC_reset : out std_logic;
		XADC_convst : out std_logic;
		XADC_convstclk : out std_logic;

		clk : in std_logic;
		reset : in std_logic
	) ;
end entity ; -- ADSampler

architecture arch of ADSampler is
	-- Address to the value of the first port A/D converter
	constant address_input : std_logic_vector(6 downto 0) := x"10";

	-- Address to the flag register
	constant address_flags : std_logic_vector(6 downto 0) := x"3F";

	-- ADdress to config registers
	constant address_config0 : std_logic_vector(6 downto 0) := x"40";
	constant address_config1 : std_logic_vector(6 downto 0) := x"41";
	constant address_config2 : std_logic_vector(6 downto 0) := x"42";

	type state_type is (config_flags, config_r0, config_r1, config_r2, sample);

	type reg_type is record
		state : state_type;
	end record;

	signal r, rin : reg_type;
begin
	-- Tie to global clock according to XADC spec.
	XADC_convst <= clk;
	DRP_input <= (others => '0');

	clk_proc : process( clk, reset )
	begin
		if(reset = '1') then
			r.state <= config;
		elsif(rising_edge(clk)) then
			r <= rin;
		end if;
	end process ; -- clk_proc

	comb_proc : process( r, rin, DRP_output, DRP_dataReady )
		variable v : reg_type;
	begin
		v := r;

		case r.state is
			when config_flags =>
				-- Config flags register;
			when config_r0 =>
				-- Config register 0
			when config_r1 =>
				-- Config register 1;
			when config_r2 =>
				-- Config register 2;
			when others =>
				-- Don't care
		end case;

		rin <= v;
	end process ; -- comb_proc

end architecture ; -- arch