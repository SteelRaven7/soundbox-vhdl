--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Description:                                                               --
-- This file describes the implementation of a generic equalizer. This        --
-- equaliser is made up out of N second order, direct IIR-filters with        --
-- multipliers between.                                                       --
--                                                                            --
--                                                                            --
-- Generic:                                                                   --
-- NO_SECTIONS       - The number of second order sections that the equalizer --
--                   - should be made up out of                               --
--                                                                            --
-- INPUT_WIDTH       - The width of the input data                            --
-- INPUT_FRACT       - The fractional width of the input data                 --
-- OUTPUT_WIDTH      - The width of the output data                           --
-- OUTPUT_FRACT      - The fractional width of the output data                --
--                                                                            --
-- SCALE_WIDTH       - The width of the scaling coefficients                  --
-- SCALE_FRACT       - An array of the fractional widths of the scaling       --
--                     coefficients, starting with the first multiplier       --
--                                                                            --
-- INTERNAL_WIDTH    - The width of all internal registers                    --
-- INTERNAL_FRACT    - The fractional width of all internal registers         --
--                                                                            --
-- COEFF_WIDTH_B     - The width of all B-coefficients in the IIR-filters     --
-- COEFF_FRACT_B     - An array of the fractional widths of all the           --
--                     B-coefficeints, starting with the first filter         --
-- COEFF_WIDTH_A     - The width of all A-coefficients in the IIR-filters     --
-- COEFF_FRACT_A     - An array of the fractional widths of all the           --
--                     A-coefficeints, starting with the first filter         --
--                                                                            --
-- Input/Output:                                                              --
-- clk               - System clock                                           --
-- reset             - Resets component when high                             --
-- x                 - Input                                                  --
--                                                                            --
-- scale             - An array of all the scaling factors, put the scaling   --
--                     value for the first multiplier first                   --
--                                                                            --
-- b0                - An array of all the B0-coefficients, put the           --
--                     coefficient for the first filter first                 --
-- b1                - An array of all the B1-coefficients, put the           --
--                     coefficient for the first filter first                 --
-- b2                - An array of all the B2-coefficients, put the           --
--                     coefficient for the first filter first                 --
-- a1                - An array of all the A1-coefficients, put the           --
--                     coefficient for the first filter first                 --
-- a2                - An array of all the A2-coefficients, put the           --
--                     coefficient for the first filter first                 --
--                                                                            --
-- y                 - Output                                                 --
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
			
			INPUT_WIDTH  : natural        := 8;
            INPUT_FRACT  : natural        := 6;
			OUTPUT_WIDTH : natural        := 8;
            OUTPUT_FRACT : natural        := 6;

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
        x          : in  std_logic_vector(INPUT_WIDTH-1 downto 0);

        scale      : in  std_logic_vector(SCALE_WIDTH*(NO_SECTIONS+1)-1 downto 0);

        b0         : in  std_logic_vector(COEFF_WIDTH_B*(NO_SECTIONS)-1 downto 0);
        b1         : in  std_logic_vector(COEFF_WIDTH_B*(NO_SECTIONS)-1 downto 0);
        b2         : in  std_logic_vector(COEFF_WIDTH_B*(NO_SECTIONS)-1 downto 0);
        a1         : in  std_logic_vector(COEFF_WIDTH_A*(NO_SECTIONS)-1 downto 0);
        a2         : in  std_logic_vector(COEFF_WIDTH_A*(NO_SECTIONS)-1 downto 0);

        y          : out std_logic_vector(OUTPUT_WIDTH-1 downto 0));
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
  Multiplier_in : entity work.Multiplier_Saturate
  generic map(X_WIDTH    => INPUT_WIDTH,
              X_FRACTION => INPUT_FRACT,
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
    Multiplier : entity work.Multiplier_Saturate
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
  Multiplier_out : entity work.Multiplier_Saturate
  generic map(X_WIDTH    => INTERNAL_WIDTH,
              X_FRACTION => INTERNAL_FRACT,
              Y_WIDTH    => SCALE_WIDTH,
              Y_FRACTION => SCALE_FRACT(NO_SECTIONS),
              S_WIDTH    => OUTPUT_WIDTH,
              S_FRACTION => OUTPUT_FRACT)
    port map(x => s_iir_output(NO_SECTIONS-1),
             y => s_scale(NO_SECTIONS),
             s => y);

end architecture;