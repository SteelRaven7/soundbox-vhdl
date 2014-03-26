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

entity Generic_Equalizer_No_Change_Test is
  port(clk    : in  std_logic;
       reset  : in  std_logic;
       input  : in  std_logic_vector(15 downto 0);
       output : out std_logic_vector(15 downto 0));
end Generic_Equalizer_No_Change_Test;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

architecture behaviour of Generic_Equalizer_No_Change_Test is

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

  Generic_Equalizer : entity work.Generic_Equalizer
  generic map(NO_SECTIONS    => 3,
			
			  DATA_WIDTH     => 8,
              DATA_FRACT     => 6,

              SCALE_WIDTH    => 8,
              SCALE_FRACT    => (6,6,6,6),

              INTERNAL_WIDTH => 14,
              INTERNAL_FRACT => 8,

              COEFF_WIDTH_B  => 8,
              COEFF_FRACT_B  => (6,6,6),
              COEFF_WIDTH_A  => 8,
              COEFF_FRACT_A  => (6,6,6))
   port map(clk        => clk,
            reset      => reset,
            write_mode => write_mode,
            x          => input,

            scale      => (x"40" & x"40" & x"40" & x"40"),

            b0         => (x"40" & x"40" & x"40"),
            b1         => (x"00" & x"00" & x"00"),
            b2         => (x"00" & x"00" & x"00"),
            a1         => (x"00" & x"00" & x"00"),
            a2         => (x"00" & x"00" & x"00"),

            y          => output);

end architecture;