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
        CLK_I   : in std_logic;
        RST_I   : in std_logic;
        STB_I   : in std_logic;
        CYC_I   : in std_logic;
        WE_I    : in std_logic;
        ACK_O   : out std_logic;
        ADR_I   : in std_logic_vector(15 downto 0);
        DAT_I   : in std_logic_vector(7 downto 0);
        DAT_O   : out std_logic_vector(7 downto 0);

        EFB_STB_O   : out std_logic;
        EFB_DAT_I   : in std_logic_vector(7 downto 0);
        EFB_ACK_I   : in std_logic;

        DRAM_STB_O  : out std_logic;
        DRAM_ADR_O  : out std_logic_vector(8 downto 0);
        DRAM_TGA_O  : out std_logic_vector(1 downto 0);
        DRAM_DAT_I  : in std_logic_vector(7 downto 0);
        DRAM_ACK_I  : in std_logic;
        DRAM_ERR_I  : in std_logic;

        GPIO_IN     : in std_logic_vector(3 downto 0);
        GPIO_OUT    : out std_logic_vector(3 downto 0);

        SELECT_MBC      : out std_logic_vector(2 downto 0);
        SOFT_RESET_OUT  : out std_logic;
        SOFT_RESET_IN   : in std_logic;
        DRAM_READY      : in std_logic;
        DBG_ACTIVE      : in std_logic);
end mbch;

architecture behaviour of mbch is

    type bus_selection_t is (BS_REGISTER, BS_BOOT_ROM, BS_EFB, BS_DRAM);

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

    signal wb_cart_access   : std_logic;
    signal wb_ack           : std_logic;

    signal boot_rom_enabled         : std_logic;
    signal boot_rom_accessible      : std_logic;
    signal boot_rom_accessible_reg  : std_logic;
    signal boot_rom_data            : std_logic_vector(7 downto 0);
    signal boot_rom_we              : std_logic;

    signal dram_bank_mbc            : std_logic_vector(8 downto 0);     -- MBC bank selector register
    signal dram_bank                : std_logic_vector(1 downto 0);     -- DRAM bank selector register
    signal dram_bank_select_zero    : std_logic;                        -- Set if MBC & DRAM banks 0 is selected (zero bank)
    signal dram_bank_passthrough    : std_logic;                        -- Set if selector registers should be used to select bank, otherwise will force bank 1 
    signal dram_bank_force_zero     : std_logic;                        -- Set to force zero bank to be selected

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
        Q => boot_rom_data);
    
    wb_cart_access <= STB_I and CYC_I;
    boot_rom_enabled <= boot_rom_accessible and wb_cart_access;
    boot_rom_we <= WE_I and DBG_ACTIVE;
        
    -- GPIO input synchroniser
    GPIO_IN_SYNCHRONISER : component synchroniser
    port map (
        CLK => CLK_I,
        RST => RST_I,
        DAT_IN => GPIO_IN,
        DAT_OUT => gpio_in_sync);

    GPIO_OUT <= gpio_out_reg;

    -- Address decoder
    process (CLK_I)
    begin
        if rising_edge(CLK_I) then
            register_ack <= '0';
            bus_selector <= BS_REGISTER;
            dram_bank_force_zero <= '0';
            SOFT_RESET_OUT <= '0';

            if RST_I = '1' then
                register_data <= x"00";
                boot_rom_accessible_reg <= '1';
                boot_rom_accessible <= '1';
                dram_bank_mbc <= (others => '0');
                dram_bank <= (others => '0');
                reg_selected_mbc <= "000";
                soft_reset_rising <= '1';
                gpio_out_reg <= (others => '0');

                SELECT_MBC <= "000";
            else
                if (wb_cart_access and not(wb_ack)) = '1' then
                    case? ADR_I is
                        -- Boot ROM or lower 4kB of bank 0
                        when b"0000_----_----_----" =>
                            if boot_rom_accessible = '1' then
                                bus_selector <= BS_BOOT_ROM;
                                register_ack <= '1';
                            else
                                bus_selector <= BS_DRAM;
                                dram_bank_force_zero <= '1';
                            end if;

                        -- Upper 12kB of back 0
                        when b"0001_----_----_----" | b"0010_----_----_----" | b"0011_----_----_----" =>
                            bus_selector <= BS_DRAM;
                            dram_bank_force_zero <= '1';

                        -- Banked DRAM
                        when b"01--_----_----_----" =>
                            bus_selector <= BS_DRAM;

                        -- EFB access
                        when b"1010_0000_----_----" =>
                            bus_selector <= BS_EFB;

                        -- MBCH Control 0 reg
                        when b"1010_0001_----_----" =>
                            if WE_I = '1' then
                                SOFT_RESET_OUT <= DAT_I(7);
                                boot_rom_accessible_reg <= DAT_I(6);
                                reg_selected_mbc <= DAT_I(2 downto 0);
                            else
                                register_data <= "0" & boot_rom_accessible_reg & boot_rom_accessible & DRAM_READY & "0" & reg_selected_mbc;
                            end if;
                            register_ack <= '1';

                        -- MBCH DRAM bank sel 0 reg
                        when b"1010_0010_----_----" =>
                            if WE_I = '1' then
                                dram_bank_mbc(7 downto 0) <= DAT_I;
                            else
                                register_data <= dram_bank_mbc(7 downto 0);
                            end if;
                            register_ack <= '1';

                        -- MBCH DRAM bank sel 1 reg
                        when b"1010_0011_----_----" =>
                            if WE_I = '1' then
                                dram_bank_mbc(8) <= DAT_I(0);
                                dram_bank <= DAT_I(2 downto 1);
                            else
                                register_data <= "00000" & dram_bank & dram_bank_mbc(8);
                            end if;
                            register_ack <= '1';

                        -- MBCH GPIO reg
                        when b"1010_0100_----_----" =>
                            if WE_I = '1' then
                                gpio_out_reg <= DAT_I(7 downto 4);
                            else
                                register_data <= gpio_out_reg & gpio_in_sync;
                            end if;
                            register_ack <= '1';

                        -- Reserved for DMA registers
                        when b"1010_0101_----_----" =>
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
    
    -- DRAM bank selection
    dram_bank_select_zero <= nor_reduce(dram_bank) nor nor_reduce(dram_bank_mbc);
    dram_bank_passthrough <= (dram_bank_select_zero nor boot_rom_accessible) or boot_rom_accessible;

    -- DRAM ports
    with dram_bank_passthrough & dram_bank_force_zero select DRAM_ADR_O <=
        (0 => '1', others => '0')   when "00",
        dram_bank_mbc               when "10",
        (others => '0')             when others;

    with dram_bank_force_zero select DRAM_TGA_O <=
        dram_bank                   when '0',
        (others => '0')             when others;

    -- Bus selection data
    with bus_selector select DAT_O <=
        boot_rom_data   when BS_BOOT_ROM,
        EFB_DAT_I       when BS_EFB,
        DRAM_DAT_I      when BS_DRAM,
        register_data   when others;

    -- Bus selection ack
    ACK_O <= wb_ack;
    with bus_selector select wb_ack <=
        EFB_ACK_I       when BS_EFB,
        DRAM_ACK_I      when BS_DRAM,
        register_ack    when others;

    -- Bus selection strobe
    EFB_STB_O <= '1' when bus_selector = BS_EFB else '0';
    DRAM_STB_O <= '1' when bus_selector = BS_DRAM else '0';
    
end behaviour;
