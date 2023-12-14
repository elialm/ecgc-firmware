----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/31/2022 02:16:43 PM
-- Design Name: 
-- Module Name: testbench - rtl
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

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity gameboy_tb is
end gameboy_tb;

architecture rtl of gameboy_tb is

    component cart_tl
        generic (
            SIMULATION : boolean := TRUE
        );
        port (
            FPGA_CLK33M        : in std_logic;
            CLK_EN             : out std_logic;
            FPGA_SOFT_RSTN     : in std_logic;
            GB_ADDR            : in std_logic_vector(15 downto 0);
            GB_DATA            : inout std_logic_vector(7 downto 0);
            GB_BUS_EN          : out std_logic;
            GB_CLK             : in std_logic;
            GB_CSN             : in std_logic;
            GB_RDN             : in std_logic;
            GB_WRN             : in std_logic;
            GB_RSTN            : out std_logic;
            RAM_ADQ            : inout std_logic_vector(15 downto 0);
            RAM_A              : out std_logic_vector(5 downto 0);
            RAM_ADVN           : out std_logic;
            RAM_CE0N           : out std_logic;
            RAM_CE1N           : out std_logic;
            RAM_CLK            : out std_logic;
            RAM_CRE            : out std_logic;
            RAM_LBN            : out std_logic;
            RAM_UBN            : out std_logic;
            RAM_OEN            : out std_logic;
            RAM_WAIT           : in std_logic;
            RAM_WEN            : out std_logic;
            FPGA_SPI_CLK       : inout std_logic;
            FPGA_SPI_MISO      : inout std_logic;
            FPGA_SPI_MOSI      : inout std_logic;
            FPGA_SPI_FLASH_CSN : out std_logic;
            FPGA_SPI_RTC_CSN   : out std_logic;
            FPGA_SPI_SD_CSN    : out std_logic;
            FPGA_USER          : inout std_logic_vector(5 downto 0);
            RTC_RSTN           : in std_logic;
            SD_CARD_DETECT     : in std_logic
        );
    end component;

    signal fpga_clk33m : std_logic := '0';
    signal clk_en : std_logic;
    signal fpga_soft_rstn : std_logic := '0';
    signal gb_addr : std_logic_vector(15 downto 0);
    signal gb_data : std_logic_vector(7 downto 0);
    signal gb_bus_en : std_logic;
    signal gb_clk : std_logic := '0';
    signal gb_csn : std_logic := '1';
    signal gb_rdn : std_logic := '1';
    signal gb_wrn : std_logic := '1';
    signal gb_rstn : std_logic;
    signal ram_adq : std_logic_vector(15 downto 0);
    signal ram_a : std_logic_vector(5 downto 0);
    signal ram_advn : std_logic;
    signal ram_ce0n : std_logic;
    signal ram_ce1n : std_logic;
    signal ram_clk : std_logic;
    signal ram_cre : std_logic;
    signal ram_lbn : std_logic;
    signal ram_ubn : std_logic;
    signal ram_oen : std_logic;
    signal ram_wait : std_logic := '0';
    signal ram_wen : std_logic;
    signal fpga_spi_clk : std_logic;
    signal fpga_spi_miso : std_logic;
    signal fpga_spi_mosi : std_logic;
    signal fpga_spi_flash_csn : std_logic;
    signal fpga_spi_rtc_csn : std_logic;
    signal fpga_spi_sd_csn : std_logic;
    signal fpga_user : std_logic_vector(5 downto 0);
    signal rtc_rstn : std_logic := '1';
    signal sd_card_detect : std_logic := '1';

    --Each element is a bitfield
        --0-7       : data (if write)
        --8-23      : address
        --24        : 0 = read, 1 = write
        --25        : 1 = perform cart access, 0 = perform internal access
    type gb_bus_transactions is array (integer range <>) of std_logic_vector(25 downto 0);
    constant test_bus_transactions : gb_bus_transactions(0 to 24) := (
        b"10_0000_0001_0000_0000_0000_0000",    -- NOP
        b"10_0000_0001_0000_0001_0000_0000",    -- JP $0150
        b"10_0000_0001_0000_0010_0000_0000",
        b"10_0000_0001_0000_0011_0000_0000",
        b"00_0000_0000_0000_0000_0000_0000",    -- idle bus...
        b"10_0000_0001_0101_0000_0000_0000",    -- DI 
        b"10_0000_0001_0101_0001_0000_0000",    -- LD SP, $FFFE
        b"10_0000_0001_0101_0010_0000_0000",
        b"10_0000_0001_0101_0011_0000_0000",
        b"10_0000_0001_0101_0100_0000_0000",    -- LD HL, $FF40
        b"10_0000_0001_0101_0101_0000_0000",
        b"10_0000_0001_0101_0110_0000_0000",
        b"10_0000_0001_0101_0111_0000_0000",    -- RES 7, [HL]
        b"10_0000_0001_0101_1000_0000_0000",
        b"00_0000_0000_0000_0000_0000_0000",    -- idle bus...
        b"00_0000_0000_0000_0000_0000_0000",    -- idle bus...
        b"11_0000_0001_0000_0000_1010_0101",    -- not an instruction, just to test if cart correctly ignores writes to ROM
        b"10_0100_0000_0000_0000_0000_0000",    -- Read from DRAM
        b"11_0100_0000_0000_0000_1010_0101",    -- Write to DRAM
        b"10_1011_0000_0000_0000_0000_0000",    -- Read from cart RAM
        b"11_1011_0000_0000_0000_0011_1111",    -- Write to cart RAM
        b"10_1010_0000_0101_0100_0000_0000",    -- Read from cart RAM (or cart IO space, who knows)
        b"10_1010_0001_0000_0000_0000_0000",    -- Read from cart RAM (or cart IO space, who knows)
        b"11_1010_0000_0101_0101_1000_0000",    -- Write to cart RAM (or cart IO space, who knows)
        b"10_0000_0001_0000_0000_0000_0000"     -- followed by a read to see if the cart recovers
    );

    -- As the name suggests, enable double speed mode in simulation
    constant enable_double_speed : boolean := FALSE;

