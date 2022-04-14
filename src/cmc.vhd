----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/31/2022 04:10:42 PM
-- Design Name: 
-- Module Name: gb_decoder - behaviour
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


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;

entity cmc is
    port (
        CLK_I 	: in std_logic;
		RST_I	: in std_logic;
		STB_I	: in std_logic;
		CYC_I	: in std_logic;
		ACK_O	: out std_logic;
		ADR_I	: in std_logic_vector(15 downto 0);
		DAT_I	: in std_logic_vector(7 downto 0);
		DAT_O	: out std_logic_vector(7 downto 0));
end cmc;

architecture behaviour of cmc is

	component prog_mem is
		port (
			Address		: in  std_logic_vector(11 downto 0); 
			OutClock	: in  std_logic; 
			OutClockEn	: in  std_logic; 
			Reset		: in  std_logic; 
			Q			: out  std_logic_vector(7 downto 0));
	end component;

	signal outgoing_data : std_logic_vector(7 downto 0);

	signal rom_within_range : std_logic;
	signal rom_selected : std_logic;
	signal rom_data : std_logic_vector(7 downto 0);
	signal stb_delay : std_logic;
	signal ack_o_signal : std_logic;

begin

    CARTRIDGE_BOOTROM : component prog_mem
	port map (
		Address => ADR_I(11 downto 0),
		OutClock => CLK_I,
		OutClockEn => '1',
		Reset => RST_I,
		Q => DAT_O);
	
	--rom_within_range <= and_reduce((ADR_I(15 downto 12) nor "0000"));
	rom_within_range <= not(ADR_I(15) or ADR_I(14) or ADR_I(13) or ADR_I(12));
	rom_selected <= STB_I and CYC_I and rom_within_range;
	--DAT_O <= outgoing_data when stb_delay = '1' else "00000000";
		
	process (CLK_I)
	begin
		if rising_edge(CLK_I) then
			if RST_I = '1' then
				stb_delay <= '0';
			else
				stb_delay <= rom_selected;
			end if;
		end if;
	end process;
	
	ack_o_signal <= stb_delay and rom_selected;
	ACK_O <= ack_o_signal;
    
end behaviour;
