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
		WE_O  	: in std_logic;
		ACK_O	: out std_logic;
		ADR_I	: in std_logic_vector(15 downto 0);
		DAT_I	: in std_logic_vector(7 downto 0);
		DAT_O	: out std_logic_vector(7 downto 0);
		
		ACCESS_ROM	: in std_logic;
		ACCESS_RAM	: in std_logic);
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

	signal wb_cart_access : std_logic;
	signal wb_ack : std_logic;
	signal outgoing_data : std_logic_vector(7 downto 0);

	signal boot_rom_within_range : std_logic;
	signal boot_rom_selected : std_logic;
	signal boot_rom_data : std_logic_vector(7 downto 0);

begin

	-- ROM instance containing boot code
    CARTRIDGE_BOOTROM : component prog_mem
	port map (
		Address => ADR_I(11 downto 0),
		OutClock => CLK_I,
		OutClockEn => '1',
		Reset => RST_I,
		Q => boot_rom_data);
	
	-- Signal whether bootrom is selected
	boot_rom_within_range <= nor_reduce(ADR_I(15 downto 12));
	boot_rom_selected <= wb_cart_access and boot_rom_within_range;
	
	wb_cart_access <= STB_I and CYC_I;
		
	-- Address decoder
	process (CLK_I)
	begin
		if rising_edge(CLK_I) then
			wb_ack <= '0';

			if RST_I = '1' then
				outgoing_data <= x"00";
			else
				if wb_cart_access = '1' then
					if ACCESS_ROM = '1' then
						wb_ack <= '1';
						outgoing_data <= x"00";
					else	-- ACCESS_RAM = '1'
						wb_ack <= '1';

						-- If accessing RAM, then ADR_I should be "101-_----_----_----"
						case ADR_I(12 downto 8) is
							when b"0_0000" => outgoing_data <= x"FF";
							when others => outgoing_data <= x"00";
						end case;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	ACK_O <= wb_ack and wb_cart_access;
	DAT_O <= boot_rom_data when boot_rom_selected = '1' else outgoing_data;
    
end behaviour;
