----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 02/12/2024 12:02:32 PM
-- Design Name: Gameboy with debug core testbench
-- Module Name: gameboy_debug_tb - rtl
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity gameboy_debug_tb is
end gameboy_debug_tb;

architecture rtl of gameboy_debug_tb is

    constant c_baud_rate : natural := 115200;

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

    procedure transmit_serial (
        constant c_data : in std_logic_vector(7 downto 0);
        signal o_serial_tx : out std_logic
    ) is
        constant c_baud_period : time := (1.0 / real(c_baud_rate)) * 1_000_000_000.0 ns;
    begin
        -- start bit
        o_serial_tx <= '0';
        wait for c_baud_period;

        -- data bits
        for i in 0 to 7 loop
            o_serial_tx <= c_data(i);
            wait for c_baud_period;
        end loop;

        -- stop bit
        o_serial_tx <= '1';
        wait for c_baud_period;
    end procedure;

    procedure receive_serial (
        variable v_data : out std_logic_vector(7 downto 0);
        signal i_serial_rx : in std_logic
    ) is
        constant c_baud_period : time := (1.0 / real(c_baud_rate)) * 1_000_000_000.0 ns;
    begin
        -- await start bit, then wait till middle of it
        wait until i_serial_rx = '0';
        wait for c_baud_period / 2;

        -- data bits
        for i in 0 to 7 loop
            wait for c_baud_period;
            v_data(i) := i_serial_rx;
        end loop;

        -- await rest of last data bit + stop bits
        wait for c_baud_period * 1.5;
    end procedure;

    type t_test_data is array (natural range <>) of std_logic_vector(7 downto 0);

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

    shared variable v_serial_data : t_test_data(0 to 31);
    shared variable v_serial_index : natural := 0;
    shared variable v_serial_length : natural := 0;

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
    
    -- simulate ram driving ADQ on OE#
    process
        variable v_low_address : std_logic_vector(15 downto 0);
    begin
        n_ram_adq <= (others => 'Z');

        wait on n_ram_oen until n_ram_oen = '0';
        wait for 20 ns - 1 ps;
        n_ram_adq <= x"1234";
        wait on n_ram_oen until n_ram_oen = '1';
        wait for 7 ns;
    end process;

    proc_testbench : process
    begin
        -- setup reader
        v_serial_data(0) := x"03";
        v_serial_data(1) := x"00";
        v_serial_data(2) := x"05";
        v_serial_data(3) := x"30";
        v_serial_data(4) := x"03";
        v_serial_data(5) := x"30";
        v_serial_index := 0;
        v_serial_length := 6;

        -- read control register
        transmit_serial(
            c_data => x"02",
            o_serial_tx => n_fpga_user(4)
        );

        -- wait to receive sent command + control register contents
        wait for 170 us;

        -- write control register
        -- enable core, enable auto increment
        transmit_serial(
            c_data => x"04",
            o_serial_tx => n_fpga_user(4)
        );
        transmit_serial(
            c_data => x"30",
            o_serial_tx => n_fpga_user(4)
        );

        -- wait to receive sent register value
        wait for 85 us;

        -- read control register
        transmit_serial(
            c_data => x"02",
            o_serial_tx => n_fpga_user(4)
        );

        -- wait to receive sent command + control register contents
        wait for 170 us;

        -- setup reader
        v_serial_data(0) := x"11";
        v_serial_data(1) := x"00";
        v_serial_data(2) := x"40";
        v_serial_index := 0;
        v_serial_length := 3;

        -- set debug address
        transmit_serial(
            c_data => x"10",
            o_serial_tx => n_fpga_user(4)
        );
        transmit_serial(
            c_data => x"00",
            o_serial_tx => n_fpga_user(4)
        );
        transmit_serial(
            c_data => x"40",
            o_serial_tx => n_fpga_user(4)
        );

        -- wait to receive resent high byte of the debug address
        wait for 85 us;

        -- setup reader
        v_serial_data(0) := x"21";
        v_serial_data(1) := x"01";
        v_serial_data(2) := "--------";
        v_serial_data(3) := "--------";
        v_serial_index := 0;
        v_serial_length := 4;

        -- initiate read of 2 byte
        transmit_serial(
            c_data => x"20",
            o_serial_tx => n_fpga_user(4)
        );
        transmit_serial(
            c_data => x"01",
            o_serial_tx => n_fpga_user(4)
        );
        
        -- wait to receive resent byte count + read data
        wait for 85 us;
        for i in 0 to 1 loop
            wait for 85 us;
        end loop;

        -- setup reader
        v_serial_data(0) := x"11";
        v_serial_data(1) := x"00";
        v_serial_data(2) := x"A1";
        v_serial_index := 0;
        v_serial_length := 3;

        -- set debug address
        transmit_serial(
            c_data => x"10",
            o_serial_tx => n_fpga_user(4)
        );
        transmit_serial(
            c_data => x"00",
            o_serial_tx => n_fpga_user(4)
        );
        transmit_serial(
            c_data => x"A1",
            o_serial_tx => n_fpga_user(4)
        );

        -- wait to receive resent high byte of the debug address
        wait for 85 us;

        -- setup reader
        v_serial_data(0) := x"31";
        v_serial_data(1) := x"00";
        v_serial_data(2) := x"80";
        v_serial_index := 0;
        v_serial_length := 3;

        -- initiate write
        transmit_serial(
            c_data => x"30",
            o_serial_tx => n_fpga_user(4)
        );
        transmit_serial(
            c_data => x"00",
            o_serial_tx => n_fpga_user(4)
        );

        -- write byte
        transmit_serial(
            c_data => x"80",
            o_serial_tx => n_fpga_user(4)
        );

        wait for 85 ns;

        wait;
    end process;

    proc_serial_reader : process
        variable v_data : std_logic_vector(7 downto 0);
    begin
        receive_serial(
            v_data => v_data,
            i_serial_rx => n_fpga_user(5)
        );

        assert v_serial_index < v_serial_length report "Serial test index exceeds test length" severity FAILURE;
        assert std_match(v_data, v_serial_data(v_serial_index)) report "Unexpected serial data received (expected = 0x"
            & to_hstring(to_bitvector(v_serial_data(v_serial_index))) & ", actual = 0x"
            & to_hstring(to_bitvector(v_data)) & ", test_index = "
            & integer'image(v_serial_index) & ")" severity ERROR;

        v_serial_index := v_serial_index + 1;
    end process;
        
end rtl;
