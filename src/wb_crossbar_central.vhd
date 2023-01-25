----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/25/2023 15:15:12 PM
-- Design Name: 
-- Module Name: wb_crossbar_central - behaviour
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

entity wb_crossbar_central is
    port (
        -- Global signals
        CLK_I           : in std_logic;
        RST_I           : in std_logic;
        ACCESS_RAM		: in std_logic;
        SELECT_MBC  	: out std_logic_vector(2 downto 0);
        DMA_BUSY        : in std_logic;
        DBG_ACTIVE      : in std_logic;

        -- SPI debug master connection
        DBG_CYC_I   : in std_logic;
        DBG_ACK_O   : out std_logic;
        DBG_WE_I    : in std_logic;
        DBG_ADR_I   : in std_logic_vector(15 downto 0);
        DBG_DAT_O   : out std_logic_vector(7 downto 0);
        DBG_DAT_I   : in std_logic_vector(7 downto 0);

        -- GB decoder master connection
        GBD_CYC_I   : in std_logic;
        GBD_STB_I   : in std_logic;
        GBD_ACK_O   : out std_logic;
        GBD_WE_I    : in std_logic;
        GBD_ADR_I   : in std_logic_vector(15 downto 0);
        GBD_DAT_O   : out std_logic_vector(7 downto 0);
        GBD_DAT_I   : in std_logic_vector(7 downto 0);

        -- DMA master connection
        DMA_CYC_I   : in std_logic;
        DMA_ACK_O   : out std_logic;
        DMA_WE_I    : in std_logic;
        DMA_ADR_I   : in std_logic_vector(15 downto 0);
        DMA_DAT_O   : out std_logic_vector(7 downto 0);
        DMA_DAT_I   : in std_logic_vector(7 downto 0);

        -- Master out (routed to MBCs)
        CYC_O   : out std_logic;
        ACK_I   : in std_logic;
        WE_O    : out std_logic;
        ADR_O   : out std_logic_vector(15 downto 0);
        DAT_O   : out std_logic_vector(7 downto 0);
        DAT_I   : in std_logic_vector(7 downto 0));
end wb_crossbar_central;

architecture behaviour of wb_crossbar_central is

    signal master_is_dma    : std_logic;
    signal master_is_dbg    : std_logic;

    signal cart_cyc_o   : std_logic;
    signal cart_we_o    : std_logic;
    signal cart_adr_o   : std_logic_vector(15 downto 0);
    signal cart_dat_o   : std_logic_vector(7 downto 0);

begin

    -- Master selection
    master_is_dma <= DMA_BUSY;
    master_is_dbg <= DBG_ACTIVE;

    -- DAT_O signals
    DBG_DAT_O <= DAT_I;
    GBD_DAT_O <= x"00" when master_is_dma = '1' else DAT_I;
    DMA_DAT_O <= DAT_I;

    -- ACK_O signals
    DBG_ACK_O <= ACK_I;
    GBD_ACK_O <= '1' when master_is_dma = '1' else ACK_I;
    DMA_ACK_O <= ACK_I;

    -- DMA and GBD output multiplexers
    cart_cyc_o <= DMA_CYC_I when master_is_dma = '1' else GBD_CYC_I and GBD_STB_I;
    cart_we_o <= DMA_WE_I when master_is_dma = '1' else GBD_WE_I;
    cart_adr_o <= DMA_ADR_I when master_is_dma = '1' else GBD_ADR_I;
    cart_dat_o <= DMA_DAT_I when master_is_dma = '1' else GBD_DAT_I;

    -- Master output multiplexers
    CYC_O <= DBG_CYC_I when master_is_dbg = '1' else cart_cyc_o;
    WE_O <= DBG_WE_I when master_is_dbg = '1' else cart_we_o;
    ADR_O <= DBG_ADR_I when master_is_dbg = '1' else cart_adr_o;
    DAT_O <= DBG_DAT_I when master_is_dbg = '1' else cart_dat_o;

end behaviour;