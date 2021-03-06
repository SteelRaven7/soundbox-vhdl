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

entity Generic_Equalizer_Debugger is
  port(clk    : in  std_logic;
       reset  : in  std_logic;
       input  : in  std_logic_vector(15 downto 0);
       output : out std_logic_vector(15 downto 0));
end Generic_Equalizer_Debugger;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

architecture behaviour of Generic_Equalizer_Debugger is
begin

  Generic_Equalizer : entity work.Generic_Equalizer
  generic map(NO_SECTIONS    => 9,
			
              INPUT_WIDTH    => 16,
              INPUT_FRACT    => 14,
              OUTPUT_WIDTH   => 16,
              OUTPUT_FRACT   => 14,

              SCALE_WIDTH    => 16,
              SCALE_FRACT    => (14,14,14,14,14,14,14,14,14,14),

              INTERNAL_WIDTH => 16,
              INTERNAL_FRACT => 14,

              COEFF_WIDTH_B  => 16,
              COEFF_FRACT_B  => (14,14,14,14,14,14,14,14,14),
              COEFF_WIDTH_A  => 16,
              COEFF_FRACT_A  => (14,14,14,14,14,14,14,14,14))
   port map(clk        => clk,
            reset      => reset,
            x          => input,

            scale      => (x"4000" 
			             & x"4001" 
						 & x"4002" 
						 & x"4003" 
						 & x"4004" 
						 & x"4005" 
						 & x"4006" 
						 & x"4007" 
						 & x"4008" 
						 & x"4009"),

            b0         => (x"4010" 
			             & x"4011"  
						 & x"4012" 
						 & x"4013" 
						 & x"4014" 
						 & x"4015" 
						 & x"4016" 
						 & x"4017"
						 & x"4018"),
            b1         => (x"4020" 
			             & x"0021"
			             & x"0022"
			             & x"0023"
			             & x"0024"
			             & x"0025"
			             & x"0026"
			             & x"0027" 
						 & x"0028"),
            b2         => (x"4030" 
			             & x"0031"
			             & x"0032"
			             & x"0033"
			             & x"0034"
			             & x"0035"
			             & x"0036"
			             & x"0037" 
						 & x"0038"),
            a1         => (x"4040" 
			             & x"0041"
			             & x"0042"
			             & x"0043"
			             & x"0044"
			             & x"0045"
			             & x"0046"
			             & x"0047" 
						 & x"0048"),
            a2         => (x"4050"
			             & x"0051"
			             & x"0052"
			             & x"0053"
			             & x"0054"
			             & x"0055"
			             & x"0056"
			             & x"0057" 
						 & x"0058"),

            y          => output);

end architecture;