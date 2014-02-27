
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

entity Equalizer12DB is
   generic (WIDTH    : integer := 16;
            FRACTION : integer := 15);
   port(clk    : in  std_logic;
        clk_en : in  std_logic;
        x      : in  std_logic_vector(WIDTH-1 downto 0);
        y      : out std_logic_vector(WIDTH-1 downto 0));
end Equalizer12DB;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

architecture behaviour of Equalizer12DB is
-- Multiplier ------------------------------------------------------------------
component Multiplier
   generic (X_WIDTH    : integer := 16;
            X_FRACTION : integer := 15;
            Y_WIDTH    : integer := 16;
            Y_FRACTION : integer := 15;
            S_WIDTH    : integer := 16;
            S_FRACTION : integer := 15);
   port(x : in  std_logic_vector(X_WIDTH-1 downto 0);
        y : in  std_logic_vector(Y_WIDTH-1 downto 0);
        s : out std_logic_vector(S_WIDTH-1 downto 0));
end component;

-- Generic IIR -----------------------------------------------------------------  
component Generic_IIR
   generic (WIDTH    : integer := 16;
            N        : integer := 3;
            N_WIDTH  : integer := 24;
            N_BINALS : integer := 22);
   port(clk    : in  std_logic;
        clk_en : in  std_logic;
        x      : in  std_logic_vector(WIDTH-1   downto 0);
        B0     : in  std_logic_vector(N_WIDTH-1 downto 0);
        B1     : in  std_logic_vector(N_WIDTH-1 downto 0);
        B2     : in  std_logic_vector(N_WIDTH-1 downto 0);
        A1     : in  std_logic_vector(N_WIDTH-1 downto 0);
        A2     : in  std_logic_vector(N_WIDTH-1 downto 0);
        y      : out std_logic_vector(WIDTH-1   downto 0));
end component;
-- Constants -------------------------------------------------------------------

  constant DATA_WIDTH : integer := 16;
  constant DATA_FRACT : integer := 15;

  constant SCALE_WIDTH_1 : integer := 16;
  constant SCALE_FRACT_1 : integer := 13;
  constant SCALE_1       : std_logic_vector(SCALE_WIDTH_1-1 downto 0) := x"7f65";
  
  constant COEFF_WIDTH_1 : integer := 18;
  constant COEFF_FRACT_1 : integer := 16;
  constant B0_1          : std_logic_vector := "00" & x"4393";
  constant B1_1          : std_logic_vector := "11" & x"8644";
  constant B2_1          : std_logic_vector := "00" & x"3760";
  constant A1_1          : std_logic_vector := x"8663" & "00";
  constant A2_1          : std_logic_vector := x"39ea" & "00";

  constant SCALE_WIDTH_2 : integer := 16;
  constant SCALE_FRACT_2 : integer := 13;
  constant SCALE_2       : std_logic_vector(SCALE_WIDTH_1-1 downto 0) := x"7f65";
  
  constant COEFF_WIDTH_2 : integer := 18;
  constant COEFF_FRACT_2 : integer := 16;
  constant B0_2          : std_logic_vector := "00" & x"47e9";
  constant B1_2          : std_logic_vector := "11" & x"864b";
  constant B2_2          : std_logic_vector := "00" & x"3399";
  constant A1_2          : std_logic_vector := x"86df" & "00";
  constant A2_2          : std_logic_vector := x"3aec" & "00";

  constant SCALE_WIDTH_3 : integer := 16;
  constant SCALE_FRACT_3 : integer := 13;
  constant SCALE_3       : std_logic_vector(SCALE_WIDTH_1-1 downto 0) := x"0766";
  
  constant COEFF_WIDTH_3 : integer := 17;
  constant COEFF_FRACT_3 : integer := 14;
  constant B0_3          : std_logic_vector := x"4000" & "0";
  constant B1_3          : std_logic_vector := x"cce2" & "0";
  constant B2_3          : std_logic_vector := x"038c" & "0";
  constant A1_3          : std_logic_vector := "1" & x"b0e9";
  constant A2_3          : std_logic_vector := "0" & x"2881";

  constant SCALE_WIDTH_4 : integer := 16;
  constant SCALE_FRACT_4 : integer := 13;
  constant SCALE_4       : std_logic_vector(SCALE_WIDTH_1-1 downto 0) := x"6b0e";
  
-- Signals ---------------------------------------------------------------------

signal iir_input_1  : std_logic_vector(DATA_WIDTH-1 downto 0);
signal iir_input_2  : std_logic_vector(DATA_WIDTH-1 downto 0);
signal iir_input_3  : std_logic_vector(DATA_WIDTH-1 downto 0);

signal iir_output_1 : std_logic_vector(DATA_WIDTH-1 downto 0);
signal iir_output_2 : std_logic_vector(DATA_WIDTH-1 downto 0);
signal iir_output_3 : std_logic_vector(DATA_WIDTH-1 downto 0);

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  
begin

  -- Stage 1 -------------------------------------------------------------------
  Multiplier_1 :	Multiplier
  generic map(X_WIDTH    => DATA_WIDTH,
              X_FRACTION => DATA_FRACT,
              Y_WIDTH    => SCALE_WIDTH_1,
              Y_FRACTION => SCALE_FRACT_1,
              S_WIDTH    => DATA_WIDTH,
              S_FRACTION => DATA_FRACT)
	port map(x => x,
           y => SCALE_1,
           s => iir_input_1);


  Generic_IIR_1 : Generic_IIR
  generic map(WIDTH    => DATA_WIDTH,
              N        => 3,
              N_WIDTH  => COEFF_WIDTH_1,
              N_BINALS => COEFF_FRACT_1)
  port map(clk    => clk,
           clk_en => clk_en,
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
           y => SCALE_2,
           s => iir_input_2);


  Generic_IIR_2 : Generic_IIR
  generic map(WIDTH    => DATA_WIDTH,
              N        => 3,
              N_WIDTH  => COEFF_WIDTH_2,
              N_BINALS => COEFF_FRACT_2)
  port map(clk    => clk,
           clk_en => clk_en,
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
           y => SCALE_3,
           s => iir_input_3);


  Generic_IIR_3 : Generic_IIR
  generic map(WIDTH    => DATA_WIDTH,
              N        => 3,
              N_WIDTH  => COEFF_WIDTH_3,
              N_BINALS => COEFF_FRACT_3)
  port map(clk    => clk,
           clk_en => clk_en,
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
           y => SCALE_4,
           s => y);
           

end architecture;