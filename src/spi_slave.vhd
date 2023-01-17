----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/16/2023 10:35:12 PM
-- Design Name: 
-- Module Name: spi_slave - behaviour
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

entity spi_slave is
    generic (
        CONFIG_SPI_CPOL : std_logic := '0';
        CONFIG_SPI_CPHA : std_logic := '0');
    port (
        -- SPI pins
        SPI_CLK     : in std_logic;
        SPI_CSN     : in std_logic;
        SPI_MOSI    : in std_logic;
        SPI_MISO    : out std_logic;

        -- Wishbone signals
        CLK_I       : in std_logic;
        RST_I       : in std_logic
    );
end spi_slave;

architecture behaviour of spi_slave is

    signal spi_clocked_data : std_logic_vector(7 downto 0);
    signal spi_data_out     : std_logic;

begin

    -- SPI shift register
    process (SPI_CLK, RST_I)
    begin
        if RST_I = '1' then
            spi_clocked_data <= (others => '0');
            spi_data_out <= '0';
        elsif rising_edge(SPI_CLK) and SPI_CSN = '0' then
            spi_clocked_data <= SPI_MOSI & spi_clocked_data(7 downto 1);
        elsif falling_edge(SPI_CLK) and SPI_CSN = '0' then
            spi_data_out <= spi_clocked_data(0);
        end if;
    end process;

    SPI_MISO <= spi_data_out when SPI_CSN = '0' else 'Z';

end behaviour;