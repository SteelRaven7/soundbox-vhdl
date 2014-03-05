
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

entity Equalizer is
   generic (WIDTH    : natural := 16;
            FRACTION : natural := 15);
   port(clk    : in  std_logic;
        clk_en : in  std_logic;
        reset  : in  std_logic;
        mode   : in  std_logic_vector(3 downto 0);
        x      : in  std_logic_vector(WIDTH-1 downto 0);
        y      : out std_logic_vector(WIDTH-1 downto 0));
end Equalizer;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

architecture behaviour of Equalizer is

-- Components ------------------------------------------------------------------

-- Multiplier --
component Multiplier
   generic (X_WIDTH    : natural := 16;
            X_FRACTION : natural := 15;
            Y_WIDTH    : natural := 16;
            Y_FRACTION : natural := 15;
            S_WIDTH    : natural := 16;
            S_FRACTION : natural := 15);
   port(x : in  std_logic_vector(X_WIDTH-1 downto 0);
        y : in  std_logic_vector(Y_WIDTH-1 downto 0);
        s : out std_logic_vector(S_WIDTH-1 downto 0));
end component;

-- Generic IIR SO --
component Generic_IIR_SO
   generic (IN_WIDTH          : natural := 16;
            IN_FRACT          : natural := 15;
            COEFFICIENT_WIDTH : natural := 16;
            COEFFICIENT_FRACT : natural := 15;
            INTERNAL_WIDTH    : natural := 32;
            INTERNAL_FRACT    : natural := 30;
            OUT_WIDTH         : natural := 16;
            OUT_FRACT         : natural := 15);
   port(clk    : in  std_logic;
        clk_en : in  std_logic;
        reset  : in  std_logic;
        x      : in  std_logic_vector(IN_WIDTH-1          downto 0);
        B0     : in  std_logic_vector(COEFFICIENT_WIDTH-1 downto 0);
        B1     : in  std_logic_vector(COEFFICIENT_WIDTH-1 downto 0);
        B2     : in  std_logic_vector(COEFFICIENT_WIDTH-1 downto 0);
        A1     : in  std_logic_vector(COEFFICIENT_WIDTH-1 downto 0);
        A2     : in  std_logic_vector(COEFFICIENT_WIDTH-1 downto 0);
        y      : out std_logic_vector(OUT_WIDTH-1         downto 0));
end component;

-- Data Widths -----------------------------------------------------------------
  constant DATA_WIDTH    : natural := WIDTH;
  constant DATA_FRACT    : natural := FRACTION;
  constant SCALE_WIDTH_1 : natural := 16;
  constant SCALE_FRACT_1 : natural := 13;
  constant SCALE_WIDTH_2 : natural := 16;
  constant SCALE_FRACT_2 : natural := 13;
  constant SCALE_WIDTH_3 : natural := 16;
  constant SCALE_FRACT_3 : natural := 13;
  constant SCALE_WIDTH_4 : natural := 16;
  constant SCALE_FRACT_4 : natural := 13;

  constant SPEZIAL_WIDTH : natural := 16;

  constant COEFF_WIDTH_1 : natural := 18;
  constant COEFF_FRACT_1 : natural := 16;
  constant COEFF_WIDTH_2 : natural := 18;
  constant COEFF_FRACT_2 : natural := 16;
  constant COEFF_WIDTH_3 : natural := 17;
  constant COEFF_FRACT_3 : natural := 14;
-- Type Declarations -----------------------------------------------------------

  type scale_array_1 is array(0 to 4) of std_logic_vector(SCALE_WIDTH_1-1 downto 0);
  type scale_array_2 is array(0 to 4) of std_logic_vector(SCALE_WIDTH_2-1 downto 0);
  type scale_array_3 is array(0 to 4) of std_logic_vector(SCALE_WIDTH_3-1 downto 0);
  type scale_array_4 is array(0 to 4) of std_logic_vector(SCALE_WIDTH_4-1 downto 0);

  type coeff_array_1 is array(0 to 4) of std_logic_vector(COEFF_WIDTH_1-1 downto 0);
  type coeff_array_2 is array(0 to 4) of std_logic_vector(COEFF_WIDTH_2-1 downto 0);
  type coeff_array_3 is array(0 to 4) of std_logic_vector(COEFF_WIDTH_3-1 downto 0);

