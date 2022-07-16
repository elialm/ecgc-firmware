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
		WE_I  	: in std_logic;
		ACK_O	: out std_logic;
		ADR_I	: in std_logic_vector(15 downto 0);
		DAT_I	: in std_logic_vector(7 downto 0);
		DAT_O	: out std_logic_vector(7 downto 0);

		EFB_CYC_O	: out std_logic;
		EFB_STB_O	: out std_logic;
		EFB_WE_O	: out std_logic;
		EFB_ADR_O	: out std_logic_vector(7 downto 0);
		EFB_DAT_O	: out std_logic_vector(7 downto 0);
		EFB_DAT_I	: in std_logic_vector(7 downto 0);
		EFB_ACK_I	: in std_logic;

		DRAM_CYC_O	: out std_logic;
		DRAM_STB_O	: out std_logic;
		DRAM_WE_O	: out std_logic;
		DRAM_ADR_O	: out std_logic_vector(22 downto 0);
		DRAM_TGA_O	: out std_logic_vector(1 downto 0);
		DRAM_DAT_O	: out std_logic_vector(7 downto 0);
		DRAM_DAT_I	: in std_logic_vector(7 downto 0);
		DRAM_ACK_I	: in std_logic;
		DRAM_ERR_I	: in std_logic;

		ACCESS_ROM		: in std_logic;
		ACCESS_RAM		: in std_logic;
		SELECT_MBC  	: out std_logic_vector(2 downto 0);
		SOFT_RESET_OUT  : out std_logic;
		SOFT_RESET_IN   : in std_logic;
		DRAM_READY		: in std_logic);
end mbch;

architecture behaviour of mbch is

    type bus_selection_t is (BS_REGISTER, BS_BOOT_ROM, BS_EFB, BS_DRAM);

	component boot_rom is
	port (
		Address		: in  std_logic_vector(11 downto 0); 
		OutClock	: in  std_logic; 
		OutClockEn	: in  std_logic; 
		Reset		: in  std_logic; 
		Q			: out  std_logic_vector(7 downto 0));
	end component;

	signal wb_cart_access : std_logic;
	signal wb_ack : std_logic;

	signal boot_rom_enabled : std_logic;
	signal boot_rom_accessible : std_logic;
	signal boot_rom_data : std_logic_vector(7 downto 0);
	
	signal register_data : std_logic_vector(7 downto 0);
	signal register_ack : std_logic;
	signal reg_selected_mbc : std_logic_vector(2 downto 0);
	signal bus_selector : bus_selection_t;

begin

	-- ROM instance containing boot code
    CARTRIDGE_BOOTROM : component boot_rom
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
				reg_selected_mbc <= "000";
				SELECT_MBC <= "000";
				SOFT_RESET_OUT <= '0';
			else
			    if (wb_cart_access and not(wb_ack)) = '1' then
                    if ACCESS_ROM = '1' then
                        -- Decode ROM addresses
                        case? ADR_I(14 downto 0) is     -- bit 15 = '0'
                            when b"000_----_----_----" =>
                                if boot_rom_accessible = '1' then
                                    bus_selector <= BS_BOOT_ROM;
                                end if; 
							when b"1--_----_----_----" =>
								bus_selector <= BS_DRAM;
                            when others =>
                                null;
                        end case?;

						register_ack <= '1';
						register_data <= x"00";
                    elsif ACCESS_RAM = '1' then
                    
                        -- Decode RAM addresses
                        case? ADR_I(12 downto 0) is     -- bits (15 downto 13) = "101"
                            when b"0_0000_----_----" =>
                                bus_selector <= BS_EFB;
                            when b"0_0001_----_----" =>
                                if WE_I = '1' then
                                    boot_rom_accessible <= DAT_I(7) when boot_rom_accessible = '1' else '0';
									SOFT_RESET_OUT <= DAT_I(6);
                                    reg_selected_mbc <= DAT_I(2 downto 0);
                                else
                                    register_data <= boot_rom_accessible & DRAM_READY & "000" & reg_selected_mbc;
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
			end if;
		end if;
	end process;
	
    -- EFB ports
    EFB_CYC_O <= CYC_I;
    EFB_WE_O <= WE_I;
    EFB_ADR_O <= ADR_I(7 downto 0);
    EFB_DAT_O <= DAT_I;

	-- DRAM ports
	DRAM_CYC_O <= CYC_I;
	DRAM_WE_O <= WE_I;
	DRAM_ADR_O <= "000000000" & ADR_I(13 downto 0);
	DRAM_TGA_O <= "00";
	DRAM_DAT_O <= DAT_I;

	-- Bus selection data
	with bus_selector select DAT_O <=
		boot_rom_data 	when BS_BOOT_ROM,
		EFB_DAT_I 		when BS_EFB,
		DRAM_DAT_I		when BS_DRAM,
		register_data 	when others;

	-- Bus selection ack
	ACK_O <= wb_ack;
	with bus_selector select wb_ack <=
		EFB_ACK_I 		when BS_EFB,
		DRAM_ACK_I		when BS_DRAM,
		register_ack 	when others;

	-- Bus selection strobe
	EFB_STB_O <= '1' when bus_selector = BS_EFB else '0';
	DRAM_STB_O <= '1' when bus_selector = BS_DRAM else '0';
	
end behaviour;
