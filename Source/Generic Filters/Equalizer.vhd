--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Description:                                                               --
-- This file describes the implementation of a generic equalizer. This        --
-- equaliser is made up out of three second order, direct IIR-filters with    --
-- multipliers between.                                                       --
--                                                                            --
--                                                                            --
-- Generic:                                                                   --
-- DATA_WIDTH            - The width of the input data, output data as well   --
--                         as the data signals between the IIR-filters and    --
--                         multipliers                                        --
-- DATA_FRACT            - The factrional width of above data                 --
--                                                                            --
-- SCALE_WIDTH_1         - Data width of the first scaling factor             --
-- SCALE_FRACT_1         - Fractional width of the first scaling factor       --
-- SCALE_WIDTH_2         - Data width of the second scaling factor            --
-- SCALE_FRACT_2         - Fractional width of the second scaling factor      --
-- SCALE_WIDTH_3         - Data width of the third scaling factor             --
-- SCALE_FRACT_3         - Fractional width of the third scaling factor       --
-- SCALE_WIDTH_4         - Data width of the fourth scaling factor            --
-- SCALE_FRACT_4         - Fractional width of the fourth scaling factor      --
--                                                                            --
-- INTERNAL_IIR_WIDTH_1  - Width of the internal calculations within the      --
--                         first IIR-filter                                   --
-- INTERNAL_IIR_FRACT_1  - Fractional width of the internal calculations      --
--                         within the first IIR-filter                        --
-- INTERNAL_IIR_WIDTH_2  - Width of the internal calculations within the      --
--                         second IIR-filter                                  --
-- INTERNAL_IIR_FRACT_2  - Fractional width of the internal calculations      --
--                         within the second IIR-filter                       --
-- INTERNAL_IIR_WIDTH_3  - Width of the internal calculations within the      --
--                         third IIR-filter                                   --
-- INTERNAL_IIR_FRACT_3  - Fractional width of the internal calculations      --
--                         within the third IIR-filter                        --
--                                                                            --
-- COEFF_WIDTH_1         - Width of the coefficients used in the first        --
--                         IIR-filter                                         --
-- COEFF_FRACT_1         - Fractional width of the coefficients used in the   --
--                         first IIR-filter                                   --
-- COEFF_WIDTH_2         - Width of the coefficients used in the second       --
--                         IIR-filter                                         --
-- COEFF_FRACT_2         - Fractional width of the coefficients used in the   --
--                         second IIR-filter                                  --
-- COEFF_WIDTH_3         - Width of the coefficients used in the third        --
--                         IIR-filter                                         --
-- COEFF_FRACT_3         - Fractional width of the coefficients used in the   --
--                         third IIR-filter                                   --
--                                                                            --
--                                                                            --
-- Input/Output:                                                              --
-- clk               - System clock                                           --
-- reset             - Resets component when high                             --
-- write_mode        - Write new coefficients when high                       --
-- x                 - Input                                                  --
--                                                                            --
-- scale_1           - First scaling factor                                   --
-- scale_2           - Second scaling factor                                  --
-- scale_3           - Third scaling factor                                   --
-- scale_4           - Fourth scaling factor                                  --
--                                                                            --
-- b0_1              - B coefficient of the first IIR filter                  --
-- b1_1              - B coefficient of the first IIR filter                  --
-- b2_1              - B coefficient of the first IIR filter                  --
-- a1_1              - A coefficient of the first IIR filter                  --
-- a2_1              - A coefficient of the first IIR filter                  --
--                                                                            --
-- b0_2              - B coefficient of the second IIR filter                 --
-- b1_2              - B coefficient of the second IIR filter                 --
-- b2_2              - B coefficient of the second IIR filter                 --
-- a1_2              - A coefficient of the second IIR filter                 --
-- a2_2              - A coefficient of the second IIR filter                 --
--                                                                            --
-- b0_3              - B coefficient of the third IIR filter                  --
-- b1_3              - B coefficient of the third IIR filter                  --
-- b2_3              - B coefficient of the third IIR filter                  --
-- a1_3              - A coefficient of the third IIR filter                  --
-- a2_3              - A coefficient of the third IIR filter                  --
--                                                                            --
-- y                 - Output                                                 --
--                                                                            --
--                                                                            --
-- Internal Constants:                                                        --
-- N                 - Number of coefficients, this number is three for a     --
--                     second order filter and should not be changed. The     --
--                     constant is mearly there to simplify creation of       --
--                     higher order filters. Note that for this to be done    --
--                     successfully, you have to increase the number of       --
--                     coefficients as well.                                  --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

entity Equalizer is
   generic (DATA_WIDTH    : natural := 8;
            DATA_FRACT    : natural := 6;

            SCALE_WIDTH_1 : natural := 8;
            SCALE_FRACT_1 : natural := 6;
            SCALE_WIDTH_2 : natural := 8;
            SCALE_FRACT_2 : natural := 6;
            SCALE_WIDTH_3 : natural := 8;
            SCALE_FRACT_3 : natural := 6;
            SCALE_WIDTH_4 : natural := 8;
            SCALE_FRACT_4 : natural := 6;

            INTERNAL_IIR_WIDTH_1 : natural := 12;
            INTERNAL_IIR_FRACT_1 : natural := 8;
            INTERNAL_IIR_WIDTH_2 : natural := 12;
            INTERNAL_IIR_FRACT_2 : natural := 8;
            INTERNAL_IIR_WIDTH_3 : natural := 12;
            INTERNAL_IIR_FRACT_3 : natural := 8;

            COEFF_WIDTH_1 : natural := 8;
            COEFF_FRACT_1 : natural := 6;
            COEFF_WIDTH_2 : natural := 8;
            COEFF_FRACT_2 : natural := 6;
            COEFF_WIDTH_3 : natural := 8;
            COEFF_FRACT_3 : natural := 6);
   port(clk        : in  std_logic;
        reset      : in  std_logic;
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
             y => s_scale_3,
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
             y => s_scale_4,
             s => y);

end architecture;