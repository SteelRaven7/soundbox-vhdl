--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Description:                                                               --
-- This file initiates a equalizer and sends i the correct coefficients       --
-- depending on what bands the user currently want to enhance                 --
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
-- b_1_gain          - A value between 0 and 4 indicating what gain the user  --
--                     wants on the lowest band                               --
-- b_2_gain          - A value between 0 and 4 indicating what gain the user  --
--                     wants on the second to lowest band                     --
-- b_3_gain          - A value between 0 and 4 indicating what gain the user  --
--                     wants on the middle band                               --
-- b_4_gain          - A value between 0 and 4 indicating what gain the user  --
--                     wants on the second to highest band                    --
-- b_5_gain          - A value between 0 and 4 indicating what gain the user  --
--                     wants on the highest band                              --
--                                                                            --
-- y                 - Output                                                 --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all ;
use work.filter_pkg.all;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

entity Equalizer is
  generic (NO_SECTIONS    : natural       := 16;
      
           INPUT_WIDTH    : natural       := 16;
           INPUT_FRACT    : natural       := 15;
           OUTPUT_WIDTH   : natural       := 16;
           OUTPUT_FRACT   : natural       := 15;

           SCALE_WIDTH    : natural       := 20;
           SCALE_FRACT    : natural_array := (16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16);

           INTERNAL_WIDTH : natural       := 30;
           INTERNAL_FRACT : natural       := 24;

           COEFF_WIDTH_B  : natural       := 20;
           COEFF_FRACT_B  : natural_array := (16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16);
           COEFF_WIDTH_A  : natural       := 20;
           COEFF_FRACT_A  : natural_array := (16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16));
  port (clk      : in  std_logic;
        reset    : in  std_logic;
        x        : in  std_logic_vector(INPUT_WIDTH-1 downto 0);

        b_1_gain : in std_logic_vector(2 downto 0);
        b_2_gain : in std_logic_vector(2 downto 0);
        b_3_gain : in std_logic_vector(2 downto 0);
        b_4_gain : in std_logic_vector(2 downto 0);
        b_5_gain : in std_logic_vector(2 downto 0);

        y        : out std_logic_vector(OUTPUT_WIDTH-1 downto 0));
end Equalizer;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

architecture arch of Equalizer is

-- Type Declarations -----------------------------------------------------------
  type coeff_array is array(0 to 484) of std_logic_vector(19 downto 0);

