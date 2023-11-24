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
-- The MBCH is also used to access the MBCH control registers. These include functions
-- such as DRAM banking and soft reset control. The control registers are further
-- documented in /doc/register.md. 
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
        -- Main slave interface
        CLK_I   : in std_logic;
        RST_I   : in std_logic;
        CYC_I   : in std_logic;
        WE_I    : in std_logic;
        ACK_O   : out std_logic;
        ADR_I   : in std_logic_vector(15 downto 0);
        DAT_I   : in std_logic_vector(7 downto 0);
        DAT_O   : out std_logic_vector(7 downto 0);

        -- Master interface to external RAM controller
        XRAM_ADR_O  : out std_logic_vector(21 downto 0);
        XRAM_DAT_I  : in std_logic_vector(7 downto 0);
        XRAM_ACK_I  : in std_logic;
        XRAM_CYC_O  : out std_logic;

        GPIO_IN     : in std_logic_vector(3 downto 0);
        GPIO_OUT    : out std_logic_vector(3 downto 0);

        SELECT_MBC      : out std_logic_vector(2 downto 0);
        SOFT_RESET_REQ  : out std_logic;
        SOFT_RESET_IN   : in std_logic;
        DBG_ACTIVE      : in std_logic
    );
end mbch;

architecture behaviour of mbch is

    type bus_selection_t is (BS_REGISTER, BS_BOOT_ROM, BS_CART_RAM, BS_XRAM);

    component boot_ram is
    port (
        Clock       : in std_logic; 
        ClockEn     : in std_logic; 
        Reset       : in std_logic; 
        WE          : in std_logic;
        Address     : in std_logic_vector(11 downto 0); 
        Data        : in std_logic_vector(7 downto 0); 
        Q           : out std_logic_vector(7 downto 0));
    end component;

    -- component cart_ram
    -- port (
    --     Clock       : in std_logic;
    --     ClockEn     : in std_logic; 
    --     Reset       : in std_logic;
    --     WE          : in std_logic; 
    --     Address     : in std_logic_vector(9 downto 0); 
    --     Data        : in std_logic_vector(7 downto 0); 
    --     Q           : out std_logic_vector(7 downto 0));
    -- end component;

    component synchroniser is
    generic (
        FF_COUNT : natural := 2;
        DATA_WIDTH : natural := 4;
        RESET_VALUE : std_logic := '0');
    port (
        CLK : in std_logic;
        RST : in std_logic;
        DAT_IN : in std_logic_vector(DATA_WIDTH-1 downto 0);
        DAT_OUT : out std_logic_vector(DATA_WIDTH-1 downto 0));
    end component;

    signal wb_ack           : std_logic;

    signal boot_rom_enabled         : std_logic;
    signal boot_rom_accessible      : std_logic;
    signal boot_rom_accessible_reg  : std_logic;
    signal boot_rom_data            : std_logic_vector(7 downto 0);
    signal boot_rom_we              : std_logic;
    signal cart_ram_data            : std_logic_vector(7 downto 0);

    signal xram_bank_mbc            : std_logic_vector(6 downto 0);     -- MBC bank selector register
    signal xram_bank                : std_logic_vector(0 downto 0);     -- XRAM bank selector register
    signal xram_bank_select_zero    : std_logic;                        -- Set if MBC & DRAM banks 0 is selected (zero bank)
    signal xram_bank_passthrough    : std_logic;                        -- Set if selector registers should be used to select bank, otherwise will force bank 1 
    signal xram_bank_force_zero     : std_logic;                        -- Set to force zero bank to be selected

    signal gpio_out_reg         : std_logic_vector(3 downto 0);
    signal gpio_in_sync         : std_logic_vector(3 downto 0);
    
    signal register_data        : std_logic_vector(7 downto 0);
    signal register_ack         : std_logic;
    signal reg_selected_mbc     : std_logic_vector(2 downto 0);
    signal bus_selector         : bus_selection_t;
    signal soft_reset_rising    : std_logic;

