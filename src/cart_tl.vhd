----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 03/31/2022 02:16:43 PM
-- Design Name: Cartridge toplevel
-- Module Name: toplevel - behaviour
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Documentation
--
-- This is the cartridge's toplevel VHDL file. It contains the instances of all
-- the necessary cores for implementing the cartridge functions.
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library MachXO3D;
use MachXO3D.all;

entity cart_tl is
    generic (
        SIMULATION  : boolean := false);
    port (
        -- Gameboy signals
        GB_CLK      : in std_logic;
        GB_RESETN   : out std_logic;
        GB_ADDR     : in std_logic_vector(15 downto 0);
        GB_DATA     : inout std_logic_vector(7 downto 0);
        GB_RDN      : in std_logic;
        GB_CSN      : in std_logic;

        -- SPI signals
        SPI_CLK         : inout std_logic;
        SPI_MISO        : inout std_logic;
        SPI_MOSI        : inout std_logic;
        SPI_HARD_CSN    : out std_logic;
        SPI_SDC_CSN     : out std_logic;

        -- Debugger signals
        DBG_CLK     : in std_logic;
        DBG_CSN     : in std_logic;
        DBG_MOSI    : in std_logic;
        DBG_MISO    : out std_logic;
        DBG_ENABLE  : in std_logic;

        -- Bus tranceivers
        BTA_OEN     : out std_logic;
        BTD_OEN     : out std_logic;
        BTD_DIR     : out std_logic;

        -- DRAM signals
        DRAM_CLK    : out std_logic;
        DRAM_CKE    : out std_logic;
        DRAM_BA     : out std_logic_vector(1 downto 0);
        DRAM_A      : out std_logic_vector(12 downto 0);
        DRAM_CSN    : out std_logic;
        DRAM_RASN   : out std_logic;
        DRAM_CASN   : out std_logic;
        DRAM_WEN    : out std_logic;
        DRAM_DQM    : out std_logic;
        DRAM_DQ     : inout std_logic_vector(7 downto 0);

        -- Audio related
        AUDIO_OUT   : out std_logic;

        -- Temporary for testing
        USER_RST    : in std_logic;
        STATUS_LED  : out std_logic_vector(7 downto 0));
end cart_tl;

