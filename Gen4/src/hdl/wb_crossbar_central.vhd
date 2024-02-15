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
        i_dat   : in std_logic_vector(7 downto 0)
    );
end wb_crossbar_central;

architecture rtl of wb_crossbar_central is

    alias n_master_is_dbg : std_logic is i_dbg_active;
    alias n_master_is_dma : std_logic is i_dma_busy;
    signal n_master_is_gbd : std_logic;
    signal r_ack_d : std_logic;

begin

    n_master_is_gbd <= n_master_is_dbg nor n_master_is_dma;

    inst_crossbar: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                -- o_dbg_dat <= (others => '0');
                -- o_dma_dat <= (others => '0');
                -- o_gbd_dat <= (others => '0');
                o_dbg_ack <= '0';
                o_dma_ack <= '0';
                o_gbd_ack <= '0';
                o_cyc <= '0';
                -- o_we <= '0';
                -- o_adr <= (others => '0');
                -- o_dat <= (others => '0');
                r_ack_d <= '0';
            else
                -- delayed ack
                r_ack_d <= i_ack;

                -- assign slave o_dat lines
                o_dbg_dat <= i_dat;
                o_dma_dat <= i_dat;
                o_gbd_dat <= i_dat;

                -- assign slave o_ack lines
                o_dbg_ack <= i_ack when n_master_is_dbg = '1' else '0';
                o_dma_ack <= i_ack when n_master_is_dma = '1' else '0';
                o_gbd_ack <= i_ack when n_master_is_gbd = '1' else '0';

                -- select bus master
                if n_master_is_dbg = '1' then
                    o_cyc <= i_dbg_cyc;
                    o_we <= i_dbg_we;
                    o_adr <= i_dbg_adr;
                    o_dat <= i_dbg_dat;
                elsif n_master_is_dma = '1' then
                    o_cyc <= i_dma_cyc;
                    o_we <= i_dma_we;
                    o_adr <= i_dma_adr;
                    o_dat <= i_dma_dat;
                else
                    o_cyc <= i_gbd_cyc;
                    o_we <= i_gbd_we;
                    o_adr <= i_gbd_adr;
                    o_dat <= i_gbd_dat;
                end if;

                -- drive o_cyc low to compensate for FF delay
                if (i_ack or r_ack_d) = '1' then
                    o_cyc <= '0';
                end if;
            end if;
        end if;
    end process inst_crossbar;

end rtl;