----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/16/2023 10:57:12 PM
-- Design Name: 
-- Module Name: spi_slave_tb - behaviour
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

entity spi_slave_tb is
end spi_slave_tb;

architecture behaviour of spi_slave_tb is

    signal spi_clk          : std_logic := '0';
    signal spi_csn          : std_logic := '1';
    signal spi_mosi         : std_logic := '0';
    signal spi_miso         : std_logic;
    signal clk_i            : std_logic := '0';
    signal rst_i            : std_logic := '1';
    signal cyc_i            : std_logic := '0';
    signal we_i             : std_logic := '0';
    signal dat_i            : std_logic_vector(7 downto 0) := x"00";
    signal dat_o            : std_logic_vector(7 downto 0);
    signal status_rxrdy     : std_logic;
    signal status_txrdy     : std_logic;
    signal status_overrun   : std_logic;

    signal transaction_id   : natural := 0;

    type SPI_DATA_TYPE is array (integer range <>) of std_logic_vector(8 downto 0);

begin

    SPI_SLAVE : entity work.spi_slave
    port map (
        SPI_CLK => spi_clk,
        SPI_CSN => spi_csn,
        SPI_MOSI => spi_mosi,
        SPI_MISO => spi_miso,
        CLK_I => clk_i,
        RST_I => rst_i,
        CYC_I => cyc_i,
        WE_I => we_i,
        DAT_I => dat_i,
        DAT_O => dat_o,
        STATUS_RXRDY => status_rxrdy,
        STATUS_TXRDY => status_txrdy,
        STATUS_OVERRUN => status_overrun);

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
        variable spi_data : SPI_DATA_TYPE(0 to 3) := (
            b"0_1010_1010",
            b"1_1111_0101",
            b"0_0110_1001",
            b"0_1111_1111");

        variable current_data : std_logic_vector(8 downto 0);
    begin
        wait for 500 ns;

        for i in spi_data'range loop
            current_data := spi_data(i);
            spi_csn <= current_data(8);

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
                when 220 =>
                    cyc_i <= '1';
                when 221 =>
                    we_i <= '1';
                    dat_i <= x"8E";
                when 222 =>
                    cyc_i <= '0';
                    we_i <= '0';
                when 223 =>
                    transaction_id <= transaction_id;
                when others =>
                    null;
            end case;
        end if;
    end process;

end behaviour;