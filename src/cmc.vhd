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

		EFB_CYC_O	: out std_logic;
		EFB_STB_O	: out std_logic;
		EFB_WE_O	: out std_logic;
		EFB_ADR_O	: out std_logic_vector(15 downto 0);
		EFB_DAT_O	: out std_logic_vector(7 downto 0);
		EFB_DAT_I	: in std_logic_vector(7 downto 0);
		EFB_ACK_I	: in std_logic;

		ACCESS_ROM	: in std_logic;
		ACCESS_RAM	: in std_logic);
end cmc;

architecture behaviour of cmc is

    type bus_selection_t is (BS_REGISTER, BS_BOOT_ROM, BS_EFB);

	component prog_mem is
	port (
		Address		: in  std_logic_vector(11 downto 0); 
		OutClock	: in  std_logic; 
		OutClockEn	: in  std_logic; 
		Reset		: in  std_logic; 
		Q			: out  std_logic_vector(7 downto 0));
	end component;

	signal wb_cart_access : std_logic;
	signal outgoing_data : std_logic_vector(7 downto 0);

	signal boot_rom_enabled : std_logic;
	signal boot_rom_accessible : std_logic;
	signal boot_rom_data : std_logic_vector(7 downto 0);
	signal boot_rom_ack : std_logic;
	
	signal register_data : std_logic_vector(7 downto 0);
	signal register_ack : std_logic;
	signal bus_selector : bus_selection_t;

begin

	-- ROM instance containing boot code
    CARTRIDGE_BOOTROM : component prog_mem
	port map (
		Address => ADR_I(11 downto 0),
		OutClock => CLK_I,
		OutClockEn => boot_rom_enabled,
		Reset => RST_I,
		Q => boot_rom_data);
	
	wb_cart_access <= STB_I and CYC_I;
	boot_rom_enabled <= ACCESS_ROM and boot_rom_accessible;
		
	-- Address decoder
	process (CLK_I)
	begin
		if rising_edge(CLK_I) then
			register_ack <= '0';
			bus_selector <= BS_REGISTER;

			if RST_I = '1' then
				register_data <= x"00";
				boot_rom_accessible <= '1';
				boot_rom_ack <= '0';
			else
			    if wb_cart_access = '1' then
                    if ACCESS_ROM = '1' then
                    
                        -- Decode ROM addresses
                        case? ADR_I(14 downto 0) is     -- bit 15 = '0'
                            when b"000_----_----_----" =>
                                bus_selector <= BS_BOOT_ROM;
                            when others =>
                                register_data <= x"00";
                                register_ack <= '1';
                        end case?;
                    elsif ACCESS_RAM = '1' then
                    
                        -- Decode RAM addresses
                        case? ADR_I(12 downto 0) is     -- bits (15 downto 13) = "101"
                            when b"0_0000_----_----" =>
                                bus_selector <= BS_EFB;
                            when others =>
                                register_data <= x"00";
                                register_ack <= '1';
                        end case?;
                    end if;
                end if;
                
                boot_rom_ack <= register_ack;
			end if;
			
			
		end if;
	end process;
	
    -- EFB ports
    EFB_CYC_O <= CYC_I;
    EFB_WE_O <= WE_O;
    EFB_ADR_O <= ADR_I;
    EFB_DAT_O <= DAT_I;
	
	-- Bus selection
	process (bus_selector)
	begin
        case bus_selector is
            when BS_BOOT_ROM =>
                DAT_O <= boot_rom_data;
                ACK_O <= boot_rom_ack;
            when BS_EFB =>
                DAT_O <= EFB_DAT_I;
                ACK_O <= EFB_ACK_I;
                EFB_STB_O <= '1';
            when others =>
                DAT_O <= register_data;
                ACK_O <= register_ack;
                EFB_STB_O <= '0';
        end case;
	end process;
	
end behaviour;
