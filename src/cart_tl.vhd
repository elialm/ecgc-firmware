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
        GB_ADDR     : in std_logic_vector(15 downto 0);
        GB_DATA     : inout std_logic_vector(7 downto 0);
        GB_RDN      : in std_logic;
		GB_CSN      : in std_logic;
		
		-- Bus tranceivers
		BTA_OEN		: out std_logic;
		BTD_OEN		: out std_logic;
		BTD_DIR		: out std_logic;

		-- Temporary for testing
		USER_RST	: in std_logic;		-- TODO: make synchronous
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

	attribute NOM_FREQ : string;
	attribute NOM_FREQ of INTERNAL_OSCILLATOR : label is "53.20";
    
    signal gb_data_outgoing : std_logic_vector(7 downto 0);
    signal gb_data_incoming : std_logic_vector(7 downto 0);
	
	signal wb_clk_i : std_logic;
	signal wb_adr_o : std_logic_vector(15 downto 0);
	signal wb_dat_o : std_logic_vector(7 downto 0);
	signal wb_dat_i : std_logic_vector(7 downto 0);
	signal wb_we_o 	: std_logic;
	
	signal rom_stb : std_logic;
	signal rom_cyc : std_logic;
	signal rom_ack : std_logic;

	signal led_gb_clk_divider : std_logic_vector(18 downto 0);
	signal led_wb_clk_divider : std_logic_vector(24 downto 0);

	-- Access signals
	signal gb_access_rom : std_logic;
	signal gb_access_ram : std_logic;

begin

    GB_SIGNAL_DECODER : entity work.gb_decoder
    port map (
        GB_CLK => GB_CLK,
        GB_ADDR => GB_ADDR,
        GB_DATA_IN => gb_data_incoming,
        GB_DATA_OUT => gb_data_outgoing,
		GB_RDN => GB_RDN,
		GB_CSN => GB_CSN,
		CLK_I => wb_clk_i,
		RST_I => USER_RST,
		STB_O => rom_stb,
		CYC_O => rom_cyc,
		WE_O => wb_we_o,
        ADR_O => wb_adr_o,
        DAT_I => wb_dat_i,
        DAT_O => wb_dat_o,
        ACK_I => rom_ack,
		ACCESS_ROM => gb_access_rom,
		ACCESS_RAM => gb_access_ram);
		
    GB_DATA <= gb_data_outgoing when (GB_CLK nor GB_RDN) = '1' else "ZZZZZZZZ";
    gb_data_incoming <= GB_DATA;

	-- LED indicator for reset state [TEMP]
	LED_RST <= not(USER_RST);

	-- Other leds off [TEMP]
	LED_OFF <= (others => '1');
	
	-- Bus tranceiver control [TEMP]
	BTA_OEN <= USER_RST;
	BTD_OEN <= GB_CLK or USER_RST;
	BTD_DIR <= '0';
	
	CARTRIDGE_MEMORY_CONTROLLER : entity work.cmc
	port map (
		CLK_I => wb_clk_i,
		RST_I => USER_RST,
		STB_I => rom_stb,
		CYC_I => rom_cyc,
		WE_O => wb_we_o,
		ACK_O => rom_ack,
		ADR_I => wb_adr_o,
		DAT_I => wb_dat_o,
		DAT_O => wb_dat_i,
		ACCESS_ROM => gb_access_rom,
		ACCESS_RAM => gb_access_ram);

	INTERNAL_OSCILLATOR : component OSCJ
	-- synthesis translate_off
	generic map (
		NOM_FREQ => "53.20")
	-- synthesis translate_on
	port map (
		STDBY => '0',
		OSC => wb_clk_i,
		SEDSTDBY => open,
		OSCESB => open);

	process (GB_CLK)
	begin
		if rising_edge(GB_CLK) then
			if USER_RST = '1' then
				led_gb_clk_divider <= (others => '0');
			else
				led_gb_clk_divider <= std_logic_vector(unsigned(led_gb_clk_divider) + 1);
			end if;
		end if;
	end process;

	LED_GB_CLK <= not(led_gb_clk_divider(led_gb_clk_divider'high));

	process (wb_clk_i)
	begin
		if rising_edge(wb_clk_i) then
			if USER_RST = '1' then
				led_wb_clk_divider <= (others => '0');
			else
				led_wb_clk_divider <= std_logic_vector(unsigned(led_wb_clk_divider) + 1);
			end if;
		end if;
	end process;

	LED_WB_CLK <= not(led_wb_clk_divider(led_wb_clk_divider'high));
    
end behaviour;
