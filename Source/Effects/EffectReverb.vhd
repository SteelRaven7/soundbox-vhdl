library ieee ;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use work.memory_pkg.all;


entity EffectReverb is
	generic(IO_length : integer := 16;
			c_length : integer := 16;
			addr_length : integer := 12); --Maximum delay is 0 to 4095 samples for all stages.
	port(input : in std_logic_vector(IO_length-1 downto 0);
			output : out std_logic_vector(IO_length-1 downto 0);
			configBus : configurableRegisterBus;
			CLK : in std_logic;
			RESET : in std_logic);
end EffectReverb;

architecture behav of EffectReverb is
	
	type signal_array is array(3 downto 0) of std_logic_vector(c_length-1 downto 0);
	type gain_array is array(3 downto 0) of signed(IO_length+c_length-1 downto 0);
	type gain_array2 is array(3 downto 0) of signed(IO_length+c_length+3 downto 0);
	type pad_array is array(3 downto 0) of std_logic_vector(2+c_length-1 downto 0);
	
	constant coeff_pos : std_logic_vector(c_length-1 downto 0) := x"7F5B";
	constant coeff_neg : std_logic_vector(c_length-1 downto 0) := x"80A5";

	constant wet_coeff : std_logic_vector(c_length-1 downto 0) := x"2000";
	constant dry_coeff : std_logic_vector(c_length-1 downto 0) := x"2ccd";
	
	signal addrMax1 : integer range 0 to 4095;
	signal delay1par : std_logic_vector(11 downto 0);
	signal addrMax2 : integer range 0 to 4095;
	signal delay2par : std_logic_vector(11 downto 0);
	signal addrMax3 : integer range 0 to 4095;
	signal delay3par : std_logic_vector(11 downto 0);
	signal addrMax4 : integer range 0 to 4095;
	signal delay4par : std_logic_vector(11 downto 0);

	signal gain_outputs : gain_array;
	signal scalar : gain_array;
	signal matrix_outputs : signal_array;
	
	signal dry_gain : std_logic_vector(c_length-1 downto 0);
	
	signal wet_padded_sig : pad_array;
	signal wet_padded_coe : std_logic_vector(2+IO_length-1 downto 0);
	signal dry_padded_sig : std_logic_vector(2+IO_length-1 downto 0);
	signal dry_padded_coe : std_logic_vector(2+IO_length-1 downto 0);
	
	signal delay_outputs : signal_array;
	signal wet_gain : gain_array2;
	signal wet_sum : signal_array;
	signal wet_gain2 : signal_array;
	signal wet_2_out : std_logic_vector(2*IO_length-1 downto 0);
	signal input_sum : signal_array;

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
	
	--constant addrMax1 : natural := 313;
	--constant addrMax2 : natural := 449;
	--constant addrMax3 : natural := 677;
	--constant addrMax4 : natural := 829;

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
	
	function addsat (a,b : std_logic_vector) return std_logic_vector is
		constant MAX : std_logic_vector(a'length-1 downto 0) := '0' & (a'length-2 downto 0 => '1');
		constant MIN : std_logic_vector(a'length-1 downto 0) := '1' & (a'length-2 downto 0 => '0');
		variable sum : std_logic_vector(a'length-1 downto 0);
		variable overflow : std_logic;
		variable s_a : std_logic;
		variable s_b : std_logic;
		variable s_s : std_logic;
		begin
			sum := std_logic_vector(signed(a) + signed(b));

			s_a := a(a'length-1);
			s_b := b(b'length-1);
			s_s := sum(a'length-1);

	-- Signs of a and b are the same, but not equal to sign of s means overflow.
			overflow := ((s_a and s_b) and not(s_s)) or ((not(s_a) and not(s_b)) and s_s);
			
			if overflow = '0' then
				return sum;
			elsif s_a = '0' then
				return MAX;
			elsif s_a = '1' then
				return MIN;
			else
				return (a'length-1 downto 0 => '0');
			end if;
			
	end addsat;
	
	begin
		
	delay1Reg: entity work.ConfigRegister
	generic map(
		wordLength => 12,
		address => std_logic_vector(to_unsigned(7,16))
	)
	port map(
		input => configBus,
		output => delay1par,

		reset => reset
	);
	
	delay2Reg: entity work.ConfigRegister
	generic map(
		wordLength => 12,
		address => std_logic_vector(to_unsigned(8,16))
	)
	port map(
		input => configBus,
		output => delay2par,

		reset => reset
	);
	
	delay3Reg: entity work.ConfigRegister
	generic map(
		wordLength => 12,
		address => std_logic_vector(to_unsigned(9,16))
	)
	port map(
		input => configBus,
		output => delay3par,

		reset => reset
	);
	
	delay4Reg: entity work.ConfigRegister
	generic map(
		wordLength => 12,
		address => std_logic_vector(to_unsigned(10,16))
	)
	port map(
		input => configBus,
		output => delay4par,

		reset => reset
	);
	
		addrMax1 <= to_integer(unsigned(delay1par));
		addrMax2 <= to_integer(unsigned(delay2par));
		addrMax3 <= to_integer(unsigned(delay3par));
		addrMax4 <= to_integer(unsigned(delay4par));
		
		wet_padded_sig(0) <= "00" & delay_outputs(0) when delay_outputs(0)(IO_length-1) = '0' else
							"11" & delay_outputs(0);
		wet_padded_sig(1) <= "00" & delay_outputs(1) when delay_outputs(1)(IO_length-1) = '0' else
							"11" & delay_outputs(1);
		wet_padded_sig(2) <= "00" & delay_outputs(2) when delay_outputs(2)(IO_length-1) = '0' else
							"11" & delay_outputs(2);
		wet_padded_sig(3) <= "00" & delay_outputs(3) when delay_outputs(3)(IO_length-1) = '0' else
							"11" & delay_outputs(3);
							
		wet_padded_coe <= wet_coeff & "00";
		dry_padded_coe <= dry_coeff & "00";
		dry_padded_sig <= "00" & input when input(IO_length-1) = '0' else
						"11" & input;
		
		--Each delayed signal times it's feedback coefficient, vector*vector transpose
		gain_outputs(0) <= signed(delay_outputs(0))*signed(coeff_pos);
		gain_outputs(1) <= signed(delay_outputs(1))*signed(coeff_pos);
		gain_outputs(2) <= signed(delay_outputs(2))*signed(coeff_pos);
		gain_outputs(3) <= signed(delay_outputs(3))*signed(coeff_neg);
		
		--summation of the input and the mixed feedback signals
		delay1.dataIn <= input_sum(0);
		delay2.dataIn <= input_sum(1);
		delay3.dataIn <= input_sum(2);
		delay4.dataIn <= input_sum(3);
		
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
		wet_gain(0) <= signed(wet_padded_sig(0))*signed(wet_padded_coe);
		wet_gain(1) <= signed(wet_padded_sig(1))*signed(wet_padded_coe);
		wet_gain(2) <= signed(wet_padded_sig(2))*signed(wet_padded_coe);
		wet_gain(3) <= signed(wet_padded_sig(3))*signed(wet_padded_coe);
		
		wet_gain2(0) <= std_logic_vector(wet_gain(0)(2*IO_length-1 downto IO_length));
		wet_gain2(1) <= std_logic_vector(wet_gain(1)(2*IO_length-1 downto IO_length));
		wet_gain2(2) <= std_logic_vector(wet_gain(2)(2*IO_length-1 downto IO_length));
		wet_gain2(3) <= std_logic_vector(wet_gain(3)(2*IO_length-1 downto IO_length));
		
		dry_gain <= input;
					
		wet_sum(0) <= addsat(wet_gain2(0),dry_gain);
		wet_sum(1) <= addsat(wet_gain2(1),wet_sum(0));
		wet_sum(2) <= addsat(wet_gain2(2),wet_sum(1));
		wet_sum(3) <= addsat(wet_gain2(3),wet_sum(2));
		
		output <= wet_sum(3);
		
		input_sum(0) <= addsat(input,matrix_outputs(0));
		input_sum(1) <= addsat(input,matrix_outputs(1));
		input_sum(2) <= addsat(input,matrix_outputs(2));
		input_sum(3) <= addsat(input,matrix_outputs(3));
		
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