----------------------------------------------------------------------------------
--   
-- Engineer:Lenin Lawrence 
-- 
-- Create Date: 02/2*WIDTH-1/2014 08:00:22 PM
-- Design Name: Decimaotr
-- Module Name: decimator - Behavioral
-- Project Name: Soundbox
-- Target Devices: artix-7
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity decimator is
 GENERIC(WIDTH:INTEGER:=12);
    Port ( input_signal : in std_logic_vector(WIDTH-1 downto 0);
           -- output_signal: out std_logic_vector(2*WIDTH-1 downto 0);
           output_signal: out std_logic_vector(31 downto 0);
           clk :in std_logic;
           reset:in std_logic;
           start:in std_logic );
end decimator;

architecture arch_decimator of decimator is

component clocks is
    -- GENERIC(c1:INTEGER :=567);-- 1133.7868/2 for 44100x16 Hz
             -- c2:INTEGER :=1134;--  2267.57
             -- c3:INTEGER :=2268;--  4535.147
             -- c4:INTEGER :=9070);-- 9070.29 
    Port ( clk : in STD_LOGIC;
    	   reset : in STD_LOGIC;
           sample_clk1 : out STD_LOGIC;
           sample_clk2 : out STD_LOGIC;
           sample_clk3 : out STD_LOGIC;
           sample_clk4 : out STD_LOGIC);
end component clocks;

-- component MAC_serial_implementation IS
--   GENERIC(WIDTH:INTEGER:=12;
--           N:INTEGER:=25);
--   PORT(reset:STD_LOGIC;
--        start:STD_LOGIC;
--        clk:STD_LOGIC;
--        x:IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
--        y:OUT STD_LOGIC_VECTOR(2*WIDTH-1 DOWNTO 0);
-- --     y:OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
--        finished:OUT STD_LOGIC);
-- END component MAC_serial_implementation;



component stage_1 IS
  GENERIC(WIDTH:INTEGER:=12);
  PORT(reset:in STD_LOGIC;
       start:in STD_LOGIC;
       sample_clk1:in STD_LOGIC;
       x1:IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
       y1: OUT STD_LOGIC_VECTOR(2*WIDTH-1 DOWNTO 0);
       finished_1:OUT STD_LOGIC);
END component stage_1;

component stage_2 IS
  GENERIC(WIDTH:INTEGER:=16);
  PORT(reset:in STD_LOGIC;
       start:in STD_LOGIC;
       sample_clk2 :in STD_LOGIC;
       x2:IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
       y2: OUT STD_LOGIC_VECTOR(2*WIDTH-1 DOWNTO 0);
       finished_2:OUT STD_LOGIC);
END component stage_2;

component stage_3 IS
  GENERIC(WIDTH:INTEGER:=16);
  PORT(reset:in STD_LOGIC;
       start:in STD_LOGIC;
       sample_clk3:in STD_LOGIC;
       x3:IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
       y3: OUT STD_LOGIC_VECTOR(2*WIDTH-1 DOWNTO 0);
       finished_3:OUT STD_LOGIC);
END component stage_3;

component stage_4 IS
  GENERIC(WIDTH:INTEGER:=16);
  PORT(reset:in STD_LOGIC;
       start:in STD_LOGIC;
       sample_clk4:in STD_LOGIC;
       x4:IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
       y4: OUT STD_LOGIC_VECTOR(2*WIDTH-1 DOWNTO 0);
       finished_4:OUT STD_LOGIC);
END component stage_4;

signal sample_clk1_temp: std_logic;
signal sample_clk2_temp: std_logic;
signal sample_clk3_temp: std_logic;
signal sample_clk4_temp: std_logic;

signal output1 : std_logic_vector(2*WIDTH-1 downto 0);
signal output2 : std_logic_vector(31 downto 0);
signal output3 : std_logic_vector(31 downto 0);
signal output4 : std_logic_vector(31 downto 0);

signal start2 : std_logic;
signal start3 : std_logic;
signal start4 : std_logic;
signal start5 : std_logic;
begin

clocking: component clocks port map (clk=>clk,
					reset=>reset,
					sample_clk1=>sample_clk1_temp,
					sample_clk2=>sample_clk2_temp,
					sample_clk3=>sample_clk3_temp,
					sample_clk4=>sample_clk4_temp);


-- zyz:component MAC_serial_implementation
--   PORT map(reset=>reset,
--        start=>start,
--        clk=>sample_clk1_temp,
--        x=>input_signal,
--        y=>output_signal,
-- --     y:OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
--        finished=>start2);

filter_1: component stage_1 port map (reset => reset,
									 start=>start,
									 sample_clk1=>sample_clk1_temp,
									 x1=>input_signal,
									 y1=>output1,
									 finished_1=>start2	);


filter_2: component stage_2 port map (reset => reset,
                  start=>start2,
                  sample_clk2=>sample_clk2_temp,
									 x2=>output1(15 downto 0),
									 y2=>output2,
									 finished_2=>start3	);

filter_3: component stage_3 port map (reset => reset,
									 start=>start3,
									 sample_clk3=>sample_clk3_temp,
									 x3=>output2(15 downto 0),
									 y3=>output3,
									 finished_3=>start4	);

filter_4: component stage_4 port map (reset => reset,
									 start=>start4,
									 sample_clk4=>sample_clk4_temp,
									 x4=>output3(15 downto 0),
									 y4=>output4,
									 finished_4=>start5	);
-- output4(31) <=start5;
-- output4(30) <=start4;
-- output4(29) <=start3;
-- output4(28) <=start2;
-- output_signal <= output4(11 downto 0);
output_signal <= output4;
end arch_decimator;
