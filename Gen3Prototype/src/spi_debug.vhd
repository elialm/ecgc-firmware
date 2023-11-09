----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 01/23/2023 13:26:12 PM
-- Design Name: Cartridge SPI-controlled debug core
-- Module Name: spi_debug - behaviour
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Documentation
--
-- SPI controller debugging core. This core enables one to interface with the
-- main bus via an external SPI master. This is very useful to debug certain
-- features, without having to write an assembly program on the Gameboy for it.
-- 
-- It also allows one to write a program to the boot ROM. The boot ROM is
-- implemented using block RAM, so a write to is is volatile. However, this is
-- very useful for quickly writing a program for testing.
--
-- The debug core will activate upon assertion of the DBG_ENABLE signal. This
-- will assert DBG_ACTIVE, which suppresses certain cores and resets the
-- cartridge. While the core is active, commands can be sent oer SPI.
--
-- The SPI command packages are documented in detail in /doc/spi_debug.md.
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity spi_debug is
    port (
        -- Wishbone signals
        CLK_I   : in std_logic;
        RST_I   : in std_logic;
        CYC_O   : out std_logic;
        ACK_I   : in std_logic;
        WE_O    : out std_logic;
        ADR_O   : out std_logic_vector(15 downto 0);
        DAT_O   : out std_logic_vector(7 downto 0);
        DAT_I   : in std_logic_vector(7 downto 0);

        -- SPI pins
        SPI_DBG_CLK     : in std_logic;
        SPI_DBG_CSN     : in std_logic;
        SPI_DBG_MOSI    : in std_logic;
        SPI_DBG_MISO    : out std_logic;

        -- Control pins
        DBG_ENABLE  : in std_logic;
        DBG_ACTIVE  : out std_logic);
end spi_debug;

architecture behaviour of spi_debug is

    type DBG_STATE_TYPE is (DBGS_DEACTIVATED, DBGS_IDLE, DBGS_AWAIT_NOT_RXRDY, DBGS_IGNORE_RX, DBGS_SET_ADDR_H, DBGS_SET_ADDR_L, DBGS_READ_AWAIT_ACK, DBGS_WRITE_AWAIT_SPI, DBGS_WRITE_AWAIT_ACK);

    component spi_slave is
    port (
        SPI_CLK         : in std_logic;
        SPI_CSN         : in std_logic;
        SPI_MOSI        : in std_logic;
        SPI_MISO        : out std_logic;
        CLK_I           : in std_logic;
        RST_I           : in std_logic;
        CYC_I           : in std_logic;
        WE_I            : in std_logic;
        DAT_I           : in std_logic_vector(7 downto 0);
        DAT_O           : out std_logic_vector(7 downto 0);
        STATUS_RXRDY    : out std_logic;
        STATUS_TXRDY    : out std_logic;
        STATUS_OVERRUN  : out std_logic);
    end component;

    signal spi_slv_cyc      : std_logic;
    signal spi_slv_cyc_d    : std_logic;
    signal spi_slv_we       : std_logic;
    signal spi_slv_dat_i    : std_logic_vector(7 downto 0);
    signal spi_slv_dat_o    : std_logic_vector(7 downto 0);
    signal spi_slv_rxrdy    : std_logic;
    signal spi_slv_txrdy    : std_logic;

    signal current_state            : DBG_STATE_TYPE;
    signal after_not_rxrdy_state    : DBG_STATE_TYPE;
    signal after_ignore_state       : DBG_STATE_TYPE;

    signal dbg_wb_addr      : std_logic_vector(15 downto 0);
    signal dbg_inc_addr     : std_logic;
    signal dbg_inc_addr_en  : std_logic;
    signal dbg_byte_cnt     : std_logic_vector(3 downto 0);
    signal dbg_cnt_is_zero  : std_logic;

