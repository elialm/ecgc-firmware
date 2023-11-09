----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 09/11/2023 15:44:31 PM
-- Design Name: Cartridge top level
-- Module Name: cart_tl - behaviour
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Documentation
--
-- This is the cartridge's toplevel VHDL file. It contains the instances of all
-- the necessary cores for implementing the cartridge functions.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity cart_tl is
    port (
        -- Clocking and reset
        FPGA_CLK33M    : in std_logic;
        CLK_EN         : out std_logic;
        FPGA_SOFT_RSTN : in std_logic;

        -- GB related ports
        GB_ADDR   : in std_logic_vector(15 downto 0);
        GB_DATA   : inout std_logic_vector(7 downto 0);
        GB_BUS_EN : out std_logic;
        GB_CLK    : in std_logic;
        GB_CSN    : in std_logic;
        GB_RDN    : in std_logic;
        GB_WRN    : in std_logic;
        GB_RSTN   : out std_logic;

        -- RAM related ports
        RAM_ADQ  : inout std_logic_vector(15 downto 0);
        RAM_A    : out std_logic_vector(5 downto 0);
        RAM_ADVN : out std_logic;
        RAM_CE0N : out std_logic;
        RAM_CE1N : out std_logic;
        RAM_CLK  : out std_logic;
        RAM_CRE  : out std_logic;
        RAM_LBN  : out std_logic;
        RAM_UBN  : out std_logic;
        RAM_OEN  : out std_logic;
        RAM_WAIT : in std_logic;
        RAM_WEN  : out std_logic;

        -- SPI related signals
        FPGA_SPI_CLK       : inout std_logic;
        FPGA_SPI_MISO      : inout std_logic;
        FPGA_SPI_MOSI      : inout std_logic;
        FPGA_SPI_FLASH_CSN : out std_logic;
        FPGA_SPI_RTC_CSN   : out std_logic;
        FPGA_SPI_SD_CSN    : out std_logic;

        -- Miscellaneous signals
        FPGA_USER      : inout std_logic_vector(5 downto 0);
        RTC_RSTN       : in std_logic;
        SD_CARD_DETECT : in std_logic
    );
end entity cart_tl;

architecture rtl of cart_tl is

    signal gb_data_incoming : std_logic_vector(7 downto 0);
    signal gb_data_outgoing : std_logic_vector(7 downto 0);

    signal gbd_cyc : std_logic;
    signal gbd_we : std_logic;
    signal gbd_adr : std_logic_vector(15 downto 0);
    signal gbd_dat_i : std_logic_vector(7 downto 0);
    signal gbd_dat_o : std_logic_vector(7 downto 0);
    signal gbd_ack : std_logic;

    signal gb_timeout_rd : std_logic;
    signal gb_timeout_wr : std_logic;

begin

    -- Gameboy decoder instance
    GB_SIGNAL_DECODER : entity work.gb_decoder
        generic map(
            ENABLE_TIMEOUT_DETECTION => true)
        port map(
            GB_CLK      => GB_CLK,
            GB_ADDR     => GB_ADDR,
            GB_DATA_IN  => gb_data_incoming,
            GB_DATA_OUT => gb_data_outgoing,
            GB_RDN      => GB_RDN,
            GB_CSN      => GB_CSN,

            CLK_I => FPGA_CLK33M,
            RST_I => FPGA_SOFT_RSTN,
            CYC_O => gbd_cyc,
            WE_O  => gbd_we,
            ADR_O => gbd_adr,
            DAT_I => gbd_dat_i,
            DAT_O => gbd_dat_o,
            ACK_I => gbd_ack,

            ACCESS_ROM    => open,
            ACCESS_RAM    => open,
            REFRESH_BLOCK => open,
            RD_TIMEOUT    => gb_timeout_rd,
            WR_TIMEOUT    => gb_timeout_wr);

    CLK_EN <= '1';
    GB_DATA <= (others => 'Z');
    GB_BUS_EN <= '0';
    GB_RSTN <= '1';

    RAM_ADQ <= (others => 'Z');
    RAM_A <= "000000";
    RAM_ADVN <= '0';
    RAM_CE0N <= '0';
    RAM_CE1N <= '0';
    RAM_CLK <= '0';
    RAM_CRE <= '0';
    RAM_LBN <= '0';
    RAM_UBN <= '0';
    RAM_OEN <= '0';
    RAM_WEN <= '0';

    FPGA_SPI_CLK <= 'Z';
    FPGA_SPI_MISO <= 'Z';
    FPGA_SPI_MOSI <= 'Z';
    FPGA_SPI_FLASH_CSN <= '1';
    FPGA_SPI_RTC_CSN <= '1';
    FPGA_SPI_SD_CSN <= '1';

    FPGA_USER <= "ZZZZZZ";

end architecture rtl;