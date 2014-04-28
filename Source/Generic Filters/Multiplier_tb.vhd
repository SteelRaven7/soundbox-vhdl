library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

entity Multiplier_tb is
end Multiplier_tb;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

architecture Behaviour of Multiplier_tb is

component Multiplier is
   generic (X_WIDTH    : integer;
            X_FRACTION : integer;
            Y_WIDTH    : integer;
            Y_FRACTION : integer;
            S_WIDTH    : integer;
            S_FRACTION : integer);
   port(x : in  std_logic_vector;
        y : in  std_logic_vector;
        s : out std_logic_vector);
end component;

constant NO_OF_SAMPLES : integer := 10;
constant X_1_WIDTH     : integer := 16;
constant X_1_FRACTION  : integer := 14;
constant Y_1_WIDTH     : integer := 16;
constant Y_1_FRACTION  : integer := 14;
constant S_1_WIDTH     : integer := 16;
constant S_1_FRACTION  : integer := 13;
constant X_2_WIDTH     : integer := 14;
constant X_2_FRACTION  : integer := 10;
constant Y_2_WIDTH     : integer := 8;
constant Y_2_FRACTION  : integer := 6;
constant S_2_WIDTH     : integer := 10;
constant S_2_FRACTION  : integer := 6;

type x_1_array is array(0 to NO_OF_SAMPLES-1) of std_logic_vector(X_1_WIDTH-1 downto 0);
type y_1_array is array(0 to NO_OF_SAMPLES-1) of std_logic_vector(Y_1_WIDTH-1 downto 0);
type s_1_array is array(0 to NO_OF_SAMPLES-1) of std_logic_vector(S_1_WIDTH-1 downto 0);
type x_2_array is array(0 to NO_OF_SAMPLES-1) of std_logic_vector(X_2_WIDTH-1 downto 0);
type y_2_array is array(0 to NO_OF_SAMPLES-1) of std_logic_vector(Y_2_WIDTH-1 downto 0);
type s_2_array is array(0 to NO_OF_SAMPLES-1) of std_logic_vector(S_2_WIDTH-1 downto 0);

signal x_1 : x_1_array := ("1111100001010010",
                           "0001001001011001",
                           "0101011101011110",
                           "0011011100001000",
                           "0101011001110111",
                           "1111100011010000",
                           "0110100111011001",
                           "0111111011100010",
                           "0011100001010111",
                           "1000111111101101");
signal y_1 : y_1_array := ("0100000000000000",
                           "0100000000000000",
                           "0100000000000000",
                           "0100000000000000",
                           "0100000000000000",
                           "0100000000000000", 
						   "0100000000000000", 
						   "0100000000000000", 
                           "0100000000000000", 
						   "0100000000000000");
signal s_1 : s_1_array := ("1111110000101001",
                           "0000100100101100",
                           "0010101110101111",
                           "0001101110000100",
                           "0010101100111011",
                           "1111110001101000",
                           "0011010011101100",
                           "0011111101110001",
                           "0001110000101011",
                           "1100011111110110");
signal x_2 : x_2_array := ("01010111100101", 
                           "10000001101101", 
						   "00010100011110", 
						   "01101101011010", 
                           "11011111110111", 
						   "01011101111111", 
						   "00101101011011", 
						   "00100100110000", 
                           "11011010111001", 
						   "01010000000101");
signal y_2 : y_2_array := ("01000000", 
                           "01000000", 
						   "01000000", 
						   "01000000", 
						   "01000000", 
						   "01000000", 
						   "01000000", 
						   "01000000", 
                           "01000000", 
						   "01000000");
signal s_2 : s_2_array := ("0101011110", 
                           "1000000110", 
						   "0001010001", 
						   "0110110101", 
                           "1101111111", 
						   "0101110111", 
						   "0010110101", 
						   "0010010011", 
                           "1101101011", 
						   "0101000000");

signal s1 : std_logic_vector(S_1_WIDTH-1 downto 0);
signal s2 : std_logic_vector(S_2_WIDTH-1 downto 0);
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

begin

  -- End process
  ending : process
  begin
    wait for 1050 ns;
	assert false
	report "Simulation Done!"
	severity failure;
  end process;

  -- Test process
  test : process
  begin
    wait for 100 ns;
	
	assert (s1 = s_1(0)) 
    report "Error: Multiplier 1 output wrong!"
    severity Error;
	
	assert (s2 = s_2(0))
    report "Error: Multiplier 2 output wrong!"
    severity Error;
	
	x_1(0 to NO_OF_SAMPLES-2) <= x_1(1 to NO_OF_SAMPLES-1);
	y_1(0 to NO_OF_SAMPLES-2) <= y_1(1 to NO_OF_SAMPLES-1);
	s_1(0 to NO_OF_SAMPLES-2) <= s_1(1 to NO_OF_SAMPLES-1);
	x_2(0 to NO_OF_SAMPLES-2) <= x_2(1 to NO_OF_SAMPLES-1);
	y_2(0 to NO_OF_SAMPLES-2) <= y_2(1 to NO_OF_SAMPLES-1);
	s_2(0 to NO_OF_SAMPLES-2) <= s_2(1 to NO_OF_SAMPLES-1);
  end process;

  Multiplier_1 : Multiplier
  generic map(X_WIDTH    => X_1_WIDTH,
              X_FRACTION => X_1_FRACTION,
              Y_WIDTH    => Y_1_WIDTH,
              Y_FRACTION => Y_1_FRACTION,
              S_WIDTH    => S_1_WIDTH,
              S_FRACTION => S_1_FRACTION)
    port map(x => x_1(0),
             y => y_1(0),
             s => s1);

  Multiplier_2 : Multiplier
  generic map(X_WIDTH    => X_2_WIDTH,
              X_FRACTION => X_2_FRACTION,
              Y_WIDTH    => Y_2_WIDTH,
              Y_FRACTION => Y_2_FRACTION,
              S_WIDTH    => S_2_WIDTH,
              S_FRACTION => S_2_FRACTION)
    port map(x => x_2(0),
             y => y_2(0),
             s => s2);

end Behaviour;