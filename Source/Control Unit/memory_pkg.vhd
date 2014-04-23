library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;


package memory_pkg is
	type configurableRegisterBus is record
		-- This likely doesn't need to be 15 bits.
		address : std_logic_vector(15 downto 0);
		data : std_logic_vector(15 downto 0);

		writeEnable : std_logic;
	end record;
end package;

package body memory_pkg is

end package body;