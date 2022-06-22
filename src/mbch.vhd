----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 06/22/2022 14:49:42 PM
-- Design Name: Memory Bank Controller Hypervisor
-- Module Name: mbch - behaviour
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Documentation
--
-- MBCH (Memory Bank Controller Hypervisor) is the base MBC used by the system.
-- It has access to the entire system, including DRAM, SPI and Flash. It also provides
-- access to the boot ROM, which initialised the system using this hypervisor level
-- access.
--
-- It also uses the SELECT_MBC to override itself and switch to a different MBC
-- implementation. After switching to a different MBC, it is only possible to
-- switch back after a reset.
--
-- Selection values are:
--     "000" => MBCH
--     "001" => MBC1 (NYI)
--     "010" => MBC3 (NYI)
--     "011" => MBC5 (NYI)
--     "100" => No MBC (NYI)
--     others => Undefined
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;

entity mbch is
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

		ACCESS_ROM		: in std_logic;
		ACCESS_RAM		: in std_logic;
		SELECT_MBC  	: out std_logic_vector(2 downto 0);
		SOFT_RESET_OUT  : out std_logic;
		SOFT_RESET_IN   : in std_logic);
end mbch;

architecture behaviour of mbch is

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
	signal reg_selected_mbc : std_logic_vector(2 downto 0);
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
	boot_rom_enabled <= boot_rom_accessible and wb_cart_access;
		
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
				reg_selected_mbc <= "000";
				SELECT_MBC <= "000";
			else
			    if wb_cart_access = '1' then
                    if ACCESS_ROM = '1' then
                    
                        -- Decode ROM addresses
                        case? ADR_I(14 downto 0) is     -- bit 15 = '0'
                            when b"000_----_----_----" =>
                                if boot_rom_accessible = '1' then
                                    bus_selector <= BS_BOOT_ROM;
                                else
                                    register_data <= x"00";
                                    register_ack <= '1';
                                end if; 
                            when others =>
                                register_data <= x"00";
                                register_ack <= '1';
                        end case?;
                    elsif ACCESS_RAM = '1' then
                    
                        -- Decode RAM addresses
                        case? ADR_I(12 downto 0) is     -- bits (15 downto 13) = "101"
                            when b"0_0000_----_----" =>
                                bus_selector <= BS_EFB;
                            when b"0_0001_----_----" =>
                                if WE_O = '1' then
                                    boot_rom_accessible <= DAT_I(7) when boot_rom_accessible = '1' else '0';
									SOFT_RESET_OUT <= DAT_I(6);
                                    reg_selected_mbc <= DAT_I(2 downto 0);
                                else
                                    register_data <= boot_rom_accessible & "0000" & reg_selected_mbc;
                                end if;
                                register_ack <= '1';
                            when others =>
                                register_data <= x"00";
                                register_ack <= '1';
                        end case?;
                    end if;
                end if;

				-- Perform soft reset
				if SOFT_RESET_IN = '1' then
					boot_rom_accessible <= '1';
					reg_selected_mbc <= "000";

					SELECT_MBC <= reg_selected_mbc;
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
