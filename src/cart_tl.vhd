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
        GB_CLK      : in std_logic;
        GB_ADDR     : in std_logic_vector(15 downto 0);
        GB_DATA     : inout std_logic_vector(7 downto 0);
		GB_WRN      : in std_logic;
        GB_RDN      : in std_logic;
		GB_CSN      : in std_logic;
		
		-- Temporary for testing
		USER_RST	: in std_logic);
end cart_tl;

architecture behaviour of cart_tl is

    component gb_decoder is
	port (
		USER_RST    : in std_logic;
		GB_CLK      : in std_logic;
		GB_ADDR     : in std_logic_vector(15 downto 0);
		GB_DATA_IN  : in std_logic_vector(7 downto 0);
		GB_DATA_OUT : out std_logic_vector(7 downto 0);
		GB_RDN      : in std_logic;
		GB_CSN      : in std_logic;
		
		CLK_I : in std_logic;
		STB_O : out std_logic;
		CYC_O : out std_logic;
		ADR_O : out std_logic_vector(15 downto 0);
		DAT_I : in std_logic_vector(7 downto 0);
		DAT_O : out std_logic_vector(7 downto 0);
		ACK_I : in std_logic);
    end component;
	
	component cmc is
	port (
		CLK_I 	: in std_logic;
		RST_I	: in std_logic;
		STB_I	: in std_logic;
		CYC_I	: in std_logic;
		ACK_O	: out std_logic;
		ADR_I	: in std_logic_vector(15 downto 0);
		DAT_I	: in std_logic_vector(7 downto 0);
		DAT_O	: out std_logic_vector(7 downto 0));
	end component;

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
	
	signal rom_stb : std_logic;
	signal rom_cyc : std_logic;
	signal rom_ack : std_logic;

begin

    GB_SIGNAL_DECODER : component gb_decoder
    port map (
        USER_RST => USER_RST,
        GB_CLK => GB_CLK,
        GB_ADDR => GB_ADDR,
        GB_DATA_IN => gb_data_incoming,
        GB_DATA_OUT => gb_data_outgoing,
		GB_RDN => GB_RDN,
		GB_CSN => GB_CSN,
		CLK_I => WB_CLK_I,
		STB_O => rom_stb,
		CYC_O => rom_cyc,
        ADR_O => wb_adr_o,
        DAT_I => wb_dat_i,
        DAT_O => wb_dat_o,
        ACK_I => rom_ack);
		
    GB_DATA <= gb_data_outgoing when (GB_CLK nor GB_RDN) = '1' else "ZZZZZZZZ";
    gb_data_incoming <= GB_DATA;
	
	CARTRIDGE_MEMORY_CONTROLLER : component cmc
	port map (
		CLK_I => WB_CLK_I,
		RST_I => USER_RST,
		STB_I => rom_stb,
		CYC_I => rom_cyc,
		ACK_O => rom_ack,
		ADR_I => wb_adr_o,
		DAT_I => wb_dat_o,
		DAT_O => wb_dat_i);

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
    
end behaviour;
