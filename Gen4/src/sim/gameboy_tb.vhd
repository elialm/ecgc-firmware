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
            p_simulation : boolean := TRUE
        );
        port (
            i_fpga_clk33m        : in std_logic;
            o_clk_en             : out std_logic;
            i_fpga_rstn          : in std_logic;
            i_gb_addr            : in std_logic_vector(15 downto 0);
            io_gb_data           : inout std_logic_vector(7 downto 0);
            o_gb_bus_en          : out std_logic;
            i_gb_clk             : in std_logic;
            i_gb_csn             : in std_logic;
            i_gb_rdn             : in std_logic;
            i_gb_wrn             : in std_logic;
            o_gb_rstn            : out std_logic;
            io_ram_adq           : inout std_logic_vector(15 downto 0);
            o_ram_a              : out std_logic_vector(5 downto 0);
            o_ram_advn           : out std_logic;
            o_ram_ce0n           : out std_logic;
            o_ram_ce1n           : out std_logic;
            o_ram_clk            : out std_logic;
            o_ram_cre            : out std_logic;
            o_ram_lbn            : out std_logic;
            o_ram_ubn            : out std_logic;
            o_ram_oen            : out std_logic;
            i_ram_wait           : in std_logic;
            o_ram_wen            : out std_logic;
            io_fpga_spi_clk      : inout std_logic;
            io_fpga_spi_miso     : inout std_logic;
            io_fpga_spi_mosi     : inout std_logic;
            o_fpga_spi_flash_csn : out std_logic;
            o_fpga_spi_rtc_csn   : out std_logic;
            o_fpga_spi_sd_csn    : out std_logic;
            io_fpga_user         : inout std_logic_vector(5 downto 0);
            i_rtc_rstn           : in std_logic;
            i_sd_card_detect     : in std_logic
        );
    end component;

    signal n_fpga_clk33m : std_logic := '0';
    signal n_clk_en : std_logic;
    signal n_fpga_soft_rstn : std_logic := '1';
    signal n_gb_addr : std_logic_vector(15 downto 0);
    signal n_gb_data : std_logic_vector(7 downto 0);
    signal n_gb_bus_en : std_logic;
    signal n_gb_clk : std_logic := '0';
    signal n_gb_csn : std_logic := '1';
    signal n_gb_rdn : std_logic := '1';
    signal n_gb_wrn : std_logic := '1';
    signal n_gb_rstn : std_logic;
    signal n_ram_adq : std_logic_vector(15 downto 0);
    signal n_ram_a : std_logic_vector(5 downto 0);
    signal n_ram_advn : std_logic;
    signal n_ram_ce0n : std_logic;
    signal n_ram_ce1n : std_logic;
    signal n_ram_clk : std_logic;
    signal n_ram_cre : std_logic;
    signal n_ram_lbn : std_logic;
    signal n_ram_ubn : std_logic;
    signal n_ram_oen : std_logic;
    signal n_ram_wait : std_logic := '0';
    signal n_ram_wen : std_logic;
    signal n_fpga_spi_clk : std_logic;
    signal n_fpga_spi_miso : std_logic;
    signal n_fpga_spi_mosi : std_logic;
    signal n_fpga_spi_flash_csn : std_logic;
    signal n_fpga_spi_rtc_csn : std_logic;
    signal n_fpga_spi_sd_csn : std_logic;
    signal n_fpga_user : std_logic_vector(5 downto 0);
    signal n_rtc_rstn : std_logic := '1';
    signal n_sd_card_detect : std_logic := '1';

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
    n_fpga_clk33m <= not(n_fpga_clk33m) after 15 ns;

    inst_cart : cart_tl
    port map(
        i_fpga_clk33m => n_fpga_clk33m,
        o_clk_en => n_clk_en,
        i_fpga_rstn => n_fpga_soft_rstn,
        i_gb_addr => n_gb_addr,
        io_gb_data => n_gb_data,
        o_gb_bus_en => n_gb_bus_en,
        i_gb_clk => n_gb_clk,
        i_gb_csn => n_gb_csn,
        i_gb_rdn => n_gb_rdn,
        i_gb_wrn => n_gb_wrn,
        o_gb_rstn => n_gb_rstn,
        io_ram_adq => n_ram_adq,
        o_ram_a => n_ram_a,
        o_ram_advn => n_ram_advn,
        o_ram_ce0n => n_ram_ce0n,
        o_ram_ce1n => n_ram_ce1n,
        o_ram_clk => n_ram_clk,
        o_ram_cre => n_ram_cre,
        o_ram_lbn => n_ram_lbn,
        o_ram_ubn => n_ram_ubn,
        o_ram_oen => n_ram_oen,
        i_ram_wait => n_ram_wait,
        o_ram_wen => n_ram_wen,
        io_fpga_spi_clk => n_fpga_spi_clk,
        io_fpga_spi_miso => n_fpga_spi_miso,
        io_fpga_spi_mosi => n_fpga_spi_mosi,
        o_fpga_spi_flash_csn => n_fpga_spi_flash_csn,
        o_fpga_spi_rtc_csn => n_fpga_spi_rtc_csn,
        o_fpga_spi_sd_csn => n_fpga_spi_sd_csn,
        io_fpga_user => n_fpga_user,
        i_rtc_rstn => n_rtc_rstn,
        i_sd_card_detect => n_sd_card_detect
    );
    
    -- GameBoy simulation
    process
        type bus_state is (BS_CLK_UP_UP, BS_CLK_UP_DOWN, BS_CLK_HIGH_UP, BS_CLK_HIGH_DOWN, BS_CLK_DOWN_UP, BS_CLK_DOWN_DOWN, BS_CLK_LOW_UP, BS_CLK_LOW_DOWN);
    
        variable v_current_transaction : std_logic_vector(25 downto 0);
        variable v_transaction_address : std_logic_vector(15 downto 0);
        variable v_transaction_data : std_logic_vector(7 downto 0);
        variable v_transaction_is_idle : boolean;
        variable v_transaction_is_read : boolean;
    begin
        -- Wait a bit for the PLL to lock and o_gb_rstn to deassert
        wait for 5 us;
    
        for i in test_bus_transactions'low to test_bus_transactions'high loop
            v_current_transaction := test_bus_transactions(i);
            v_transaction_address := v_current_transaction(23 downto 8);
            v_transaction_data := v_current_transaction(7 downto 0);
            v_transaction_is_idle := v_current_transaction(25) = '0';
            v_transaction_is_read := v_current_transaction(24) = '0';
            
            for state in bus_state loop
                if enable_double_speed then
                    wait for 62500 ps;  -- Double speed (GBC)
                else
                    wait for 125 ns; -- Normal speed (DMG)
                end if;

                if not(v_transaction_is_idle) then
                    case state is
                        when BS_CLK_UP_UP =>
                            n_gb_clk <= '1';
                            n_gb_data <= (others => 'U');
                            n_gb_addr(14 downto 0) <= (others => 'U');
                            n_gb_rdn <= '0';
                            n_gb_addr(15) <= '1';
                            n_gb_csn <= '1';
                        when BS_CLK_UP_DOWN =>
                            n_gb_addr(14 downto 0) <= v_transaction_address(14 downto 0);
                            if not(v_transaction_is_read) then
                                n_gb_rdn <= '1';
                            end if;
                        when BS_CLK_HIGH_UP =>
                            n_gb_addr(15) <= v_transaction_address(15);
                            n_gb_csn <= not(v_transaction_address(15));
                            -- Data should be presented during read
                            if v_transaction_is_read then
                                n_gb_data <= (others => 'Z');
                            end if;
                        when BS_CLK_HIGH_DOWN =>
                            null;
                        when BS_CLK_DOWN_UP =>
                            n_gb_clk <= '0';
                            if not(v_transaction_is_read) then
                                n_gb_wrn <= '0';
                                n_gb_data <= v_transaction_data;
                            end if;
                        when BS_CLK_DOWN_DOWN =>
                            null;
                        when BS_CLK_LOW_UP =>
                            -- Data is sampled by the Gameboy (I think?)
                            null;
                        when BS_CLK_LOW_DOWN =>
                            n_gb_wrn <= '1';
                    end case;
                else
                    n_gb_addr(14 downto 0) <= (others => 'U');
                    n_gb_addr(15) <= '1';
                    n_gb_csn <= '1';
                    n_gb_data <= (others => 'U');
                    n_gb_rdn <= '0';
                    n_gb_wrn <= '1';
                    
                    case state is
                        when BS_CLK_UP_UP =>
                            n_gb_clk <= '1';
                        when BS_CLK_DOWN_UP =>
                            n_gb_clk <= '0';
                        when others =>
                            null;
                    end case;
                end if;
            end loop;
        end loop;
        
        wait;
    end process;
        
end rtl;
