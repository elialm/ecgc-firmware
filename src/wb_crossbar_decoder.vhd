----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/25/2023 16:43:12 PM
-- Design Name: 
-- Module Name: wb_crossbar_decoder - behaviour
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
use ieee.std_logic_misc.all;

entity wb_crossbar_decoder is
    port (
        -- Global signals
        CLK_I           : in std_logic;
        RST_I           : in std_logic;
        ACCESS_RAM      : in std_logic;
        SELECT_MBC      : out std_logic_vector(2 downto 0);

        -- GB decoder master connection
        CYC_I   : in std_logic;
        ACK_O   : out std_logic;
        WE_I    : in std_logic;
        ADR_I   : in std_logic_vector(15 downto 0);
        DAT_O   : out std_logic_vector(7 downto 0);
        DAT_I   : in std_logic_vector(7 downto 0);

        -- Master to central crossbar
        CCB_CYC_O   : out std_logic;
        CCB_STB_O   : out std_logic;
        CCB_ACK_I   : in std_logic;
        CCB_WE_O    : out std_logic;
        CCB_ADR_O   : out std_logic_vector(15 downto 0);
        CCB_DAT_O   : out std_logic_vector(7 downto 0);
        CCB_DAT_I   : in std_logic_vector(7 downto 0);

        -- Master to DMA configuration port
        DMA_CYC_O   : out std_logic;
        DMA_STB_O   : out std_logic;
        DMA_ACK_I   : in std_logic;
        DMA_WE_O    : out std_logic;
        DMA_ADR_O   : out std_logic_vector(3 downto 0);
        DMA_DAT_O   : out std_logic_vector(7 downto 0);
        DMA_DAT_I   : in std_logic_vector(7 downto 0));
end wb_crossbar_decoder;

architecture behaviour of wb_crossbar_decoder is

    signal mbch_is_active   : std_logic;
    signal dma_reg_addr     : std_logic;
    signal valid_dma_access : std_logic;

begin

    -- Bus decoding for DMA access
    mbch_is_active <= '1' when SELECT_MBC = "000" else '0';
    -- DMA is accessible at address range 0xA500 to 0xA5FF
    -- Though, only last nibble is relavant due to the address being 4-bit
    dma_reg_addr <= '1'
        when ACCESS_RAM = '1' and ADR_I(12 downto 8) = "00101"
        else '0';
    valid_dma_access <= mbch_is_active and dma_reg_addr;

    -- Master output (central crossbar)
    CCB_CYC_O <= CYC_I;
    CCB_STB_O <= not(valid_dma_access);
    CCB_WE_O <= WE_I;
    CCB_ADR_O <= ADR_I;
    CCB_DAT_O <= DAT_I;

    -- Master output (DMA)
    DMA_CYC_O <= CYC_I;
    DMA_STB_O <= valid_dma_access;
    DMA_WE_O <= WE_I;
    DMA_ADR_O <= ADR_I(3 downto 0);
    DMA_DAT_O <= DAT_I;

    -- GB decoder output multiplexers
    ACK_O <= DMA_ACK_I when valid_dma_access = '1' else CCB_ACK_I;
    DAT_O <= DMA_DAT_I when valid_dma_access = '1' else CCB_DAT_I;

end behaviour;