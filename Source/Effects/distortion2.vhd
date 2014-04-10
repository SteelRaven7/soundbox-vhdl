library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all ;
use std.textio.all;


entity EffectDistortion is
  
    generic ( DATA_WIDTH: integer := 16;
              ADDR_WIDTH: integer := 16;
              INIT_FILE: string := "LUT_distortion.txt"
              );
      
    Port (  ADDR : in STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0);
            --DATAIN : in STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
            --CLK : in STD_LOGIC;
            OUTPUT : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0));
    
  end EffectDistortion;
  
architecture behav of EffectDistortion is
  
  type memory_array is array (0 to (2**addr_width)-1) of std_logic_vector((data_width-1) downto 0);
  
  impure function init_memory_wfile(init_file : in string) return MEMORY_ARRAY is
    file mif_file : text open read_mode is init_file;
    variable mif_line : line;
    variable temp_bv : integer range -2**(DATA_WIDTH-1) to 2**(DATA_WIDTH-1)-1;
    variable temp_mem : MEMORY_ARRAY;
  begin
    for i in MEMORY_ARRAY'range loop
        readline(mif_file, mif_line);
        read(mif_line, temp_bv);
        temp_mem(i) := std_logic_vector(to_signed(temp_bv,DATA_WIDTH));
    end loop;
    return temp_mem;
  end function;

  constant memory : memory_array := init_memory_wfile(INIT_FILE); -- "" around the argument?

  begin
    
     OUTPUT <= memory(to_integer(unsigned(ADDR)));
  
end behav;
  