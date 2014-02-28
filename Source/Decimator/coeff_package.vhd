library ieee ;
use ieee.std_logic_1164.all;

package decimator_data is


type filter_data is record
input_samples_12bit : std_logic_vector(7 downto 0);
input_samples_16bit : std_logic_vector(15 downto 0);
end record;

type reg_type is record
	vector12bit : std_logic_vector(7 downto 0);
	vector16bit : std_logic_vector(15 downto 0);
end record;

type dataArray_12bit is ARRAY (0 to 5) of  filter_data;
type dataleArray_16bit is ARRAY (0 to 15) of filter_data;


end package decimator_data;

package body decimator_data is 


end decimator_data;