-- Coefficients ----------------------------------------------------------------
-- The coefficients are sorted in the following way: 12dB, 6dB, 0dB, -6dB, -12dB
  constant SCALE_1_ARRAY : scale_array_1 := (x"7f65", x"7fb2", x"2000", x"2000", x"2000");

  constant B0_1_ARRAY    : coeff_array_1 := ("00"&x"4393", "00"&x"41bd", "00"&x"4000", "00"&x"3e74", "00"&x"3ce7");
  constant B1_1_ARRAY    : coeff_array_1 := ("11"&x"8644", "11"&x"8784", "11"&x"8903", "11"&x"8a7f", "11"&x"8c46");
  constant B2_1_ARRAY    : coeff_array_1 := ("00"&x"3760", "00"&x"3799", "00"&x"3795", "00"&x"3777", "00"&x"371d");
  constant A1_1_ARRAY    : coeff_array_1 := (x"8663"&"00", x"8797"&"00", x"8903"&"00", x"8ab4"&"00", x"8cb4"&"00");
  constant A2_1_ARRAY    : coeff_array_1 := (x"39ea"&"00", x"38d6"&"00", x"3795"&"00", x"3620"&"00", x"3473"&"00");

  constant SCALE_2_ARRAY : scale_array_2 := (x"7f65", x"7fb2", x"2000", x"2000", x"2000");

  constant B0_2_ARRAY    : coeff_array_2 := ("00"&x"47e9", "00"&x"43bd", "00"&x"4000", "00"&x"3c9d", "00"&x"393b");
  constant B1_2_ARRAY    : coeff_array_2 := ("11"&x"864b", "11"&x"88aa", "11"&x"0000", "11"&x"8f3f", "11"&x"93ae");
  constant B2_2_ARRAY    : coeff_array_2 := ("00"&x"3399", "00"&x"355d", "00"&x"0000", "00"&x"35cf", "00"&x"34b1");
  constant A1_2_ARRAY    : coeff_array_2 := (x"86df"&"00", x"88f3"&"00", x"0000"&"00", x"8f3f"&"00", x"93ae"&"00");
  constant A2_2_ARRAY    : coeff_array_2 := (x"3aec"&"00", x"38d0"&"00", x"0000"&"00", x"326c"&"00", x"2dec"&"00");

  constant SCALE_3_ARRAY : scale_array_3 := (x"0766", x"7fb2", x"2000", x"2000", x"2000");

  constant B0_3_ARRAY    : coeff_array_3 := (x"4000"&"0", x"4fc4"&"0", x"4000"&"0", x"66f2"&"0", x"52bb"&"0");
  constant B1_3_ARRAY    : coeff_array_3 := (x"cce2"&"0", x"b6a5"&"0", x"0000"&"0", x"8a49"&"0", x"99c3"&"0");
  constant B2_3_ARRAY    : coeff_array_3 := (x"038c"&"0", x"112a"&"0", x"0000"&"0", x"3499"&"0", x"345c"&"0");
  constant A1_3_ARRAY    : coeff_array_3 := ("1"&x"b0e9", "1"&x"b6d1", "1"&x"0000", "1"&x"c524", "1"&x"cce2");
  constant A2_3_ARRAY    : coeff_array_3 := ("0"&x"2881", "0"&x"20b3", "0"&x"0000", "0"&x"0dc5", "0"&x"038c");

  constant SCALE_4_ARRAY : scale_array_4 := (x"6b0e", x"2000", x"2000", x"2000", x"2000");

-- Signals ---------------------------------------------------------------------

