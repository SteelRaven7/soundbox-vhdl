library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all ;
use std.textio.all;


entity EffectDistortion is
  
    generic ( DATA_WIDTH: integer := 16;
              ADDR_WIDTH: integer := 16
              -- INIT_FILE: string := "LUT_distortion.mif"
              );
      
    Port (  ADDR : in STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0);
            --DATAIN : in STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
            clk : in STD_LOGIC;
            OUTPUT : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0)
            );
    
  end EffectDistortion;
  
architecture behav of EffectDistortion is
  
  COMPONENT blk_mem_gen_distortion
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END COMPONENT;

  begin
 memory: blk_mem_gen_distortion
 port map(
 	clka =>clk,
 	addra=>ADDR,
 	douta=>OUTPUT
 	);
     
  
end behav;
  