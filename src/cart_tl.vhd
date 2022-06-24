----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/31/2022 02:16:43 PM
-- Design Name: 
-- Module Name: toplevel - behaviour
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
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library MACHXO3D;
use MACHXO3D.all;

entity cart_tl is
    port (
		-- Gameboy signals
        GB_CLK      : in std_logic;
		GB_RESETN	: out std_logic;
        GB_ADDR     : in std_logic_vector(15 downto 0);
        GB_DATA     : inout std_logic_vector(7 downto 0);
        GB_RDN      : in std_logic;
		GB_CSN      : in std_logic;

		-- SPI signals
		SPI_CLK		: inout std_logic;
		SPI_MISO	: inout std_logic;
		SPI_MOSI	: inout std_logic;
		SPI_CSN		: out std_logic;
		
		-- Bus tranceivers
		BTA_OEN		: out std_logic;
		BTD_OEN		: out std_logic;
		BTD_DIR		: out std_logic;

		-- Temporary for testing
		USER_RST	: in std_logic;
		LED_RST		: out std_logic;
		LED_GB_CLK	: out std_logic;
		LED_WB_CLK	: out std_logic;
		LED_OFF		: out std_logic_vector(4 downto 0));
end cart_tl;

architecture behaviour of cart_tl is

	component OSCJ
	-- synthesis translate_off
	generic (
		NOM_FREQ	: string := "53.20");
	-- synthesis translate_on
	port (
		STDBY 		: in std_logic;
		OSC			: out std_logic;
		SEDSTDBY	: out std_logic;
		OSCESB 		: out std_logic);
	end component;

	component efb
    port (
		wb_clk_i	: in std_logic;
		wb_rst_i	: in std_logic; 
        wb_cyc_i	: in std_logic;
		wb_stb_i	: in std_logic; 
        wb_we_i		: in std_logic; 
        wb_adr_i	: in std_logic_vector(7 downto 0); 
        wb_dat_i	: in std_logic_vector(7 downto 0); 
        wb_dat_o	: out std_logic_vector(7 downto 0); 
        wb_ack_o	: out std_logic;
		spi_clk		: inout std_logic; 
        spi_miso	: inout std_logic;
		spi_mosi	: inout std_logic; 
        spi_scsn	: in std_logic; 
        spi_csn		: out std_logic_vector(0 downto 0); 
        ufm_sn		: in std_logic;
		wbc_ufm_irq	: out std_logic);
	end component;

    signal gb_data_outgoing : std_logic_vector(7 downto 0);
    signal gb_data_incoming : std_logic_vector(7 downto 0);
	signal wb_data_outgoing : std_logic_vector(7 downto 0);
	signal wb_data_incoming : std_logic_vector(7 downto 0);

	signal wb_clk   : std_logic;
	signal wb_adr   : std_logic_vector(15 downto 0);
	signal wb_we 	: std_logic;
	signal wb_cyc   : std_logic;
	signal wb_ack	: std_logic;

	signal bus_selector	: std_logic_vector(2 downto 0);
	signal wb_mbch_strb : std_logic;
	signal wb_mbch_ack	: std_logic;
	signal wb_mbch_dat	: std_logic_vector(7 downto 0);

	signal wb_efb_cyc	: std_logic;
	signal wb_efb_stb	: std_logic;
	signal wb_efb_we	: std_logic;
	signal wb_efb_adr	: std_logic_vector(7 downto 0);
	signal wb_efb_wdat	: std_logic_vector(7 downto 0);
	signal wb_efb_rdat	: std_logic_vector(7 downto 0);
	signal wb_efb_ack	: std_logic;

	signal led_gb_clk_divider : std_logic_vector(18 downto 0);
	signal led_wb_clk_divider : std_logic_vector(24 downto 0);

	signal power_up_reset	: std_logic;
	signal soft_reset		: std_logic;
	signal hard_reset		: std_logic;
	signal aux_reset		: std_logic;

	-- Access signals
	signal gb_access_rom : std_logic;
	signal gb_access_ram : std_logic;

	attribute NOM_FREQ : string;
	attribute NOM_FREQ of INTERNAL_OSCILLATOR : label is "53.20";

	-- attribute SYN_KEEP : boolean;
	-- attribute SYN_KEEP of power_up_reset : signal is true;
	attribute GSR_ENABLED : boolean;
	attribute GSR_ENABLED of power_up_reset : signal is true;

