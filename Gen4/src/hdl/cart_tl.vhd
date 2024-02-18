----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 09/11/2023 15:44:31 PM
-- Design Name: Cartridge top level
-- Module Name: cart_tl - rtl
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

library XP2;
use XP2.all;

entity cart_tl is
    generic (
        p_simulation : boolean := FALSE
    );
    port (
        -- Clocking and reset
        i_fpga_clk33m : in std_logic;
        o_clk_en      : out std_logic;
        i_fpga_rstn   : in std_logic;

        -- GB related ports
        i_gb_addr   : in std_logic_vector(15 downto 0);
        io_gb_data  : inout std_logic_vector(7 downto 0);
        o_gb_bus_en : out std_logic;
        i_gb_clk    : in std_logic;
        i_gb_csn    : in std_logic;
        i_gb_rdn    : in std_logic;
        i_gb_wrn    : in std_logic;
        o_gb_rstn   : out std_logic;

        -- RAM related ports
        io_ram_adq : inout std_logic_vector(15 downto 0);
        o_ram_a    : out std_logic_vector(5 downto 0);
        o_ram_advn : out std_logic;
        o_ram_ce0n : out std_logic;
        o_ram_ce1n : out std_logic;
        o_ram_clk  : out std_logic;
        o_ram_cre  : out std_logic;
        o_ram_lbn  : out std_logic;
        o_ram_ubn  : out std_logic;
        o_ram_oen  : out std_logic;
        i_ram_wait : in std_logic;
        o_ram_wen  : out std_logic;

        -- SPI related signals
        io_fpga_spi_clk      : inout std_logic;
        io_fpga_spi_miso     : inout std_logic;
        io_fpga_spi_mosi     : inout std_logic;
        o_fpga_spi_flash_csn : out std_logic;
        o_fpga_spi_rtc_csn   : out std_logic;
        o_fpga_spi_sd_csn    : out std_logic;

        -- Miscellaneous signals
        io_fpga_user     : inout std_logic_vector(5 downto 0);
        i_rtc_rstn       : in std_logic;
        i_sd_card_detect : in std_logic
    );
end entity cart_tl;

