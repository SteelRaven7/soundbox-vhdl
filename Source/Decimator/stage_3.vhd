

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY stage_3 IS
  GENERIC(WIDTH:INTEGER:=16;
          N:INTEGER:=7);
  PORT(reset:in STD_LOGIC;
       start:in STD_LOGIC;
       sample_clk3:in STD_LOGIC;
       x3:IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
       y3: OUT STD_LOGIC_VECTOR(2*WIDTH-1 DOWNTO 0);
       finished_3:OUT STD_LOGIC);
END stage_3;

ARCHITECTURE arch_stage_3 OF stage_3 IS
  TYPE SampleArray IS ARRAY (0 to N-1) OF STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
  TYPE CoffArray IS ARRAY (0 to N-1) OF STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
  
  SIGNAL x3_sample:SampleArray;
  SIGNAL y3_temp:STD_LOGIC_VECTOR(2*WIDTH-1 DOWNTO 0);
  SIGNAL start_EN:STD_LOGIC;
  SIGNAL tx3:CoffArray;
  SIGNAL counter:INTEGER RANGE 0 TO N;
  
BEGIN
  clock:PROCESS(reset,sample_clk3)
  
  BEGIN
    IF reset = '1' THEN
      FOR i IN 0 TO N-1 LOOP
        x3_sample(i) <= (OTHERS => '0');
      END LOOP;
      y3 <= (OTHERS => '0');
      finished_3 <= '0';
		
		
     tx3(0) <= "1111101100000000";-- fb0
     tx3(1) <= "0000000000000000";-- 000
     tx3(2) <= "0010010011010000"; -- 24d     
     tx3(3) <= "0100000000000000"; -- 400  
     tx3(4) <= "0010010011010000"; -- 24d  
     tx3(5) <= "0000000000000000"; -- 000
     tx3(6) <= "1111101100000000"; -- fb0

      start_EN <= '0';    
      
    ELSIF sample_clk3 = '1' AND sample_clk3'EVENT THEN
      IF start = '1' AND start_EN = '0' THEN
        x3_sample(0) <= x3;
        FOR i IN 0 TO N-2 LOOP
          x3_sample(i+1) <= x3_sample(i);
        END LOOP;
      
        finished_3 <= '0';
        start_EN <= '1';
        counter <= 0;
      END IF;
      
      IF  start_EN = '1' THEN
        IF counter = N THEN
          y3 <=  y3_temp(2*WIDTH-2 DOWNTO 0)& '0'; --TO_STDLOGICVECTOR(TO_BITVECTOR(y_temp) SLL 1); 
          finished_3 <= '1';
          start_EN <= '0';
        ELSE
          IF counter = 0 THEN
            y3_temp <= STD_LOGIC_VECTOR(SIGNED(tx3(counter)) * SIGNED(x3_sample(counter)));
          ELSE
            y3_temp <= STD_LOGIC_VECTOR(SIGNED(y3_temp) + SIGNED(tx3(counter)) * SIGNED(x3_sample(counter)));
          END IF;         
          
          counter <= counter + 1;
        END IF;
      END IF;
    END IF;          
  END PROCESS clock; 
END arch_stage_3;
