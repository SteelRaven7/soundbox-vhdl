

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY stage_2 IS
  GENERIC(WIDTH:INTEGER:=16;
          N:INTEGER:=7);
  PORT(reset:in STD_LOGIC;
       start:in STD_LOGIC;
       sample_clk2 :in STD_LOGIC;
       x2:IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
       y2: OUT STD_LOGIC_VECTOR(2*WIDTH-1 DOWNTO 0);
       finished_2:OUT STD_LOGIC);
END stage_2;

ARCHITECTURE arch_stage_2 OF stage_2 IS
  TYPE SampleArray IS ARRAY (0 to N-1) OF STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
  TYPE CoffArray IS ARRAY (0 to N-1) OF STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
  
  SIGNAL x2_sample:SampleArray;
  SIGNAL y2_temp:STD_LOGIC_VECTOR(2*WIDTH-1 DOWNTO 0);
  SIGNAL start_EN:STD_LOGIC;
  SIGNAL tx2:CoffArray;
  SIGNAL counter:INTEGER RANGE 0 TO N;
  
BEGIN
  clock:PROCESS(reset,sample_clk2)
  
  BEGIN
    IF reset = '1' THEN
      FOR i IN 0 TO N-1 LOOP
        x2_sample(i) <= (OTHERS => '0');
      END LOOP;
      y2 <= (OTHERS => '0');
      finished_2 <= '0';
		
		
     tx2(0) <= "1111101111000000";-- fbc
     tx2(1) <= "0000000000000000";-- 000
     tx2(2) <= "0010010000110000"; -- 243     
     tx2(3) <= "0100000000000000"; -- 400  
     tx2(4) <= "0010010000110000"; -- 243  
     tx2(5) <= "0000000000000000"; -- 000
     tx2(6) <= "1111101111000000"; -- fbc
     -- tx2(0) <= "1111101111001111";-- fbc
     -- tx2(1) <= "0000000000001111";-- 000
     -- tx2(2) <= "0010010000111111"; -- 243     
     -- tx2(3) <= "0100000000001111"; -- 400  
     -- tx2(4) <= "0010010000111111"; -- 243  
     -- tx2(5) <= "0000000000001111"; -- 000
     -- tx2(6) <= "1111101111001111"; -- fbc
     -- tx2(7) <= "1111101111001111";-- fbc
     -- tx2(8) <= "0000000000001111";-- 000
     -- tx2(9) <= "0010010000111111"; -- 243     
     -- tx2(10) <= "0100000000001111"; -- 400  
     -- tx2(11) <= "0010010000111111"; -- 243  
     -- tx2(12) <= "0000000000001111"; -- 000
     -- tx2(13) <= "1111101111001111"; -- fbc
     -- tx2(14) <= "0000000000001111"; -- 000
     -- tx2(15) <= "1111101111001111"; -- fbc



      start_EN <= '0';    
      
    ELSIF sample_clk2 = '1' AND sample_clk2'EVENT THEN
      IF start = '1' AND start_EN = '0' THEN
        x2_sample(0) <= x2;
        FOR i IN 0 TO N-2 LOOP
          x2_sample(i+1) <= x2_sample(i);
        END LOOP;
      
        finished_2 <= '0';
        start_EN <= '1';
        counter <= 0;
      END IF;
      
      IF  start_EN = '1' THEN
        IF counter = N THEN
          y2 <=  y2_temp(2*WIDTH-2 DOWNTO 0)& '0'; --TO_STDLOGICVECTOR(TO_BITVECTOR(y_temp) SLL 1); 
          finished_2 <= '1';
          start_EN <= '0';
        ELSE
          IF counter = 0 THEN
            y2_temp <= STD_LOGIC_VECTOR(SIGNED(tx2(counter)) * SIGNED(x2_sample(counter)));
          ELSE
            y2_temp <= STD_LOGIC_VECTOR(SIGNED(y2_temp) + SIGNED(tx2(counter)) * SIGNED(x2_sample(counter)));
          END IF;         
          
          counter <= counter + 1;
        END IF;
      END IF;
    END IF;          
  END PROCESS clock; 
END arch_stage_2;
