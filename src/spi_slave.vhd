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
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

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

    component synchroniser is
    generic (
        FF_COUNT : natural := 2;
        DATA_WIDTH : natural := 1;
        RESET_VALUE : std_logic := '0');
    port (
        CLK : in std_logic;
        RST : in std_logic;
        DAT_IN : in std_logic_vector(DATA_WIDTH-1 downto 0);
        DAT_OUT : out std_logic_vector(DATA_WIDTH-1 downto 0));
    end component;

    signal spi_clk_sync         : std_logic;
    signal spi_clk_sync_delay   : std_logic;
    signal spi_csn_sync         : std_logic;

    signal spi_clk_has_edge     : std_logic;
    signal spi_clk_has_edge_r   : std_logic;
    signal spi_clk_has_edge_f   : std_logic;
    signal spi_clocked_data     : std_logic_vector(7 downto 0);
    signal spi_data_out         : std_logic;
    signal spi_bit_count        : std_logic_vector(2 downto 0);
    signal spi_byte_received    : std_logic;

begin

    SPI_CLK_SYNCHRONISER : component synchroniser
    port map (
        CLK => CLK_I,
        RST => RST_I,
        DAT_IN(0) => SPI_CLK,
        DAT_OUT(0) => spi_clk_sync);

    SPI_CSN_SYNCHRONISER : component synchroniser
    port map (
        CLK => CLK_I,
        RST => RST_I,
        DAT_IN(0) => SPI_CSN,
        DAT_OUT(0) => spi_csn_sync);

    spi_clk_has_edge <= spi_clk_sync_delay xor spi_clk_sync;
    spi_clk_has_edge_r <= spi_clk_has_edge and spi_clk_sync;
    spi_clk_has_edge_f <= spi_clk_has_edge and spi_clk_sync_delay;
    spi_byte_received <= and_reduce(spi_bit_count);

    process (CLK_I)
    begin
        if rising_edge(CLK_I) then
            if RST_I = '1' then
                spi_clk_sync_delay <= '0';
                spi_clocked_data <= (others => '0');
                spi_data_out <= '0';
                spi_bit_count <= (others => '0');
            else
                spi_clk_sync_delay <= spi_clk_sync;

                -- Rising edge on SPI_CLK
                if (spi_clk_has_edge_r and not(spi_csn_sync)) = '1' then
                    spi_clocked_data <= SPI_MOSI & spi_clocked_data(7 downto 1);
                    spi_bit_count <= std_logic_vector(unsigned(spi_bit_count) + 1);
                end if;

                -- Falling edge on SPI_CLK
                if (spi_clk_has_edge_f and not(spi_csn_sync)) = '1' then
                    spi_data_out <= spi_clocked_data(0);
                end if;

                if (spi_csn_sync or spi_byte_received) = '1' then
                    spi_bit_count <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    SPI_MISO <= spi_data_out when SPI_CSN = '0' else 'Z';

end behaviour;