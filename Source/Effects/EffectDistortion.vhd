--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Description:                                                               --
-- This file initiates a soft distortion. The memory is instantiated using    --
-- the LUT_Distortion.coe file.                                               --
--                                                                            --
-- Generic:                                                                   --
-- DATA_WIDTH        - Wordlength of the input/output signals.				  --
--                                                                            --
-- Input/Output:                                                              --
-- ADDR              - Input signal                                           --
-- OUTPUT            - Output signal                                          --																		  --
-- CLK               - The clock for the memory, fs.                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all ;

entity EffectDistortion is
  
    generic ( DATA_WIDTH: integer := 16);
    Port (  ADDR : in STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
            clk : in STD_LOGIC;
            OUTPUT : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0)
            );
    
  end EffectDistortion;
  
architecture behav of EffectDistortion is
  
  COMPONENT blk_mem_gen_1
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END COMPONENT;
signal temp_ADDR : std_logic_vector(DATA_WIDTH-1 downto 0);

signal shifted : signed(DATA_WIDTH-1 downto 0);

  begin

  --shifted <= shift_left(signed(ADDR),1);
  --temp_ADDR <= std_logic_vector(shifted);
  temp_ADDR <= ADDR;

 memory: blk_mem_gen_1
 port map(
 	clka =>clk,
    addra => temp_ADDR,
 	douta=>OUTPUT
 	);
     
  
end behav;
  