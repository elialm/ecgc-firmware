----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 01/25/2023 15:15:12 PM
-- Design Name: Central Wishbone crossbar
-- Module Name: wb_crossbar_central - rtl
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Documentation
--
-- This is the central Wishbone crossbar. It multiplexes the 3 bus masters
-- in the cartridge to the main Wishbone bus containing the MBCs.
--
-- The multiplexers are cascaded in such a way to always give priority to
-- certain masters, which is hardcoded behaviour.
--
-- The priorities are as such (from high to low):
--      1. SPI debugger master (signals prefixed with DBG_)
--      2. DMA master (signals prefixed with DMA_)
--      3. Gameboy bus decoder master (signals prefixed with GBD_)
-- 
-- The multiplexers do NOT keep track of bus cycles, meaning that if a
-- transaction is being done by a lower priority master and a higher priority
-- "steals" the bus, the multiplexers WILL switch to the higher priority master.
--
-- This is done intentionally, since only 1 master should be active at any time.
-- The only exception is the DMA and Gameboy masters. The way these are handled,
-- is that while the DMA is active mastering the bus, the GBD_ slave will ignore
-- writes and alyways return x"00" when reading. The DMA registers are still able
-- to be accessed, since these are accessed from a different bus (see 
-- wb_crossbar_decoder.vhd).
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;

entity wb_crossbar_central is
    port (
        -- Global signals
        i_clk           : in std_logic;
        i_rst           : in std_logic;
        i_dma_busy        : in std_logic;
        i_dbg_active      : in std_logic;

        -- Debug master connection
        i_dbg_cyc   : in std_logic;
        o_dbg_ack   : out std_logic;
        i_dbg_we    : in std_logic;
        i_dbg_adr   : in std_logic_vector(15 downto 0);
        o_dbg_dat   : out std_logic_vector(7 downto 0);
        i_dbg_dat   : in std_logic_vector(7 downto 0);

        -- GB decoder master connection
        i_gbd_cyc   : in std_logic;
        o_gbd_ack   : out std_logic;
        i_gbd_we    : in std_logic;
        i_gbd_adr   : in std_logic_vector(15 downto 0);
        o_gbd_dat   : out std_logic_vector(7 downto 0);
        i_gbd_dat   : in std_logic_vector(7 downto 0);

        -- DMA master connection
        i_dma_cyc   : in std_logic;
        o_dma_ack   : out std_logic;
        i_dma_we    : in std_logic;
        i_dma_adr   : in std_logic_vector(15 downto 0);
        o_dma_dat   : out std_logic_vector(7 downto 0);
        i_dma_dat   : in std_logic_vector(7 downto 0);

        -- Master out (routed to MBCs)
        o_cyc   : out std_logic;
        i_ack   : in std_logic;
        o_we    : out std_logic;
        o_adr   : out std_logic_vector(15 downto 0);
        o_dat   : out std_logic_vector(7 downto 0);
        i_dat   : in std_logic_vector(7 downto 0));
end wb_crossbar_central;

architecture rtl of wb_crossbar_central is

    signal n_master_is_dma    : std_logic;
    signal n_master_is_dbg    : std_logic;

    signal n_cart_cyc_o   : std_logic;
    signal n_cart_we_o    : std_logic;
    signal n_cart_adr_o   : std_logic_vector(15 downto 0);
    signal n_cart_dat_o   : std_logic_vector(7 downto 0);

begin

    -- Master selection
    n_master_is_dma <= i_dma_busy;
    n_master_is_dbg <= i_dbg_active;

    -- o_dat signals
    o_dbg_dat <= i_dat;
    o_gbd_dat <= x"00" when n_master_is_dma = '1' else i_dat;
    o_dma_dat <= i_dat;

    -- ACK_O signals
    o_dbg_ack <= i_ack;
    o_gbd_ack <= '1' when n_master_is_dma = '1' else i_ack;
    o_dma_ack <= i_ack;

    -- DMA and GBD output multiplexers
    n_cart_cyc_o <= i_dma_cyc when n_master_is_dma = '1' else i_gbd_cyc;
    n_cart_we_o <= i_dma_we when n_master_is_dma = '1' else i_gbd_we;
    n_cart_adr_o <= i_dma_adr when n_master_is_dma = '1' else i_gbd_adr;
    n_cart_dat_o <= i_dma_dat when n_master_is_dma = '1' else i_gbd_dat;

    -- Master output multiplexers
    o_cyc <= i_dbg_cyc when n_master_is_dbg = '1' else n_cart_cyc_o;
    o_we <= i_dbg_we when n_master_is_dbg = '1' else n_cart_we_o;
    o_adr <= i_dbg_adr when n_master_is_dbg = '1' else n_cart_adr_o;
    o_dat <= i_dbg_dat when n_master_is_dbg = '1' else n_cart_dat_o;

end rtl;