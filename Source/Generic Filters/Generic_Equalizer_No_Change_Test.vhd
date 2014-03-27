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
  generic map(NO_SECTIONS    => 9,
			
			  DATA_WIDTH     => 16,
              DATA_FRACT     => 14,

              SCALE_WIDTH    => 16,
              SCALE_FRACT    => (14,14,14,14,14,14,14,14,14,14),

              INTERNAL_WIDTH => 30,
              INTERNAL_FRACT => 24,

              COEFF_WIDTH_B  => 16,
              COEFF_FRACT_B  => (14,14,14,14,14,14,14,14,14),
              COEFF_WIDTH_A  => 16,
              COEFF_FRACT_A  => (14,14,14,14,14,14,14,14,14))
   port map(clk        => clk,
            reset      => reset,
            write_mode => write_mode,
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

            b0         => (x"4000" 
			             & x"4000" 
						 & x"4000" 
						 & x"4000" 
						 & x"4000" 
						 & x"4000" 
						 & x"4000" 
						 & x"4000" 
						 & x"4000"),
						 
            b1         => (x"0000" 
			             & x"0000" 
						 & x"0000" 
						 & x"0000" 
						 & x"0000" 
						 & x"0000" 
						 & x"0000" 
						 & x"0000" 
						 & x"0000"),
						 
            b2         => (x"0000" 
			             & x"0000" 
						 & x"0000" 
						 & x"0000" 
						 & x"0000" 
						 & x"0000" 
						 & x"0000" 
						 & x"0000" 
						 & x"0000"),
			
            a1         => (x"0000" 
			             & x"0000" 
						 & x"0000" 
						 & x"0000" 
						 & x"0000" 
						 & x"0000" 
						 & x"0000" 
						 & x"0000" 
						 & x"0000"),
			
            a2         => (x"0000" 
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