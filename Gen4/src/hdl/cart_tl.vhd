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

    component CLKDIVB
        -- synthesis translate_off
        generic (
            gsr : in string
        );
        -- synthesis translate_on
        port (
            clki : in std_logic;
            rst  : in std_logic;
            -- synthesis translate_off
            release : in std_logic;
            -- synthesis translate_on
            cdiv1 : out std_logic;
            cdiv2 : out std_logic;
            cdiv4 : out std_logic;
            cdiv8 : out std_logic
        );
    end component;

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
            p_enable_timeout_detection : boolean := true;
            p_clk_freq : real := c_clkdivb_cdiv1_freq
        );
        port (
            i_gb_clk     : in std_logic;
            i_gb_addr    : in std_logic_vector(15 downto 0);
            i_gb_din     : in std_logic_vector(7 downto 0);
            o_gb_dout    : out std_logic_vector(7 downto 0);
            i_gb_rdn     : in std_logic;
            i_gb_csn     : in std_logic;
            i_clk        : in std_logic;
            i_rst        : in std_logic;
            o_cyc        : out std_logic;
            o_we         : out std_logic;
            o_adr        : out std_logic_vector(15 downto 0);
            i_dat        : in std_logic_vector(7 downto 0);
            o_dat        : out std_logic_vector(7 downto 0);
            i_ack        : in std_logic;
            o_access_rom : out std_logic;
            o_access_ram : out std_logic;
            o_wr_timeout : out std_logic;
            o_rd_timeout : out std_logic
        );
    end component;

    component wb_crossbar_decoder
        port (
            i_clk        : in std_logic;
            i_rst        : in std_logic;
            i_access_ram : in std_logic;
            i_select_mbc : in std_logic_vector(2 downto 0);
            i_cyc        : in std_logic;
            o_ack        : out std_logic;
            i_we         : in std_logic;
            i_adr        : in std_logic_vector(15 downto 0);
            o_dat        : out std_logic_vector(7 downto 0);
            i_dat        : in std_logic_vector(7 downto 0);
            o_ccb_cyc    : out std_logic;
            i_ccb_ack    : in std_logic;
            o_ccb_we     : out std_logic;
            o_ccb_adr    : out std_logic_vector(15 downto 0);
            o_ccb_dat    : out std_logic_vector(7 downto 0);
            i_ccb_dat    : in std_logic_vector(7 downto 0);
            o_dma_cyc    : out std_logic;
            i_dma_ack    : in std_logic;
            o_dma_we     : out std_logic;
            o_dma_adr    : out std_logic_vector(3 downto 0);
            o_dma_dat    : out std_logic_vector(7 downto 0);
            i_dma_dat    : in std_logic_vector(7 downto 0)
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

    component wb_crossbar_central
        port (
            i_clk        : in std_logic;
            i_rst        : in std_logic;
            i_dma_busy   : in std_logic;
            i_dbg_active : in std_logic;
            i_dbg_cyc    : in std_logic;
            o_dbg_ack    : out std_logic;
            i_dbg_we     : in std_logic;
            i_dbg_adr    : in std_logic_vector(15 downto 0);
            o_dbg_dat    : out std_logic_vector(7 downto 0);
            i_dbg_dat    : in std_logic_vector(7 downto 0);
            i_gbd_cyc    : in std_logic;
            o_gbd_ack    : out std_logic;
            i_gbd_we     : in std_logic;
            i_gbd_adr    : in std_logic_vector(15 downto 0);
            o_gbd_dat    : out std_logic_vector(7 downto 0);
            i_gbd_dat    : in std_logic_vector(7 downto 0);
            i_dma_cyc    : in std_logic;
            o_dma_ack    : out std_logic;
            i_dma_we     : in std_logic;
            i_dma_adr    : in std_logic_vector(15 downto 0);
            o_dma_dat    : out std_logic_vector(7 downto 0);
            i_dma_dat    : in std_logic_vector(7 downto 0);
            o_cyc        : out std_logic;
            i_ack        : in std_logic;
            o_we         : out std_logic;
            o_adr        : out std_logic_vector(15 downto 0);
            o_dat        : out std_logic_vector(7 downto 0);
            i_dat        : in std_logic_vector(7 downto 0)
        );
    end component;

    component mbch
        port (
            i_clk            : in std_logic;
            i_rst            : in std_logic;
            i_cyc            : in std_logic;
            i_we             : in std_logic;
            o_ack            : out std_logic;
            i_adr            : in std_logic_vector(15 downto 0);
            i_dat            : in std_logic_vector(7 downto 0);
            o_dat            : out std_logic_vector(7 downto 0);
            o_xram_adr       : out std_logic_vector(21 downto 0);
            i_xram_dat       : in std_logic_vector(7 downto 0);
            i_xram_ack       : in std_logic;
            i_gpio           : in std_logic_vector(3 downto 0);
            o_gpio           : out std_logic_vector(3 downto 0);
            o_select_mbc     : out std_logic_vector(2 downto 0);
            o_soft_reset_req : out std_logic;
            i_soft_reset     : in std_logic;
            i_dbg_active     : in std_logic
        );
    end component;

    attribute GSR : string;
    attribute GSR of inst_clkdiv : label is "DISABLED";

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

    -- Gameboy decoder related
    signal n_gb_dout : std_logic_vector(7 downto 0);
    signal n_gb_access_ram : std_logic;
    signal n_gb_timeout_rd : std_logic;
    signal n_gb_timeout_wr : std_logic;

    -- Wishbone bus from Gameboy decoder
    signal n_gbd_cyc : std_logic;
    signal n_gbd_we : std_logic;
    signal n_gbd_adr : std_logic_vector(15 downto 0);
    signal n_gbd_dat_i : std_logic_vector(7 downto 0);
    signal n_gbd_dat_o : std_logic_vector(7 downto 0);
    signal n_gbd_ack : std_logic;

    -- Wishbone bus from decoder crossbar to central crossbar
    signal n_dcb_ccb_cyc : std_logic;
    signal n_dcb_ccb_we : std_logic;
    signal n_dcb_ccb_adr : std_logic_vector(15 downto 0);
    signal n_dcb_ccb_dat_i : std_logic_vector(7 downto 0);
    signal n_dcb_ccb_dat_o : std_logic_vector(7 downto 0);
    signal n_dcb_ccb_ack : std_logic;

    -- Wishbone bus from decoder crossbar to DMA config port
    signal n_dcb_dma_cyc : std_logic;
    signal n_dcb_dma_we : std_logic;
    signal n_dcb_dma_adr : std_logic_vector(3 downto 0);
    signal n_dcb_dma_dat_i : std_logic_vector(7 downto 0);
    signal n_dcb_dma_dat_o : std_logic_vector(7 downto 0);
    signal n_dcb_dma_ack : std_logic;

    -- Wisbone bus from DMA master and DMA related
    signal n_dma_cyc : std_logic;
    signal n_dma_ack : std_logic;
    signal n_dma_we : std_logic;
    signal n_dma_adr : std_logic_vector(15 downto 0);
    signal n_dma_dat_i : std_logic_vector(7 downto 0);
    signal n_dma_dat_o : std_logic_vector(7 downto 0);
    signal n_dma_busy : std_logic;

    -- Wisbone bus from central crossbar
    signal n_ccb_adr : std_logic_vector(15 downto 0);
    signal n_ccb_we : std_logic;
    signal n_ccb_cyc : std_logic;
    signal n_ccb_dat_i : std_logic_vector(7 downto 0);
    signal n_ccb_dat_o : std_logic_vector(7 downto 0);
    signal n_ccb_ack : std_logic;

    -- MBCH related signals
    signal n_mbch_selected_mcb : std_logic_vector(2 downto 0);

    signal r_led_divider : std_logic_vector(21 downto 0);

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

    -- CLKDIVB instantiation for lower clocks
    inst_clkdiv : CLKDIVB
    -- synthesis translate_off
    generic map(
        GSR => "disabled"
    )
    -- synthesis translate_on
    port map(
        CLKI => n_pll_clk_op,
        RST  => n_pll_lockn,
        -- synthesis translate_off
        release => '1',
        -- synthesis translate_on
        CDIV1 => n_clk_div1,
        CDIV2 => n_clk_div2,
        CDIV4 => n_clk_div4,
        CDIV8 => n_clk_div8
    );

    -- Instantiate reset controller (hard and soft resets)
    inst_reset_controller : reset
    port map(
        i_clk        => n_clk_div1,
        i_pll_lock   => n_pll_lock,
        i_ext_softn  => i_fpga_rstn,
        i_aux_soft   => n_aux_reset,
        i_dbg_active => '0',
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
        o_cyc => n_gbd_cyc,
        o_we  => n_gbd_we,
        o_adr => n_gbd_adr,
        i_dat => n_gbd_dat_i,
        o_dat => n_gbd_dat_o,
        i_ack => n_gbd_ack,

        o_access_rom => open,
        o_access_ram => n_gb_access_ram,
        o_wr_timeout => n_gb_timeout_rd,
        o_rd_timeout => n_gb_timeout_wr
    );

    -- Decoder crossbar instance
    inst_crossbar_decoder : wb_crossbar_decoder
    port map(
        i_clk        => n_clk_div1,
        i_rst        => n_hard_reset,
        i_access_ram => n_gb_access_ram,
        i_select_mbc => n_mbch_selected_mcb,

        i_cyc => n_gbd_cyc,
        o_ack => n_gbd_ack,
        i_we  => n_gbd_we,
        i_adr => n_gbd_adr,
        o_dat => n_gbd_dat_i,
        i_dat => n_gbd_dat_o,

        o_ccb_cyc => n_dcb_ccb_cyc,
        i_ccb_ack => n_dcb_ccb_ack,
        o_ccb_we  => n_dcb_ccb_we,
        o_ccb_adr => n_dcb_ccb_adr,
        o_ccb_dat => n_dcb_ccb_dat_o,
        i_ccb_dat => n_dcb_ccb_dat_i,

        o_dma_cyc => n_dcb_dma_cyc,
        i_dma_ack => n_dcb_dma_ack,
        o_dma_we  => n_dcb_dma_we,
        o_dma_adr => n_dcb_dma_adr,
        o_dma_dat => n_dcb_dma_dat_o,
        i_dma_dat => n_dcb_dma_dat_i
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

        i_cfg_cyc => n_dcb_dma_cyc,
        o_cfg_ack => n_dcb_dma_ack,
        i_cfg_we  => n_dcb_dma_we,
        i_cfg_adr => n_dcb_dma_adr,
        o_cfg_dat => n_dcb_dma_dat_i,
        i_cfg_dat => n_dcb_dma_dat_o,

        o_status_busy => n_dma_busy
    );

    -- Central crossbar instance
    inst_crossbar_central : wb_crossbar_central
    port map(
        i_clk        => n_clk_div1,
        i_rst        => n_hard_reset,
        i_dma_busy   => n_dma_busy,
        i_dbg_active => '0',

        i_dbg_cyc => '0',
        o_dbg_ack => open,
        i_dbg_we  => '0',
        i_dbg_adr => (others => '0'),
        o_dbg_dat => open,
        i_dbg_dat => (others => '0'),

        i_gbd_cyc => n_dcb_ccb_cyc,
        o_gbd_ack => n_dcb_ccb_ack,
        i_gbd_we  => n_dcb_ccb_we,
        i_gbd_adr => n_dcb_ccb_adr,
        o_gbd_dat => n_dcb_ccb_dat_i,
        i_gbd_dat => n_dcb_ccb_dat_o,

        i_dma_cyc => n_dma_cyc,
        o_dma_ack => n_dma_ack,
        i_dma_we  => n_dma_we,
        i_dma_adr => n_dma_adr,
        o_dma_dat => n_dma_dat_i,
        i_dma_dat => n_dma_dat_o,

        o_cyc => n_ccb_cyc,
        i_ack => n_ccb_ack,
        o_we  => n_ccb_we,
        o_adr => n_ccb_adr,
        o_dat => n_ccb_dat_o,
        i_dat => n_ccb_dat_i
    );

    inst_mbch : mbch
    port map(
        i_clk            => n_clk_div1,
        i_rst            => n_hard_reset,
        i_cyc            => n_ccb_cyc,
        i_we             => n_ccb_we,
        o_ack            => n_ccb_ack,
        i_adr            => n_ccb_adr,
        i_dat            => n_ccb_dat_o,
        o_dat            => n_ccb_dat_i,
        o_xram_adr       => open,
        i_xram_dat       => (others => '0'),
        i_xram_ack       => '1',
        i_gpio           => (others => '0'),
        o_gpio           => open,
        o_select_mbc     => n_mbch_selected_mcb,
        o_soft_reset_req => n_aux_reset,
        i_soft_reset     => n_soft_reset,
        i_dbg_active     => '0'
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
    io_gb_data <= n_gb_dout when (i_gb_clk nor i_gb_rdn) = '1' else
        (others => 'Z');
    o_gb_bus_en <= '0';

    io_ram_adq <= (others => 'Z');
    o_ram_a <= "000000";
    o_ram_advn <= '0';
    o_ram_ce0n <= '0';
    o_ram_ce1n <= '0';
    o_ram_clk <= '0';
    o_ram_cre <= '0';
    o_ram_lbn <= '0';
    o_ram_ubn <= '0';
    o_ram_oen <= '0';
    o_ram_wen <= '0';

    io_fpga_spi_clk <= 'Z';
    io_fpga_spi_miso <= 'Z';
    io_fpga_spi_miso <= 'Z';
    o_fpga_spi_flash_csn <= '1';
    o_fpga_spi_rtc_csn <= '1';
    o_fpga_spi_sd_csn <= '1';

    -- io_fpga_user(5) <= 'Z';
    io_fpga_user(5) <= r_led_divider(r_led_divider'high);
    io_fpga_user(4) <= 'Z';
    io_fpga_user(3) <= 'Z';
    io_fpga_user(2) <= 'Z';
    io_fpga_user(1) <= 'Z';
    io_fpga_user(0) <= 'Z';

end architecture rtl;