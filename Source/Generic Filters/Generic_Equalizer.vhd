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
-- write_mode        - Write new coefficients when high                       --
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
use work.memory_pkg.all;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

entity Generic_Equalizer is
   generic (NO_SECTIONS : natural         := 16;
            
            INPUT_WIDTH  : natural        := 16;
            INPUT_FRACT  : natural        := 15;
            OUTPUT_WIDTH : natural        := 16;
            OUTPUT_FRACT : natural        := 15;

            SCALE_WIDTH : natural         := 20;
            SCALE_FRACT : natural_array   := (16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16);

            INTERNAL_WIDTH : natural      := 20;
            INTERNAL_FRACT : natural      := 16;

            COEFF_WIDTH_B : natural       := 20;
            COEFF_FRACT_B : natural_array := (16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16);
            COEFF_WIDTH_A : natural       := 20;
            COEFF_FRACT_A : natural_array := (16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16));
   port(clk         : in  std_logic;
        reset       : in  std_logic;
        x           : in  std_logic_vector(INPUT_WIDTH-1 downto 0);

        config_bus  : in configurableRegisterBus;
        
        band_1_gain : in  natural range 0 to 4;
        band_2_gain : in  natural range 0 to 4;
        band_3_gain : in  natural range 0 to 4;
        band_4_gain : in  natural range 0 to 4;
        band_5_gain : in  natural range 0 to 4;

        y           : out std_logic_vector(OUTPUT_WIDTH-1 downto 0));
end Generic_Equalizer;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

architecture behaviour of Generic_Equalizer is

  -- Type Declarations ---------------------------------------------------------
  type coeff_array_low  is array(0 to 484)           of std_logic_vector(15                downto 0);
  type coeff_array_high is array(0 to 484)           of std_logic_vector(19                downto 16);
  type coeff_array      is array(0 to 484)           of std_logic_vector(19                downto 0);
  type scale_array      is array(0 to NO_SECTIONS)   of std_logic_vector(SCALE_WIDTH-1     downto 0);
  type b_array          is array(0 to NO_SECTIONS-1) of std_logic_vector(COEFF_WIDTH_B*3-1 downto 0);
  type a_array          is array(0 to NO_SECTIONS-1) of std_logic_vector(COEFF_WIDTH_A*2-1 downto 0);
  type internal_array   is array(0 to NO_SECTIONS-1) of std_logic_vector(INTERNAL_WIDTH-1  downto 0);

-- Signals -------------------------------------------------------------------
  signal s_coeff_array_low  : coeff_array_low;
  signal s_coeff_array_high : coeff_array_high;
  signal s_coeff_array      : coeff_array;

  signal scale : std_logic_vector(SCALE_WIDTH  *(NO_SECTIONS+1)-1 downto 0);
  signal b0    : std_logic_vector(COEFF_WIDTH_B*(NO_SECTIONS)  -1 downto 0);
  signal b1    : std_logic_vector(COEFF_WIDTH_B*(NO_SECTIONS)  -1 downto 0);
  signal b2    : std_logic_vector(COEFF_WIDTH_B*(NO_SECTIONS)  -1 downto 0);
  signal a1    : std_logic_vector(COEFF_WIDTH_A*(NO_SECTIONS)  -1 downto 0);
  signal a2    : std_logic_vector(COEFF_WIDTH_A*(NO_SECTIONS)  -1 downto 0);

  signal s_scale : scale_array;
  signal s_b     : b_array;
  signal s_a     : a_array;

  signal s_iir_input  : internal_array;
  signal s_iir_output : internal_array;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

