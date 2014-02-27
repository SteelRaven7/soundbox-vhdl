

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY stage_1 IS
  GENERIC(WIDTH:INTEGER:=12;
          N:INTEGER:=7);
  PORT(reset:in STD_LOGIC;
       start:in STD_LOGIC;
       sample_clk1:in STD_LOGIC;
       x1:IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
       y1:OUT STD_LOGIC_VECTOR(2*WIDTH-1 DOWNTO 0);
      finished_1:OUT STD_LOGIC);
END stage_1;

ARCHITECTURE arch_stage_1 OF stage_1 IS
  TYPE SampleArray IS ARRAY (0 to N-1) OF STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
  TYPE CoffArray IS ARRAY (0 to N-1) OF STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
  
  SIGNAL x1_sample:SampleArray;
  SIGNAL y1_temp:STD_LOGIC_VECTOR(2*WIDTH-1 DOWNTO 0);
  SIGNAL start_EN:STD_LOGIC;
  SIGNAL tx1:CoffArray;
  SIGNAL counter:INTEGER RANGE 0 TO N;
  
BEGIN
  clock:PROCESS(reset,sample_clk1)
  -- variable counter:INTEGER RANGE 0 TO N;
  BEGIN
    IF reset = '1' THEN
          FOR i IN 0 TO N-1 LOOP
            x1_sample(i) <= (OTHERS => '0');
          END LOOP;
          y1 <= (OTHERS => '0');
          finished_1 <= '0';
    		
    		
         tx1(0) <= "111110111111";-- fbf
         tx1(1) <= "000000000000";-- 000
         tx1(2) <= "001001000001"; -- 241     
         tx1(3) <= "010000000000"; -- 400  
         tx1(4) <= "001001000001"; -- 241  
         tx1(5) <= "000000000000"; -- 000
         tx1(6) <= "111111011111"; -- fbf

          start_EN <= '0';    
      ELSIF sample_clk1 = '1' AND rising_edge(sample_clk1) THEN
          IF start = '1' AND start_EN = '0' THEN
            x1_sample(0) <= x1;
            FOR i IN 0 TO N-2 LOOP
              x1_sample(i+1) <= x1_sample(i);
            END LOOP;
          
            finished_1 <= '0';
            start_EN <= '1';
            counter <= 0;
          END IF;
          
IF  start_EN = '1' THEN
        IF counter = N THEN
          y1 <=  y1_temp(2*WIDTH-2 DOWNTO 0)& '0'; --TO_STDLOGICVECTOR(TO_BITVECTOR(y_temp) SLL 1); 
          finished_1 <= '1';
          start_EN <= '0';
        ELSE
          IF counter = 0 THEN
            y1_temp <= STD_LOGIC_VECTOR(SIGNED(tx1(counter)) * SIGNED(x1_sample(counter)));
          ELSE
            y1_temp <= STD_LOGIC_VECTOR(SIGNED(y1_temp) + SIGNED(tx1(counter)) * SIGNED(x1_sample(counter)));
          END IF;         
          
          counter <= counter + 1;
        END IF;
      END IF;
    END IF;          





     --      IF  start_EN = '1' THEN
     --            IF counter = N THEN
     --             y1 <= TO_STDLOGICVECTOR(TO_BITVECTOR(y1_temp) SLL 1); -- y1_temp(2*WIDTH-2 DOWNTO 0)& '0'; 
     --             -- y1 <= (OTHERS =>'0');
     --              finished_1 <= '1';
     --              start_EN <= '0';
     --            ELSIF counter = 0 THEN
     --                y1_temp <= STD_LOGIC_VECTOR(SIGNED(tx1(counter)) * SIGNED(x1_sample(counter)));
     --                -- y1 <= (OTHERS =>'0');
     --                counter <= counter + 1;
     --            ELSE
     --                y1_temp <= STD_LOGIC_VECTOR(SIGNED(y1_temp) + SIGNED(tx1(counter)) * SIGNED(x1_sample(counter)));
     --                -- y1 <="010101010101010101010101";
     --                counter <= counter + 1;
     --            END IF;         
     --         -- counter <= counter + 1;
     --        END IF;
     -- end if;        
  END PROCESS clock; 
  

  END architecture arch_stage_1;
