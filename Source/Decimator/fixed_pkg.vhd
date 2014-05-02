--
-- Author: Erik Alveflo
-- Version:
--   * 1.0 2014-02-11 EA Inital release.
--
-- This package contains helper functions for fixed point math.
--
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;


package fixed_pkg is

type real_array_t is array(natural range <>) of real;

-- Converts a real number to a fixed number of supplied width on format SIF..F
function real_to_fixed (R:real; W:natural)
  return std_logic_vector;

-- Same as above but more generic and also takes amount of fraction bits F.
function real_to_fixed (R:real; W:natural; F:natural)
  return std_logic_vector;  

-- Converts a fixed number on format SIF..F to a real number.
function fixed_to_real (V:std_logic_vector)
  return real;

-- Same as above but more generic and also takes amount of fraction bits F.
function fixed_to_real (V:std_logic_vector; F:natural)
  return real;

-- Round towards zero.
function round_zero (R:real)
  return real;

-- Converts a gain in dB to fixed point, W bits wide, F fraction bits.
function db_to_fixed (R:real; W:natural; F:natural)
  return std_logic_vector;

end package;


package body fixed_pkg is

function round_zero (R:real) return real is
begin
  if (R < 0.0) then
    return ceil(R);
  else
    return floor(R);
  end if;
end function;

function real_to_fixed (R:real; W:natural) return std_logic_vector is
begin
  return real_to_fixed(R,W,W-2);
end function;

function fixed_to_real (V:std_logic_vector) return real is
  variable W : natural := V'high+1 - V'low;
begin
  return fixed_to_real(V,W-2);
end function;

function db_to_fixed (R:real; W:natural; F:natural) return std_logic_vector is
  variable mag : real := (10.0**(R / 20.0));
begin
  return real_to_fixed(mag,W,F);
end function;

function fixed_to_real (V:std_logic_vector; F:natural) return real is
  begin
  return real(to_integer(signed(V))) / (2.0**(F));
end function;

function real_to_fixed (R:real; W:natural; F:natural) return std_logic_vector is
begin
  return std_logic_vector(to_signed(integer(round_zero(R * (2.0**(F)))),W));
end function;

end package body;