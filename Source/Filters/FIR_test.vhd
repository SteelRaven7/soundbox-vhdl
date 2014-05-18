library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.filter_pkg.all;

entity FIR_test is
  generic(Order: integer := 6;
          IO_length: integer := 16;
          M_length: integer := 32;
		  coeffs: coeff_int_array := (0,0,0,0,0,0));
  port(RESET :in std_logic;
       CLK :in std_logic;
       input :in std_logic_vector(IO_length-1 downto 0);
       output :out std_logic_vector(IO_length-1 downto 0));
end FIR_test;

architecture behav of FIR_test is
  
  component MACcell is
  generic(IO_length: integer := IO_length;
          M_length: integer := M_length);
  port(Multiplier :in std_logic_vector(IO_length-1 downto 0);
       Coefficient :in std_logic_vector(IO_length-1 downto 0);
       Accumulator :in std_logic_vector(IO_length-1 downto 0);
       Cell_out :out std_logic_vector(IO_length-1 downto 0));
  end component;
  
  type coeff_array is array(order downto 0) of std_logic_vector(IO_length-1 downto 0);
  type delay_array is array(order-1 downto 0) of std_logic_vector(IO_length-1 downto 0);
  type Acc_array is array(order downto 0) of std_logic_vector(IO_length-1 downto 0);
  
  signal coefficients : coeff_array;
  
  signal delay : delay_array;
  signal Acc : Acc_array;  
  signal multi_out : signed(M_length-1 downto 0);

  begin
	
	coeff_conv: for i in 0 to order generate
		coefficients(i) <= std_logic_vector(to_signed(coeffs(i),IO_length));
	end generate coeff_conv;
	
    gen_MAC: for i in 1 to order generate
      MAC: MACcell generic map(IO_length,M_length)
      port map(delay(i-1),coefficients(i),Acc(i-1),Acc(i));
    end generate gen_MAC;
    
    multi_out <= (signed(input)*signed(coefficients(0)));
		Acc(0) <= std_logic_vector(multi_out(M_length-1 downto IO_length));
    output <= Acc(order);
    
    process(RESET,CLK)
      begin
        if RESET = '1' then
            delay <= (others => (others => '0'));
        elsif rising_edge(CLK) then
          for i in 1 to order loop
            delay(order-i) <= delay(order-i-1);
          end loop;
			delay(0) <= input;
        end if;
      end process;
    end behav;
