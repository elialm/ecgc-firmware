----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 01/25/2023 16:43:12 PM
-- Design Name: Gameboy bus Wishbone crossbar
-- Module Name: wb_crossbar_decoder - rtl
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Documentation
--
-- This is the Gameboy bus Wishbone decoder. It multiplexes the Wishbone master
-- from the Gameboy bus decoder to its 2 slaves:
--      1. DMA configuration slave (signals prefixed with DMA_)
--      2. Central crossbar slave (signals prefixed with CCB_)
--
-- The crossbar decodes the address (i_adr) to figure out if a transaction is
-- meant to access the DMA slave or the central crossbar (which is routed
-- further through the cartridge).
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;

entity wb_crossbar_decoder is
    port (
        -- Global signals
        i_clk           : in std_logic;
        i_rst           : in std_logic;
        i_access_ram      : in std_logic;
        i_select_mbc      : in std_logic_vector(2 downto 0);

        -- GB decoder master connection
        i_cyc   : in std_logic;
        o_ack   : out std_logic;
        i_we    : in std_logic;
        i_adr   : in std_logic_vector(15 downto 0);
        o_dat   : out std_logic_vector(7 downto 0);
        i_dat   : in std_logic_vector(7 downto 0);

        -- Master to central crossbar
        o_ccb_cyc   : out std_logic;
        i_ccb_ack   : in std_logic;
        o_ccb_we    : out std_logic;
        o_ccb_adr   : out std_logic_vector(15 downto 0);
        o_ccb_dat   : out std_logic_vector(7 downto 0);
        i_ccb_dat   : in std_logic_vector(7 downto 0);

        -- Master to DMA configuration port
        o_dma_cyc   : out std_logic;
        i_dma_ack   : in std_logic;
        o_dma_we    : out std_logic;
        o_dma_adr   : out std_logic_vector(3 downto 0);
        o_dma_dat   : out std_logic_vector(7 downto 0);
        i_dma_dat   : in std_logic_vector(7 downto 0)
    );
end wb_crossbar_decoder;

architecture rtl of wb_crossbar_decoder is

    signal n_mbch_is_active   : std_logic;
    signal n_dma_reg_addr     : std_logic;
    signal n_valid_dma_access : std_logic;

begin

    -- Bus decoding for DMA access
    n_mbch_is_active <= '1' when i_select_mbc = "000" else '0';
    -- DMA is accessible at address range 0xA500 to 0xA5FF
    -- Though, only last nibble is relavant due to the address being 4-bit
    n_dma_reg_addr <= '1' when i_access_ram = '1' and i_adr(12 downto 8) = "00101" else '0';
    n_valid_dma_access <= n_mbch_is_active and n_dma_reg_addr;

    -- Master output (central crossbar)
    o_ccb_cyc <= i_cyc and not(n_valid_dma_access);
    o_ccb_we <= i_we;
    o_ccb_adr <= i_adr;
    o_ccb_dat <= i_dat;

    -- Master output (DMA)
    o_dma_cyc <= i_cyc and n_valid_dma_access;
    o_dma_we <= i_we;
    o_dma_adr <= i_adr(3 downto 0);
    o_dma_dat <= i_dat;

    -- GB decoder output multiplexers
    o_ack <= i_dma_ack when n_valid_dma_access = '1' else i_ccb_ack;
    o_dat <= i_dma_dat when n_valid_dma_access = '1' else i_ccb_dat;

end rtl;