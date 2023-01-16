----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/16/2023 03:07:43 PM
-- Design Name: 
-- Module Name: dma_controller - behaviour
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

entity dma_controller is
    port (
        CLK_I       : in std_logic;
        RST_I       : in std_logic;

        -- DMA master port
        DMA_CYC_O   : out std_logic;
        DMA_ACK_I   : in std_logic;
        DMA_WE_O    : out std_logic;
        DMA_ADR_O   : out std_logic_vector(15 downto 0);
        DMA_DAT_O   : out std_logic_vector(7 downto 0);
        DMA_DAT_I   : in std_logic_vector(7 downto 0);
    
        -- Configuration slave port
        CFG_CYC_I   : in std_logic;
        CFG_ACK_O   : out std_logic;
        CFG_WE_I    : in std_logic;
        CFG_ADR_I   : in std_logic_vector(7 downto 0);
        CFG_DAT_O   : out std_logic_vector(7 downto 0);
        CFG_DAT_I   : in std_logic_vector(7 downto 0));
end dma_controller;

architecture behaviour of dma_controller is

    signal master_address   : std_logic_vector(15 downto 0);
    signal master_data      : std_logic_vector(7 downto 0);
    signal slave_data       : std_logic_vector(7 downto 0);

begin

    -- DMA state machine
    process (CLK_I)
    begin
        if rising_edge(CLK_I) then
            if RST_I = '1' then
                master_address <= (others => '0');
                master_data <= (others => '0');
            
                DMA_CYC_O <= '0';
                DMA_WE_O <= '0';
            else
            end if;
        end if;
    end process;

    DMA_ADR_O <= master_address;
    DMA_DAT_O <= master_data;

    -- Configuration address decoder
    process (CLK_I)
    begin
        if rising_edge(CLK_I) then
            CFG_ACK_O <= '0';

            if RST_I = '1' then
                slave_data <= (others => '0');
            elsif CFG_CYC_I = '1' then
                -- TODO
            end if;
        end if;
    end process;

    CFG_DAT_O <= slave_data;

end behaviour;