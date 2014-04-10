library ieee ;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity EffectReverb is
	generic(IO_length : integer := 16;
			c_length : integer := 16;
			addr_length : integer := 12); --Maximum delay is 4095 samples for all stages.
	port(input : in std_logic_vector(IO_length-1 downto 0);
			output : out std_logic_vector(IO_length-1 downto 0);
			--gain : in std_logic_vector(c_length-1 downto 0);
			-- SCLK : in std_logic;
			CLK : in std_logic;
			RESET : in std_logic);
end EffectReverb;

architecture behav of EffectReverb is
	
	type signal_array is array(3 downto 0) of std_logic_vector(c_length-1 downto 0);
	type gain_array is array(3 downto 0) of signed(IO_length+c_length-1 downto 0);
	
	constant coeff_pos : std_logic_vector(c_length-1 downto 0) := x"7F5B";
	constant coeff_neg : std_logic_vector(c_length-1 downto 0) := x"80A5";
	constant wet_coeff : std_logic_vector(c_length-1 downto 0) := x"7FFF";

	signal gain_outputs : gain_array;
	signal scalar : gain_array;
	signal matrix_outputs : signal_array;
	
	signal delay_outputs : signal_array;
	signal wet_gain : gain_array;
	signal wet_sum : signed(IO_length+c_length-1 downto 0);
	signal wet_2_out : std_logic_vector(IO_length-1 downto 0);

	type mem_signals is record
		--writeEnable : std_logic;
		addr : std_logic_vector(addr_length-1 downto 0);
		--writeAddr : std_logic_vector(11 downto 0);
		dataIn : std_logic_vector(IO_length-1 downto 0);
		--readAddr : std_logic_vector(11 downto 0);
		dataOut : std_logic_vector(IO_length-1 downto 0);
		feedback : unsigned(addr_length-1 downto 0);
	end record;
	
	signal writeEnable : std_logic;
	signal delay1 : mem_signals;
	signal delay2 : mem_signals;
	signal delay3 : mem_signals;
	signal delay4 : mem_signals;

	COMPONENT blk_mem_gen_delay1
	PORT (
		clka : IN STD_LOGIC;
		wea : IN STD_LOGIC;
		addra : IN STD_LOGIC_VECTOR(addr_length-1 DOWNTO 0);
		dina : IN STD_LOGIC_VECTOR(IO_length-1 DOWNTO 0);
		clkb : IN STD_LOGIC;
		addrb : IN STD_LOGIC_VECTOR(addr_length-1 DOWNTO 0);
		doutb : OUT STD_LOGIC_VECTOR(IO_length-1 DOWNTO 0)
	);
	END COMPONENT;

	COMPONENT blk_mem_gen_delay2
	PORT (
		clka : IN STD_LOGIC;
		wea : IN STD_LOGIC;
		addra : IN STD_LOGIC_VECTOR(addr_length-1 DOWNTO 0);
		dina : IN STD_LOGIC_VECTOR(IO_length-1 DOWNTO 0);
		clkb : IN STD_LOGIC;
		addrb : IN STD_LOGIC_VECTOR(addr_length-1 DOWNTO 0);
		doutb : OUT STD_LOGIC_VECTOR(IO_length-1 DOWNTO 0)
	);
	END COMPONENT;

	COMPONENT blk_mem_gen_delay3
	PORT (
		clka : IN STD_LOGIC;
		wea : IN STD_LOGIC;
		addra : IN STD_LOGIC_VECTOR(addr_length-1 DOWNTO 0);
		dina : IN STD_LOGIC_VECTOR(IO_length-1 DOWNTO 0);
		clkb : IN STD_LOGIC;
		addrb : IN STD_LOGIC_VECTOR(addr_length-1 DOWNTO 0);
		doutb : OUT STD_LOGIC_VECTOR(IO_length-1 DOWNTO 0)
	);
	END COMPONENT;

	COMPONENT blk_mem_gen_delay4
	PORT (
		clka : IN STD_LOGIC;
		wea : IN STD_LOGIC;
		addra : IN STD_LOGIC_VECTOR(addr_length-1 DOWNTO 0);
		dina : IN STD_LOGIC_VECTOR(IO_length-1 DOWNTO 0);
		clkb : IN STD_LOGIC;
		addrb : IN STD_LOGIC_VECTOR(addr_length-1 DOWNTO 0);
		doutb : OUT STD_LOGIC_VECTOR(IO_length-1 DOWNTO 0)
	);
	END COMPONENT;
	
	type state_type is (readStart, readWait, read, writeDone);

	constant waitTime : natural := 4;
	
	constant addrMax1 : natural := 313;
	constant addrMax2 : natural := 449;
	constant addrMax3 : natural := 677;
	constant addrMax4 : natural := 829;

	type reg_type is record
		state : state_type;
		waitCounter : natural range 0 to waitTime;
		address1 : unsigned(addr_length-1 downto 0);
		address2 : unsigned(addr_length-1 downto 0);
		address3 : unsigned(addr_length-1 downto 0);
		address4 : unsigned(addr_length-1 downto 0);
		writeEnable : std_logic;
		delayedOutput1 : std_logic_vector(IO_length-1 downto 0);
		delayedOutput2 : std_logic_vector(IO_length-1 downto 0);
		delayedOutput3 : std_logic_vector(IO_length-1 downto 0);
		delayedOutput4 : std_logic_vector(IO_length-1 downto 0);
	end record;

	signal r, rin : reg_type;
	
	begin
	
		--Each delayed signal times it's feedback coefficient, vector*vector transpose
		gain_outputs(0) <= signed(delay_outputs(0))*signed(coeff_pos);
		gain_outputs(1) <= signed(delay_outputs(1))*signed(coeff_pos);
		gain_outputs(2) <= signed(delay_outputs(2))*signed(coeff_pos);
		gain_outputs(3) <= signed(delay_outputs(3))*signed(coeff_neg);
		
		--summation of the input and the mixed feedback signals
		delay1.dataIn <= std_logic_vector(signed(input)+signed(matrix_outputs(0)));
		delay2.dataIn <= std_logic_vector(signed(input)+signed(matrix_outputs(1)));
		delay3.dataIn <= std_logic_vector(signed(input)+signed(matrix_outputs(2)));
		delay4.dataIn <= std_logic_vector(signed(input)+signed(matrix_outputs(3)));
		
		--vector*vector transpose = scalar. a(0:3)*delayOut(0:3) = a(0)*delayOut(0) + ...
		--minimizing gain stages by using subtractions instead of two separate gains.
		scalar(0) <= gain_outputs(1)+gain_outputs(2);
		scalar(1) <= gain_outputs(3)-gain_outputs(0);
		scalar(2) <= gain_outputs(3)+gain_outputs(0);
		scalar(3) <= gain_outputs(1)-gain_outputs(2);
		
		--Result of the vector multiplications
		matrix_outputs(0) <= std_logic_vector(scalar(0)(IO_length+c_length-1 downto IO_length));
		matrix_outputs(1) <= std_logic_vector(scalar(1)(IO_length+c_length-1 downto IO_length));
		matrix_outputs(2) <= std_logic_vector(scalar(2)(IO_length+c_length-1 downto IO_length));
		matrix_outputs(3) <= std_logic_vector(scalar(3)(IO_length+c_length-1 downto IO_length));
		
		--Output gains of the delay net
		wet_gain(0) <= signed(delay_outputs(0))*signed(wet_coeff);
		wet_gain(1) <= signed(delay_outputs(1))*signed(wet_coeff);
		wet_gain(2) <= signed(delay_outputs(2))*signed(wet_coeff);
		wet_gain(3) <= signed(delay_outputs(3))*signed(wet_coeff);
		
		--Summation of the wet signals and the dry input
		wet_sum <= wet_gain(0) + wet_gain(1) + wet_gain(2) + wet_gain(3);
		wet_2_out <= std_logic_vector(wet_sum(IO_length+c_length-1 downto IO_length));
		output <= std_logic_vector(signed(input)+signed(wet_2_out));

		memory_1:blk_mem_gen_delay1
		port map (
			dina => delay1.dataIn,
			wea => writeEnable,
			doutb => delay1.dataOut,
			clka => clk,
			clkb => clk,
			addra => delay1.addr,
			addrb => delay1.addr
		);

		memory_2: blk_mem_gen_delay2
		port map (
			dina => delay2.dataIn,
			wea => writeEnable,
			doutb => delay2.dataOut,
			clka => clk,
			clkb => clk,
			addra => delay2.addr,
			addrb => delay2.addr
		);

		memory_3: blk_mem_gen_delay3
		port map (
			dina => delay3.dataIn,
			wea => writeEnable,
			doutb => delay3.dataOut,
			clka => clk,
			clkb => clk,
			addra => delay3.addr,
			addrb => delay3.addr
		);

		memory_4: blk_mem_gen_delay4
		port map (
			dina => delay4.dataIn,
			wea => writeEnable,
			doutb => delay4.dataOut,
			clka => clk,
			clkb => clk,
			addra => delay4.addr,
			addrb => delay4.addr
		);
		
		writeEnable <= r.writeEnable;
		delay_outputs(0) <= r.delayedOutput1;
		delay_outputs(1) <= r.delayedOutput2;
		delay_outputs(2) <= r.delayedOutput3;
		delay_outputs(3) <= r.delayedOutput4;
		delay1.addr <= std_logic_vector(r.address1);
		delay2.addr <= std_logic_vector(r.address2);
		delay3.addr <= std_logic_vector(r.address3);
		delay4.addr <= std_logic_vector(r.address4);
		
	clk_proc : process( clk, reset )
	begin
		if(reset = '1') then
			r.state <= readStart;
			r.address1 <= (others => '0');
			r.address2 <= (others => '0');
			r.address3 <= (others => '0');
			r.address4 <= (others => '0');
			r.writeEnable <= '0';
			r.delayedOutput1 <= (others => '0');
			r.delayedOutput2 <= (others => '0');
			r.delayedOutput3 <= (others => '0');
			r.delayedOutput4 <= (others => '0');
		elsif(rising_edge(clk)) then
			r <= rin;
		end if;
	end process ; -- clk_proc
	
	comb_proc : process( r, rin, delay1.dataOut, delay2.dataOut, delay3.dataOut, delay4.dataOut)
		variable v : reg_type;
	begin
		v := r;

		v.writeEnable := '0';

		case r.state is
			when readStart =>

				v.state := readWait;
				v.waitCounter := 0;

			when readWait =>
				-- Wait some cycles before reading

				if(r.waitCounter >= waitTime) then
					v.state := read;
				else
					v.waitCounter := r.waitCounter + 1;
				end if;

			when read =>
				v.state := writeDone;

				-- Write the new value
				v.writeEnable := '1';

				-- Result is ready, read it.
				v.delayedOutput1 := delay1.dataOut;
				v.delayedOutput2 := delay2.dataOut;
				v.delayedOutput3 := delay3.dataOut;
				v.delayedOutput4 := delay4.dataOut;

			when writeDone =>
				v.state := readStart;

				if(r.address1 = addrMax1-1) then
					v.address1 := (others => '0');
				else
					v.address1 := v.address1 + 1;
				end if;
				if(r.address2 = addrMax2-1) then
					v.address2 := (others => '0');
				else
					v.address2 := v.address2 + 1;
				end if;
				if(r.address3 = addrMax3-1) then
					v.address3 := (others => '0');
				else
					v.address3 := v.address3 + 1;
				end if;
				if(r.address4 = addrMax4-1) then
					v.address4 := (others => '0');
				else
					v.address4 := v.address4 + 1;
				end if;

			when others =>
			-- Don't care
		end case;

		rin <= v;
	end process ; -- comb_proc
end architecture ; -- arch