-- Constants -------------------------------------------------------------------
  constant s_coeff_array : coeff_array :=  -- -6db scale, Equalizer 1
                                          (x"10000" , x"10000" , x"3fb91" , x"10000" , x"10000" , x"10000" , x"3fb28" , x"10000" , x"10000" , x"10000" , x"3fb28" , x"10000" , x"10000" , x"10000" , x"3fb28" , x"10000" , x"3fb91" ,
                                           -- -6db B0
                                           x"07977" , x"08a72" , x"08182" , x"0df46" , x"0b919" , x"0ce17" , x"08284" , x"0df2d" , x"0bafe" , x"0cf0c" , x"08438" , x"0dfe1" , x"0a7a9" , x"0ed84" , x"0ba4a" , x"10201" ,
                                           -- -6db B1
                                           x"f110a" , x"ef955" , x"f029d" , x"e462b" , x"e9aad" , x"e6ebf" , x"f0a66" , x"e4dae" , x"ea7a6" , x"e7a9d" , x"f24dc" , x"e608e" , x"edf5b" , x"e7eef" , x"ef988" , x"ed7fc" ,
                                           -- -6db B2
                                           x"075dd" , x"07cb4" , x"07de5" , x"0dbb2" , x"0ae4a" , x"0c497" , x"07b67" , x"0d7ff" , x"0a5dc" , x"0bc4a" , x"07654" , x"0d1b1" , x"08a87" , x"0babb" , x"087d2" , x"05ddf" ,
                                           -- -6db A1
                                           x"e0655" , x"e113a" , x"e082d" , x"e04c1" , x"e0d02" , x"e0aac" , x"e1779" , x"e0cfc" , x"e1f3b" , x"e1948" , x"e4753" , x"e254b" , x"e4f86" , x"e3f0a" , x"ed062" , x"f3244" ,
                                           -- -6db A2
                                           x"0fa22" , x"0ef29" , x"0fb3a" , x"0fcc8" , x"0f5ab" , x"0f73e" , x"0f69a" , x"0f98e" , x"0ebcc" , x"0eeb7" , x"0eda2" , x"0f33d" , x"0d91d" , x"0de77" , x"0adc7" , x"036e6" ,
                                           -- -3db scale, Equalizer 2
                                           x"10000" , x"10000" , x"1fedf" , x"10000" , x"10000" , x"10000" , x"1feca" , x"10000" , x"10000" , x"10000" , x"1feca" , x"10000" , x"10000" , x"10000" , x"1feca" , x"10000" , x"1fedf" ,
                                           -- -3db B0
                                           x"0afbd" , x"0bce9" , x"0b551" , x"0ef51" , x"0da21" , x"0e5f3" , x"0b605" , x"0ef42" , x"0db3e" , x"0e67c" , x"0b731" , x"0efa2" , x"0dd23" , x"0e7be" , x"0d9d5" , x"101b2" ,
                                           -- -3db B1
                                           x"ea5f4" , x"e97b5" , x"e9ca2" , x"e2644" , x"e59bb" , x"e3f96" , x"ea812" , x"e2e32" , x"e69f8" , x"e4d41" , x"eccf8" , x"e436f" , x"e9537" , x"e6f0c" , x"ed88b" , x"eecf5" ,
                                           -- -3db B2
                                           x"0aac7" , x"0abea" , x"0b0c0" , x"0ebb2" , x"0ce87" , x"0dc17" , x"0ad0a" , x"0e7fd" , x"0c49a" , x"0d30c" , x"0a5b4" , x"0e147" , x"0b1b8" , x"0c223" , x"09b4f" , x"05336" ,
                                           -- -3db A1
                                           x"e06e1" , x"e133b" , x"e08cb" , x"e04ea" , x"e0e09" , x"e0b55" , x"e18e8" , x"e0d30" , x"e2140" , x"e1a7e" , x"e4acd" , x"e253d" , x"e5355" , x"e40f5" , x"ec167" , x"f1aa6" ,
                                           -- -3db A2
                                           x"0f9a7" , x"0ed3e" , x"0faba" , x"0fc92" , x"0f4ae" , x"0f68d" , x"0f5a3" , x"0f91f" , x"0e9e8" , x"0ed5d" , x"0ebcd" , x"0f266" , x"0d5a3" , x"0dbf0" , x"0aff8" , x"03f6a" ,
                                           -- 0db scale, Equalizer 3
                                           x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" ,
                                           -- 0db B0
                                           x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" ,
                                           -- 0db B0
                                           x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" ,
                                           -- 0db B2
                                           x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" ,
                                           -- 0db A0
                                           x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" ,
                                           -- 0db A2
                                           x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" , x"00000" ,
                                           -- 3db scale, Equalizer 4
                                           x"10000" , x"10000" , x"1121d" , x"10000" , x"10000" , x"10000" , x"10980" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"10000" , x"1000b" ,
                                           -- 3db B0
                                           x"0e39f" , x"109fe" , x"0e5f4" , x"1027b" , x"10737" , x"105cb" , x"0e51b" , x"106c5" , x"109b7" , x"106a2" , x"0e391" , x"1086b" , x"10567" , x"10545" , x"0b7a2" , x"0d0c2" ,
                                           -- 3db B1
                                           x"e3ee0" , x"e0000" , x"e3bff" , x"e0000" , x"e0000" , x"e0000" , x"e4c15" , x"e0000" , x"e0f15" , x"e0de9" , x"e7b5c" , x"e15a1" , x"e4a4a" , x"e37c1" , x"f1b77" , x"f44f9" ,
                                           -- 3db B2
                                           x"0ddfa" , x"0f681" , x"0e137" , x"0ff04" , x"0fb93" , x"0fc21" , x"0dbd4" , x"0ffb5" , x"0f2c8" , x"0f384" , x"0d19d" , x"0fa5e" , x"0da25" , x"0e077" , x"07e3a" , x"033b6" ,
                                           -- 3db A1
                                           x"e07ea" , x"e17c1" , x"e0a42" , x"e053e" , x"e106b" , x"e0cc8" , x"e1c48" , x"e0d99" , x"e25e6" , x"e1d20" , x"e52f1" , x"e2512" , x"e5c05" , x"e4514" , x"ea4c6" , x"eeec5" ,
                                           -- 3db A2
                                           x"0f8c6" , x"0e8f9" , x"0f98e" , x"0fc20" , x"0f262" , x"0f507" , x"0f35f" , x"0f839" , x"0e590" , x"0ea69" , x"0e78f" , x"0f0a9" , x"0cdbd" , x"0d675" , x"0b685" , x"052aa" ,
                                           -- 6db scale, Equalizer 5
                                           x"10000" , x"10000" , x"130cd" , x"10000" , x"10000" , x"10000" , x"122e1" , x"10000" , x"10000" , x"10000" , x"107c1" , x"10000" , x"10000" , x"10000" , x"19667" , x"10000" , x"1001b" ,
                                           -- 6db B0
                                           x"0cb50" , x"108ea" , x"0d057" , x"10266" , x"106ac" , x"10573" , x"0cecd" , x"106a9" , x"110a1" , x"10d4c" , x"0cc02" , x"11087" , x"0988d" , x"123f2" , x"0848e" , x"0a933" ,
                                           -- 6db B1
                                           x"e6e67" , x"e0000" , x"e65fa" , x"e0000" , x"e0000" , x"e0000" , x"e755d" , x"e0000" , x"e0000" , x"e0000" , x"ea0d2" , x"e06a5" , x"efe49" , x"e0000" , x"f62ca" , x"f7805" ,
                                           -- 6db B2
                                           x"0c6a7" , x"0f77c" , x"0cc74" , x"0ff27" , x"0fc13" , x"0fc82" , x"0c735" , x"1000c" , x"0fb1d" , x"0fb1e" , x"0bd5f" , x"102f1" , x"08161" , x"0fdb4" , x"059fb" , x"02449" ,
                                           -- 6db A1
                                           x"e085f" , x"e1a4e" , x"e0b1f" , x"e0568" , x"e11cd" , x"e0d91" , x"e1e45" , x"e0dcc" , x"e2893" , x"e1e8c" , x"e57b3" , x"e24f3" , x"e4745" , x"e60f7" , x"e9750" , x"eda48" ,
                                           -- 6db A2
                                           x"0f869" , x"0e696" , x"0f8dd" , x"0fbe6" , x"0f10e" , x"0f433" , x"0f20d" , x"0f7c4" , x"0e310" , x"0e8cf" , x"0e51c" , x"0efc7" , x"0d384" , x"0c943" , x"0baa5" , x"05d25");

