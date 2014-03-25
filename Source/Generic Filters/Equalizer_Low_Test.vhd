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

entity Equalizer_Low_Test is
  port(clk    : in  std_logic;
       reset  : in  std_logic;
       input  : in  std_logic_vector(15 downto 0);
       output : out std_logic_vector(15 downto 0));
end Equalizer_Low_Test;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

architecture behaviour of Equalizer_Low_Test is

  signal write_mode : std_logic;
  
  constant sa1_1 : std_logic_vector(17 downto 0) := (x"8797") & "00";
  constant sa2_1 : std_logic_vector(17 downto 0) := (x"38d6") & "00";
  constant sa1_2 : std_logic_vector(17 downto 0) := (x"88f3") & "00";
  constant sa2_2 : std_logic_vector(17 downto 0) := (x"38d0") & "00";
  constant sa1_3 : std_logic_vector(16 downto 0) := "1" & (x"c524");
  constant sa2_3 : std_logic_vector(16 downto 0) := "0" & (x"0dc5");

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
              SCALE_FRACT_1 => 13,
              SCALE_WIDTH_2 => 16,
              SCALE_FRACT_2 => 13,
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

              COEFF_WIDTH_1 => 18,
              COEFF_FRACT_1 => 16,
              COEFF_WIDTH_2 => 18,
              COEFF_FRACT_2 => 16,
              COEFF_WIDTH_3 => 17,
              COEFF_FRACT_3 => 14)
   port map(clk        => clk,
            reset      => reset,
            write_mode => write_mode,
            x          => input,

            scale_1    => x"7fb2",
            scale_2    => x"7fb2",
            scale_3    => "0100000000000000",
            scale_4    => "0100000000000000",

            b0_1       => "00" & (x"41bd"),
            b1_1       => "11" & (x"8784"),
            b2_1       => "00" & (x"3799"),
            a1_1       => std_logic_vector(-signed(sa1_1)),
            a2_1       => std_logic_vector(-signed(sa2_1)),

            b0_2       => "00" & (x"43bd"),
            b1_2       => "11" & (x"88aa"),
            b2_2       => "00" & (x"355d"),
            a1_2       => std_logic_vector(-signed(sa1_2)),
            a2_2       => std_logic_vector(-signed(sa2_2)),

            b0_3       => (x"66f2") & "0",
            b1_3       => (x"8a49") & "0",
            b2_3       => (x"3499") & "0",
            a1_3       => std_logic_vector(-signed(sa1_3)),
            a2_3       => std_logic_vector(-signed(sa2_3)),

            y          => output);

end architecture;