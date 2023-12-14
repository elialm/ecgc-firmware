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
        SIMULATION : boolean := FALSE
    );
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

    component pll
        port (
            CLK   : in std_logic;
            CLKOP : out std_logic;
            CLKOK : out std_logic;
            LOCK  : out std_logic
        );
    end component;

    component CLKDIVB
        -- synthesis translate_off
        generic (
            GSR : in string
        );
        -- synthesis translate_on
        port (
            CLKI    : in std_logic;
            RST     : in std_logic;
            -- synthesis translate_off
            RELEASE : in std_logic;
            -- synthesis translate_on
            CDIV1   : out std_logic;
            CDIV2   : out std_logic;
            CDIV4   : out std_logic;
            CDIV8   : out std_logic
        );
    end component;

    component reset
        generic (
            GSR_FF : positive := 8;
            AUX_FF : positive := 9;
            SIMULATION : boolean := SIMULATION
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
            ENABLE_TIMEOUT_DETECTION : boolean := false;
            CLK_FREQ : real := 99.999999
        );
        port (
            GB_CLK      : in std_logic;
            GB_ADDR     : in std_logic_vector(15 downto 0);
            GB_DATA_IN  : in std_logic_vector(7 downto 0);
            GB_DATA_OUT : out std_logic_vector(7 downto 0);
            GB_RDN      : in std_logic;
            GB_CSN      : in std_logic;
            CLK_I       : in std_logic;
            RST_I       : in std_logic;
            CYC_O       : out std_logic;
            WE_O        : out std_logic;
            ADR_O       : out std_logic_vector(15 downto 0);
            DAT_I       : in std_logic_vector(7 downto 0);
            DAT_O       : out std_logic_vector(7 downto 0);
            ACK_I       : in std_logic;
            ACCESS_ROM  : out std_logic;
            ACCESS_RAM  : out std_logic;
            WR_TIMEOUT  : out std_logic;
            RD_TIMEOUT  : out std_logic
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
    signal pll_clk_op : std_logic;
    signal pll_clk_ok : std_logic;
    signal pll_lock : std_logic;
    signal pll_lockn : std_logic;
    signal clk_div1 : std_logic;
    signal clk_div2 : std_logic;
    signal clk_div4 : std_logic;
    signal clk_div8 : std_logic;

    -- Resets
    signal soft_reset : std_logic;
    signal hard_reset : std_logic;
    signal aux_reset : std_logic;

    -- Gameboy decoder related
    signal gb_data_o : std_logic_vector(7 downto 0);
    signal gb_access_ram : std_logic;
    signal gb_timeout_rd : std_logic;
    signal gb_timeout_wr : std_logic;

    -- Wishbone bus from Gameboy decoder
    signal gbd_cyc : std_logic;
    signal gbd_we : std_logic;
    signal gbd_adr : std_logic_vector(15 downto 0);
    signal gbd_dat_i : std_logic_vector(7 downto 0);
    signal gbd_dat_o : std_logic_vector(7 downto 0);
    signal gbd_ack : std_logic;

    -- Wishbone bus from decoder crossbar to central crossbar
    signal dcb_ccb_cyc : std_logic;
    signal dcb_ccb_we : std_logic;
    signal dcb_ccb_adr : std_logic_vector(15 downto 0);
    signal dcb_ccb_dat_i : std_logic_vector(7 downto 0);
    signal dcb_ccb_dat_o : std_logic_vector(7 downto 0);
    signal dcb_ccb_ack : std_logic;

    -- Wishbone bus from decoder crossbar to DMA config port
    signal dcb_dma_cyc : std_logic;
    signal dcb_dma_we : std_logic;
    signal dcb_dma_adr : std_logic_vector(3 downto 0);
    signal dcb_dma_dat_i : std_logic_vector(7 downto 0);
    signal dcb_dma_dat_o : std_logic_vector(7 downto 0);
    signal dcb_dma_ack : std_logic;

    -- Wisbone bus from DMA master and DMA related
    signal dma_cyc : std_logic;
    signal dma_ack : std_logic;
    signal dma_we : std_logic;
    signal dma_adr : std_logic_vector(15 downto 0);
    signal dma_dat_i : std_logic_vector(7 downto 0);
    signal dma_dat_o : std_logic_vector(7 downto 0);
    signal dma_busy : std_logic;

    -- Wisbone bus from central crossbar
    signal ccb_adr : std_logic_vector(15 downto 0);
    signal ccb_we : std_logic;
    signal ccb_cyc : std_logic;
    signal ccb_dat_i : std_logic_vector(7 downto 0);
    signal ccb_dat_o : std_logic_vector(7 downto 0);
    signal ccb_ack : std_logic;

    -- MBCH related signals
    signal mbch_selected_mcb : std_logic_vector(2 downto 0);

begin

    -- PLL instantiation for frequency synthesis from FPGA_CLK33M
    inst_pll : pll
    port map(
        CLK   => FPGA_CLK33M,
        CLKOP => pll_clk_op,
        CLKOK => pll_clk_ok,
        LOCK  => pll_lock
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
        CLKI    => pll_clk_op,
        RST     => pll_lockn,
        -- synthesis translate_off
        RELEASE => '1',
        -- synthesis translate_on
        CDIV1   => clk_div1,
        CDIV2   => clk_div2,
        CDIV4   => clk_div4,
        CDIV8   => clk_div8
    );

    -- Instantiate reset controller (hard and soft resets)
    inst_reset_controller : reset
    port map(
        SYNC_CLK   => clk_div1,
        PLL_LOCK   => pll_lock,
        EXT_SOFT   => FPGA_SOFT_RSTN,
        AUX_SOFT   => aux_reset,
        DBG_ACTIVE => '0',
        GB_RESETN  => GB_RSTN,
        SOFT_RESET => soft_reset,
        HARD_RESET => hard_reset
    );

    -- Gameboy decoder instance
    inst_gameboy_decoder : gb_decoder
    generic map(
        ENABLE_TIMEOUT_DETECTION => true
    )
    port map(
        GB_CLK      => GB_CLK,
        GB_ADDR     => GB_ADDR,
        GB_DATA_IN  => GB_DATA,
        GB_DATA_OUT => gb_data_o,
        GB_RDN      => GB_RDN,
        GB_CSN      => GB_CSN,

        CLK_I => clk_div1,
        RST_I => soft_reset,
        CYC_O => gbd_cyc,
        WE_O  => gbd_we,
        ADR_O => gbd_adr,
        DAT_I => gbd_dat_i,
        DAT_O => gbd_dat_o,
        ACK_I => gbd_ack,

        ACCESS_ROM => open,
        ACCESS_RAM => gb_access_ram,
        RD_TIMEOUT => gb_timeout_rd,
        WR_TIMEOUT => gb_timeout_wr
    );

    -- Decoder crossbar instance
    inst_crossbar_decoder : wb_crossbar_decoder
    port map(
        CLK_I      => clk_div1,
        RST_I      => hard_reset,
        ACCESS_RAM => gb_access_ram,
        SELECT_MBC => mbch_selected_mcb,

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
        SELECT_MBC => mbch_selected_mcb,
        SOFT_RESET_REQ => aux_reset,
        SOFT_RESET_IN => soft_reset,
        DBG_ACTIVE => '0'
    );

    CLK_EN <= '1';
    GB_DATA <= gb_data_o when (GB_CLK nor GB_RDN) = '1' else (others => 'Z');
    GB_BUS_EN <= '0';

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