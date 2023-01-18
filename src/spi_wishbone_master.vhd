----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/16/2023 10:30:12 PM
-- Design Name: 
-- Module Name: spi_wishbone_master - behaviour
-- Project Name: 
-- Target Devices: 
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

library ieee;
use ieee.std_logic_1164.all;

entity spi_wishbone_master is
    port (
        CLK_I   : in std_logic;
        RST_I   : in std_logic;
        CYC_O   : out std_logic;
        ACK_I   : in std_logic;
        WE_O    : out std_logic;
        ADR_O   : out std_logic_vector(15 downto 0);
        DAT_O   : out std_logic_vector(7 downto 0);
        DAT_I   : in std_logic_vector(7 downto 0);
    )