begin

    -- 33.333333 MHz clock
    fpga_clk33m <= not(fpga_clk33m) after 15 ns;

    inst_cart : cart_tl
    port map(
        FPGA_CLK33M => fpga_clk33m,
        CLK_EN => clk_en,
        FPGA_SOFT_RSTN => fpga_soft_rstn,
        GB_ADDR => gb_addr,
        GB_DATA => gb_data,
        GB_BUS_EN => gb_bus_en,
        GB_CLK => gb_clk,
        GB_CSN => gb_csn,
        GB_RDN => gb_rdn,
        GB_WRN => gb_wrn,
        GB_RSTN => gb_rstn,
        RAM_ADQ => ram_adq,
        RAM_A => ram_a,
        RAM_ADVN => ram_advn,
        RAM_CE0N => ram_ce0n,
        RAM_CE1N => ram_ce1n,
        RAM_CLK => ram_clk,
        RAM_CRE => ram_cre,
        RAM_LBN => ram_lbn,
        RAM_UBN => ram_ubn,
        RAM_OEN => ram_oen,
        RAM_WAIT => ram_wait,
        RAM_WEN => ram_wen,
        FPGA_SPI_CLK => fpga_spi_clk,
        FPGA_SPI_MISO => fpga_spi_miso,
        FPGA_SPI_MOSI => fpga_spi_mosi,
        FPGA_SPI_FLASH_CSN => fpga_spi_flash_csn,
        FPGA_SPI_RTC_CSN => fpga_spi_rtc_csn,
        FPGA_SPI_SD_CSN => fpga_spi_sd_csn,
        FPGA_USER => fpga_user,
        RTC_RSTN => rtc_rstn,
        SD_CARD_DETECT => sd_card_detect
    );
    
    -- GameBoy simulation
    process
        type bus_state is (BS_CLK_UP_UP, BS_CLK_UP_DOWN, BS_CLK_HIGH_UP, BS_CLK_HIGH_DOWN, BS_CLK_DOWN_UP, BS_CLK_DOWN_DOWN, BS_CLK_LOW_UP, BS_CLK_LOW_DOWN);
    
        variable current_transaction : std_logic_vector(25 downto 0);
        variable transaction_address : std_logic_vector(15 downto 0);
        variable transaction_data : std_logic_vector(7 downto 0);
        variable transaction_is_idle : boolean;
        variable transaction_is_read : boolean;
    begin
        -- Wait a bit for the PLL to lock and GB_RSTN to deassert
        wait for 5 us;
    
        for i in test_bus_transactions'low to test_bus_transactions'high loop
            current_transaction := test_bus_transactions(i);
            transaction_address := current_transaction(23 downto 8);
            transaction_data := current_transaction(7 downto 0);
            transaction_is_idle := current_transaction(25) = '0';
            transaction_is_read := current_transaction(24) = '0';
            
            for state in bus_state loop
                if enable_double_speed then
                    wait for 62500 ps;  -- Double speed (GBC)
                else
                    wait for 125 ns; -- Normal speed (DMG)
                end if;

                if not(transaction_is_idle) then
                    case state is
                        when BS_CLK_UP_UP =>
                            gb_clk <= '1';
                            gb_data <= (others => 'U');
                            gb_addr(14 downto 0) <= (others => 'U');
                            gb_rdn <= '0';
                            gb_addr(15) <= '1';
                            gb_csn <= '1';
                        when BS_CLK_UP_DOWN =>
                            gb_addr(14 downto 0) <= transaction_address(14 downto 0);
                            if not(transaction_is_read) then
                                gb_rdn <= '1';
                            end if;
                        when BS_CLK_HIGH_UP =>
                            gb_addr(15) <= transaction_address(15);
                            gb_csn <= not(transaction_address(15));
                            -- Data should be presented during read
                            if transaction_is_read then
                                gb_data <= (others => 'Z');
                            end if;
                        when BS_CLK_HIGH_DOWN =>
                            null;
                        when BS_CLK_DOWN_UP =>
                            gb_clk <= '0';
                            if not(transaction_is_read) then
                                gb_wrn <= '0';
                                gb_data <= transaction_data;
                            end if;
                        when BS_CLK_DOWN_DOWN =>
                            null;
                        when BS_CLK_LOW_UP =>
                            -- Data is sampled by the Gameboy (I think?)
                            null;
                        when BS_CLK_LOW_DOWN =>
                            gb_wrn <= '1';
                    end case;
                else
                    gb_addr(14 downto 0) <= (others => 'U');
                    gb_addr(15) <= '1';
                    gb_csn <= '1';
                    gb_data <= (others => 'U');
                    gb_rdn <= '0';
                    gb_wrn <= '1';
                    
                    case state is
                        when BS_CLK_UP_UP =>
                            gb_clk <= '1';
                        when BS_CLK_DOWN_UP =>
                            gb_clk <= '0';
                        when others =>
                            null;
                    end case;
                end if;
            end loop;
        end loop;
        
        wait;
    end process;
        
end rtl;