begin

    -- ROM instance containing boot code
    CARTRIDGE_BOOTROM : component boot_ram
    port map (
        Clock => CLK_I,
        ClockEn => boot_rom_enabled,
        Reset => RST_I,
        WE => boot_rom_we,
        Address => ADR_I(11 downto 0),
        Data => DAT_I,
        Q => boot_rom_data
    );
    
    boot_rom_enabled <= boot_rom_accessible and CYC_I;
    boot_rom_we <= WE_I and DBG_ACTIVE;

    -- -- Cart RAM instance, for DMA buffering and reset management
    -- CARTRIDGE_RAM : component cart_ram
    -- port map (
    --     Clock => CLK_I,
    --     ClockEn => CYC_I,
    --     Reset => RST_I,
    --     WE => WE_I,
    --     Address => ADR_I(9 downto 0),
    --     Data => DAT_I,
    --     Q => cart_ram_data
    -- );
        
    -- GPIO input synchroniser
    GPIO_IN_SYNCHRONISER : component synchroniser
    port map (
        CLK => CLK_I,
        RST => RST_I,
        DAT_IN => GPIO_IN,
        DAT_OUT => gpio_in_sync
    );

    GPIO_OUT <= gpio_out_reg;

    -- Address decoder
    process (CLK_I)
    begin
        if rising_edge(CLK_I) then
            register_ack <= '0';
            bus_selector <= BS_REGISTER;
            xram_bank_force_zero <= '0';
            SOFT_RESET_REQ <= '0';

            if RST_I = '1' then
                register_data <= x"00";
                boot_rom_accessible_reg <= '1';
                boot_rom_accessible <= '1';
                xram_bank_mbc <= (others => '0');
                xram_bank <= (others => '0');
                reg_selected_mbc <= "000";
                soft_reset_rising <= '1';
                gpio_out_reg <= (others => '0');

                SELECT_MBC <= "000";
            else
                if (CYC_I and not(wb_ack)) = '1' then
                    case? ADR_I is
                        -- Boot ROM or lower 4kB of bank 0
                        when b"0000_----_----_----" =>
                            if boot_rom_accessible = '1' then
                                bus_selector <= BS_BOOT_ROM;
                                register_ack <= '1';
                            else
                                bus_selector <= BS_XRAM;
                                xram_bank_force_zero <= '1';
                            end if;

                        -- Upper 12kB of back 0
                        when b"0001_----_----_----" | b"0010_----_----_----" | b"0011_----_----_----" =>
                            bus_selector <= BS_XRAM;
                            xram_bank_force_zero <= '1';

                        -- Banked DRAM
                        when b"01--_----_----_----" =>
                            bus_selector <= BS_XRAM;

                        -- Reserved (previously EFB)
                        when b"1010_0000_----_----" =>
                            register_data <= x"00";
                            register_ack <= '1';

                        -- MBCH Control 0 reg
                        when b"1010_0001_----_----" =>
                            if WE_I = '1' then
                                SOFT_RESET_REQ <= DAT_I(7);
                                boot_rom_accessible_reg <= DAT_I(6);
                                reg_selected_mbc <= DAT_I(2 downto 0);
                            else
                                register_data <= "0" & boot_rom_accessible_reg & boot_rom_accessible & "00" & reg_selected_mbc;
                            end if;
                            register_ack <= '1';

                        -- MBCH DRAM bank selection reg
                        when b"1010_0010_----_----" =>
                            if WE_I = '1' then
                                xram_bank_mbc <= DAT_I(6 downto 0);
                                xram_bank(0) <= DAT_I(7);
                            else
                                register_data <= xram_bank & xram_bank_mbc;
                            end if;
                            register_ack <= '1';

                        -- Reserved (previously MBCH DRAM bank sel 1 reg)
                        when b"1010_0011_----_----" =>
                            register_data <= x"00";
                            register_ack <= '1';

                        -- MBCH GPIO reg
                        when b"1010_0100_----_----" =>
                            if WE_I = '1' then
                                gpio_out_reg <= DAT_I(7 downto 4);
                            else
                                register_data <= gpio_out_reg & gpio_in_sync;
                            end if;
                            register_ack <= '1';

                        -- Reserved (mapped to DMA registers)
                        when b"1010_0101_----_----" =>
                            register_data <= x"00";
                            register_ack <= '1';

                        -- Cart RAM
                        when b"1011_00--_----_----" =>
                            -- Currently not in use
                            -- bus_selector <= BS_CART_RAM;
                            register_data <= x"00";
                            register_ack <= '1';

                        -- Other regions will always read as 0x00 and ignore writes
                        when others =>
                            register_data <= x"00";
                            register_ack <= '1';
                    end case?;
                end if;

                -- Perform soft reset
                if (SOFT_RESET_IN and soft_reset_rising) = '1' then
                    boot_rom_accessible_reg <= '1';
                    boot_rom_accessible <= boot_rom_accessible_reg;
                    reg_selected_mbc <= "000";
                    soft_reset_rising <= '0';

                    SELECT_MBC <= reg_selected_mbc;
                elsif SOFT_RESET_IN = '0' then
                    soft_reset_rising <= '1';
                end if;
            end if;
        end if;
    end process;
    
    -- XRAM bank selection
    xram_bank_select_zero <= nor_reduce(xram_bank) nor nor_reduce(xram_bank_mbc);
    xram_bank_passthrough <= (xram_bank_select_zero nor boot_rom_accessible) or boot_rom_accessible;

    -- XRAM ports
    -- TODO: look at this again, I don't have the head for it now
    XRAM_ADR_O(13 downto 0) <= ADR_I(13 downto 0);
    with xram_bank_passthrough & xram_bank_force_zero select XRAM_ADR_O(21 downto 14) <=
        (14 => '1', others => '0')  when "00",
        xram_bank_mbc & xram_bank   when "10",
        (others => '0')             when others;

    -- Bus selection data
    with bus_selector select DAT_O <=
        boot_rom_data   when BS_BOOT_ROM,
        -- cart_ram_data   when BS_CART_RAM,
        XRAM_DAT_I      when BS_XRAM,
        register_data   when others;

    -- Bus selection ack
    ACK_O <= wb_ack;
    with bus_selector select wb_ack <=
        XRAM_ACK_I      when BS_XRAM,
        register_ack    when others;

    -- Bus selection CYC_O
    XRAM_CYC_O <= CYC_I when bus_selector = BS_XRAM else '0';
    
end behaviour;
