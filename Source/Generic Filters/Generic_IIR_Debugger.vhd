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

entity Generic_IIR_Debugger is
  port(clk    : in  std_logic;
       reset  : in  std_logic;
       input  : in  std_logic_vector(15 downto 0);
       output : out std_logic_vector(15 downto 0));
end Generic_IIR_Debugger;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

architecture behaviour of Generic_IIR_Debugger is
begin

  Generic_IIR : entity work.Generic_IIR
  generic map(ORDER          => 2,
              IN_WIDTH       => 16,
              IN_FRACT       => 11,
              B_WIDTH        => 16,
              B_FRACT        => 13,
              A_WIDTH        => 16,
              A_FRACT        => 14,
			  INTERNAL_WIDTH => 24,
			  INTERNAL_FRACT => 12,
			  OUT_WIDTH      => 16,
			  OUT_FRACT      => 9)
   port map(clk   => clk,
		    reset => reset,
            x     => input,
            B     => x"2000" &
			         x"0000" &
					 x"0000",
            A     => x"4000" &
			         x"4000",
            y     => output);

end architecture;