signal scale_1      : std_logic_vector(SCALE_WIDTH_1-1 downto 0);
signal scale_2      : std_logic_vector(SCALE_WIDTH_1-1 downto 0);
signal scale_3      : std_logic_vector(SCALE_WIDTH_1-1 downto 0);
signal scale_4      : std_logic_vector(SCALE_WIDTH_1-1 downto 0);

signal B0_1         : std_logic_vector(COEFF_WIDTH_1-1 downto 0);
signal B1_1         : std_logic_vector(COEFF_WIDTH_1-1 downto 0);
signal B2_1         : std_logic_vector(COEFF_WIDTH_1-1 downto 0);
signal A1_1         : std_logic_vector(COEFF_WIDTH_1-1 downto 0);
signal A2_1         : std_logic_vector(COEFF_WIDTH_1-1 downto 0);

signal B0_2         : std_logic_vector(COEFF_WIDTH_2-1 downto 0);
signal B1_2         : std_logic_vector(COEFF_WIDTH_2-1 downto 0);
signal B2_2         : std_logic_vector(COEFF_WIDTH_2-1 downto 0);
signal A1_2         : std_logic_vector(COEFF_WIDTH_2-1 downto 0);
signal A2_2         : std_logic_vector(COEFF_WIDTH_2-1 downto 0);

signal B0_3         : std_logic_vector(COEFF_WIDTH_3-1 downto 0);
signal B1_3         : std_logic_vector(COEFF_WIDTH_3-1 downto 0);
signal B2_3         : std_logic_vector(COEFF_WIDTH_3-1 downto 0);
signal A1_3         : std_logic_vector(COEFF_WIDTH_3-1 downto 0);
signal A2_3         : std_logic_vector(COEFF_WIDTH_3-1 downto 0);

signal iir_input_1  : std_logic_vector(DATA_WIDTH-1 downto 0);
signal iir_input_2  : std_logic_vector(DATA_WIDTH-1 downto 0);
signal iir_input_3  : std_logic_vector(DATA_WIDTH-1 downto 0);

signal iir_output_1 : std_logic_vector(DATA_WIDTH-1 downto 0);
signal iir_output_2 : std_logic_vector(DATA_WIDTH-1 downto 0);
signal iir_output_3 : std_logic_vector(DATA_WIDTH-1 downto 0);

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

begin

  -- Set coefficients
--  process(clk)
--    variable v_mode : natural;
--  begin
--    if(rising_edge(clk)) then
--      v_mode := to_natural(unsigned(mode));
--      if(v_mode <= 4) then
        scale_1 <= SCALE_1_ARRAY(1);
        scale_2 <= SCALE_2_ARRAY(1);
        scale_3 <= SCALE_3_ARRAY(1);
        scale_4 <= SCALE_4_ARRAY(1);

        B0_1    <= B0_1_ARRAY(1);
        B1_1    <= B1_1_ARRAY(1);
        B2_1    <= B2_1_ARRAY(1);
        A1_1    <= A1_1_ARRAY(1);
        A2_1    <= A2_1_ARRAY(1);

        B0_2    <= B0_2_ARRAY(1);
        B1_2    <= B1_2_ARRAY(1);
        B2_2    <= B2_2_ARRAY(1);
        A1_2    <= A1_2_ARRAY(1);
        A2_2    <= A2_2_ARRAY(1);

        B0_3    <= B0_3_ARRAY(1);
        B1_3    <= B1_3_ARRAY(1);
        B2_3    <= B2_3_ARRAY(1);
        A1_3    <= A1_3_ARRAY(1);
        A2_3    <= A2_3_ARRAY(1);
