library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all ;



entity EffectDistortion is
  
    generic ( DATA_WIDTH: integer := 16;
              ADDR_WIDTH: integer := 16
              
              );
      
    Port (  ADDR : in STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0);
            --DATAIN : in STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
            clk : in STD_LOGIC;
            OUTPUT : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0)
            );
    
  end EffectDistortion;
  
architecture behav of EffectDistortion is
  
  COMPONENT blk_mem_distortion_2
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END COMPONENT;
signal temp_ADDR : std_logic_vector(ADDR_WIDTH-1 downto 0);

  begin

  
 memory: blk_mem_distortion_2
 port map(
 	clka =>clk,
    addra =>ADDR,
 	-- addra=>ADDR,
 	douta=>OUTPUT
 	);
     
  
end behav;
  