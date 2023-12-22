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
        io_fpga_spi_miso     : inout std_logic;
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
    constant c_pll_clkop_freq     : real := 99.999999;
    constant c_pll_clkok_freq     : real := c_pll_clkop_freq / 100;
    constant c_clkdivb_cdiv1_freq : real := c_pll_clkop_freq;
    constant c_clkdivb_cdiv2_freq : real := c_clkdivb_cdiv1_freq / 2;
    constant c_clkdivb_cdiv4_freq : real := c_clkdivb_cdiv1_freq / 4;
    constant c_clkdivb_cdiv8_freq : real := c_clkdivb_cdiv1_freq / 8;

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
            clki    : in std_logic;
            rst     : in std_logic;
            -- synthesis translate_off
            release : in std_logic;
            -- synthesis translate_on
            cdiv1   : out std_logic;
            cdiv2   : out std_logic;
            cdiv4   : out std_logic;
            cdiv8   : out std_logic
        );
    end component;

    component reset
        generic (
            GSR_FF : positive := 8;
            AUX_FF : positive := 9;
            SIMULATION : boolean := p_simulation
        );
        port (
            SYNC_CLK   : in std_logic;
            PLL_LOCK   : in std_logic;
            EXT_SOFT   : in std_logic;
            AUX_SOFT   : in std_logic;
            DBG_ACTIVE : in std_logic;

            GB_RESETN  : out std_logic;
            SOFT_RESET : out std_logic;
            HARD_RESET : out std_logic
        );
    end component;

    component gb_decoder
        generic (
            p_enable_timeout_detection : boolean := true;
            p_clk_freq : real := c_clkdivb_cdiv1_freq
        );
        port (
            i_gb_clk      : in std_logic;
            i_gb_addr     : in std_logic_vector(15 downto 0);
            i_gb_din  : in std_logic_vector(7 downto 0);
            o_gb_dout : out std_logic_vector(7 downto 0);
            i_gb_rdn      : in std_logic;
            i_gb_csn      : in std_logic;
            i_clk       : in std_logic;
            i_rst       : in std_logic;
            o_cyc       : out std_logic;
            o_we        : out std_logic;
            o_adr       : out std_logic_vector(15 downto 0);
            i_dat       : in std_logic_vector(7 downto 0);
            o_dat       : out std_logic_vector(7 downto 0);
            i_ack       : in std_logic;
            o_access_rom  : out std_logic;
            o_access_ram  : out std_logic;
            o_wr_timeout  : out std_logic;
            o_rd_timeout  : out std_logic
        );
    end component;

    component wb_crossbar_decoder
        port (
            CLK_I      : in std_logic;
            RST_I      : in std_logic;
            ACCESS_RAM : in std_logic;
            SELECT_MBC : in std_logic_vector(2 downto 0);
            CYC_I      : in std_logic;
            ACK_O      : out std_logic;
            WE_I       : in std_logic;
            ADR_I      : in std_logic_vector(15 downto 0);
            DAT_O      : out std_logic_vector(7 downto 0);
            DAT_I      : in std_logic_vector(7 downto 0);
            CCB_CYC_O  : out std_logic;
            CCB_ACK_I  : in std_logic;
            CCB_WE_O   : out std_logic;
            CCB_ADR_O  : out std_logic_vector(15 downto 0);
            CCB_DAT_O  : out std_logic_vector(7 downto 0);
            CCB_DAT_I  : in std_logic_vector(7 downto 0);
            DMA_CYC_O  : out std_logic;
            DMA_ACK_I  : in std_logic;
            DMA_WE_O   : out std_logic;
            DMA_ADR_O  : out std_logic_vector(3 downto 0);
            DMA_DAT_O  : out std_logic_vector(7 downto 0);
            DMA_DAT_I  : in std_logic_vector(7 downto 0)
        );
    end component;

    component dma_controller
        port (
            CLK_I       : in std_logic;
            RST_I       : in std_logic;
            DMA_CYC_O   : out std_logic;
            DMA_ACK_I   : in std_logic;
            DMA_WE_O    : out std_logic;
            DMA_ADR_O   : out std_logic_vector(15 downto 0);
            DMA_DAT_O   : out std_logic_vector(7 downto 0);
            DMA_DAT_I   : in std_logic_vector(7 downto 0);
            CFG_CYC_I   : in std_logic;
            CFG_ACK_O   : out std_logic;
            CFG_WE_I    : in std_logic;
            CFG_ADR_I   : in std_logic_vector(3 downto 0);
            CFG_DAT_O   : out std_logic_vector(7 downto 0);
            CFG_DAT_I   : in std_logic_vector(7 downto 0);
            STATUS_BUSY : out std_logic
        );
    end component;

    component wb_crossbar_central
        port (
            CLK_I      : in std_logic;
            RST_I      : in std_logic;
            DMA_BUSY   : in std_logic;
            DBG_ACTIVE : in std_logic;
            DBG_CYC_I  : in std_logic;
            DBG_ACK_O  : out std_logic;
            DBG_WE_I   : in std_logic;
            DBG_ADR_I  : in std_logic_vector(15 downto 0);
            DBG_DAT_O  : out std_logic_vector(7 downto 0);
            DBG_DAT_I  : in std_logic_vector(7 downto 0);
            GBD_CYC_I  : in std_logic;
            GBD_ACK_O  : out std_logic;
            GBD_WE_I   : in std_logic;
            GBD_ADR_I  : in std_logic_vector(15 downto 0);
            GBD_DAT_O  : out std_logic_vector(7 downto 0);
            GBD_DAT_I  : in std_logic_vector(7 downto 0);
            DMA_CYC_I  : in std_logic;
            DMA_ACK_O  : out std_logic;
            DMA_WE_I   : in std_logic;
            DMA_ADR_I  : in std_logic_vector(15 downto 0);
            DMA_DAT_O  : out std_logic_vector(7 downto 0);
            DMA_DAT_I  : in std_logic_vector(7 downto 0);
            CYC_O      : out std_logic;
            ACK_I      : in std_logic;
            WE_O       : out std_logic;
            ADR_O      : out std_logic_vector(15 downto 0);
            DAT_O      : out std_logic_vector(7 downto 0);
            DAT_I      : in std_logic_vector(7 downto 0)
        );
    end component;

    component mbch
        port (
            CLK_I          : in std_logic;
            RST_I          : in std_logic;
            CYC_I          : in std_logic;
            WE_I           : in std_logic;
            ACK_O          : out std_logic;
            ADR_I          : in std_logic_vector(15 downto 0);
            DAT_I          : in std_logic_vector(7 downto 0);
            DAT_O          : out std_logic_vector(7 downto 0);
            XRAM_ADR_O     : out std_logic_vector(21 downto 0);
            XRAM_DAT_I     : in std_logic_vector(7 downto 0);
            XRAM_ACK_I     : in std_logic;
            GPIO_IN        : in std_logic_vector(3 downto 0);
            GPIO_OUT       : out std_logic_vector(3 downto 0);
            SELECT_MBC     : out std_logic_vector(2 downto 0);
            SOFT_RESET_REQ : out std_logic;
            SOFT_RESET_IN  : in std_logic;
            DBG_ACTIVE     : in std_logic
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
    signal n_gb_dout       : std_logic_vector(7 downto 0);
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

begin

    -- PLL instantiation for frequency synthesis from i_fpga_clk33m
    inst_pll : pll
    port map(
        CLK   => i_fpga_clk33m,
        CLKOP => n_pll_clk_op,
        CLKOK => n_pll_clk_ok,
        LOCK  => n_pll_lock
    );

    pll_lockn <= not(pll_lock);

    -- CLKDIVB instantiation for lower clocks
    inst_clkdiv : CLKDIVB
    -- synthesis translate_off
    generic map(
        GSR => "disabled"
    )
    -- synthesis translate_on
    port map(
        CLKI    => n_pll_clk_op,
        RST     => n_pll_lockn,
        -- synthesis translate_off
        RELEASE => '1',
        -- synthesis translate_on
        CDIV1   => n_clk_div1,
        CDIV2   => n_clk_div2,
        CDIV4   => n_clk_div4,
        CDIV8   => n_clk_div8
    );

    -- Instantiate reset controller (hard and soft resets)
    inst_reset_controller : reset
    port map(
        SYNC_CLK   => n_clk_div1,
        PLL_LOCK   => n_pll_lock,
        EXT_SOFT   => i_fpga_rstn,
        AUX_SOFT   => n_aux_reset,
        DBG_ACTIVE => '0',
        GB_RESETN  => o_gb_rstn,
        SOFT_RESET => n_soft_reset,
        HARD_RESET => n_hard_reset
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
        o_access_ram => gb_access_ram,
        o_wr_timeout => gb_timeout_rd,
        o_rd_timeout => gb_timeout_wr
    );

    -- Decoder crossbar instance
    inst_crossbar_decoder : wb_crossbar_decoder
    port map(
        CLK_I      => clk_div1,
        RST_I      => hard_reset,
        ACCESS_RAM => gb_access_ram,
        SELECT_MBC => n_mbch_selected_mcb,

        CYC_I => gbd_cyc,
        ACK_O => gbd_ack,
        WE_I  => gbd_we,
        ADR_I => gbd_adr,
        DAT_O => gbd_dat_i,
        DAT_I => gbd_dat_o,

        CCB_CYC_O => dcb_ccb_cyc,
        CCB_ACK_I => dcb_ccb_ack,
        CCB_WE_O  => dcb_ccb_we,
        CCB_ADR_O => dcb_ccb_adr,
        CCB_DAT_O => dcb_ccb_dat_o,
        CCB_DAT_I => dcb_ccb_dat_i,

        DMA_CYC_O => dcb_dma_cyc,
        DMA_ACK_I => dcb_dma_ack,
        DMA_WE_O  => dcb_dma_we,
        DMA_ADR_O => dcb_dma_adr,
        DMA_DAT_O => dcb_dma_dat_o,
        DMA_DAT_I => dcb_dma_dat_i
    );

    -- DMA controller instance
    inst_dma_controller : dma_controller
    port map(
        CLK_I => clk_div1,
        RST_I => soft_reset,

        DMA_CYC_O => dma_cyc,
        DMA_ACK_I => dma_ack,
        DMA_WE_O  => dma_we,
        DMA_ADR_O => dma_adr,
        DMA_DAT_O => dma_dat_o,
        DMA_DAT_I => dma_dat_i,

        CFG_CYC_I => dcb_dma_cyc,
        CFG_ACK_O => dcb_dma_ack,
        CFG_WE_I  => dcb_dma_we,
        CFG_ADR_I => dcb_dma_adr,
        CFG_DAT_O => dcb_dma_dat_i,
        CFG_DAT_I => dcb_dma_dat_o,

        STATUS_BUSY => dma_busy
    );

    -- Central crossbar instance
    inst_crossbar_central : wb_crossbar_central
    port map(
        CLK_I      => clk_div1,
        RST_I      => hard_reset,
        DMA_BUSY   => dma_busy,
        DBG_ACTIVE => '0',

        DBG_CYC_I => '0',
        DBG_ACK_O => open,
        DBG_WE_I  => '0',
        DBG_ADR_I => (others => '0'),
        DBG_DAT_O => open,
        DBG_DAT_I => (others => '0'),

        GBD_CYC_I => dcb_ccb_cyc,
        GBD_ACK_O => dcb_ccb_ack,
        GBD_WE_I  => dcb_ccb_we,
        GBD_ADR_I => dcb_ccb_adr,
        GBD_DAT_O => dcb_ccb_dat_i,
        GBD_DAT_I => dcb_ccb_dat_o,

        DMA_CYC_I => dma_cyc,
        DMA_ACK_O => dma_ack,
        DMA_WE_I  => dma_we,
        DMA_ADR_I => dma_adr,
        DMA_DAT_O => dma_dat_i,
        DMA_DAT_I => dma_dat_o,

        CYC_O => ccb_cyc,
        ACK_I => ccb_ack,
        WE_O  => ccb_we,
        ADR_O => ccb_adr,
        DAT_O => ccb_dat_o,
        DAT_I => ccb_dat_i
    );

    inst_mbch : mbch
    port map(
        CLK_I => clk_div1,
        RST_I => hard_reset,
        CYC_I => ccb_cyc,
        WE_I => ccb_we,
        ACK_O => ccb_ack,
        ADR_I => ccb_adr,
        DAT_I => ccb_dat_o,
        DAT_O => ccb_dat_i,
        XRAM_ADR_O => open,
        XRAM_DAT_I => (others => '0'),
        XRAM_ACK_I => '1',
        GPIO_IN => (others => '0'),
        GPIO_OUT => open,
        SELECT_MBC => n_mbch_selected_mcb,
        SOFT_RESET_REQ => aux_reset,
        SOFT_RESET_IN => soft_reset,
        DBG_ACTIVE => '0'
    );

    o_clk_en <= '1';
    io_gb_data <= n_gb_dout when (i_gb_clk nor i_gb_rdn) = '1' else (others => 'Z');
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

    io_fpga_user <= "ZZZZZZ";

end architecture rtl;