architecture behaviour of cart_tl is

    component OSCJ
    -- synthesis translate_off
    generic (
        NOM_FREQ    : string := "53.20");
    -- synthesis translate_on
    port (
        STDBY       : in std_logic;
        OSC         : out std_logic;
        SEDSTDBY    : out std_logic;
        OSCESB      : out std_logic);
    end component;

    component pll
    port (
        CLKI    : in std_logic;
        CLKOP   : out std_logic; 
        CLKOS   : out std_logic;
        LOCK    : out std_logic);
    end component;
        
    component efb
    port (
        wb_clk_i    : in std_logic;
        wb_rst_i    : in std_logic; 
        wb_cyc_i    : in std_logic;
        wb_stb_i    : in std_logic; 
        wb_we_i     : in std_logic; 
        wb_adr_i    : in std_logic_vector(7 downto 0); 
        wb_dat_i    : in std_logic_vector(7 downto 0); 
        wb_dat_o    : out std_logic_vector(7 downto 0); 
        wb_ack_o    : out std_logic;
        spi_clk     : inout std_logic; 
        spi_miso    : inout std_logic;
        spi_mosi    : inout std_logic; 
        spi_scsn    : in std_logic; 
        spi_csn     : out std_logic_vector(1 downto 0); 
        ufm_sn      : in std_logic;
        wbc_ufm_irq : out std_logic);
    end component;

    -- PLL signals
    signal pll_clk_in   : std_logic;
    signal pll_clk_op   : std_logic;
    signal pll_clk_os   : std_logic;
    signal pll_lock     : std_logic;

    signal gb_data_outgoing : std_logic_vector(7 downto 0);
    signal gb_data_incoming : std_logic_vector(7 downto 0);
    signal wb_data_outgoing : std_logic_vector(7 downto 0);
    signal wb_data_incoming : std_logic_vector(7 downto 0);

    signal wb_adr   : std_logic_vector(15 downto 0);
    signal wb_we    : std_logic;
    signal wb_cyc   : std_logic;
    signal wb_ack   : std_logic;

    signal gbd_cyc      : std_logic;
    signal gbd_ack      : std_logic;
    signal gbd_we       : std_logic;
    signal gbd_adr      : std_logic_vector(15 downto 0);
    signal gbd_dat_i    : std_logic_vector(7 downto 0);
    signal gbd_dat_o    : std_logic_vector(7 downto 0);

    signal ccb_cyc      : std_logic;
    signal ccb_stb      : std_logic;
    signal ccb_ack      : std_logic;
    signal ccb_we       : std_logic;
    signal ccb_adr      : std_logic_vector(15 downto 0);
    signal ccb_dat_i    : std_logic_vector(7 downto 0);
    signal ccb_dat_o    : std_logic_vector(7 downto 0);

    signal dma_cyc      : std_logic;
    signal dma_ack      : std_logic;
    signal dma_we       : std_logic;
    signal dma_adr      : std_logic_vector(15 downto 0);
    signal dma_dat_i    : std_logic_vector(7 downto 0);
    signal dma_dat_o    : std_logic_vector(7 downto 0);
    signal dma_busy     : std_logic;

    signal dma_cfg_cyc      : std_logic;
    signal dma_cfg_stb      : std_logic;
    signal dma_cfg_ack      : std_logic;
    signal dma_cfg_we       : std_logic;
    signal dma_cfg_adr      : std_logic_vector(3 downto 0);
    signal dma_cfg_dat_i    : std_logic_vector(7 downto 0);
    signal dma_cfg_dat_o    : std_logic_vector(7 downto 0);

    signal dbg_cyc      : std_logic;
    signal dbg_ack      : std_logic;
    signal dbg_we       : std_logic;
    signal dbg_adr      : std_logic_vector(15 downto 0);
    signal dbg_dat_i    : std_logic_vector(7 downto 0);
    signal dbg_dat_o    : std_logic_vector(7 downto 0);
    signal dbg_active   : std_logic;

    signal bus_selector : std_logic_vector(2 downto 0);
    signal wb_mbch_strb : std_logic;
    signal wb_mbch_ack  : std_logic;
    signal wb_mbch_dat  : std_logic_vector(7 downto 0);

    signal wb_efb_stb   : std_logic;
    signal wb_efb_rdat  : std_logic_vector(7 downto 0);
    signal wb_efb_ack   : std_logic;

    signal wb_dram_stb  : std_logic;
    signal wb_dram_bank : std_logic_vector(8 downto 0);
    signal wb_dram_tga  : std_logic_vector(1 downto 0);
    signal wb_dram_rdat : std_logic_vector(7 downto 0);
    signal wb_dram_ack  : std_logic;

    signal wb_audio_stb     : std_logic;
    signal wb_audio_rdat    : std_logic_vector(7 downto 0);
    signal wb_audio_ack     : std_logic;

    signal led_gb_clk_divider   : std_logic_vector(18 downto 0);
    signal led_wb_clk_divider   : std_logic_vector(24 downto 0);

    signal soft_reset       : std_logic;
    signal hard_reset       : std_logic;
    signal aux_reset        : std_logic;

    signal dram_ready       : std_logic;
    signal dram_rblock      : std_logic;
    signal gb_access_ram    : std_logic;
    signal gb_timeout_rd    : std_logic;
    signal gb_timeout_wr    : std_logic;

    attribute NOM_FREQ : string;
    attribute NOM_FREQ of INTERNAL_OSCILLATOR : label is "53.20";

    -- attribute SYN_KEEP : boolean;
    -- attribute SYN_KEEP of power_up_reset : signal is true;