architecture rtl of cart_tl is

    -- Frequencies used for timing calculations
    constant c_pll_clkop_freq : real := 99.999999;
    constant c_pll_clkok_freq : real := c_pll_clkop_freq / 100.0;
    constant c_clkdivb_cdiv1_freq : real := c_pll_clkop_freq;
    constant c_clkdivb_cdiv2_freq : real := c_clkdivb_cdiv1_freq / 2.0;
    constant c_clkdivb_cdiv4_freq : real := c_clkdivb_cdiv1_freq / 4.0;
    constant c_clkdivb_cdiv8_freq : real := c_clkdivb_cdiv1_freq / 8.0;

    component pll
        port (
            clk   : in std_logic;
            clkop : out std_logic;
            clkok : out std_logic;
            lock  : out std_logic
        );
    end component;

    -- component CLKDIVB
    --     -- synthesis translate_off
    --     generic (
    --         gsr : in string
    --     );
    --     -- synthesis translate_on
    --     port (
    --         clki : in std_logic;
    --         rst  : in std_logic;
    --         -- synthesis translate_off
    --         release : in std_logic;
    --         -- synthesis translate_on
    --         cdiv1 : out std_logic;
    --         cdiv2 : out std_logic;
    --         cdiv4 : out std_logic;
    --         cdiv8 : out std_logic
    --     );
    -- end component;

    component reset
        generic (
            p_aux_ff_count : positive := 9
        );
        port (
            i_clk        : in std_logic;
            i_pll_lock   : in std_logic;
            i_ext_softn  : in std_logic;
            i_aux_soft   : in std_logic;
            i_dbg_active : in std_logic;

            o_gb_resetn  : out std_logic;
            o_soft_reset : out std_logic;
            o_hard_reset : out std_logic
        );
    end component;

    component gb_decoder
        generic (
            p_enable_timeout_detection : boolean := false;
            p_clk_freq : real := c_clkdivb_cdiv1_freq
        );
        port (
            i_gb_clk       : in std_logic;
            i_gb_addr      : in std_logic_vector(15 downto 0);
            i_gb_din       : in std_logic_vector(7 downto 0);
            o_gb_dout      : out std_logic_vector(7 downto 0);
            i_gb_rdn       : in std_logic;
            i_gb_csn       : in std_logic;
            i_clk          : in std_logic;
            i_rst          : in std_logic;
            o_dma_cyc      : out std_logic;
            o_dma_we       : out std_logic;
            o_dma_adr      : out std_logic_vector(3 downto 0);
            o_dma_dat      : out std_logic_vector(7 downto 0);
            i_dma_dat      : in std_logic_vector(7 downto 0);
            i_dma_ack      : in std_logic;
            o_mbch_cyc     : out std_logic;
            o_mbch_we      : out std_logic;
            o_mbch_adr     : out std_logic_vector(15 downto 0);
            o_mbch_dat     : out std_logic_vector(7 downto 0);
            i_mbch_dat     : in std_logic_vector(7 downto 0);
            i_mbch_ack     : in std_logic;
            i_dma_busy     : in std_logic;
            i_selected_mbc : in std_logic_vector(2 downto 0);
            o_wr_timeout   : out std_logic;
            o_rd_timeout   : out std_logic
        );
    end component;

    component dma_controller
        port (
            i_clk         : in std_logic;
            i_rst         : in std_logic;
            o_dma_cyc     : out std_logic;
            i_dma_ack     : in std_logic;
            o_dma_we      : out std_logic;
            o_dma_adr     : out std_logic_vector(15 downto 0);
            o_dma_dat     : out std_logic_vector(7 downto 0);
            i_dma_dat     : in std_logic_vector(7 downto 0);
            i_cfg_cyc     : in std_logic;
            o_cfg_ack     : out std_logic;
            i_cfg_we      : in std_logic;
            i_cfg_adr     : in std_logic_vector(3 downto 0);
            o_cfg_dat     : out std_logic_vector(7 downto 0);
            i_cfg_dat     : in std_logic_vector(7 downto 0);
            o_status_busy : out std_logic
        );
    end component;

    component uart_debug
        generic (
            p_clk_freq : real := c_clkdivb_cdiv1_freq;
            p_baud_rate : natural := 115200;
            p_parity : string := "NONE";
            p_stop_bits : natural := 1
        );
        port (
            i_clk        : in std_logic;
            i_rst        : in std_logic;
            o_cyc        : out std_logic;
            i_ack        : in std_logic;
            o_we         : out std_logic;
            o_adr        : out std_logic_vector(15 downto 0);
            o_dat        : out std_logic_vector(7 downto 0);
            i_dat        : in std_logic_vector(7 downto 0);
            o_serial_tx  : out std_logic;
            i_serial_rx  : in std_logic;
            o_dbg_active : out std_logic
        );
    end component;

    component mbch
        port (
            i_clk            : in std_logic;
            i_rst            : in std_logic;
            i_dbg_cyc        : in std_logic;
            i_dbg_we         : in std_logic;
            o_dbg_ack        : out std_logic;
            i_dbg_adr        : in std_logic_vector(15 downto 0);
            i_dbg_dat        : in std_logic_vector(7 downto 0);
            o_dbg_dat        : out std_logic_vector(7 downto 0);
            i_dma_cyc        : in std_logic;
            i_dma_we         : in std_logic;
            o_dma_ack        : out std_logic;
            i_dma_adr        : in std_logic_vector(15 downto 0);
            i_dma_dat        : in std_logic_vector(7 downto 0);
            o_dma_dat        : out std_logic_vector(7 downto 0);
            i_gbd_cyc        : in std_logic;
            i_gbd_we         : in std_logic;
            o_gbd_ack        : out std_logic;
            i_gbd_adr        : in std_logic_vector(15 downto 0);
            i_gbd_dat        : in std_logic_vector(7 downto 0);
            o_gbd_dat        : out std_logic_vector(7 downto 0);
            o_xram_cyc       : out std_logic;
            o_xram_we        : out std_logic;
            i_xram_ack       : in std_logic;
            o_xram_adr       : out std_logic_vector(23 downto 0);
            o_xram_tga       : out std_logic;
            i_xram_dat       : in std_logic_vector(7 downto 0);
            o_xram_dat       : out std_logic_vector(7 downto 0);
            i_gpio           : in std_logic_vector(3 downto 0);
            o_gpio           : out std_logic_vector(3 downto 0);
            o_select_mbc     : out std_logic_vector(2 downto 0);
            o_soft_reset_req : out std_logic;
            i_soft_reset     : in std_logic;
            i_dbg_active     : in std_logic;
            i_dma_busy       : in std_logic
        );
    end component;

    component uart_core
        generic (
            p_clk_freq : real := 100.0;
            p_baud_rate : natural := 115200;
            p_parity : string := "NONE";
            p_data_bits : natural := 8;
            p_stop_bits : natural := 1
        );
        port (
            i_clk       : in std_logic;
            i_rst       : in std_logic;
            i_tx_wr     : in std_logic;
            i_tx_dat    : in std_logic_vector(p_data_bits - 1 downto 0);
            o_tx_rdy    : out std_logic;
            i_rx_rd     : in std_logic;
            o_rx_dat    : out std_logic_vector(p_data_bits - 1 downto 0);
            o_rx_rdy    : out std_logic;
            o_serial_tx : out std_logic;
            i_serial_rx : in std_logic
        );
    end component;

    component as1c8m16pl_controller
        generic (
            p_clk_freq : real := 100.0
        );
        port (
            i_clk      : in std_logic;
            i_rst      : in std_logic;
            i_cyc      : in std_logic;
            i_we       : in std_logic;
            o_ack      : out std_logic;
            i_adr      : in std_logic_vector(23 downto 0);
            i_tga      : in std_logic_vector(0 downto 0);
            i_dat      : in std_logic_vector(7 downto 0);
            o_dat      : out std_logic_vector(7 downto 0);
            io_ram_adq : inout std_logic_vector(15 downto 0);
            o_ram_a    : out std_logic_vector(5 downto 0);
            o_ram_advn : out std_logic;
            o_ram_ce0n : out std_logic;
            o_ram_ce1n : out std_logic;
            o_ram_clk  : out std_logic;
            o_ram_cre  : out std_logic;
            o_ram_lbn  : out std_logic;
            o_ram_ubn  : out std_logic;
            o_ram_oen  : out std_logic;
            i_ram_wait : in std_logic;
            o_ram_wen  : out std_logic
        );
    end component;

    -- attribute GSR : string;
    -- attribute GSR of inst_clkdiv : label is "DISABLED";

    -- Clocks
    signal n_pll_clk_op : std_logic;
    signal n_pll_clk_ok : std_logic;
    signal n_pll_lock : std_logic;
    signal n_pll_lockn : std_logic;
    signal n_clk_div1 : std_logic;
    signal n_clk_div2 : std_logic;
    signal n_clk_div4 : std_logic;
    signal n_clk_div8 : std_logic;

    -- Resets
    signal n_soft_reset : std_logic;
    signal n_hard_reset : std_logic;
    signal n_aux_reset : std_logic;
    signal n_dbg_active : std_logic;

    -- Gameboy decoder related
    signal n_gb_dout : std_logic_vector(7 downto 0);
    signal n_gb_access_ram : std_logic;
    signal n_gb_timeout_rd : std_logic;
    signal n_gb_timeout_wr : std_logic;

    -- Wishbone bus from Gameboy decoder to DMA config port
    signal n_gbd_dma_cyc : std_logic;
    signal n_gbd_dma_we : std_logic;
    signal n_gbd_dma_adr : std_logic_vector(3 downto 0);
    signal n_gbd_dma_dat_o : std_logic_vector(7 downto 0);
    signal n_gbd_dma_dat_i : std_logic_vector(7 downto 0);
    signal n_gbd_dma_ack : std_logic;

    -- Wishbone bus from Gameboy decoder to MBCH
    signal n_gbd_mbch_cyc : std_logic;
    signal n_gbd_mbch_we : std_logic;
    signal n_gbd_mbch_adr : std_logic_vector(15 downto 0);
    signal n_gbd_mbch_dat_o : std_logic_vector(7 downto 0);
    signal n_gbd_mbch_dat_i : std_logic_vector(7 downto 0);
    signal n_gbd_mbch_ack : std_logic;

    -- Wisbone bus from DMA master and DMA related
    signal n_dma_cyc : std_logic;
    signal n_dma_ack : std_logic;
    signal n_dma_we : std_logic;
    signal n_dma_adr : std_logic_vector(15 downto 0);
    signal n_dma_dat_i : std_logic_vector(7 downto 0);
    signal n_dma_dat_o : std_logic_vector(7 downto 0);
    signal n_dma_busy : std_logic;

    -- Wishbone bus from debug core to MBCH
    signal n_dbg_cyc : std_logic;
    signal n_dbg_we : std_logic;
    signal n_dbg_adr : std_logic_vector(15 downto 0);
    signal n_dbg_dat_i : std_logic_vector(7 downto 0);
    signal n_dbg_dat_o : std_logic_vector(7 downto 0);
    signal n_dbg_ack : std_logic;

    -- Wishbone bus from MBCH to XRAM
    signal n_xram_cyc : std_logic;
    signal n_xram_we : std_logic;
    signal n_xram_ack : std_logic;
    signal n_xram_adr : std_logic_vector(23 downto 0);
    signal n_xram_tga : std_logic;
    signal n_xram_dat_i : std_logic_vector(7 downto 0);
    signal n_xram_dat_o : std_logic_vector(7 downto 0);

    -- MBCH related signals
    signal n_mbch_selected_mcb : std_logic_vector(2 downto 0);

    signal r_led_divider : std_logic_vector(24 downto 0);

