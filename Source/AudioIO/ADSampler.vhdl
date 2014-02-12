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

		XADC_EOC : in std_logic;
		XADC_busy : in std_logic;
		XADC_reset : out std_logic;

		output : out std_logic_vector(15 downto 0);

		clk : in std_logic;
		reset : in std_logic
	) ;
end entity ; -- ADSampler

architecture arch of ADSampler is
	constant address_input : std_logic_vector(6 downto 0) := "000" & x"3";

	type state_type is (res, busy, busy_conversion, read);

	type reg_type is record
		state : state_type;

		output : std_logic_vector(15 downto 0);

		DRP_enable : std_logic;
	end record;

	signal r, rin : reg_type;
begin

	DRP_clk <= clk;
	XADC_reset <= reset;
	DRP_address <= address_input;
	DRP_enable <= r.DRP_enable;
	DRP_writeEnable <= '0';
	DRP_input <= (others => '0');

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
					v.output := DRP_output;

				end if;

			when others =>
				-- Don't care
		end case;

		rin <= v;
	end process ; -- comb_proc

end architecture ; -- arch