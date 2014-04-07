LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
-- USE ieee.numeric_std.ALL;
use std.textio.all;
use IEEE.math_real.all;
use IEEE.std_logic_arith.all;

entity testbench is 
	generic(
			width : natural :=16
			);
	port(
		
		output : out std_logic_vector(width-1 downto 0)
		);
end testbench;

architecture arch_testbench of testbench is 

 
 -- COMPONENT StructuralDecimator is
 --    Port ( input: in std_logic_vector(11 downto 0);
 --           output: out std_logic_vector(15 downto 0);
 --           clk :in std_logic;
 --           reset:in std_logic
 --         );
           
 --   END COMPONENT StructuralDecimator;


-- COMPONENT EffectEcho is
--  generic (
--    wordLength : natural := 16;
--    constantsWordLength : natural := 16
--  );
--  port (
--    input : in std_logic_vector(wordLength-1 downto 0);
--    output : out std_logic_vector(wordLength-1 downto 0);
--
--    clk : in std_logic;
--    reset : in std_logic
--  );
--end COMPONENT ;


begin

-- decimator_comp:  COMPONENT StructuralDecimator
--          PORT MAP(clk=>clock,
--                   reset=>reset_signal,
--                   input=>input_signal,
--                   output=>output_signal
--            );
                  
   
--   EffectEcho_comp: COMPONENT EffectEcho
--            PORT MAP(clk=>clock,
--                  reset=>reset_signal,
--                  input=>input_signal,
--                  output=>output_signal
--           );

test_comp: entity work.Generic_Equalizer_Low_Pass 
port map (input => input_signal,
					output => output_signal,
					clk=> clock,
					reset => reset_signal
   );


   reset_signal<='0',
                 '1' AFTER 15 ns,
                 '0' AFTER 25 ns;



clk_proc:process
    	 begin
     		 wait for  25 us;
     		 clock<=NOT(clock);
  		 end process clk_proc;

  		 


reading:process
        	file   		infile	     : text is in  "Input.txt";   --declare input file
        	variable  	inline  	 : line; --line number declaration
    		variable  	dataread1    : real;
        begin
    		wait until  clock = '1' and clock'event;
				if (not endfile(infile)) then   --checking the "END OF FILE" is not reached.
				readline(infile, inline);
   			read(inline, dataread1);
        	dataread <=dataread1;   --put the value available in variable in a signal.
			else
			endoffile <='1';         --set signal to tell end of file read file is reached.
			end if;	
	    end process reading;

input_signal <= STD_LOGIC_VECTOR(CONV_SIGNED(INTEGER(dataread*65536.0),width));-- 12 =width
output_signal1 <= SIGNED(output_signal(15 downto 0));
--output_signal1 <= SIGNED(input_signal(15 downto 0));
datawrite <= REAL(CONV_INTEGER(output_signal1))/65536.0 ;

writing:process
			file      outfile  : text is out "Output_Low.txt";  --declare output file
			variable  outline  : line;   --line number declaration  					
		begin					
			wait until clock = '0' and clock'event;
			if(endoffile='0') then   write(outline, datawrite, left, 16, 12);--write(linenumber,value(real type),justified(side),field(width),digits(natural));
			writeline(outfile, outline);
			linenumber <= linenumber + 1;
			else
			null;
			end if;
		end process writing; 

end arch_testbench;