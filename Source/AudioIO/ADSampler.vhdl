library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity ADSampler is
	port (
		--http://www.xilinx.com/support/documentation/user_guides/ug480_7Series_XADC.pdf

		vauxp : in std_logic;
		vauxn : in std_logic;

		output : out std_logic_vector(11 downto 0);

		sampleClk : in std_logic;
		clk : in std_logic;
		reset : in std_logic
	) ;
end entity ; -- ADSampler

architecture arch of ADSampler is
	constant address_input : std_logic_vector(6 downto 0) := "001" & x"3";

	type state_type is (res, busy, busy_conversion, read);

	type reg_type is record
		state : state_type;

		output : std_logic_vector(11 downto 0);

		DRP_enable : std_logic;
	end record;

	signal r, rin : reg_type;

	signal DRP_output : std_logic_vector(15 downto 0);
	signal DRP_dataReady : std_logic;
	signal DRP_input : std_logic_vector(15 downto 0);
	signal DRP_address : std_logic_vector(6 downto 0);
	signal DRP_enable : std_logic;
	signal DRP_writeEnable : std_logic;
	signal DRP_clk : std_logic;
	signal XADC_EOC : std_logic;
	signal XADC_busy : std_logic;
	signal XADC_reset : std_logic;
	signal CONVST_IN : std_logic;

	component xadc_wiz_0
	port (
          DADDR_IN            : in  STD_LOGIC_VECTOR (6 downto 0);     -- Address bus for the dynamic reconfiguration port
          DCLK_IN             : in  STD_LOGIC;                         -- Clock input for the dynamic reconfiguration port
          DEN_IN              : in  STD_LOGIC;                         -- Enable Signal for the dynamic reconfiguration port
          DI_IN               : in  STD_LOGIC_VECTOR (15 downto 0);    -- Input data bus for the dynamic reconfiguration port
          DWE_IN              : in  STD_LOGIC;                         -- Write Enable for the dynamic reconfiguration port
          RESET_IN            : in  STD_LOGIC;                         -- Reset signal for the System Monitor control logic
          VAUXP3              : in  STD_LOGIC;                         -- Auxiliary Channel 2
          VAUXN3              : in  STD_LOGIC;
          BUSY_OUT            : out  STD_LOGIC;                        -- ADC Busy signal
          DO_OUT              : out  STD_LOGIC_VECTOR (15 downto 0);   -- Output data bus for dynamic reconfiguration port
          DRDY_OUT            : out  STD_LOGIC;                        -- Data ready signal for the dynamic reconfiguration port
          EOC_OUT             : out  STD_LOGIC;                        -- End of Conversion Signal
          ALARM_OUT          : out STD_LOGIC;                         -- OR'ed output of all the Alarms
          VP_IN               : in  STD_LOGIC;                         -- Dedicated Analog Input Pair
          VN_IN               : in  STD_LOGIC;
          CONVST_IN			  : in  STD_LOGIC
	);
	end component;
begin

	DRP_clk <= clk;
	XADC_reset <= reset;
	DRP_address <= address_input;
	DRP_enable <= r.DRP_enable;
	DRP_writeEnable <= '0';
	DRP_input <= (others => '0');

	CONVST_IN <= sampleClk;

	theCore : xadc_wiz_0
	port map (
		DADDR_IN => DRP_address,
		DCLK_IN => DRP_clk,
		DEN_IN => DRP_enable,
		DI_IN => DRP_input,
		DWE_IN => DRP_writeEnable,
		RESET_IN => XADC_reset,
		VAUXP3 => vauxp,
		VAUXN3 => vauxn,
		BUSY_OUT => XADC_busy,
		DO_OUT => DRP_output,
		DRDY_OUT => DRP_dataReady,
		EOC_OUT => XADC_EOC,
		CONVST_IN => CONVST_IN,
		--ALARM_OUT
		VP_IN => '0',
		VN_IN => '0'
	);
	
	output <= r.output;

	clk_proc : process( clk, reset )
	begin
		if(reset = '1') then
			r.state <= res;
			r.output <= (others => '0');
		elsif(rising_edge(clk)) then
			r <= rin;
		end if;
	end process ; -- clk_proc

	comb_proc : process( r, rin, DRP_output, DRP_dataReady, XADC_busy, XADC_EOC )
		variable v : reg_type;
	begin
		v := r;

		v.DRP_enable := '0';

		case r.state is
			when res =>
				-- Reset the XADC (done strucutrally, just go to next state)
				v.state := busy;

			when busy =>
				-- Wait for the XADC to become ready
				-- (This state might not be necessary)
				if(XADC_busy = '0') then
					v.state := busy_conversion;
				end if;

			when busy_conversion =>
				-- Wait for the DRP to acquire the data
				if(XADC_EOC = '1') then
					-- Data is available in the DRP, read it.
					v.DRP_enable := '1';
					v.state := read;
				end if;

			when read =>
				-- Wait for the DRP data to become ready
				if(DRP_dataReady = '1') then
					v.state := busy_conversion;

					-- Read the DRP output
					v.output := DRP_output(15 downto 4);

				end if;

			when others =>
				-- Don't care
		end case;

		rin <= v;
	end process ; -- comb_proc

end architecture ; -- arch