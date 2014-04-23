library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;
	use ieee.math_real.all;

entity SPI is
	generic (
		maxInputWidth : natural := 32;
		maxOutputWidth : natural := 16
	);
	port (
		input : in std_logic_vector(maxInputWidth-1 downto 0);
		inputMSB : in std_logic_vector(natural(ceil(log2(real(maxInputWidth))))-1 downto 0);
		writeEnable : in std_logic;

		output : out std_logic_vector(maxOutputWidth-1 downto 0);
		outputMSB : in std_logic_vector(natural(ceil(log2(real(maxOutputWidth))))-1 downto 0);
		outputReady : out std_logic;

		serialInput : out std_logic;
		serialOutput : in std_logic;

		done : out std_logic;

		cs : out std_logic;
		sclk : out std_logic;

		serialClk : in std_logic;
		reset : in std_logic
	);
end entity ; -- SPI

architecture arch of SPI is

	constant inputMax : natural := natural(ceil(log2(real(maxInputWidth))))-1;
	constant outputMax : natural := natural(ceil(log2(real(maxOutputWidth))))-1;

	type state_type is (ready, write, sleep, read);

	type reg_type is record
		state : state_type;
		inputData : std_logic_vector(maxInputWidth-1 downto 0);
		outputData : std_logic_vector(maxOutputWidth-1 downto 0);
		outputReady : std_logic;
		done : std_logic;

		inputIndex : natural range 0 to inputMax;
		outputIndex : natural range 0 to outputMax;

		serialInput : std_logic;

		cs : std_logic;
	end record;

	signal r, rin : reg_type;
	signal regSerialOutput : std_logic;
	signal sharedClk : std_logic;
begin

	sharedClk <= r.cs or not(serialClk);
	sclk <= sharedClk;

	cs <= r.cs;
	serialInput <= r.serialInput;
	output <= r.outputData;
	outputReady <= r.outputReady;
	done <= r.done;

	-- Poll the serialOutput of the slave when the synchronized sclk is high.
	serialReg : entity work.VectorRegister
	generic map (
		wordLength => 1
	)
	port map (
		input(0) => serialOutput,
		output(0) => regSerialOutput,

		clk => sharedClk,
		reset => reset
	);

	clk_proc : process(serialClk, reset)
	begin
		if(reset = '1') then
			r.state <= ready;
			r.cs <= '1';
			r.serialInput <= '0';
			r.outputData <= (others => '0');
			r.outputReady <= '0';
			r.done <= '0';
		elsif(rising_edge(serialClk)) then
			r <= rin;
		end if;
	end process ; -- clk_proc

	comb_proc : process(r, rin, input, inputMSB, writeEnable, outputMSB, regSerialOutput)
		variable v : reg_type;
	begin
		v := r;

		case r.state is
			when ready =>

				v.cs := '1';
				v.outputReady := '0';
				v.done := '1';

				if(writeEnable = '1') then
					v.inputData := input;
					v.inputIndex := to_integer(unsigned(inputMSB));
					v.outputIndex := to_integer(unsigned(outputMSB));

					v.done := '0';
					v.state := write;
				end if;

			when write =>

				v.cs := '0';

				v.serialInput := r.inputData(r.inputIndex);

				if(r.inputIndex = 0) then
					if(r.outputIndex = 0) then
						v.state := ready;
					else
						v.state := sleep;
					end if;
				else
					v.inputIndex := r.inputIndex-1;
				end if;

			when sleep =>
				v.state := read;

			when read =>

				v.outputData(r.outputIndex) := regSerialOutput;

				if(r.outputIndex = 0) then
					v.outputReady := '1';
					v.state := ready;
				else
					v.outputIndex := r.outputIndex-1;
				end if;

			when others =>

				-- Don't care

		end case;

		rin <= v;
	end process ; -- comb_proc

end architecture ; -- arch