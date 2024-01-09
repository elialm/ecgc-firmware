----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 01/03/2024 14:38:20 PM
-- Design Name: Serial Transmitter
-- Module Name: serial_tx - rtl
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Documentation
--
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity serial_tx is
    generic (
        p_clk_freq : real := 100.0;
        p_baud_rate : natural := 115200;
        p_parity : string := "NONE";
        p_data_bits : natural := 8;
        p_stop_bits : natural := 1
    );
    port (
        -- Wishbone signals
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_cyc : in std_logic;
        i_we  : in std_logic;
        i_dat : in std_logic_vector(7 downto 0);
        o_ack : out std_logic;

        -- Serial signals
        o_serial_tx : out std_logic
    );
end entity serial_tx;

architecture rtl of serial_tx is

begin

    assert p_data_bits >= 5 and p_data_bits <= 8 report "p_data_bits must be within 5 and 8 bits" severity FAILURE;
    assert p_stop_bits = 1 or p_stop_bits = 2 report "p_stop_bits must be either 1 or 2 bits" severity FAILURE;

end architecture rtl;