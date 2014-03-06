
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

entity Equalizer is
   generic (DATA_WIDTH    : natural := 16;
            DATA_FRACT    : natural := 15;
			
			SCALE_WIDTH_1 : natural := 16;
		    SCALE_FRACT_1 : natural := 14;
		    SCALE_WIDTH_2 : natural := 16;
		    SCALE_FRACT_2 : natural := 14;
		    SCALE_WIDTH_3 : natural := 16;
		    SCALE_FRACT_3 : natural := 14;
		    SCALE_WIDTH_4 : natural := 16;
		    SCALE_FRACT_4 : natural := 14;

            INTERNAL_IIR_WIDTH_1 : natural := 42;
            INTERNAL_IIR_FRACT_1 : natural := 31;
            INTERNAL_IIR_WIDTH_2 : natural := 42;
            INTERNAL_IIR_FRACT_2 : natural := 31;
            INTERNAL_IIR_WIDTH_3 : natural := 42;
            INTERNAL_IIR_FRACT_3 : natural := 31;

		    COEFF_WIDTH_1 : natural := 16;
		    COEFF_FRACT_1 : natural := 15;
		    COEFF_WIDTH_2 : natural := 16;
		    COEFF_FRACT_2 : natural := 15;
		    COEFF_WIDTH_3 : natural := 16;
		    COEFF_FRACT_3 : natural := 15);
   port(clk        : in  std_logic;
        reset      : in  std_logic;
        write_mode : in  std_logic;
        x          : in  std_logic_vector(DATA_WIDTH-1 downto 0);
		
		scale_1    : in  std_logic_vector(SCALE_WIDTH_1-1 downto 0);
		scale_2    : in  std_logic_vector(SCALE_WIDTH_2-1 downto 0);
		scale_3    : in  std_logic_vector(SCALE_WIDTH_3-1 downto 0);
		scale_4    : in  std_logic_vector(SCALE_WIDTH_4-1 downto 0);

		b0_1       : in  std_logic_vector(COEFF_WIDTH_1-1 downto 0);
		b1_1       : in  std_logic_vector(COEFF_WIDTH_1-1 downto 0);
		b2_1       : in  std_logic_vector(COEFF_WIDTH_1-1 downto 0);
		a1_1       : in  std_logic_vector(COEFF_WIDTH_1-1 downto 0);
	    a2_1       : in  std_logic_vector(COEFF_WIDTH_1-1 downto 0);

		b0_2       : in  std_logic_vector(COEFF_WIDTH_2-1 downto 0);
		b1_2       : in  std_logic_vector(COEFF_WIDTH_2-1 downto 0);
		b2_2       : in  std_logic_vector(COEFF_WIDTH_2-1 downto 0);
		a1_2       : in  std_logic_vector(COEFF_WIDTH_2-1 downto 0);
		a2_2       : in  std_logic_vector(COEFF_WIDTH_2-1 downto 0);

		b0_3       : in  std_logic_vector(COEFF_WIDTH_3-1 downto 0);
		b1_3       : in  std_logic_vector(COEFF_WIDTH_3-1 downto 0);
		b2_3       : in  std_logic_vector(COEFF_WIDTH_3-1 downto 0);
		a1_3       : in  std_logic_vector(COEFF_WIDTH_3-1 downto 0);
		a2_3       : in  std_logic_vector(COEFF_WIDTH_3-1 downto 0);
		
        y          : out std_logic_vector(DATA_WIDTH-1 downto 0));
end Equalizer;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

architecture behaviour of Equalizer is

-- Signals ---------------------------------------------------------------------
signal s_scale_1    : std_logic_vector(SCALE_WIDTH_1-1 downto 0);
signal s_scale_2    : std_logic_vector(SCALE_WIDTH_2-1 downto 0);
signal s_scale_3    : std_logic_vector(SCALE_WIDTH_3-1 downto 0);
signal s_scale_4    : std_logic_vector(SCALE_WIDTH_4-1 downto 0);

signal s_b0_1       : std_logic_vector(COEFF_WIDTH_1-1 downto 0);
signal s_b1_1       : std_logic_vector(COEFF_WIDTH_1-1 downto 0);
signal s_b2_1       : std_logic_vector(COEFF_WIDTH_1-1 downto 0);
signal s_a1_1       : std_logic_vector(COEFF_WIDTH_1-1 downto 0);
signal s_a2_1       : std_logic_vector(COEFF_WIDTH_1-1 downto 0);

signal s_b0_2       : std_logic_vector(COEFF_WIDTH_2-1 downto 0);
signal s_b1_2       : std_logic_vector(COEFF_WIDTH_2-1 downto 0);
signal s_b2_2       : std_logic_vector(COEFF_WIDTH_2-1 downto 0);
signal s_a1_2       : std_logic_vector(COEFF_WIDTH_2-1 downto 0);
signal s_a2_2       : std_logic_vector(COEFF_WIDTH_2-1 downto 0);

