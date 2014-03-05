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
constant X_1_FRACTION  : integer := 16;
constant Y_1_WIDTH     : integer := 16;
constant Y_1_FRACTION  : integer := 16;
constant S_1_WIDTH     : integer := 16;
constant S_1_FRACTION  : integer := 16;
constant X_2_WIDTH     : integer := 16;
constant X_2_FRACTION  : integer := 16;
constant Y_2_WIDTH     : integer := 16;
constant Y_2_FRACTION  : integer := 16;
constant S_2_WIDTH     : integer := 16;
constant S_2_FRACTION  : integer := 16;

type x_1_array is array(0 to NO_OF_SAMPLES-1) of std_logic_vector(X_1_WIDTH-1 downto 0);
type y_1_array is array(0 to NO_OF_SAMPLES-1) of std_logic_vector(Y_1_WIDTH-1 downto 0);
type s_1_array is array(0 to NO_OF_SAMPLES-1) of std_logic_vector(S_1_WIDTH-1 downto 0);
type x_2_array is array(0 to NO_OF_SAMPLES-1) of std_logic_vector(X_2_WIDTH-1 downto 0);
type y_2_array is array(0 to NO_OF_SAMPLES-1) of std_logic_vector(Y_2_WIDTH-1 downto 0);
type s_2_array is array(0 to NO_OF_SAMPLES-1) of std_logic_vector(S_2_WIDTH-1 downto 0);

signal x_1 : x_1_array := ("0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000");
signal y_1 : y_1_array := ("0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000");
signal s_1 : s_1_array := ("0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000");
signal x_2 : x_2_array := ("0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000");
signal y_2 : y_2_array := ("0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000");
signal s_2 : s_2_array := ("0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000",
                           "0000000000000000");

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

begin

  test:
  process
  begin
    wait for 100 ns;
  end process;

  Multiplier_1 : Multiplier
  generic map(X_WIDTH    => 16,
              X_FRACTION => 14,
              Y_WIDTH    => 16,
              Y_FRACTION => 14,
              S_WIDTH    => 16,
              S_FRACTION => 13)
    port map(x => x_1(0),
             y => y_1(0),
             s => s_1(0));

  Multiplier_2 : Multiplier
  generic map(X_WIDTH    => 10,
              X_FRACTION => 8,
              Y_WIDTH    => 6,
              Y_FRACTION => 4,
              S_WIDTH    => 4,
              S_FRACTION => 1)
    port map(x => x_2(0),
             y => y_2(0),
             s => s_2(0));

end Behaviour;