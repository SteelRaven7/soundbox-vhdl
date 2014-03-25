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

entity Equalizer_No_Change_Test is
  port(clk    : in  std_logic;
       reset  : in  std_logic;
       input  : in  std_logic_vector(15 downto 0);
       output : out std_logic_vector(15 downto 0));
end Equalizer_No_Change_Test;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

architecture behaviour of Equalizer_No_Change_Test is

  signal write_mode : std_logic;

begin

  process(clk, reset)
  begin
    if(rising_edge(clk)) then
	  if(reset = '1') then
	    write_mode <= '1';
	  else
	    write_mode <= '0';
	  end if;
	end if;
  end process;

  Equalizer : entity work.Equalizer
  generic map(DATA_WIDTH    => 16,
              DATA_FRACT    => 15,

              SCALE_WIDTH_1 => 16,
              SCALE_FRACT_1 => 14,
              SCALE_WIDTH_2 => 16,
              SCALE_FRACT_2 => 14,
              SCALE_WIDTH_3 => 16,
              SCALE_FRACT_3 => 14,
              SCALE_WIDTH_4 => 16,
              SCALE_FRACT_4 => 14,

              INTERNAL_IIR_WIDTH_1 => 24,
              INTERNAL_IIR_FRACT_1 => 20,
              INTERNAL_IIR_WIDTH_2 => 24,
              INTERNAL_IIR_FRACT_2 => 20,
              INTERNAL_IIR_WIDTH_3 => 24,
              INTERNAL_IIR_FRACT_3 => 20,

              COEFF_WIDTH_1 => 16,
              COEFF_FRACT_1 => 14,
              COEFF_WIDTH_2 => 16,
              COEFF_FRACT_2 => 14,
              COEFF_WIDTH_3 => 16,
              COEFF_FRACT_3 => 14)
   port map(clk        => clk,
            reset      => reset,
            write_mode => write_mode,
            x          => input,

            scale_1    => "0100000000000000",
            scale_2    => "0100000000000000",
            scale_3    => "0100000000000000",
            scale_4    => "0100000000000000",

            b0_1       => "0100000000000000",
            b1_1       => "0000000000000000",
            b2_1       => "0000000000000000",
            a1_1       => "0000000000000000",
            a2_1       => "0000000000000000",

            b0_2       => "0100000000000000",
            b1_2       => "0000000000000000",
            b2_2       => "0000000000000000",
            a1_2       => "0000000000000000",
            a2_2       => "0000000000000000",

            b0_3       => "0100000000000000",
            b1_3       => "0000000000000000",
            b2_3       => "0000000000000000",
            a1_3       => "0000000000000000",
            a2_3       => "0000000000000000",

            y          => output);

end architecture;