begin

    DBG_SPI_SLAVE : component spi_slave
    port map (
        SPI_CLK => SPI_DBG_CLK,
        SPI_CSN => SPI_DBG_CSN,
        SPI_MOSI => SPI_DBG_MOSI,
        SPI_MISO => SPI_DBG_MISO,
        CLK_I => CLK_I,
        RST_I => RST_I,
        CYC_I => spi_slv_cyc,
        WE_I => spi_slv_we,
        DAT_I => spi_slv_dat_i,
        DAT_O => spi_slv_dat_o,
        STATUS_RXRDY => spi_slv_rxrdy,
        STATUS_TXRDY => spi_slv_txrdy,
        STATUS_OVERRUN => open);

    -- Main process
    process (CLK_I)
    begin
        if rising_edge(CLK_I) then
            if RST_I = '1' then
                spi_slv_cyc <= '0';
                spi_slv_cyc_d <= '0';
                spi_slv_we <= '0';
                spi_slv_dat_i <= (others => '0');
                current_state <= DBGS_DEACTIVATED;
                after_not_rxrdy_state <= DBGS_DEACTIVATED;
                after_ignore_state <= DBGS_DEACTIVATED;
                dbg_wb_addr <= (others => '0');
                dbg_inc_addr <= '0';
                dbg_inc_addr_en <= '0';
                dbg_byte_cnt <= (others => '0');

                CYC_O <= '0';
                WE_O <= '0';
                DAT_O <= (others => '0');
                DBG_ACTIVE <= '0';
            else
                spi_slv_cyc <= spi_slv_cyc_d;
                spi_slv_cyc_d <= '0';
                spi_slv_we <= '0';

                -- Increment address
                dbg_inc_addr <= '0';
                if dbg_inc_addr = '1' then
                    dbg_wb_addr <= std_logic_vector(unsigned(dbg_wb_addr) + 1);
                end if;

                -- Debug core state machine
                case current_state is
                    when DBGS_DEACTIVATED => 
                        if DBG_ENABLE = '1' then
                            current_state <= DBGS_IDLE;
                            DBG_ACTIVE <= '1';
                        end if;
                    when DBGS_IDLE =>
                        if DBG_ENABLE = '0' then
                            current_state <= DBGS_DEACTIVATED;
                            DBG_ACTIVE <= '0';
                        elsif spi_slv_rxrdy = '1' then
                            spi_slv_cyc <= '1';
                            spi_slv_cyc_d <= '1';
                            spi_slv_we <= '1';

                            -- Response gives back received cmd code
                            -- Bit 0 indicates valid cmd (1 = valid, 0 = invalid)
                            spi_slv_dat_i <= spi_slv_dat_o(3 downto 0) & "0001";

                            -- Decode SPI data as cmd
                            case spi_slv_dat_o(3 downto 0) is
                                when x"F" =>
                                    -- NOP
                                    after_not_rxrdy_state <= DBGS_IDLE;
                                    current_state <= DBGS_AWAIT_NOT_RXRDY;
                                when x"2" =>
                                    -- SET_ADDR_L
                                    after_not_rxrdy_state <= DBGS_IGNORE_RX;
                                    after_ignore_state <= DBGS_SET_ADDR_L;
                                    current_state <= DBGS_AWAIT_NOT_RXRDY;
                                when x"3" =>
                                    -- SET_ADDR_H
                                    after_not_rxrdy_state <= DBGS_IGNORE_RX;
                                    after_ignore_state <= DBGS_SET_ADDR_H;
                                    current_state <= DBGS_AWAIT_NOT_RXRDY;
                                when x"4" =>
                                    -- AUTO_INC_EN
                                    after_not_rxrdy_state <= DBGS_IDLE;
                                    current_state <= DBGS_AWAIT_NOT_RXRDY;
                                    dbg_inc_addr_en <= '1';
                                when x"5" =>
                                    -- AUTO_INC_DIS
                                    after_not_rxrdy_state <= DBGS_IDLE;
                                    current_state <= DBGS_AWAIT_NOT_RXRDY;
                                    dbg_inc_addr_en <= '0';
                                when x"8" =>
                                    -- READ
                                    after_not_rxrdy_state <= DBGS_IGNORE_RX;
                                    after_ignore_state <= DBGS_READ_AWAIT_ACK;
                                    current_state <= DBGS_AWAIT_NOT_RXRDY;
                                    dbg_byte_cnt <= "0000";
                                when x"9" =>
                                    -- WRITE
                                    after_not_rxrdy_state <= DBGS_IGNORE_RX;
                                    after_ignore_state <= DBGS_WRITE_AWAIT_SPI;
                                    current_state <= DBGS_AWAIT_NOT_RXRDY;
                                    dbg_byte_cnt <= "0000";
                                when x"A" =>
                                    -- READ_BURST
                                    after_not_rxrdy_state <= DBGS_IGNORE_RX;
                                    after_ignore_state <= DBGS_READ_AWAIT_ACK;
                                    current_state <= DBGS_AWAIT_NOT_RXRDY;
                                    dbg_byte_cnt <= "1111";
                                when x"B" =>
                                    -- WRITE_BURST
                                    after_not_rxrdy_state <= DBGS_IGNORE_RX;
                                    after_ignore_state <= DBGS_WRITE_AWAIT_SPI;
                                    current_state <= DBGS_AWAIT_NOT_RXRDY;
                                    dbg_byte_cnt <= "1111";
                                when others =>
                                    -- Invalid cmd
                                    after_not_rxrdy_state <= DBGS_IDLE;
                                    current_state <= DBGS_AWAIT_NOT_RXRDY;
                                    spi_slv_dat_i(0) <= '0';
                            end case;
                        end if;
                    when DBGS_AWAIT_NOT_RXRDY =>
                        if spi_slv_rxrdy = '0' then
                            current_state <= after_not_rxrdy_state;
                        end if;
                    when DBGS_IGNORE_RX =>
                        if spi_slv_rxrdy = '1' then
                            spi_slv_cyc <= '1';
                            spi_slv_cyc_d <= '1';
                            spi_slv_we <= '1';
                            spi_slv_dat_i <= x"00";

                            current_state <= DBGS_AWAIT_NOT_RXRDY;
                            after_not_rxrdy_state <= after_ignore_state;
                        end if;
                    when DBGS_SET_ADDR_H =>
                        if spi_slv_rxrdy = '1' then
                            spi_slv_cyc <= '1';
                            spi_slv_cyc_d <= '1';
                            spi_slv_we <= '1';

                            -- Resend received data for validation
                            spi_slv_dat_i <= spi_slv_dat_o;

                            -- Decode SPI data as high address
                            dbg_wb_addr(15 downto 8) <= spi_slv_dat_o;

                            after_not_rxrdy_state <= DBGS_IDLE;
                            current_state <= DBGS_AWAIT_NOT_RXRDY;
                        end if;
                    when DBGS_SET_ADDR_L =>
                        if spi_slv_rxrdy = '1' then
                            spi_slv_cyc <= '1';
                            spi_slv_cyc_d <= '1';
                            spi_slv_we <= '1';

                            -- Resend received data for validation
                            spi_slv_dat_i <= spi_slv_dat_o;

                            -- Decode SPI data as low address
                            dbg_wb_addr(7 downto 0) <= spi_slv_dat_o;

                            after_not_rxrdy_state <= DBGS_IDLE;
                            current_state <= DBGS_AWAIT_NOT_RXRDY;
                        end if;
                    when DBGS_READ_AWAIT_ACK =>
                        CYC_O <= '1';
                        WE_O <= '0';

                        if ACK_I = '1' then
                            spi_slv_cyc <= '1';
                            spi_slv_we <= '1';
                            spi_slv_dat_i <= DAT_I;
                            dbg_inc_addr <= dbg_inc_addr_en;
                            dbg_byte_cnt <= std_logic_vector(unsigned(dbg_byte_cnt) - 1);

                            current_state <= DBGS_IGNORE_RX;
                            after_ignore_state <= DBGS_IDLE
                                when dbg_cnt_is_zero = '1'
                                else DBGS_READ_AWAIT_ACK;

                            CYC_O <= '0';
                        end if;
                    when DBGS_WRITE_AWAIT_SPI =>
                        if spi_slv_rxrdy = '1' then
                            spi_slv_cyc <= '1';
                            spi_slv_cyc_d <= '1';
                            spi_slv_we <= '1';
                            spi_slv_dat_i <= spi_slv_dat_o;
                            DAT_O <= spi_slv_dat_o;

                            current_state <= DBGS_AWAIT_NOT_RXRDY;
                            after_not_rxrdy_state <= DBGS_WRITE_AWAIT_ACK;
                        end if;
                    when DBGS_WRITE_AWAIT_ACK =>
                        CYC_O <= '1';
                        WE_O <= '1';

                        if ACK_I = '1' then
                            dbg_inc_addr <= dbg_inc_addr_en;
                            dbg_byte_cnt <= std_logic_vector(unsigned(dbg_byte_cnt) - 1);

                            current_state <= DBGS_IDLE
                                when dbg_cnt_is_zero = '1'
                                else DBGS_WRITE_AWAIT_SPI;

                            CYC_O <= '0';
                        end if;
                    when others =>
                        current_state <= DBGS_DEACTIVATED;
                        DBG_ACTIVE <= '0';
                end case;
            end if;
        end if;
    end process;

    dbg_cnt_is_zero <= nor_reduce(dbg_byte_cnt);
    ADR_O <= dbg_wb_addr;

end behaviour;