-- Signals --------------------------------------------------------------------
  signal band_1_gain : natural range 0 to 4;
  signal band_2_gain : natural range 0 to 4;
  signal band_3_gain : natural range 0 to 4;
  signal band_4_gain : natural range 0 to 4;
  signal band_5_gain : natural range 0 to 4;

  signal scale : std_logic_vector(SCALE_WIDTH  *(NO_SECTIONS+1)-1 downto 0);
  signal b0    : std_logic_vector(COEFF_WIDTH_B*(NO_SECTIONS  )-1 downto 0);
  signal b1    : std_logic_vector(COEFF_WIDTH_B*(NO_SECTIONS  )-1 downto 0);
  signal b2    : std_logic_vector(COEFF_WIDTH_B*(NO_SECTIONS  )-1 downto 0);
  signal a1    : std_logic_vector(COEFF_WIDTH_A*(NO_SECTIONS  )-1 downto 0);
  signal a2    : std_logic_vector(COEFF_WIDTH_A*(NO_SECTIONS  )-1 downto 0);

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

begin

  -- Convert gains to naturals
  band_1_gain <= to_integer(unsigned(b_1_gain)) when to_integer(unsigned(b_1_gain)) <= 4 else 4;
  band_2_gain <= to_integer(unsigned(b_2_gain)) when to_integer(unsigned(b_2_gain)) <= 4 else 4;
  band_3_gain <= to_integer(unsigned(b_3_gain)) when to_integer(unsigned(b_3_gain)) <= 4 else 4;
  band_4_gain <= to_integer(unsigned(b_4_gain)) when to_integer(unsigned(b_4_gain)) <= 4 else 4;
  band_5_gain <= to_integer(unsigned(b_5_gain)) when to_integer(unsigned(b_5_gain)) <= 4 else 4;

  -- Choose correct coefficients
  scale <= s_coeff_array(0  + 97 * band_1_gain) &
           s_coeff_array(1  + 97 * band_1_gain) &
           s_coeff_array(2  + 97 * band_2_gain) &
           s_coeff_array(3  + 97 * band_2_gain) &
           s_coeff_array(4  + 97 * band_2_gain) &
           s_coeff_array(5  + 97 * band_2_gain) &
           s_coeff_array(6  + 97 * band_3_gain) &
           s_coeff_array(7  + 97 * band_3_gain) &
           s_coeff_array(8  + 97 * band_3_gain) &
           s_coeff_array(9  + 97 * band_3_gain) &
           s_coeff_array(10 + 97 * band_4_gain) &
           s_coeff_array(11 + 97 * band_4_gain) &
           s_coeff_array(12 + 97 * band_4_gain) &
           s_coeff_array(13 + 97 * band_4_gain) &
           s_coeff_array(14 + 97 * band_5_gain) &
           s_coeff_array(15 + 97 * band_5_gain) &
           s_coeff_array(16 + 97 * band_5_gain);
  b0 <= s_coeff_array(17 + 97 * band_1_gain) &
        s_coeff_array(18 + 97 * band_1_gain) &
        s_coeff_array(19 + 97 * band_2_gain) &
        s_coeff_array(20 + 97 * band_2_gain) &
        s_coeff_array(21 + 97 * band_2_gain) &
        s_coeff_array(22 + 97 * band_2_gain) &
        s_coeff_array(23 + 97 * band_3_gain) &
        s_coeff_array(24 + 97 * band_3_gain) &
        s_coeff_array(25 + 97 * band_3_gain) &
        s_coeff_array(26 + 97 * band_3_gain) &
        s_coeff_array(27 + 97 * band_4_gain) &
        s_coeff_array(28 + 97 * band_4_gain) &
        s_coeff_array(29 + 97 * band_4_gain) &
        s_coeff_array(30 + 97 * band_4_gain) &
        s_coeff_array(31 + 97 * band_5_gain) &
        s_coeff_array(32 + 97 * band_5_gain);
  b1 <= s_coeff_array(33 + 97 * band_1_gain) &
        s_coeff_array(34 + 97 * band_1_gain) &
        s_coeff_array(35 + 97 * band_2_gain) &
        s_coeff_array(36 + 97 * band_2_gain) &
        s_coeff_array(37 + 97 * band_2_gain) &
        s_coeff_array(38 + 97 * band_2_gain) &
        s_coeff_array(39 + 97 * band_3_gain) &
        s_coeff_array(40 + 97 * band_3_gain) &
        s_coeff_array(41 + 97 * band_3_gain) &
        s_coeff_array(42 + 97 * band_3_gain) &
        s_coeff_array(43 + 97 * band_4_gain) &
        s_coeff_array(44 + 97 * band_4_gain) &
        s_coeff_array(45 + 97 * band_4_gain) &
        s_coeff_array(46 + 97 * band_4_gain) &
        s_coeff_array(47 + 97 * band_5_gain) &
        s_coeff_array(48 + 97 * band_5_gain);
  b2 <= s_coeff_array(49 + 97 * band_1_gain) &
        s_coeff_array(50 + 97 * band_1_gain) &
        s_coeff_array(51 + 97 * band_2_gain) &
        s_coeff_array(52 + 97 * band_2_gain) &
        s_coeff_array(53 + 97 * band_2_gain) &
        s_coeff_array(54 + 97 * band_2_gain) &
        s_coeff_array(55 + 97 * band_3_gain) &
        s_coeff_array(56 + 97 * band_3_gain) &
        s_coeff_array(57 + 97 * band_3_gain) &
        s_coeff_array(58 + 97 * band_3_gain) &
        s_coeff_array(59 + 97 * band_4_gain) &
        s_coeff_array(60 + 97 * band_4_gain) &
        s_coeff_array(61 + 97 * band_4_gain) &
        s_coeff_array(62 + 97 * band_4_gain) &
        s_coeff_array(63 + 97 * band_5_gain) &
        s_coeff_array(64 + 97 * band_5_gain);
  a1 <= s_coeff_array(65 + 97 * band_1_gain) &
        s_coeff_array(66 + 97 * band_1_gain) &
        s_coeff_array(67 + 97 * band_2_gain) &
        s_coeff_array(68 + 97 * band_2_gain) &
        s_coeff_array(69 + 97 * band_2_gain) &
        s_coeff_array(70 + 97 * band_2_gain) &
        s_coeff_array(71 + 97 * band_3_gain) &
        s_coeff_array(72 + 97 * band_3_gain) &
        s_coeff_array(73 + 97 * band_3_gain) &
        s_coeff_array(74 + 97 * band_3_gain) &
        s_coeff_array(75 + 97 * band_4_gain) &
        s_coeff_array(76 + 97 * band_4_gain) &
        s_coeff_array(77 + 97 * band_4_gain) &
        s_coeff_array(78 + 97 * band_4_gain) &
        s_coeff_array(79 + 97 * band_5_gain) &
        s_coeff_array(80 + 97 * band_5_gain);
  a2 <= s_coeff_array(81 + 97 * band_1_gain) &
        s_coeff_array(82 + 97 * band_1_gain) &
        s_coeff_array(83 + 97 * band_2_gain) &
        s_coeff_array(84 + 97 * band_2_gain) &
        s_coeff_array(85 + 97 * band_2_gain) &
        s_coeff_array(86 + 97 * band_2_gain) &
        s_coeff_array(87 + 97 * band_3_gain) &
        s_coeff_array(88 + 97 * band_3_gain) &
        s_coeff_array(89 + 97 * band_3_gain) &
        s_coeff_array(90 + 97 * band_3_gain) &
        s_coeff_array(91 + 97 * band_4_gain) &
        s_coeff_array(92 + 97 * band_4_gain) &
        s_coeff_array(93 + 97 * band_4_gain) &
        s_coeff_array(94 + 97 * band_4_gain) &
        s_coeff_array(95 + 97 * band_5_gain) &
        s_coeff_array(96 + 97 * band_5_gain);

  -- Initiate a equalizer
  eq: entity work.Generic_Equalizer
  generic map (NO_SECTIONS    => NO_SECTIONS,

               INPUT_WIDTH    => INPUT_WIDTH, 
               INPUT_FRACT    => INPUT_FRACT,
               OUTPUT_WIDTH   => OUTPUT_WIDTH,
               OUTPUT_FRACT   => OUTPUT_FRACT,

               SCALE_WIDTH    => SCALE_WIDTH,
               SCALE_FRACT    => SCALE_FRACT,

               INTERNAL_WIDTH => INTERNAL_WIDTH,
               INTERNAL_FRACT => INTERNAL_FRACT,

               COEFF_WIDTH_B  => COEFF_WIDTH_B,
               COEFF_FRACT_B  => COEFF_FRACT_B,
               COEFF_WIDTH_A  => COEFF_WIDTH_A,
               COEFF_FRACT_A  => COEFF_FRACT_A)
  port map (clk   => clk,
            reset => reset,
            x     => x,

            scale => scale,
            b0    => b0,
            b1    => b1,
            b2    => b2,
            a1    => a1,
            a2    => a2,

            y     => y);

end architecture ; -- arch