signal s_b0_3       : std_logic_vector(COEFF_WIDTH_3-1 downto 0);
signal s_b1_3       : std_logic_vector(COEFF_WIDTH_3-1 downto 0);
signal s_b2_3       : std_logic_vector(COEFF_WIDTH_3-1 downto 0);
signal s_a1_3       : std_logic_vector(COEFF_WIDTH_3-1 downto 0);
signal s_a2_3       : std_logic_vector(COEFF_WIDTH_3-1 downto 0);

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
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(write_mode = '1') then
        s_scale_1 <= scale_1;
        s_scale_2 <= scale_2;
        s_scale_3 <= scale_3;
        s_scale_4 <= scale_4;

        s_b0_1    <= b0_1;
        s_b1_1    <= b1_1;
        s_b2_1    <= b2_1;
        s_a1_1    <= a1_1;
        s_a2_1    <= a2_1;

        s_b0_2    <= b0_2;
        s_b1_2    <= b1_2;
        s_b2_2    <= b2_2;
        s_a1_2    <= a1_2;
        s_a2_2    <= a2_2;

        s_b0_3    <= b0_3;
        s_b1_3    <= b1_3;
        s_b2_3    <= b2_3;
        s_a1_3    <= a1_3;
        s_a2_3    <= a2_3;
      end if;
    end if;
  end process;

  -- Stage 1 -------------------------------------------------------------------
  Multiplier_1 : entity work.Multiplier
  generic map(X_WIDTH    => DATA_WIDTH,
              X_FRACTION => DATA_FRACT,
              Y_WIDTH    => SCALE_WIDTH_1,
              Y_FRACTION => SCALE_FRACT_1,
              S_WIDTH    => DATA_WIDTH,
              S_FRACTION => DATA_FRACT)
    port map(x => x,
             y => s_scale_1,
             s => iir_input_1);


  Generic_IIR_SO_1 : entity work.Generic_IIR_SO
  generic map(IN_WIDTH          => DATA_WIDTH,
              IN_FRACT          => DATA_FRACT,
              COEFFICIENT_WIDTH => COEFF_WIDTH_1,
              COEFFICIENT_FRACT => COEFF_FRACT_1,
              INTERNAL_WIDTH    => INTERNAL_IIR_WIDTH_1,
              INTERNAL_FRACT    => INTERNAL_IIR_FRACT_1,
              OUT_WIDTH         => DATA_WIDTH,
              OUT_FRACT         => DATA_FRACT)
   port map(clk    => clk,
            reset  => reset,
            x      => iir_input_1,
            B0     => s_b0_1,
            B1     => s_b1_1,
            B2     => s_b2_1,
            A1     => s_a1_1,
            A2     => s_a2_1,
            y      => iir_output_1);


  -- Stage 2 -------------------------------------------------------------------
  Multiplier_2 : entity work.Multiplier
  generic map(X_WIDTH    => DATA_WIDTH,
              X_FRACTION => DATA_FRACT,
              Y_WIDTH    => SCALE_WIDTH_2,
              Y_FRACTION => SCALE_FRACT_2,
              S_WIDTH    => DATA_WIDTH,
              S_FRACTION => DATA_FRACT)
    port map(x => iir_output_1,
             y => s_scale_2,
             s => iir_input_2);


  Generic_IIR_SO_2 : entity work.Generic_IIR_SO
  generic map(IN_WIDTH          => DATA_WIDTH,
              IN_FRACT          => DATA_FRACT,
              COEFFICIENT_WIDTH => COEFF_WIDTH_2,
              COEFFICIENT_FRACT => COEFF_FRACT_2,
              INTERNAL_WIDTH    => INTERNAL_IIR_WIDTH_2,
              INTERNAL_FRACT    => INTERNAL_IIR_FRACT_2,
              OUT_WIDTH         => DATA_WIDTH,
              OUT_FRACT         => DATA_FRACT)
   port map(clk    => clk,
            reset  => reset,
            x      => iir_input_2,
            B0     => s_b0_2,
            B1     => s_b1_2,
            B2     => s_b2_2,
            A1     => s_a1_2,
            A2     => s_a2_2,
            y      => iir_output_2);


  -- Stage 3 -------------------------------------------------------------------
  Multiplier_3 : entity work.Multiplier
  generic map(X_WIDTH    => DATA_WIDTH,
              X_FRACTION => DATA_FRACT,
              Y_WIDTH    => SCALE_WIDTH_3,
              Y_FRACTION => SCALE_FRACT_3,
              S_WIDTH    => DATA_WIDTH,
              S_FRACTION => DATA_FRACT)
    port map(x => iir_output_2,
             y => s_scale_2,
             s => iir_input_3);


  Generic_IIR_SO_3 : entity work.Generic_IIR_SO
  generic map(IN_WIDTH          => DATA_WIDTH,
              IN_FRACT          => DATA_FRACT,
              COEFFICIENT_WIDTH => COEFF_WIDTH_3,
              COEFFICIENT_FRACT => COEFF_FRACT_3,
              INTERNAL_WIDTH    => INTERNAL_IIR_WIDTH_3,
              INTERNAL_FRACT    => INTERNAL_IIR_FRACT_3,
              OUT_WIDTH         => DATA_WIDTH,
              OUT_FRACT         => DATA_FRACT)
   port map(clk    => clk,
            reset  => reset,
            x      => iir_input_3,
            B0     => s_b0_3,
            B1     => s_b1_3,
            B2     => s_b2_3,
            A1     => s_a1_3,
            A2     => s_a2_3,
            y      => iir_output_3);


  -- Stage 4 -------------------------------------------------------------------
  Multiplier_4 : entity work.Multiplier
  generic map(X_WIDTH    => DATA_WIDTH,
              X_FRACTION => DATA_FRACT,
              Y_WIDTH    => SCALE_WIDTH_4,
              Y_FRACTION => SCALE_FRACT_4,
              S_WIDTH    => DATA_WIDTH,
              S_FRACTION => DATA_FRACT)
    port map(x => iir_output_3,
             y => s_scale_2,
             s => y);

end architecture;