begin
  
  -- Import coefficients
  coefficient_registers:
  for i in 0 to 484 generate
    config_register_lower : entity work.ConfigRegister
      generic map(wordLength => 16,
                  address    => 2*i+12)
      port map(input  => config_bus,
               output => s_coeff_array_low(i),
               reset  => reset);
        
    config_register_upper : entity work.ConfigRegister
      generic map(wordLength => 4,
                  address    => 2*i+13)
      port map(input  => config_bus,
               output => s_coeff_array_high(i),
               reset  => reset);

    s_coeff_array(i) <= s_coeff_array_high(i) & s_coeff_array_low(i);
  end generate;
  
  -- Choose coefficients (Offset + amplification * amplification_memory_size)
  gen_choice:
  for i in 0 to NO_SECTIONS generate
    scale <= s_coeff_array(0  + 194 * band_1_gain) &
             s_coeff_array(1  + 194 * band_1_gain) &
             s_coeff_array(2  + 194 * band_2_gain) &
             s_coeff_array(3  + 194 * band_2_gain) &
             s_coeff_array(4  + 194 * band_2_gain) &
             s_coeff_array(5  + 194 * band_2_gain) &
             s_coeff_array(6  + 194 * band_3_gain) &
             s_coeff_array(7  + 194 * band_3_gain) &
             s_coeff_array(8  + 194 * band_3_gain) &
             s_coeff_array(9  + 194 * band_3_gain) &
             s_coeff_array(10 + 194 * band_4_gain) &
             s_coeff_array(11 + 194 * band_4_gain) &
             s_coeff_array(12 + 194 * band_4_gain) &
             s_coeff_array(13 + 194 * band_4_gain) &
             s_coeff_array(14 + 194 * band_5_gain) &
             s_coeff_array(15 + 194 * band_5_gain) &
             s_coeff_array(16 + 194 * band_5_gain);
    b0 <= s_coeff_array(17 + 194 * band_1_gain) &
          s_coeff_array(18 + 194 * band_1_gain) &
          s_coeff_array(19 + 194 * band_2_gain) &
          s_coeff_array(20 + 194 * band_2_gain) &
          s_coeff_array(21 + 194 * band_2_gain) &
          s_coeff_array(22 + 194 * band_2_gain) &
          s_coeff_array(23 + 194 * band_3_gain) &
          s_coeff_array(24 + 194 * band_3_gain) &
          s_coeff_array(25 + 194 * band_3_gain) &
          s_coeff_array(26 + 194 * band_3_gain) &
          s_coeff_array(27 + 194 * band_4_gain) &
          s_coeff_array(28 + 194 * band_4_gain) &
          s_coeff_array(29 + 194 * band_4_gain) &
          s_coeff_array(30 + 194 * band_4_gain) &
          s_coeff_array(31 + 194 * band_5_gain) &
          s_coeff_array(32 + 194 * band_5_gain);
    b1 <= s_coeff_array(33 + 194 * band_1_gain) &
          s_coeff_array(34 + 194 * band_1_gain) &
          s_coeff_array(35 + 194 * band_2_gain) &
          s_coeff_array(36 + 194 * band_2_gain) &
          s_coeff_array(37 + 194 * band_2_gain) &
          s_coeff_array(38 + 194 * band_2_gain) &
          s_coeff_array(39 + 194 * band_3_gain) &
          s_coeff_array(40 + 194 * band_3_gain) &
          s_coeff_array(41 + 194 * band_3_gain) &
          s_coeff_array(42 + 194 * band_3_gain) &
          s_coeff_array(43 + 194 * band_4_gain) &
          s_coeff_array(44 + 194 * band_4_gain) &
          s_coeff_array(45 + 194 * band_4_gain) &
          s_coeff_array(46 + 194 * band_4_gain) &
          s_coeff_array(47 + 194 * band_5_gain) &
          s_coeff_array(48 + 194 * band_5_gain);
    b2 <= s_coeff_array(49 + 194 * band_1_gain) &
          s_coeff_array(50 + 194 * band_1_gain) &
          s_coeff_array(51 + 194 * band_2_gain) &
          s_coeff_array(52 + 194 * band_2_gain) &
          s_coeff_array(53 + 194 * band_2_gain) &
          s_coeff_array(54 + 194 * band_2_gain) &
          s_coeff_array(55 + 194 * band_3_gain) &
          s_coeff_array(56 + 194 * band_3_gain) &
          s_coeff_array(57 + 194 * band_3_gain) &
          s_coeff_array(58 + 194 * band_3_gain) &
          s_coeff_array(59 + 194 * band_4_gain) &
          s_coeff_array(60 + 194 * band_4_gain) &
          s_coeff_array(61 + 194 * band_4_gain) &
          s_coeff_array(62 + 194 * band_4_gain) &
          s_coeff_array(63 + 194 * band_5_gain) &
          s_coeff_array(64 + 194 * band_5_gain);
    a1 <= s_coeff_array(65 + 194 * band_1_gain) &
          s_coeff_array(66 + 194 * band_1_gain) &
          s_coeff_array(67 + 194 * band_2_gain) &
          s_coeff_array(68 + 194 * band_2_gain) &
          s_coeff_array(69 + 194 * band_2_gain) &
          s_coeff_array(70 + 194 * band_2_gain) &
          s_coeff_array(71 + 194 * band_3_gain) &
          s_coeff_array(72 + 194 * band_3_gain) &
          s_coeff_array(73 + 194 * band_3_gain) &
          s_coeff_array(74 + 194 * band_3_gain) &
          s_coeff_array(75 + 194 * band_4_gain) &
          s_coeff_array(76 + 194 * band_4_gain) &
          s_coeff_array(77 + 194 * band_4_gain) &
          s_coeff_array(78 + 194 * band_4_gain) &
          s_coeff_array(79 + 194 * band_5_gain) &
          s_coeff_array(80 + 194 * band_5_gain);
    a2 <= s_coeff_array(81 + 194 * band_1_gain) &
          s_coeff_array(82 + 194 * band_1_gain) &
          s_coeff_array(83 + 194 * band_2_gain) &
          s_coeff_array(84 + 194 * band_2_gain) &
          s_coeff_array(85 + 194 * band_2_gain) &
          s_coeff_array(86 + 194 * band_2_gain) &
          s_coeff_array(87 + 194 * band_3_gain) &
          s_coeff_array(88 + 194 * band_3_gain) &
          s_coeff_array(89 + 194 * band_3_gain) &
          s_coeff_array(90 + 194 * band_3_gain) &
          s_coeff_array(91 + 194 * band_4_gain) &
          s_coeff_array(92 + 194 * band_4_gain) &
          s_coeff_array(93 + 194 * band_4_gain) &
          s_coeff_array(94 + 194 * band_4_gain) &
          s_coeff_array(95 + 194 * band_5_gain) &
          s_coeff_array(96 + 194 * band_5_gain);
  end generate;
  
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