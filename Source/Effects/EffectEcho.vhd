library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

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
	constant delayDuration : natural := 2;
	constant decayGain : std_logic_vector(wordLength-1 downto 0) := (others => '0');
	constant directGain : std_logic_vector(wordLength-1 downto 0) := (others => '0');
	constant echoGain : std_logic_vector(wordLength-1 downto 0) := (others => '0');

	-- 2 second max delay
	constant addressWidth : natural := 17;
	constant addressMax : natural := 88200;

	signal feedback : std_logic_vector(wordLength-1 downto 0);
	signal direct : std_logic_vector(wordLength-1 downto 0);
	signal delayedGained : std_logic_vector(wordLength-1 downto 0);
	signal delayed : std_logic_vector(wordLength-1 downto 0);
	signal feedbackDirectSum : std_logic_vector(wordLength-1 downto 0);

	signal writeBus : std_logic_vector(wordLength-1 downto 0);
	signal readBus : std_logic_vector(wordLength-1 downto 0);
	signal writeEnable : std_logic;
	signal readEnable : std_logic;
	signal memoryAddress : std_logic_vector(addressWidth-1 downto 0);

	type state_type is (read1, read2, write);

	type reg_type is record
		state : state_type;
		address : unsigned(addressWidth-1 downto 0);
		writeEnable : std_logic;
		readEnable : std_logic;
		delayOutput : std_logic_vector(wordLength-1 downto 0);
	end record;

	signal r, rin : reg_type;
begin

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
		a => direct,
		b => delayedGained,

		s => feedbackDirectSum
	);

	writeBus <= feedbackDirectSum;
	writeEnable <= r.writeEnable;
	readEnable <= r.readEnable;

	memoryAddress <= std_logic_vector(r.address);

--	memory: entity work.CoreBlockRAM
--	port map (
--		dina => writeBus,
--		wea => writeEnable,
--		doutb => readBus,
--		enb => readEnable,
--		clka => clk,
--		clkb => clk,
--		addra => memoryAddress,
--		addrb => memoryAddress
--	)
	
	clk_proc : process( clk, reset )
	begin
		if(reset = '1') then
			r.state <= write;
			r.address <= (others => '0');
			r.writeEnable <= '0';
			r.readEnable <= '0';
		elsif(rising_edge(clk)) then
			r <= rin;
		end if;
	end process ; -- clk_proc
	
	comb_proc : process( r, rin )
		variable v : reg_type;
	begin
		v := r;

		v.readEnable := '0';
		v.writeEnable := '0';

		case r.state is
			when read1 =>
				v.state := read2;

				-- Wait one cycle before reading

			when read2 =>
				v.state := write;

				-- Result is ready, read it.
				v.delayOutput := readBus;

				-- Write the new value
				v.writeEnable := '1';

			when write =>
				v.state := read1;
				
				if(r.address = addressMax-1) then
					v.address := (others => '0');
				else
					v.address := v.address + 1;
				end if;

				v.readEnable := '1';

			when others =>
			-- Don't care
		end case;

		rin <= v;
	end process ; -- comb_proc
end architecture ; -- arch