begin

	-- -- Instantiate Power-Up Reset signal
	-- GSR_INST : GSR
	-- port map (GSR => power_up_reset);

	-- power_up_reset <= '1';

	-- Instantiate reset controller (hard and soft resets)
	RESET_CONTROLLER : entity work.reset
	port map (
		SYNC_CLK => wb_clk,
		PUR => power_up_reset,
		EXT_SOFT => USER_RST,
		AUX_SOFT => aux_reset,
		GB_RESETN => GB_RESETN,
		SOFT_RESET => soft_reset,
		HARD_RESET => hard_reset
	);

    GB_SIGNAL_DECODER : entity work.gb_decoder
    port map (
        GB_CLK => GB_CLK,
        GB_ADDR => GB_ADDR,
        GB_DATA_IN => gb_data_incoming,
        GB_DATA_OUT => gb_data_outgoing,
		GB_RDN => GB_RDN,
		GB_CSN => GB_CSN,

		CLK_I => wb_clk,
		RST_I => hard_reset,
		CYC_O => wb_cyc,
		WE_O => wb_we,
        ADR_O => wb_adr,
        DAT_I => wb_data_outgoing,
        DAT_O => wb_data_incoming,
        ACK_I => wb_ack,

		ACCESS_ROM => gb_access_rom,
		ACCESS_RAM => gb_access_ram);
		
    GB_DATA <= gb_data_outgoing when (GB_CLK nor GB_RDN) = '1' else "ZZZZZZZZ";
    gb_data_incoming <= GB_DATA;

	-- MBC selector outgoing data
	with bus_selector select wb_data_outgoing <=
		wb_mbch_dat when "000",
		x"00"		when others;

	-- MBC selector ack
	with bus_selector select wb_ack <=
		wb_mbch_ack when "000",
		'1'			when others;

	-- MBC selector strobe
	wb_mbch_strb <= '1' when bus_selector = "000" else '0';

	-- MBC Hypervisor instance
	MBC_HYPERVISOR : entity work.mbch
	port map (
		CLK_I => wb_clk,
		RST_I => hard_reset,
		STB_I => wb_mbch_strb,
		CYC_I => wb_cyc,
		WE_O => wb_we,
		ACK_O => wb_mbch_ack,
		ADR_I => wb_adr,
		DAT_I => wb_data_incoming,
		DAT_O => wb_mbch_dat,

		EFB_CYC_O => wb_efb_cyc,
		EFB_STB_O => wb_efb_stb,
		EFB_WE_O => wb_efb_we,
		EFB_ADR_O => wb_efb_adr,
		EFB_DAT_O => wb_efb_wdat,
		EFB_DAT_I => wb_efb_rdat,
		EFB_ACK_I => wb_efb_ack,

		ACCESS_ROM => gb_access_rom,
		ACCESS_RAM => gb_access_ram,
		SELECT_MBC => bus_selector,
		SOFT_RESET_OUT => aux_reset,
		SOFT_RESET_IN => soft_reset
	);

	-- EFB instance
	EFB_INST : component efb
	port map (
		wb_clk_i => wb_clk,
		wb_rst_i => hard_reset, 
        wb_cyc_i => wb_efb_cyc,
		wb_stb_i => wb_efb_stb, 
        wb_we_i => wb_efb_we, 
        wb_adr_i => wb_efb_adr, 
        wb_dat_i => wb_efb_wdat, 
        wb_dat_o => wb_efb_rdat, 
        wb_ack_o => wb_efb_ack,
		spi_clk => SPI_CLK, 
        spi_miso => SPI_MISO,
		spi_mosi => SPI_MOSI, 
        spi_scsn => '1', 
        spi_csn(0) => SPI_CSN, 
        ufm_sn => '1',
		wbc_ufm_irq	=> open);

	INTERNAL_OSCILLATOR : component OSCJ
	-- synthesis translate_off
	generic map (
		NOM_FREQ => "53.20")
	-- synthesis translate_on
	port map (
		STDBY => '0',
		OSC => wb_clk,
		SEDSTDBY => open,
		OSCESB => open);

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

	LED_GB_CLK <= not(led_gb_clk_divider(led_gb_clk_divider'high));

	-- WB clock indicator LED
	process (wb_clk)
	begin
		if rising_edge(wb_clk) then
			if hard_reset = '1' then
				led_wb_clk_divider <= (others => '0');
			else
				led_wb_clk_divider <= std_logic_vector(unsigned(led_wb_clk_divider) + 1);
			end if;
		end if;
	end process;

	LED_WB_CLK <= not(led_wb_clk_divider(led_wb_clk_divider'high));
    
	-- LED indicator for reset state [TEMP]
	LED_RST <= not(soft_reset);

	-- Other leds off [TEMP]
	LED_OFF <= (others => '1');
	
	-- Bus tranceiver control [TEMP: will assume only reads from cart]
	BTA_OEN <= hard_reset;
	BTD_OEN <= GB_CLK or hard_reset;
	BTD_DIR <= '0';

end behaviour;
