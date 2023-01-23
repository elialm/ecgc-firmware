----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/23/2023 13:57:12 PM
-- Design Name: 
-- Module Name: spi_debug_tb - behaviour
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

entity spi_debug_tb is
end spi_debug_tb;

architecture behaviour of spi_debug_tb is

    signal spi_clk          : std_logic := '0';
    signal spi_csn          : std_logic := '1';
    signal spi_mosi         : std_logic := '0';
    signal spi_miso         : std_logic;
    signal clk_i            : std_logic := '0';
    signal rst_i            : std_logic := '1';
    signal cyc_o            : std_logic;
    signal ack_i            : std_logic := '0';
    signal we_o             : std_logic;
    signal adr_o            : std_logic_vector(15 downto 0);
    signal dat_i            : std_logic_vector(7 downto 0) := x"00";
    signal dat_o            : std_logic_vector(7 downto 0);
    signal dbg_enable       : std_logic := '1';
    signal dbg_active       : std_logic;

    signal transaction_id   : natural := 0;

    type SPI_DATA_TYPE is array (integer range <>) of std_logic_vector(7 downto 0);

begin

    DBG_CORE : entity work.spi_debug
    port map (
        CLK_I => clk_i,
        RST_I => rst_i,
        CYC_O => cyc_o,
        ACK_I => ack_i,
        WE_O => we_o,
        ADR_O => adr_o,
        DAT_I => dat_i,
        DAT_O => dat_o,
        SPI_DBG_CLK => spi_clk,
        SPI_DBG_CSN => spi_csn,
        SPI_DBG_MOSI => spi_mosi,
        SPI_DBG_MISO => spi_miso,
        DBG_ENABLE => dbg_enable,
        DBG_ACTIVE => dbg_active);

    -- Main clock
    process
    begin
        loop
            wait for 20 ns;
            clk_i <= not(clk_i);
        end loop;
    end process;

    -- SPI transactions
    process
        variable spi_data : SPI_DATA_TYPE(0 to 8) := (
            b"0000_1111",   -- NOP
            b"0000_0011",   -- SET_ADDR_H
            b"0000_1111",   -- NOP
            b"1010_0000",
            b"0000_0010",   -- SET_ADDR_L
            b"0000_1111",   -- NOP
            b"0101_1001",
            b"0000_0100",   -- AUTO_INC_EN
            b"0000_1111");  -- NOP

        variable current_data : std_logic_vector(7 downto 0);
    begin
        wait for 500 ns;

        for i in spi_data'range loop
            current_data := spi_data(i);
            spi_csn <= '0';

            for j in 0 to 7 loop
                spi_mosi <= current_data(j);
                wait for 500 ns;
                spi_clk <= '1';
                wait for 500 ns;
                spi_clk <= '0';
            end loop;

            wait for 500 ns;
            spi_csn <= '1';
            wait for 500 ns;
        end loop;

        wait;
    end process;

    -- Bus transactions
    process (clk_i)
    begin
        if rising_edge(clk_i) then
            transaction_id <= transaction_id + 1;

            case transaction_id is
                when 0 =>
                    null;
                when 1 =>
                    rst_i <= '0';
                when 2 =>
                    transaction_id <= transaction_id;
                when others =>
                    null;
            end case;
        end if;
    end process;

end behaviour;