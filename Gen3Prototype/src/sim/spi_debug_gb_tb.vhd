----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/27/2023 14:08:12 PM
-- Design Name: 
-- Module Name: spi_debug_gb_tb - behaviour
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
use ieee.numeric_std.all;
use ieee.math_real.all;

entity spi_debug_tb is
end spi_debug_tb;

architecture behaviour of spi_debug_tb is

    signal gb_clk       : std_logic := '0';
    signal gb_resetn    : std_logic;
    signal gb_addr      : std_logic_vector(15 downto 0) := x"0000";
    signal gb_data      : std_logic_vector(7 downto 0);
    signal gb_rdn       : std_logic := '1';
    signal gb_csn       : std_logic := '1';
    signal spi_clk      : std_logic;
    signal spi_miso     : std_logic := '0';
    signal spi_mosi     : std_logic;
    signal spi_hard_csn : std_logic;
    signal spi_sdc_csn  : std_logic;
    signal dbg_clk      : std_logic := '0';
    signal dbg_csn      : std_logic := '1';
    signal dbg_mosi     : std_logic := '0';
    signal dbg_miso     : std_logic;
    signal dbg_enable   : std_logic := '0';
    signal bta_oen      : std_logic;
    signal btd_oen      : std_logic;
    signal btd_dir      : std_logic;
    signal dram_clk     : std_logic;
    signal dram_cke     : std_logic;
    signal dram_ba      : std_logic_vector(1 downto 0);
    signal dram_a       : std_logic_vector(12 downto 0);
    signal dram_csn     : std_logic;
    signal dram_rasn    : std_logic;
    signal dram_casn    : std_logic;
    signal dram_wen     : std_logic;
    signal dram_dqm     : std_logic;
    signal dram_dq      : std_logic_vector(7 downto 0);
    signal user_rst     : std_logic := '0';
    signal status_led   : std_logic_vector(7 downto 0);

    type SPI_DATA_TYPE is array (integer range <>) of std_logic_vector(7 downto 0);

begin

    CARTRIDGE_INST : entity work.cart_tl
    generic map (
        SIMULATION => true)
    port map (
        GB_CLK => gb_clk,
        GB_RESETN => gb_resetn,
        GB_ADDR => gb_addr,
        GB_DATA => gb_data,
        GB_RDN => gb_rdn,
        GB_CSN => gb_csn,
        SPI_CLK => spi_clk,
        SPI_MISO => spi_miso,
        SPI_MOSI => spi_mosi,
        SPI_HARD_CSN => spi_hard_csn,
        SPI_SDC_CSN => spi_sdc_csn,
        DBG_CLK => dbg_clk,
        DBG_CSN => dbg_csn,
        DBG_MOSI => dbg_mosi,
        DBG_MISO => dbg_miso,
        DBG_ENABLE => dbg_enable,
        BTA_OEN => bta_oen,
        BTD_OEN => btd_oen,
        BTD_DIR => btd_dir,
        DRAM_CLK => dram_clk,
        DRAM_CKE => dram_cke,
        DRAM_BA => dram_ba,
        DRAM_A => dram_a,
        DRAM_CSN => dram_csn,
        DRAM_RASN => dram_rasn,
        DRAM_CASN => dram_casn,
        DRAM_WEN => dram_wen,
        DRAM_DQM => dram_dqm,
        DRAM_DQ => dram_dq,
        USER_RST => user_rst,
        STATUS_LED => status_led);

    -- SPI transactions
    process
        variable spi_data : SPI_DATA_TYPE(0 to 50) := (
            b"0000_1111",   -- NOP
            b"0000_0011",   -- SET_ADDR_H
            b"0000_1111",   -- NOP
            b"0000_0000",
            b"0000_0010",   -- SET_ADDR_L
            b"0000_1111",   -- NOP
            b"0000_0000",
            b"0000_0100",   -- AUTO_INC_EN
            b"0000_1111",   -- NOP
            b"0000_1000",   -- READ
            b"0000_1111",   -- NOP
            b"0000_1111",   -- NOP
            b"0000_1010",   -- READ_BURST
            b"0000_1111",   -- NOP
            b"0000_1111",   -- NOP
            b"0000_1111",   -- NOP
            b"0000_1111",   -- NOP
            b"0000_1111",   -- NOP
            b"0000_1111",   -- NOP
            b"0000_1111",   -- NOP
            b"0000_1111",   -- NOP
            b"0000_1111",   -- NOP
            b"0000_1111",   -- NOP
            b"0000_1111",   -- NOP
            b"0000_1111",   -- NOP
            b"0000_1111",   -- NOP
            b"0000_1111",   -- NOP
            b"0000_1111",   -- NOP
            b"0000_1111",   -- NOP
            b"0000_1111",   -- NOP
            b"0000_1001",   -- WRITE
            b"0000_1111",   -- NOP
            b"0101_0011",
            b"0000_1011",   -- WRITE_BURST
            b"0000_1111",   -- NOP
            b"0001_1000",
            b"0100_0000",
            b"0101_1111",
            b"0000_0110",
            b"1001_0000",
            b"0101_0000",
            b"1101_1100",
            b"0011_1111",
            b"1011_1010",
            b"0011_0001",
            b"1100_1110",
            b"1110_1010",
            b"0000_1011",
            b"0000_0000",
            b"1000_1001",
            b"1110_1100");

        variable current_data : std_logic_vector(7 downto 0);
    begin
        wait for 500 ns;
        wait for 6 us;

        dbg_enable <= '1';

        for i in spi_data'range loop
            current_data := spi_data(i);
            dbg_csn <= '0';

            for j in 0 to 7 loop
                dbg_mosi <= current_data(j);
                wait for 500 ns;
                dbg_clk <= '1';
                wait for 500 ns;
                dbg_clk <= '0';
            end loop;

            wait for 500 ns;
            dbg_csn <= '1';
            wait for 500 ns;
        end loop;

        dbg_enable <= '0';

        wait;
    end process;

end behaviour;