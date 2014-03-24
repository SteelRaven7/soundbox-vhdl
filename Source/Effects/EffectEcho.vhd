library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;
	use work.fixed_pkg.all;

entity EffectEcho is
	generic (
		wordLength : natural := 16;
		constantsWordLength : natural := 16
	);
	port (
		input : in std_logic_vector(wordLength-1 downto 0);
		output : out std_logic_vector(wordLength-1 downto 0);

		clk : in std_logic;
		reset : in std_logic
	);
end entity ; -- EffectEcho

architecture arch of EffectEcho is
	COMPONENT blk_mem_gen_0
	PORT (
		clka : IN STD_LOGIC;
		wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
		addra : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
		dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		clkb : IN STD_LOGIC;
		addrb : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
		doutb : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
	END COMPONENT;

	constant delayDuration : natural := 2;
	constant decayGain : std_logic_vector(wordLength-1 downto 0) := real_to_fixed(-0.5, constantsWordLength);
	constant directGain : std_logic_vector(wordLength-1 downto 0) := real_to_fixed(0.8, constantsWordLength);
	constant echoGain : std_logic_vector(wordLength-1 downto 0) := real_to_fixed(0.5, constantsWordLength);

	-- 2 second max delay
	constant addressWidth : natural := 17;
	constant addressMax : natural := 44100;

	signal feedback : std_logic_vector(wordLength-1 downto 0);
	signal directGained : std_logic_vector(wordLength-1 downto 0);
	signal delayedGained : std_logic_vector(wordLength-1 downto 0);
	signal delayed : std_logic_vector(wordLength-1 downto 0);
	signal feedbackDirectSum : std_logic_vector(wordLength-1 downto 0);

	signal writeBus : std_logic_vector(wordLength-1 downto 0);
	signal readBus : std_logic_vector(wordLength-1 downto 0);
	signal writeEnable : std_logic_vector(0 downto 0);
	signal memoryAddress : std_logic_vector(addressWidth-1 downto 0);

	type state_type is (readStart, readWait, read, writeDone);

	constant waitTime : natural := 4;

	type reg_type is record
		state : state_type;
		waitCounter : natural range 0 to waitTime;
		address : unsigned(addressWidth-1 downto 0);
		writeEnable : std_logic;
		delayedOutput : std_logic_vector(wordLength-1 downto 0);
	end record;

	signal r, rin : reg_type;
begin

	-- Summation
	feedbackSum : entity work.AdderSat
	generic map (
		wordLength => wordLength
	)
	port map (
		a => input,
		b => feedback,

		s => feedbackDirectSum
	);

	outputSum : entity work.AdderSat
	generic map (
		wordLength => wordLength
	)
	port map (
		a => directGained,
		b => delayedGained,

		s => output
	);


	-- Gains
	directMult : entity work.Multiplier
	generic map (
		X_WIDTH    => wordLength,
		X_FRACTION => wordLength-1,
		Y_WIDTH    => constantsWordLength,
		Y_FRACTION => constantsWordLength-1,
		S_WIDTH    => wordLength,
		S_FRACTION => wordLength-1
	)
	port map (
		x => input,
		y => directGain,

		s => directGained
	);

	feedbackMult : entity work.Multiplier
	generic map (
		X_WIDTH    => wordLength,
		X_FRACTION => wordLength-1,
		Y_WIDTH    => constantsWordLength,
		Y_FRACTION => constantsWordLength-1,
		S_WIDTH    => wordLength,
		S_FRACTION => wordLength-1
	)
	port map (
		x => delayed,
		y => decayGain,

		s => feedback
	);

	echoMult : entity work.Multiplier
	generic map (
		X_WIDTH    => wordLength,
		X_FRACTION => wordLength-1,
		Y_WIDTH    => constantsWordLength,
		Y_FRACTION => constantsWordLength-1,
		S_WIDTH    => wordLength,
		S_FRACTION => wordLength-1
	)
	port map (
		x => delayed,
		y => echoGain,

		s => delayedGained
	);


	-- Delay
	writeBus <= feedbackDirectSum;
	writeEnable <= (others => r.writeEnable);
	delayed <= r.delayedOutput;

	memoryAddress <= std_logic_vector(r.address);

	memory: blk_mem_gen_0
	port map (
		dina => writeBus,
		wea => writeEnable,
		doutb => readBus,
		clka => clk,
		clkb => clk,
		addra => memoryAddress,
		addrb => memoryAddress
	);
	
	clk_proc : process( clk, reset )
	begin
		if(reset = '1') then
			r.state <= readStart;
			r.address <= (others => '0');
			r.writeEnable <= '0';
			r.delayedOutput <= (others => '0');
		elsif(rising_edge(clk)) then
			r <= rin;
		end if;
	end process ; -- clk_proc
	
	comb_proc : process( r, rin, readBus)
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
				v.delayedOutput := readBus;

			when writeDone =>
				v.state := readStart;

				if(r.address = addressMax-1) then
					v.address := (others => '0');
				else
					v.address := v.address + 1;
				end if;

			when others =>
			-- Don't care
		end case;

		rin <= v;
	end process ; -- comb_proc
end architecture ; -- arch