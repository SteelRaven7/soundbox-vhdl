library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MACcell is
  generic(IO_length: integer := 16;
          M_length: integer := 32);
  port(Multiplier :in std_logic_vector(IO_length-1 downto 0);
       Coefficient :in std_logic_vector(IO_length-1 downto 0);
       Accumulator :in std_logic_vector(IO_length-1 downto 0);
       Cell_out :out std_logic_vector(IO_length-1 downto 0));
end MACcell;

architecture structural of MACcell is

	function addsat (a,b : std_logic_vector) return std_logic_vector is
		constant MAX : std_logic_vector(a'length-1 downto 0) := '0' & (a'length-2 downto 0 => '1');
		constant MIN : std_logic_vector(a'length-1 downto 0) := '1' & (a'length-2 downto 0 => '0');
		variable sum : std_logic_vector(a'length-1 downto 0);
		variable overflow : std_logic;
		variable s_a : std_logic;
		variable s_b : std_logic;
		variable s_s : std_logic;
		begin
			sum := std_logic_vector(signed(a) + signed(b));

			s_a := a(a'length-1);
			s_b := b(b'length-1);
			s_s := sum(a'length-1);

	-- Signs of a and b are the same, but not equal to sign of s means overflow.
			overflow := ((s_a and s_b) and not(s_s)) or ((not(s_a) and not(s_b)) and s_s);
			
			if overflow = '0' then
				return sum;
			elsif s_a = '0' then
				return MAX;
			elsif s_a = '1' then
				return MIN;
			else
				return (a'length-1 downto 0 => '0');
			end if;
			
	end addsat;

  signal multiplier_to_accumulator: std_logic_vector(IO_length-1 downto 0);
  signal multiplier_out: signed(M_length-1 downto 0);
  
  begin
    multiplier_out <= (signed(Multiplier)*signed(Coefficient));
    multiplier_to_accumulator <= std_logic_vector(multiplier_out(M_length-1 downto IO_length));
    Cell_out <= addsat(multiplier_to_accumulator,Accumulator);
  end;
