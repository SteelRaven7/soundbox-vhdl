--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Description:                                                               --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

entity Generic_Equalizer_Low_Pass is
  port(clk    : in  std_logic;
       reset  : in  std_logic;
       input  : in  std_logic_vector(15 downto 0);
       output : out std_logic_vector(15 downto 0));
end Generic_Equalizer_Low_Pass;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

architecture behaviour of Generic_Equalizer_Low_Pass is
begin

  Generic_Equalizer : entity work.Generic_Equalizer
  generic map(NO_SECTIONS    => 9,
			
              INPUT_WIDTH    => 16,
              INPUT_FRACT    => 14,
              OUTPUT_WIDTH   => 16,
              OUTPUT_FRACT   => 14,

              SCALE_WIDTH    => 16,
              SCALE_FRACT    => (14,14,14,14,14,14,14,14,14,14),

              INTERNAL_WIDTH => 30,
              INTERNAL_FRACT => 24,

              COEFF_WIDTH_B  => 16,
              COEFF_FRACT_B  => (16,14,14,14,14,14,14,14,14),
              COEFF_WIDTH_A  => 16,
              COEFF_FRACT_A  => (14,14,14,14,14,14,14,14,14))
   port map(clk        => clk,
            reset      => reset,
            x          => input,

            scale      => (x"4000" 
			             & x"4000" 
						 & x"4000" 
						 & x"4000" 
						 & x"4000" 
						 & x"4000" 
						 & x"4000" 
						 & x"4000" 
						 & x"4000" 
						 & x"4000"),

            b0         => (x"3e74" 
			             & x"4000"  
						 & x"4000" 
						 & x"4000" 
						 & x"4000" 
						 & x"4000" 
						 & x"4000" 
						 & x"4000"
						 & x"4000"),
            b1         => (x"8a7f" 
			             & x"0000"
			             & x"0000"
			             & x"0000"
			             & x"0000"
			             & x"0000"
			             & x"0000"
			             & x"0000" 
						 & x"0000"),
            b2         => (x"3777" 
			             & x"0000"
			             & x"0000"
			             & x"0000"
			             & x"0000"
			             & x"0000"
			             & x"0000"
			             & x"0000" 
						 & x"0000"),
            a1         => (x"754C" 
			             & x"0000"
			             & x"0000"
			             & x"0000"
			             & x"0000"
			             & x"0000"
			             & x"0000"
			             & x"0000" 
						 & x"0000"),
            a2         => (x"C9E0"
			             & x"0000"
			             & x"0000"
			             & x"0000"
			             & x"0000"
			             & x"0000"
			             & x"0000"
			             & x"0000" 
						 & x"0000"),

            y          => output);

end architecture;