library ieee ;
  use ieee.std_logic_1164.all ;
  use ieee.numeric_std.all ;

ENTITY DA IS
generic(width : natural := 16
  );
  PORT(clk:IN STD_LOGIC;
       reset:IN STD_LOGIC;
       sample_clk:IN STD_LOGIC;
       data:IN STD_LOGIC_VECTOR(width-1 DOWNTO 0); -- 12 bits
       CS:OUT STD_LOGIC;
       SDI:OUT STD_LOGIC;
       counter_temp: out std_logic_vector(4 downto 0)
       );
       -- LDAC:OUT STD_LOGIC);      
END DA;

ARCHITECTURE arch_DA OF DA IS
  signal start : std_logic;
  signal counter :natural RANGE 0 TO 31;
  
  BEGIN
  PROCESS(clk,reset)
  
   
  BEGIN
    counter_temp <= std_logic_vector(to_unsigned(counter,5));
    IF(reset ='1') then
      SDI  <= '0';  -- When reset CS = 1, LDAC = 1(constant 0?), SDI = 1, SHDN = 0.
      CS   <= '1';
      start <= '0';
    ELSIF falling_edge(clk) then
        if ( start = '0' ) and sample_clk = '1' then
      start <= '1';
      counter <= 0;
      end if;
      
       IF start = '1' then
           IF counter = 0 then
            SDI <= '0';
            CS <= '0';
           elsif (counter < 8) then
            SDI <= '0';
            ELSIF counter > 7 and counter < 24  then
              SDI <= data(23-counter);
            elsif counter > 24 and counter < 27 then
            sdi <= '0';              
           ELSIF counter = 27 then
            CS <= '1';
            start<='0';
           END IF;  
            counter <= counter + 1;        
         END IF;
         
       END IF;
    END PROCESS;    
END arch_DA;