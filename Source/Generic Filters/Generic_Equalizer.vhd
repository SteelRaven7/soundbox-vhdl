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
use work.filter_pkg.all;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

entity Generic_Equalizer is
   generic (NO_SECTIONS : natural         := 9;
			
			DATA_WIDTH : natural          := 8;
            DATA_FRACT : natural          := 6;

            SCALE_WIDTH : natural         := 8;
            SCALE_FRACT : natural_array   := (6,6,6,6,6,6,6,6,6,6);

            INTERNAL_WIDTH : natural      := 14;
            INTERNAL_FRACT : natural      := 8;

            COEFF_WIDTH_B : natural       := 8;
            COEFF_FRACT_B : natural_array := (6,6,6,6,6,6,6,6,6);
            COEFF_WIDTH_A : natural       := 8;
            COEFF_FRACT_A : natural_array := (6,6,6,6,6,6,6,6,6));
   port(clk        : in  std_logic;
        reset      : in  std_logic;
        x          : in  std_logic_vector(DATA_WIDTH-1 downto 0);

        scale      : in  std_logic_vector(SCALE_WIDTH*(NO_SECTIONS+1)-1 downto 0);

        b0         : in  std_logic_vector(COEFF_WIDTH_B*(NO_SECTIONS)-1 downto 0);
        b1         : in  std_logic_vector(COEFF_WIDTH_B*(NO_SECTIONS)-1 downto 0);
        b2         : in  std_logic_vector(COEFF_WIDTH_B*(NO_SECTIONS)-1 downto 0);
        a1         : in  std_logic_vector(COEFF_WIDTH_A*(NO_SECTIONS)-1 downto 0);
        a2         : in  std_logic_vector(COEFF_WIDTH_A*(NO_SECTIONS)-1 downto 0);

        y          : out std_logic_vector(DATA_WIDTH-1 downto 0));
end Generic_Equalizer;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

architecture behaviour of Generic_Equalizer is

-- Type Declarations -----------------------------------------------------------
type scale_array    is array(0 to NO_SECTIONS)   of std_logic_vector(SCALE_WIDTH-1    downto 0);
type b_array        is array(0 to NO_SECTIONS-1) of std_logic_vector(COEFF_WIDTH_B*3-1  downto 0);
type a_array        is array(0 to NO_SECTIONS-1) of std_logic_vector(COEFF_WIDTH_A*2-1  downto 0);
type internal_array is array(0 to NO_SECTIONS-1) of std_logic_vector(INTERNAL_WIDTH-1 downto 0);

-- Signals ---------------------------------------------------------------------
signal s_scale      : scale_array;

signal s_b         : b_array;
signal s_a         : a_array;

signal s_iir_input  : internal_array;
signal s_iir_output : internal_array;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

begin

  -- Set coefficients
  gen_scale:
  for i in 0 to NO_SECTIONS generate
    s_scale(i) <= scale(SCALE_WIDTH*((NO_SECTIONS+1)-i)-1 downto SCALE_WIDTH*((NO_SECTIONS+1)-i-1));
  end generate;

  gen_coefficients:
  for i in 0 to NO_SECTIONS-1 generate
    s_b(i) <= b0(COEFF_WIDTH_B*(NO_SECTIONS-i)-1 downto COEFF_WIDTH_B*(NO_SECTIONS-i-1)) &
	  		  b1(COEFF_WIDTH_B*(NO_SECTIONS-i)-1 downto COEFF_WIDTH_B*(NO_SECTIONS-i-1)) &
			  b2(COEFF_WIDTH_B*(NO_SECTIONS-i)-1 downto COEFF_WIDTH_B*(NO_SECTIONS-i-1));
    s_a(i) <= a1(COEFF_WIDTH_A*(NO_SECTIONS-i)-1 downto COEFF_WIDTH_A*(NO_SECTIONS-i-1)) &
			  a2(COEFF_WIDTH_A*(NO_SECTIONS-i)-1 downto COEFF_WIDTH_A*(NO_SECTIONS-i-1));
  end generate;
  
  -- First multiplier ----------------------------------------------------------
  Multiplier_in : entity work.Multiplier
  generic map(X_WIDTH    => DATA_WIDTH,
              X_FRACTION => DATA_FRACT,
              Y_WIDTH    => SCALE_WIDTH,
              Y_FRACTION => SCALE_FRACT(0),
              S_WIDTH    => INTERNAL_WIDTH,
              S_FRACTION => INTERNAL_FRACT)
  port map(x => x,
           y => s_scale(0),
           s => s_iir_input(0));
			 
  -- Filters -------------------------------------------------------------------
  gen_filters:
  for i in 0 to NO_SECTIONS-1 generate
	Generic_IIR : entity work.Generic_IIR
	generic map(ORDER          => 2,
	            IN_WIDTH       => INTERNAL_WIDTH,
				IN_FRACT       => INTERNAL_FRACT,
				B_WIDTH        => COEFF_WIDTH_B,
				B_FRACT        => COEFF_FRACT_B(i),
				A_WIDTH        => COEFF_WIDTH_A,
				A_FRACT        => COEFF_FRACT_A(i),
				INTERNAL_WIDTH => INTERNAL_WIDTH,
				INTERNAL_FRACT => INTERNAL_FRACT,
				OUT_WIDTH      => INTERNAL_WIDTH,
				OUT_FRACT      => INTERNAL_FRACT)
	port map(clk    => clk,
			 reset  => reset,
			 x      => s_iir_input(i),
			 B      => s_b(i),
			 A      => s_a(i),
			 y      => s_iir_output(i));
  end generate;

  -- Multipliers ---------------------------------------------------------------
  gen_multipliers:
  for i in 1 to NO_SECTIONS-1 generate
    Multiplier : entity work.Multiplier
    generic map(X_WIDTH    => INTERNAL_WIDTH,
                X_FRACTION => INTERNAL_FRACT,
                Y_WIDTH    => SCALE_WIDTH,
                Y_FRACTION => SCALE_FRACT(i),
                S_WIDTH    => INTERNAL_WIDTH,
                S_FRACTION => INTERNAL_FRACT)
      port map(x => s_iir_output(i-1),
               y => s_scale(i),
               s => s_iir_input(i));
  end generate;
  
  -- Last multiplier -----------------------------------------------------------
  Multiplier_out : entity work.Multiplier
  generic map(X_WIDTH    => INTERNAL_WIDTH,
              X_FRACTION => INTERNAL_FRACT,
              Y_WIDTH    => SCALE_WIDTH,
              Y_FRACTION => SCALE_FRACT(NO_SECTIONS),
              S_WIDTH    => DATA_WIDTH,
              S_FRACTION => DATA_FRACT)
    port map(x => s_iir_output(NO_SECTIONS-1),
             y => s_scale(NO_SECTIONS),
             s => y);

end architecture;