--      end if;
--    end if;
--  end process;

  -- Stage 1 -------------------------------------------------------------------
  Multiplier_1 :	Multiplier
  generic map(X_WIDTH    => DATA_WIDTH,
              X_FRACTION => DATA_FRACT,
              Y_WIDTH    => SCALE_WIDTH_1,
              Y_FRACTION => SCALE_FRACT_1,
              S_WIDTH    => DATA_WIDTH,
              S_FRACTION => DATA_FRACT)
    port map(x => x,
             y => scale_1,
             s => iir_input_1);


  Generic_IIR_SO_1 : Generic_IIR_SO
  generic map(IN_WIDTH          => DATA_WIDTH,
              IN_FRACT          => DATA_FRACT,
              COEFFICIENT_WIDTH => COEFF_WIDTH_1,
              COEFFICIENT_FRACT => COEFF_FRACT_1,
              INTERNAL_WIDTH    => 42,
              INTERNAL_FRACT    => 31,
              OUT_WIDTH         => DATA_WIDTH,
              OUT_FRACT         => DATA_FRACT)
   port map(clk    => clk,
            clk_en => clk_en,
            reset  => reset,
            x      => iir_input_1,
            B0     => B0_1,
            B1     => B1_1,
            B2     => B2_1,
            A1     => A1_1,
            A2     => A2_1,
            y      => iir_output_1);


  -- Stage 2 -------------------------------------------------------------------
  Multiplier_2 :	Multiplier
  generic map(X_WIDTH    => DATA_WIDTH,
              X_FRACTION => DATA_FRACT,
              Y_WIDTH    => SCALE_WIDTH_2,
              Y_FRACTION => SCALE_FRACT_2,
              S_WIDTH    => DATA_WIDTH,
              S_FRACTION => DATA_FRACT)
    port map(x => iir_output_1,
             y => scale_2,
             s => iir_input_2);


  Generic_IIR_SO_2 : Generic_IIR_SO
  generic map(IN_WIDTH          => DATA_WIDTH,
              IN_FRACT          => DATA_FRACT,
              COEFFICIENT_WIDTH => COEFF_WIDTH_2,
              COEFFICIENT_FRACT => COEFF_FRACT_2,
              INTERNAL_WIDTH    => 42,
              INTERNAL_FRACT    => 31,
              OUT_WIDTH         => DATA_WIDTH,
              OUT_FRACT         => DATA_FRACT)
   port map(clk    => clk,
            clk_en => clk_en,
            reset  => reset,
            x      => iir_input_2,
            B0     => B0_2,
            B1     => B1_2,
            B2     => B2_2,
            A1     => A1_2,
            A2     => A2_2,
            y      => iir_output_2);


  -- Stage 3 -------------------------------------------------------------------
  Multiplier_3 :	Multiplier
  generic map(X_WIDTH    => DATA_WIDTH,
              X_FRACTION => DATA_FRACT,
              Y_WIDTH    => SCALE_WIDTH_3,
              Y_FRACTION => SCALE_FRACT_3,
              S_WIDTH    => DATA_WIDTH,
              S_FRACTION => DATA_FRACT)
    port map(x => iir_output_2,
             y => scale_3,
             s => iir_input_3);


  Generic_IIR_SO_3 : Generic_IIR_SO
  generic map(IN_WIDTH          => DATA_WIDTH,
              IN_FRACT          => DATA_FRACT,
              COEFFICIENT_WIDTH => COEFF_WIDTH_3,
              COEFFICIENT_FRACT => COEFF_FRACT_3,
              INTERNAL_WIDTH    => 42,
              INTERNAL_FRACT    => 31,
              OUT_WIDTH         => DATA_WIDTH,
              OUT_FRACT         => DATA_FRACT)
   port map(clk    => clk,
            clk_en => clk_en,
            reset  => reset,
            x      => iir_input_3,
            B0     => B0_3,
            B1     => B1_3,
            B2     => B2_3,
            A1     => A1_3,
            A2     => A2_3,
            y      => iir_output_3);


  -- Stage 4 -------------------------------------------------------------------
  Multiplier_4 :	Multiplier
  generic map(X_WIDTH    => DATA_WIDTH,
              X_FRACTION => DATA_FRACT,
              Y_WIDTH    => SCALE_WIDTH_4,
              Y_FRACTION => SCALE_FRACT_4,
              S_WIDTH    => DATA_WIDTH,
              S_FRACTION => DATA_FRACT)
    port map(x => iir_output_3,
             y => scale_4,
             s => y);

end architecture;