begin

    -- Occilator instantiation
    INTERNAL_OSCILLATOR : component OSCJ
    -- synthesis translate_off
    generic map (
        NOM_FREQ => "53.20")
    -- synthesis translate_on
    port map (
        STDBY => '0',
        OSC => pll_clk_in,
        SEDSTDBY => open,
        OSCESB => open);

    -- PLL instantiation
    CART_PLL : pll
    port map (
        CLKI => pll_clk_in,
        CLKOP => pll_clk_op,
        CLKOS => pll_clk_os,
        LOCK => pll_lock);

    -- Instantiate reset controller (hard and soft resets)
    RESET_CONTROLLER : entity work.reset
    generic map (
        SIMULATION => SIMULATION)
    port map (
        SYNC_CLK => pll_clk_op,
        PLL_LOCK => pll_lock,
        EXT_SOFT => USER_RST,
        AUX_SOFT => aux_reset,
        DBG_ACTIVE => dbg_active,
        GB_RESETN => GB_RESETN,
        SOFT_RESET => soft_reset,
        HARD_RESET => hard_reset);

    -- Gameboy decoder instance
    GB_SIGNAL_DECODER : entity work.gb_decoder
    generic map (
        ENABLE_TIMEOUT_DETECTION => true)
    port map (
        GB_CLK => GB_CLK,
        GB_ADDR => GB_ADDR,
        GB_DATA_IN => gb_data_incoming,
        GB_DATA_OUT => gb_data_outgoing,
        GB_RDN => GB_RDN,
        GB_CSN => GB_CSN,

        CLK_I => pll_clk_op,
        RST_I => soft_reset,
        CYC_O => gbd_cyc,
        WE_O => gbd_we,
        ADR_O => gbd_adr,
        DAT_I => gbd_dat_i,
        DAT_O => gbd_dat_o,
        ACK_I => gbd_ack,
        
        ACCESS_ROM => open,
        ACCESS_RAM => gb_access_ram,
        REFRESH_BLOCK => dram_rblock,
        RD_TIMEOUT => gb_timeout_rd,
        WR_TIMEOUT => gb_timeout_wr);

    GB_DATA <= gb_data_outgoing when (GB_CLK nor GB_RDN) = '1' else "ZZZZZZZZ";
    gb_data_incoming <= GB_DATA;

    -- Decoder crossbar instance
    CROSSBAR_DECODER : entity work.wb_crossbar_decoder
    port map (
        CLK_I => pll_clk_op,
        RST_I => hard_reset,
        ACCESS_RAM => gb_access_ram,
        SELECT_MBC => bus_selector,

        CYC_I => gbd_cyc,
        ACK_O => gbd_ack,
        WE_I => gbd_we,
        ADR_I => gbd_adr,
        DAT_O => gbd_dat_i,
        DAT_I => gbd_dat_o,

        CCB_CYC_O => ccb_cyc,
        CCB_STB_O => ccb_stb,
        CCB_ACK_I => ccb_ack,
        CCB_WE_O => ccb_we,
        CCB_ADR_O => ccb_adr,
        CCB_DAT_O => ccb_dat_o,
        CCB_DAT_I => ccb_dat_i,

        DMA_CYC_O => dma_cfg_cyc,
        DMA_STB_O => dma_cfg_stb,
        DMA_ACK_I => dma_cfg_ack,
        DMA_WE_O => dma_cfg_we,
        DMA_ADR_O => dma_cfg_adr,
        DMA_DAT_O => dma_cfg_dat_o,
        DMA_DAT_I => dma_cfg_dat_i);

    -- DMA controller instance
    DMA_CONTROLLER : entity work.dma_controller
    port map (
        CLK_I => pll_clk_op,
        RST_I => soft_reset,

        DMA_CYC_O => dma_cyc,
        DMA_ACK_I => dma_ack,
        DMA_WE_O => dma_we,
        DMA_ADR_O => dma_adr,
        DMA_DAT_O => dma_dat_o,
        DMA_DAT_I => dma_dat_i,

        CFG_CYC_I => dma_cfg_cyc,
        CFG_STB_I => dma_cfg_stb,
        CFG_ACK_O => dma_cfg_ack,
        CFG_WE_I => dma_cfg_we,
        CFG_ADR_I => dma_cfg_adr,
        CFG_DAT_O => dma_cfg_dat_i,
        CFG_DAT_I => dma_cfg_dat_o,

        STATUS_BUSY => dma_busy);

    -- Debug core instance
    SPI_DBG_CORE : entity work.spi_debug
    port map (
        CLK_I => pll_clk_op,
        RST_I => hard_reset,
        CYC_O => dbg_cyc,
        ACK_I => dbg_ack,
        WE_O => dbg_we,
        ADR_O => dbg_adr,
        DAT_O => dbg_dat_o,
        DAT_I => dbg_dat_i,
        SPI_DBG_CLK => DBG_CLK,
        SPI_DBG_CSN => DBG_CSN,
        SPI_DBG_MOSI => DBG_MOSI,
        SPI_DBG_MISO => DBG_MISO,
        DBG_ENABLE => DBG_ENABLE,
        DBG_ACTIVE => dbg_active);

    -- Central crossbar instance
    CROSSBAR_CENTRAL : entity work.wb_crossbar_central
    port map (
        CLK_I => pll_clk_op,
        RST_I => hard_reset,
        DMA_BUSY => dma_busy,
        DBG_ACTIVE => dbg_active,

        DBG_CYC_I => dbg_cyc,
        DBG_ACK_O => dbg_ack,
        DBG_WE_I => dbg_we,
        DBG_ADR_I => dbg_adr,
        DBG_DAT_O => dbg_dat_i,
        DBG_DAT_I => dbg_dat_o,

        GBD_CYC_I => ccb_cyc,
        GBD_STB_I => ccb_stb,
        GBD_ACK_O => ccb_ack,
        GBD_WE_I => ccb_we,
        GBD_ADR_I => ccb_adr,
        GBD_DAT_O => ccb_dat_i,
        GBD_DAT_I => ccb_dat_o,

        DMA_CYC_I => dma_cyc,
        DMA_ACK_O => dma_ack,
        DMA_WE_I => dma_we,
        DMA_ADR_I => dma_adr,
        DMA_DAT_O => dma_dat_i,
        DMA_DAT_I => dma_dat_o,

        CYC_O => wb_cyc,
        ACK_I => wb_ack,
        WE_O => wb_we,
        ADR_O => wb_adr,
        DAT_O => wb_data_incoming,
        DAT_I => wb_data_outgoing);

    -- MBC selector outgoing data
    with bus_selector select wb_data_outgoing <=
        wb_mbch_dat when "000",
        x"00"       when others;

    -- MBC selector ack
    with bus_selector select wb_ack <=
        wb_mbch_ack when "000",
        '1'         when others;

    -- MBC selector strobe
    wb_mbch_strb <= '1' when bus_selector = "000" else '0';

    -- MBC Hypervisor instance
    MBC_HYPERVISOR : entity work.mbch
    port map (
        CLK_I => pll_clk_op,
        RST_I => hard_reset,
        STB_I => wb_mbch_strb,
        CYC_I => wb_cyc,
        WE_I => wb_we,
        ACK_O => wb_mbch_ack,
        ADR_I => wb_adr,
        DAT_I => wb_data_incoming,
        DAT_O => wb_mbch_dat,

        EFB_STB_O => wb_efb_stb,
        EFB_DAT_I => wb_efb_rdat,
        EFB_ACK_I => wb_efb_ack,

        DRAM_STB_O => wb_dram_stb,
        DRAM_ADR_O => wb_dram_bank,
        DRAM_TGA_O => wb_dram_tga,
        DRAM_DAT_I => wb_dram_rdat,
        DRAM_ACK_I => wb_dram_ack,
        DRAM_ERR_I => '0',

        AUDIO_STB_O => wb_audio_stb,
        AUDIO_DAT_I => wb_audio_rdat,
        AUDIO_ACK_I => wb_audio_ack,

        GPIO_IN(0) => '0',
        GPIO_IN(1) => '0',
        GPIO_IN(2) => '0',
        GPIO_IN(3) => '0',
        GPIO_OUT => open,

        SELECT_MBC => bus_selector,
        SOFT_RESET_OUT => aux_reset,
        SOFT_RESET_IN => soft_reset,
        DRAM_READY => dram_ready,
        DBG_ACTIVE => dbg_active);

    -- EFB instance
    EFB_INST : component efb
    port map (
        wb_clk_i => pll_clk_op,
        wb_rst_i => soft_reset,
        wb_cyc_i => wb_cyc,
        wb_stb_i => wb_efb_stb,
        wb_we_i => wb_we,
        wb_adr_i => wb_adr(7 downto 0),
        wb_dat_i => wb_data_incoming,
        wb_dat_o => wb_efb_rdat,
        wb_ack_o => wb_efb_ack,
        spi_clk => SPI_CLK,
        spi_miso => SPI_MISO,
        spi_mosi => SPI_MOSI,
        spi_scsn => '1',
        spi_csn(0) => SPI_HARD_CSN,
        spi_csn(1) => SPI_SDC_CSN,
        ufm_sn => '1',
        wbc_ufm_irq => open);

    -- DRAM controller instance
    DRAM_CTRL_INST : entity work.as4c32m8sa_controller
    generic map (
        CLK_FREQ => 53.20)
    port map (
        CLK_I => pll_clk_op,
        RST_I => hard_reset,
        CYC_I => wb_cyc,
        STB_I => wb_dram_stb,
        WE_I => wb_we,
        ADR_I => wb_dram_bank & wb_adr(13 downto 0),        -- Is always divided up into 16 kB blocks
        TGA_I => wb_dram_tga,
        DAT_I => wb_data_incoming,
        DAT_O => wb_dram_rdat,
        ACK_O => wb_dram_ack,
        READY => dram_ready,
        REFRESH_BLOCK => dram_rblock,
        CKE => DRAM_CKE,
        BA => DRAM_BA,
        A => DRAM_A,
        CSN => DRAM_CSN,
        RASN => DRAM_RASN,
        CASN => DRAM_CASN,
        WEN => DRAM_WEN,
        DQM => DRAM_DQM,
        DQ => DRAM_DQ);

    DRAM_CLK <= pll_clk_op;

    -- Audio controller [TEMP]
    AUDIO_CTRL_INST : entity work.audio_controller
    port map (
        CLK_I => pll_clk_op,
        RST_I => soft_reset,
        CYC_I => wb_cyc,
        STB_I => wb_audio_stb,
        ACK_O => wb_audio_ack,
        WE_I => wb_we,
        ADR_I => wb_adr(3 downto 0),
        DAT_O => wb_audio_rdat,
        DAT_I => wb_data_incoming,
        CLK_S => pll_clk_os,
        AUDIO_OUT => AUDIO_OUT);

    -- GB clock indicator LED
    process (GB_CLK)
    begin
        if rising_edge(GB_CLK) then
            if hard_reset = '1' then
                led_gb_clk_divider <= (others => '0');
            else
                led_gb_clk_divider <= std_logic_vector(unsigned(led_gb_clk_divider) + 1);
            end if;
        end if;
    end process;

    STATUS_LED(7) <= not(led_gb_clk_divider(led_gb_clk_divider'high));

    -- WB clock indicator LED
    process (pll_clk_op)
    begin
        if rising_edge(pll_clk_op) then
            if hard_reset = '1' then
                led_wb_clk_divider <= (others => '0');
            else
                led_wb_clk_divider <= std_logic_vector(unsigned(led_wb_clk_divider) + 1);
            end if;
        end if;
    end process;

    STATUS_LED(6) <= not(led_wb_clk_divider(led_wb_clk_divider'high));
    
    -- LED indicator for reset state [TEMP]
    STATUS_LED(5) <= not(soft_reset);

    -- LED indicator for gb_decoder write timeout [TEMP]
    STATUS_LED(4) <= not(gb_timeout_wr);

    -- LED indicator for gb_decoder read timeout [TEMP]
    STATUS_LED(3) <= not(gb_timeout_rd);

    -- Other leds off [TEMP]
    STATUS_LED(2 downto 0) <= (others => '1');
    
    -- Bus tranceiver control
    BTA_OEN <= hard_reset;
    BTD_OEN <= GB_CLK or hard_reset;
    BTD_DIR <= GB_RDN;

end behaviour;
