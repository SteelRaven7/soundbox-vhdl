

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY stage_4 IS
  GENERIC(WIDTH:INTEGER:=16;
          N:INTEGER:=14);
  PORT(reset:in STD_LOGIC;
       start:in STD_LOGIC;
       sample_clk4:in STD_LOGIC;
       x4:IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
       y4: OUT STD_LOGIC_VECTOR(2*WIDTH-1 DOWNTO 0);
       finished_4:OUT STD_LOGIC);
END stage_4;

ARCHITECTURE arch_stage_4 OF stage_4 IS
  TYPE SampleArray IS ARRAY (0 to N-1) OF STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
  TYPE CoffArray IS ARRAY (0 to N-1) OF STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
  
  SIGNAL x4_sample:SampleArray;
  SIGNAL y4_temp:STD_LOGIC_VECTOR(2*WIDTH-1 DOWNTO 0);
  SIGNAL start_EN:STD_LOGIC;
  SIGNAL tx4:CoffArray;
  SIGNAL counter:INTEGER RANGE 0 TO N;
  
BEGIN
  clock:PROCESS(reset,sample_clk4)
  
  BEGIN
    IF reset = '1' THEN
      FOR i IN 0 TO N-1 LOOP
        x4_sample(i) <= (OTHERS => '0');
      END LOOP;
      y4 <= (OTHERS => '0');
      finished_4 <= '0';
		     
     tx4(0) <= "1111111010110000";-- feb
     tx4(1) <= "0000000000000000";-- 000
     tx4(2) <= "0000010000010000";-- 041
     tx4(3) <= "0000000000000000"; -- 000     
     tx4(4) <= "1111010101000000"; -- f54  
     tx4(5) <= "0000000000000000"; -- 000  
     tx4(6) <= "0010011110110000"; -- 27b    
     tx4(7) <= "0100000000000000"; -- 400     
     tx4(8) <= "0010011110110000"; -- 27b  
     tx4(9) <= "0000000000000000"; -- 000  
     tx4(10) <= "1111010101000000"; -- f54     
     tx4(11) <= "1111101100000000"; -- 000
     tx4(12) <= "0000010000010000"; -- 041     
     tx4(13) <= "1111111010110000"; -- feb
     
      start_EN <= '0';    
      
    ELSIF sample_clk4 = '1' AND sample_clk4'EVENT THEN
      IF start = '1' AND start_EN = '0' THEN
        x4_sample(0) <= x4;
        FOR i IN 0 TO N-2 LOOP
          x4_sample(i+1) <= x4_sample(i);
        END LOOP;
      
        finished_4 <= '0';
        start_EN <= '1';
        counter <= 0;
      END IF;
      
      IF  start_EN = '1' THEN
        IF counter = N THEN
          y4 <=  y4_temp(2*WIDTH-2 DOWNTO 0)& '0'; --TO_STDLOGICVECTOR(TO_BITVECTOR(y_temp) SLL 1); 
          finished_4 <= '1';
          start_EN <= '0';
        ELSE
          IF counter = 0 THEN
            y4_temp <= STD_LOGIC_VECTOR(SIGNED(tx4(counter)) * SIGNED(x4_sample(counter)));
          ELSE
            y4_temp <= STD_LOGIC_VECTOR(SIGNED(y4_temp) + SIGNED(tx4(counter)) * SIGNED(x4_sample(counter)));
          END IF;         
          
          counter <= counter + 1;
        END IF;
      END IF;
    END IF;          
  END PROCESS clock; 
END arch_stage_4;