begin

    -- PLL instantiation for frequency synthesis from i_fpga_clk33m
    inst_pll : pll
    port map(
        CLK   => i_fpga_clk33m,
        CLKOP => n_pll_clk_op,
        CLKOK => n_pll_clk_ok,
        LOCK  => n_pll_lock
    );

    n_pll_lockn <= not(n_pll_lock);

    -- -- CLKDIVB instantiation for lower clocks
    -- inst_clkdiv : CLKDIVB
    -- -- synthesis translate_off
    -- generic map(
    --     GSR => "disabled"
    -- )
    -- -- synthesis translate_on
    -- port map(
    --     CLKI => n_pll_clk_op,
    --     RST  => n_pll_lockn,
    --     -- synthesis translate_off
    --     release => '1',
    --     -- synthesis translate_on
    --     CDIV1 => n_clk_div1,
    --     CDIV2 => n_clk_div2,
    --     CDIV4 => n_clk_div4,
    --     CDIV8 => n_clk_div8
    -- );

    n_clk_div1 <= n_pll_clk_op;
    n_clk_div2 <= n_pll_clk_op;
    n_clk_div4 <= n_pll_clk_op;
    n_clk_div8 <= n_pll_clk_op;

    -- Instantiate reset controller (hard and soft resets)
    inst_reset_controller : reset
    port map(
        i_clk        => n_clk_div1,
        i_pll_lock   => n_pll_lock,
        i_ext_softn  => i_fpga_rstn,
        i_aux_soft   => n_aux_reset,
        i_dbg_active => n_dbg_active,
        o_gb_resetn  => o_gb_rstn,
        o_soft_reset => n_soft_reset,
        o_hard_reset => n_hard_reset
    );

    -- Gameboy decoder instance
    inst_gameboy_decoder : gb_decoder
    port map(
        i_gb_clk  => i_gb_clk,
        i_gb_addr => i_gb_addr,
        i_gb_din  => io_gb_data,
        o_gb_dout => n_gb_dout,
        i_gb_rdn  => i_gb_rdn,
        i_gb_csn  => i_gb_csn,

        i_clk => n_clk_div1,
        i_rst => n_soft_reset,

        o_dma_cyc  => n_gbd_dma_cyc,
        o_dma_we   => n_gbd_dma_we,
        o_dma_adr  => n_gbd_dma_adr,
        o_dma_dat  => n_gbd_dma_dat_o,
        i_dma_dat  => n_gbd_dma_dat_i,
        i_dma_ack  => n_gbd_dma_ack,

        o_mbch_cyc => n_gbd_mbch_cyc,
        o_mbch_we  => n_gbd_mbch_we,
        o_mbch_adr => n_gbd_mbch_adr,
        o_mbch_dat => n_gbd_mbch_dat_o,
        i_mbch_dat => n_gbd_mbch_dat_i,
        i_mbch_ack => n_gbd_mbch_ack,

        i_dma_busy     => n_dma_busy,
        i_selected_mbc => n_mbch_selected_mcb,
        o_wr_timeout   => n_gb_timeout_rd,
        o_rd_timeout   => n_gb_timeout_wr
    );

    -- DMA controller instance
    inst_dma_controller : dma_controller
    port map(
        i_clk => n_clk_div1,
        i_rst => n_soft_reset,

        o_dma_cyc => n_dma_cyc,
        i_dma_ack => n_dma_ack,
        o_dma_we  => n_dma_we,
        o_dma_adr => n_dma_adr,
        o_dma_dat => n_dma_dat_o,
        i_dma_dat => n_dma_dat_i,

        i_cfg_cyc => n_gbd_dma_cyc,
        o_cfg_ack => n_gbd_dma_ack,
        i_cfg_we  => n_gbd_dma_we,
        i_cfg_adr => n_gbd_dma_adr,
        o_cfg_dat => n_gbd_dma_dat_i,
        i_cfg_dat => n_gbd_dma_dat_o,

        o_status_busy => n_dma_busy
    );

    inst_mbch : mbch
    port map(
        i_clk            => n_clk_div1,
        i_rst            => n_hard_reset,
        i_dbg_cyc        => n_dbg_cyc,
        i_dbg_we         => n_dbg_we,
        o_dbg_ack        => n_dbg_ack,
        i_dbg_adr        => n_dbg_adr,
        i_dbg_dat        => n_dbg_dat_o,
        o_dbg_dat        => n_dbg_dat_i,
        i_dma_cyc        => n_dma_cyc,
        i_dma_we         => n_dma_we,
        o_dma_ack        => n_dma_ack,
        i_dma_adr        => n_dma_adr,
        i_dma_dat        => n_dma_dat_o,
        o_dma_dat        => n_dma_dat_i,
        i_gbd_cyc        => n_gbd_mbch_cyc,
        i_gbd_we         => n_gbd_mbch_we,
        o_gbd_ack        => n_gbd_mbch_ack,
        i_gbd_adr        => n_gbd_mbch_adr,
        i_gbd_dat        => n_gbd_mbch_dat_o,
        o_gbd_dat        => n_gbd_mbch_dat_i,
        o_xram_cyc       => n_xram_cyc,
        o_xram_we        => n_xram_we,
        i_xram_ack       => n_xram_ack,
        o_xram_adr       => n_xram_adr,
        o_xram_tga       => n_xram_tga,
        i_xram_dat       => n_xram_dat_o,
        o_xram_dat       => n_xram_dat_i,
        i_gpio           => (others => '0'),
        o_gpio           => open,
        o_select_mbc     => n_mbch_selected_mcb,
        o_soft_reset_req => n_aux_reset,
        i_soft_reset     => n_soft_reset,
        i_dbg_active     => n_dbg_active,
        i_dma_busy       => n_dma_busy
    );

    inst_uart_debug : uart_debug
    port map(
        i_clk        => n_clk_div1,
        i_rst        => n_hard_reset,
        o_cyc        => n_dbg_cyc,
        i_ack        => n_dbg_ack,
        o_we         => n_dbg_we,
        o_adr        => n_dbg_adr,
        o_dat        => n_dbg_dat_o,
        i_dat        => n_dbg_dat_i,
        o_serial_tx  => io_fpga_user(5),
        i_serial_rx  => io_fpga_user(4),
        o_dbg_active => n_dbg_active
    );

    inst_ram_controller : as1c8m16pl_controller
    port map(
        i_clk      => n_clk_div1,
        i_rst      => n_soft_reset,
        i_cyc      => n_xram_cyc,
        i_we       => n_xram_we,
        o_ack      => n_xram_ack,
        i_adr      => n_xram_adr,
        i_tga(0)   => n_xram_tga,
        i_dat      => n_xram_dat_i,
        o_dat      => n_xram_dat_o,
        io_ram_adq => io_ram_adq,
        o_ram_a    => o_ram_a,
        o_ram_advn => o_ram_advn,
        o_ram_ce0n => o_ram_ce0n,
        o_ram_ce1n => o_ram_ce1n,
        o_ram_clk  => o_ram_clk,
        o_ram_cre  => o_ram_cre,
        o_ram_lbn  => o_ram_lbn,
        o_ram_ubn  => o_ram_ubn,
        o_ram_oen  => o_ram_oen,
        i_ram_wait => i_ram_wait,
        o_ram_wen  => o_ram_wen
    );

    proc_led_blinker : process(n_clk_div8)
    begin
        if rising_edge(n_clk_div8) then
            if n_hard_reset = '1' then
                r_led_divider <= (others => '0');
            else
                r_led_divider <= std_logic_vector(unsigned(r_led_divider) + 1);
            end if;
        end if;
    end process proc_led_blinker;

    o_clk_en <= '1';
    io_gb_data <= n_gb_dout when (i_gb_clk nor i_gb_rdn) = '1' else (others => 'Z');
    o_gb_bus_en <= not(n_soft_reset);

    io_fpga_spi_clk <= 'Z';
    io_fpga_spi_miso <= 'Z';
    io_fpga_spi_miso <= 'Z';
    o_fpga_spi_flash_csn <= '1';
    o_fpga_spi_rtc_csn <= '1';
    o_fpga_spi_sd_csn <= '1';

    -- io_fpga_user(5) <= 'Z';
    -- io_fpga_user(4) <= 'Z';
    io_fpga_user(3) <= 'Z';
    io_fpga_user(2) <= 'Z';
    io_fpga_user(1) <= r_led_divider(r_led_divider'high);
    io_fpga_user(0) <= n_soft_reset;
    -- io_fpga_user(1) <= 'Z';
    -- io_fpga_user(0) <= 'Z';

end architecture rtl;