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
use work.memory_pkg.all;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

entity Generic_Equalizer_Low_Pass is
  port(clk        : in  std_logic;
       reset      : in  std_logic;
       config_bus : in  configurableRegisterBus;
       input      : in  std_logic_vector(15 downto 0);
       output     : out std_logic_vector(15 downto 0));
end Generic_Equalizer_Low_Pass;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

architecture behaviour of Generic_Equalizer_Low_Pass is
begin

  Generic_Equalizer : entity work.Generic_Equalizer
  generic map(NO_SECTIONS    => 16,
			
              INPUT_WIDTH    => 16,
              INPUT_FRACT    => 15,
              OUTPUT_WIDTH   => 16,
              OUTPUT_FRACT   => 15,

              SCALE_WIDTH    => 20,
              SCALE_FRACT    => (16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16),

              INTERNAL_WIDTH => 20,
              INTERNAL_FRACT => 16,

              COEFF_WIDTH_B  => 20,
              COEFF_FRACT_B  => (16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16),
              COEFF_WIDTH_A  => 20,
              COEFF_FRACT_A  => (16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16))
   port map(clk         => clk,
            reset       => reset,
            x           => input,

            config_bus  => config_bus,
		
            band_1_gain => 3,
            band_2_gain => 3,
            band_3_gain => 2,
            band_4_gain => 1,
            band_5_gain => 1,

            y           => output);

end architecture;