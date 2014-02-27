
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

entity Equalizer is
   generic (WIDTH    : integer := 16;
            FRACTION : integer := 15);
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

-- Generic IIR SO --  
component Generic_IIR_SO
   generic (IN_WIDTH          : integer := 16;
            IN_FRACT          : integer := 15;
            COEFFICIENT_WIDTH : integer := 16;
            COEFFICIENT_FRACT : integer := 15;
			INTERNAL_WIDTH    : integer := 32;
			INTERNAL_FRACT    : integer := 30;
			OUT_WIDTH         : integer := 16;
			OUT_FRACT         : integer := 15);
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
  constant DATA_WIDTH    : integer := WIDTH;
  constant DATA_FRACT    : integer := FRACTION;
  constant SCALE_WIDTH_1 : integer := 16;
  constant SCALE_FRACT_1 : integer := 13;
  constant SCALE_WIDTH_2 : integer := 16;
  constant SCALE_FRACT_2 : integer := 13;
  constant SCALE_WIDTH_3 : integer := 16;
  constant SCALE_FRACT_3 : integer := 13;
  constant SCALE_WIDTH_4 : integer := 16;
  constant SCALE_FRACT_4 : integer := 13;
  
  constant SPEZIAL_WIDTH : integer := 16;
  
  constant COEFF_WIDTH_1 : integer := 16;
  constant COEFF_FRACT_1 : integer := 16;
  constant COEFF_WIDTH_2 : integer := 16;
  constant COEFF_FRACT_2 : integer := 16;
  constant COEFF_WIDTH_3 : integer := 16;
  constant COEFF_FRACT_3 : integer := 14;
-- Type Declarations -----------------------------------------------------------

  type scale_array_1 is array(0 to 4) of std_logic_vector(SCALE_WIDTH_1-1 downto 0);
  type scale_array_2 is array(0 to 4) of std_logic_vector(SCALE_WIDTH_2-1 downto 0);
  type scale_array_3 is array(0 to 4) of std_logic_vector(SCALE_WIDTH_3-1 downto 0);
  type scale_array_4 is array(0 to 4) of std_logic_vector(SCALE_WIDTH_4-1 downto 0);
  
  type coeff_array   is array(0 to 4) of std_logic_vector(SPEZIAL_WIDTH-1 downto 0);

-- Coefficients ----------------------------------------------------------------
-- The coefficients are sorted in the following way: 12dB, 6dB, 0dB, -6dB, -12dB
  constant SCALE_1_ARRAY : scale_array_1 := (x"7f65", x"7fb2", x"2000", x"2000", x"2000");
  
  constant B0_1_ARRAY    : coeff_array   := (x"4393", x"41bd", x"4000", x"3e74", x"3ce7");
  constant B1_1_ARRAY    : coeff_array   := (x"8644", x"8784", x"8903", x"8a7f", x"8c46");
  constant B2_1_ARRAY    : coeff_array   := (x"3760", x"3799", x"3795", x"3777", x"371d");
  constant A1_1_ARRAY    : coeff_array   := (x"8663", x"8797", x"8903", x"8ab4", x"8cb4");
  constant A2_1_ARRAY    : coeff_array   := (x"39ea", x"38d6", x"3795", x"3620", x"3473");

  constant SCALE_2_ARRAY : scale_array_2 := (x"7f65", x"7fb2", x"2000", x"2000", x"2000");
  
  constant B0_2_ARRAY    : coeff_array   := (x"47e9", x"43bd", x"4000", x"3c9d", x"393b");
  constant B1_2_ARRAY    : coeff_array   := (x"864b", x"88aa", x"0000", x"8f3f", x"93ae");
  constant B2_2_ARRAY    : coeff_array   := (x"3399", x"355d", x"0000", x"35cf", x"34b1");
  constant A1_2_ARRAY    : coeff_array   := (x"86df", x"88f3", x"0000", x"8f3f", x"93ae");
  constant A2_2_ARRAY    : coeff_array   := (x"3aec", x"38d0", x"0000", x"326c", x"2dec");

  constant SCALE_3_ARRAY : scale_array_3 := (x"0766", x"7fb2", x"2000", x"2000", x"2000");
  
  constant B0_3_ARRAY    : coeff_array   := (x"4000", x"4fc4", x"4000", x"66f2", x"52bb");
  constant B1_3_ARRAY    : coeff_array   := (x"cce2", x"b6a5", x"0000", x"8a49", x"99c3");
  constant B2_3_ARRAY    : coeff_array   := (x"038c", x"112a", x"0000", x"3499", x"345c");
  constant A1_3_ARRAY    : coeff_array   := (x"b0e9", x"b6d1", x"0000", x"c524", x"cce2");
  constant A2_3_ARRAY    : coeff_array   := (x"2881", x"20b3", x"0000", x"0dc5", x"038c");

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
  process(mode)
    variable v_mode : integer;
  begin
    v_mode := to_integer(unsigned(mode));
	if(v_mode <= 4) then
	  scale_1 <= SCALE_1_ARRAY(v_mode);
      scale_2 <= SCALE_2_ARRAY(v_mode);
      scale_3 <= SCALE_3_ARRAY(v_mode);
      scale_4 <= SCALE_4_ARRAY(v_mode);

      B0_1    <= B0_1_ARRAY(v_mode);
      B1_1    <= B1_1_ARRAY(v_mode);
      B2_1    <= B2_1_ARRAY(v_mode);
      A1_1    <= A1_1_ARRAY(v_mode);
      A2_1    <= A2_1_ARRAY(v_mode);

      B0_2    <= B0_2_ARRAY(v_mode);
      B1_2    <= B1_2_ARRAY(v_mode);
      B2_2    <= B2_2_ARRAY(v_mode);
      A1_2    <= A1_2_ARRAY(v_mode);
      A2_2    <= A2_2_ARRAY(v_mode);

      B0_3    <= B0_3_ARRAY(v_mode);
      B1_3    <= B1_3_ARRAY(v_mode);
      B2_3    <= B2_3_ARRAY(v_mode);
      A1_3    <= A1_3_ARRAY(v_mode);
      A2_3    <= A2_3_ARRAY(v_mode);
	end if;
  end process;

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