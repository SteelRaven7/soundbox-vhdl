-- MemoryInterface
--
-- An interface to the flash memory on the Nexys-4 board (Spansion S25FL128S).
-- Wraps an SPI module with data, address and write/read signals. Also maps an
-- address space to an empty part of the memory through an address mask.

library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;
	use ieee.math_real.all;

library UNISIM;
	use UNISIM.VCOMPONENTS.all;

entity MemoryInterface is
	generic (
		dataWidth : natural := 16;
		addressWidth : natural := 23
	);
	port (
		dataRead : in std_logic;
		dataWrite : in std_logic;
		dataClear : in std_logic;
		pollStatusRegisters : in std_logic;
		dataOut : out std_logic_vector(dataWidth-1 downto 0);
		dataIn : in std_logic_vector(dataWidth-1 downto 0);
		address : in std_logic_vector(addressWidth-1 downto 0);

		done : out std_logic;
		outputReady : out std_logic;

		-- Serial flash ports
		CS : out std_logic;
		SI : out std_logic;
		SO : in std_logic;

		clk : in std_logic;
		reset : in std_logic
	);
end entity ; -- MemoryInterface

architecture arch of MemoryInterface is
	function padMSB(vector : std_logic_vector; targetWidth : natural) return std_logic_vector is
		variable rv : std_logic_vector(targetWidth-1 downto 0);
	begin
		rv := (others => '0');
		rv(vector'length-1 downto 0) := vector;

		return rv;
	end padMSB;

	constant flashAddressWidth : natural := 32;

	-- Offset the address to prevent overwriting FPGA configuration data.
	-- Using 2 byte words yields an effective address space from 0x00000 to 0xFFFFF.
	constant addressMask : std_logic_vector(flashAddressWidth-1 downto 0) := x"01000000";

	constant maxInputWidth : natural := 8+dataWidth+flashAddressWidth;
	constant maxOutputWidth : natural := dataWidth;

	constant inputNumberWidth : natural := natural(ceil(log2(real(maxInputWidth))));
	constant outputNumberWidth : natural := natural(ceil(log2(real(maxOutputWidth))));

	-- Flash instructions
	constant instructionWriteEnable : std_logic_vector(7 downto 0) := x"06";
	constant instructionRead : std_logic_vector(7 downto 0) := x"13";
	constant instructionWrite : std_logic_vector(7 downto 0) := x"12";
	constant instructionReadStatus1 : std_logic_vector(7 downto 0) := x"05";
	constant instructionID : std_logic_vector(7 downto 0) := x"90";
	constant instructionClearAll : std_logic_vector(7 downto 0) := x"C7";
	constant instructionClearSector : std_logic_vector(7 downto 0) := x"DC";
	
	-- MSB constants for different instruction types
	constant instruction8MSB : std_logic_vector(inputNumberWidth-1 downto 0) := std_logic_vector(to_unsigned(7, inputNumberWidth));
	constant instruction32MSB : std_logic_vector(inputNumberWidth-1 downto 0) := std_logic_vector(to_unsigned(31, inputNumberWidth));
	constant instruction40MSB : std_logic_vector(inputNumberWidth-1 downto 0) := std_logic_vector(to_unsigned(39, inputNumberWidth));
	constant instruction56MSB : std_logic_vector(inputNumberWidth-1 downto 0) := std_logic_vector(to_unsigned(55, inputNumberWidth));
	constant instructionOut8MSB : std_logic_vector(outputNumberWidth-1 downto 0) := std_logic_vector(to_unsigned(7, outputNumberWidth));
	constant instructionOut16MSB : std_logic_vector(outputNumberWidth-1 downto 0) := std_logic_vector(to_unsigned(15, outputNumberWidth));

	-- Provides the selected address in the flash address space.
	signal flashAddress : std_logic_vector(31 downto 0);

	signal waitStart : std_logic;
	signal waitDone : std_logic;

	-- SPI signals
	signal spi_input : std_logic_vector(maxInputWidth-1 downto 0);
	signal spi_inputMSB : std_logic_vector(inputNumberWidth-1 downto 0);
	signal spi_writeEnable : std_logic;
	signal spi_outputMSB : std_logic_vector(outputNumberWidth-1 downto 0);
	signal spi_done : std_logic;
	signal SCLK : std_logic;

	type state_type is (
		res,
		config,
		enableWrite,
		initialClear,
		clear,
		flagDone,
		ready,
		write,
		dummyRead,
		waitRead,
		waitRead2,
		read,
		busy,
		busy2
	);

	type reg_type is record
		state : state_type;
		doneReturnState : state_type;
		input : std_logic_vector(maxInputWidth-1 downto 0);
		outputMSB : std_logic_vector(outputNumberWidth-1 downto 0);
		inputMSB : std_logic_vector(inputNumberWidth-1 downto 0);
		waitStart : std_logic;
		writeEnable : std_logic;
		done : std_logic;
	end record;

	signal r, rin : reg_type;

begin
	-- Map to flash address space.
	--flashAddress <= addressMask or (x"00" & (address & '0'));
	flashAddress <= (others => '0');

	-- Propagate the SPI done flag.
	done <= r.done;

	spi: entity work.SPI
	generic map (
		maxInputWidth => maxInputWidth,
		maxOutputWidth => maxOutputWidth
	)
	port map (
		input => spi_input,
		inputMSB => spi_inputMSB,
		writeEnable => spi_writeEnable,
		output => dataOut,
		outputMSB => spi_outputMSB,
		outputReady => outputReady,
		done => spi_done,
		serialInput => SI,
		serialOutput => SO,
		cs => CS,
		sclk => SCLK,
		serialClk => clk,
		reset => reset
	);

	delay : entity work.Delay
	generic map (
		--counter => 100000000 -- 1 sec on 10MHz
		counter => 10000
	)
	port map (
		input => waitStart,
		output => waitDone,

		clk => clk,
		reset => reset
	);

	waitStart <= r.waitStart;
	spi_input <= r.input;
	spi_inputMSB <= r.inputMSB;
	spi_writeEnable <= r.writeEnable;
	spi_outputMSB <= r.outputMSB;

	clk_proc : process(reset, clk)
	begin
		if(reset = '1') then
			r.state <= res;
			r.done <= '0';
			r.writeEnable <= '0';
			r.waitStart <= '0';
		elsif(rising_edge(clk)) then
			r <= rin;
		end if;
	end process ; -- clk_proc

	comb_proc : process(r, rin, spi_done, dataIn, dataWrite, dataRead, dataClear, pollStatusRegisters, flashAddress, waitDone)
		variable v : reg_type;
	begin
		v := r;

		case r.state is
			when res => 
				-- Wait for the SPI to be done, then write configuration.
				v.writeEnable := '0';

				if(spi_done = '1') then
					v.state := config;
				end if;

			when config =>
				
				-- No need to setup configuration, so pulse the done flag.
				v.state := flagDone;

			when enableWrite =>
				-- Send write enable instruction

				-- Instruction contains 8 bit input, 0 bit output
				v.inputMSB := instruction8MSB;
				v.outputMSB := (others => '0');

				v.input := padMSB(instructionWriteEnable, maxInputWidth);

				v.writeEnable := '1';
				v.state := busy;

			when clear =>

				-- Clear the addressed sector
				v.inputMSB := instruction40MSB;
				v.outputMSB := (others => '0');

				v.input := padMSB(instructionClearSector&flashAddress, maxInputWidth);

				v.writeEnable := '1';
				v.state := busy;
				v.doneReturnState := flagDone;

			when flagDone =>
				v.done := '1';
				v.state := ready;

			when ready =>

				v.writeEnable := '0';
				v.done := '0';

				if(dataClear = '1') then

					v.state := enableWrite;
					v.doneReturnState := clear;

				elsif(dataWrite = '1') then
					
					-- We need to set the write enable latch before writing.
					v.state := enableWrite;
					v.doneReturnState := write;

				elsif(dataRead = '1') then

					-- Read ID
					--v.inputMSB := instruction32MSB;
					--v.outputMSB := instructionOut16MSB;
					--v.input := padMSB(instructionID&x"000000", maxInputWidth);

					v.state := dummyRead;
				
				elsif(pollStatusRegisters = '1') then
					-- Read status registers
					v.inputMSB := instruction8MSB;
					v.outputMSB := instructionOut8MSB;
					v.input := padMSB(instructionReadStatus1, maxInputWidth);

					v.writeEnable := '1';
					v.state := busy;
					v.doneReturnState := flagDone;
				end if;

			when write =>
				-- Instruction contains 56 bit input, 0 bit output
				v.inputMSB := instruction56MSB;
				v.outputMSB := (others => '0');

				v.input := padMSB(instructionWrite&flashAddress&dataIn, maxInputWidth);

				v.writeEnable := '1';
				v.state := busy;
				v.doneReturnState := flagDone;

			when dummyRead =>

				-- For some reason, the first read only outputs the first byte, so do a dummy read.

				-- Instruction contains 40 bit input, 16 bit output
				v.outputMSB := instructionOut16MSB;
				v.inputMSB := instruction40MSB;
				v.input := padMSB(instructionRead&flashAddress, maxInputWidth);

				v.writeEnable := '1';
				v.state := busy;
				v.doneReturnState := waitRead;

			when waitRead =>

				-- Wait a bit cause dat flash is a tad slow.
				v.waitStart := '1';
				v.state := waitRead2;

			when waitRead2 =>

				v.waitStart := '0';

				if(waitDone = '1') then
					v.state := read;
				end if;

			when read =>
				-- Instruction contains 40 bit input, 16 bit output
				v.outputMSB := instructionOut16MSB;
				v.inputMSB := instruction40MSB;
				v.input := padMSB(instructionRead&flashAddress, maxInputWidth);

				v.writeEnable := '1';
				v.state := busy;
				v.doneReturnState := flagDone;

			when busy =>

				v.writeEnable := '0';

				if(spi_done = '1') then
					v.state := busy2;
				end if;

			when busy2 =>
				if(spi_done = '1') then
					v.state := r.doneReturnState;
				end if;

			when others =>

				-- Don't care.

		end case;

		rin <= v;
	end process ; -- comb_proc


	-- Magically connect the SCLK to the flash through the STARTUPE2 block.

	-- STARTUPE2: STARTUP Block
	STARTUPE2_inst : STARTUPE2
	generic map (
		PROG_USR => "FALSE", -- Activate program event security feature. Requires encrypted bitstreams.
		SIM_CCLK_FREQ => 5.0 -- Set the Configuration Clock Frequency(ns) for simulation.
	)
	port map (
		--CFGCLK => CFGCLK, -- 1-bit output: Configuration main clock output
		--CFGMCLK => CFGMCLK, -- 1-bit output: Configuration internal oscillator clock output
		--EOS => EOS, -- 1-bit output: Active high output signal indicating the End Of Startup.
		--PREQ => PREQ, -- 1-bit output: PROGRAM request to fabric output
		CLK => '1', -- 1-bit input: User start-up clock input
		GSR => '0', -- 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
		GTS => '0', -- 1-bit input: Global 3-state input (GTS cannot be used for the port name)
		KEYCLEARB => '0', -- 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
		PACK => '0', -- 1-bit input: PROGRAM acknowledge input
		USRCCLKO => SCLK, -- 1-bit input: User CCLK input
		USRCCLKTS => '0', -- 1-bit input: User CCLK 3-state enable input
		USRDONEO => '1', -- 1-bit input: User DONE pin output control
		USRDONETS => '0' -- 1-bit input: User DONE 3-state enable output
	);
	-- End of STARTUPE2_inst instantiation


end architecture ; -- arch