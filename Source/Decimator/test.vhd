library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;
library work;
	use work.decimator_data.all;

entity filter is 
generic (wordlength: natural := 8;
			taps :integer := 4 );

port(input : in std_logic_vector(wordlength-1 downto 0);
	  output: out std_logic_vector(2*wordlength-1 downto 0);
	  start : in std_logic;
	  clock: std_logic;
	  reset: std_logic;
	  finished: out std_logic );	
end entity filter;

architecture arch_filter of filter is

-- type filter_data is record
-- input_samples_12bit : std_logic_vector(11 downto 0);
-- input_samples_16bit : std_logic_vector(15 downto 0);
-- end record;

-- type reg_type is record
-- 	vector12bit : std_logic_vector(11 downto 0);
-- 	vector16bit : std_logic_vector(15 downto 0);
-- end record;

-- type dataArray_12bit is ARRAY (0 to taps-1) of  filter_data;
-- type dataArray_16bit is ARRAY (0 to taps-1) of filter_data;
type sync is record
 a : std_logic;
end record;

signal inputsamples : dataArray_12bit;
signal coefficients : dataArray_12bit;
signal r,rin: reg_type;
signal x,y : sync;
signal counter: integer range 0 to taps;
signal start_en : std_logic:= '0';

begin

seq_process:process(reset,clock)
			begin
			if reset='1' then

			  FOR i IN 0 TO taps-1 LOOP
		      inputsamples(i).input_samples_12bit <= (OTHERS => '0');
		      END LOOP;

		      r.vector16bit <= (others => '0');
		      coefficients(0).input_samples_12bit <= "11011000";
		      coefficients(1).input_samples_12bit <= "00011101";
		      coefficients(2).input_samples_12bit <= "00011101";
		      coefficients(3).input_samples_12bit <= "11011000";
	 		 
	 		  
		      finished <= '0';
		      start_en <= '0';
		      
		  elsif rising_edge(clock) then
		  	
		       r <= rin ;
		 	end if;    

		end process;



comb_process:process(r,start,input)
variable v: reg_type;
	begin
      v := r;
      
		IF start = '1' and start_en ='0' THEN

	        inputsamples(0).input_samples_12bit <= input;
	        
	        FOR i IN 0 TO taps-2 LOOP
	        inputsamples(i+1).input_samples_12bit <= inputsamples(i).input_samples_12bit;
	        END LOOP;			 

	        finished <= '0';
	        start_en <= '1';
	        counter <= 0;
    	else
    	 	if counter = taps and start_en = '1' then
        
        	output <=  r.vector16bit(2*wordlength-2 DOWNTO 0)& '0'; --TO_STDLOGICVECTOR(TO_BITVECTOR(y_temp) SLL 1); 
        	finished <= '1';
        	start_en<= '1';
        	else
	        	if counter=0 then
	              r.vector16bit <= STD_LOGIC_VECTOR(SIGNED(coefficients(counter).input_samples_12bit) * SIGNED(inputsamples(counter).input_samples_12bit));
	       		else
	       		  r.vector16bit <= STD_LOGIC_VECTOR(SIGNED(rin.vector16bit) + SIGNED(coefficients(counter).input_samples_12bit) * SIGNED(inputsamples(counter).input_samples_12bit));   
	    		end if;
    			counter <= counter +1;

		    end if;
		end if;

	rin<=v;
    end process;

end architecture arch_filter;
