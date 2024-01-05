----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 06/22/2022 14:49:42 PM
-- Design Name: Memory Bank Controller Hypervisor
-- Module Name: mbch - rtl
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
-- It also uses the o_select_mbc to override itself and switch to a different MBC
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
        i_clk   : in std_logic;
        i_rst   : in std_logic;
        i_cyc   : in std_logic;
        i_we    : in std_logic;
        o_ack   : out std_logic;
        i_adr   : in std_logic_vector(15 downto 0);
        i_dat   : in std_logic_vector(7 downto 0);
        o_dat   : out std_logic_vector(7 downto 0);

        -- Master interface to external RAM controller
        o_xram_adr  : out std_logic_vector(21 downto 0);
        i_xram_dat  : in std_logic_vector(7 downto 0);
        i_xram_ack  : in std_logic;
        o_xram_cyc  : out std_logic;

        i_gpio     : in std_logic_vector(3 downto 0);
        o_gpio    : out std_logic_vector(3 downto 0);

        o_select_mbc      : out std_logic_vector(2 downto 0);
        o_soft_reset_req  : out std_logic;
        i_soft_reset   : in std_logic;
        i_dbg_active      : in std_logic
    );
end mbch;

architecture rtl of mbch is

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
        p_ff_count : natural := 2;
        p_data_width : natural := 4;
        p_reset_value : std_logic := '0'
    );
    port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_din : in std_logic_vector(p_data_width-1 downto 0);
        o_dout : out std_logic_vector(p_data_width-1 downto 0)
    );
    end component;

    signal n_wb_ack : std_logic;

    signal n_boot_rom_enabled         : std_logic;
    signal r_boot_rom_accessible      : std_logic;
    signal r_boot_rom_accessible_reg  : std_logic;
    signal n_boot_rom_data            : std_logic_vector(7 downto 0);
    signal n_boot_rom_we              : std_logic;
    signal n_cart_ram_data            : std_logic_vector(7 downto 0);

    signal r_xram_bank_mbc            : std_logic_vector(6 downto 0);     -- MBC bank selector register
    signal r_xram_bank                : std_logic_vector(0 downto 0);     -- XRAM bank selector register
    signal n_xram_bank_select_zero    : std_logic;                        -- Set if MBC & DRAM banks 0 is selected (zero bank)
    signal n_xram_bank_passthrough    : std_logic;                        -- Set if selector registers should be used to select bank, otherwise will force bank 1 
    signal r_xram_bank_force_zero     : std_logic;                        -- Set to force zero bank to be selected

    signal r_gpio_out         : std_logic_vector(3 downto 0);
    signal n_gpio_in_sync         : std_logic_vector(3 downto 0);
    
    signal r_register_data        : std_logic_vector(7 downto 0);
    signal r_register_ack         : std_logic;
    signal r_reg_selected_mbc     : std_logic_vector(2 downto 0);
    signal r_bus_selector         : bus_selection_t;
    signal r_soft_reset_rising    : std_logic;

begin

    -- ROM instance containing boot code
    CARTRIDGE_BOOTROM : component boot_ram
    port map (
        Clock => i_clk,
        ClockEn => n_boot_rom_enabled,
        Reset => i_rst,
        WE => n_boot_rom_we,
        Address => i_adr(11 downto 0),
        Data => i_dat,
        Q => n_boot_rom_data
    );
    
    n_boot_rom_enabled <= r_boot_rom_accessible and i_cyc;
    n_boot_rom_we <= i_we and i_dbg_active;

    -- -- Cart RAM instance, for DMA buffering and reset management
    -- CARTRIDGE_RAM : component cart_ram
    -- port map (
    --     Clock => i_clk,
    --     ClockEn => i_cyc,
    --     Reset => i_rst,
    --     WE => i_we,
    --     Address => i_adr(9 downto 0),
    --     Data => i_dat,
    --     Q => n_cart_ram_data
    -- );
        
    -- GPIO input synchroniser
    inst_gpio_synchroniser : component synchroniser
    port map (
        i_clk => i_clk,
        i_rst => i_rst,
        i_din => i_gpio,
        o_dout => n_gpio_in_sync
    );

    o_gpio <= r_gpio_out;

    -- i_address decoder
    process (i_clk)
    begin
        if rising_edge(i_clk) then
            r_register_ack <= '0';
            r_bus_selector <= BS_REGISTER;
            r_xram_bank_force_zero <= '0';
            o_soft_reset_req <= '0';

            if i_rst = '1' then
                r_register_data <= x"00";
                r_boot_rom_accessible_reg <= '1';
                r_boot_rom_accessible <= '1';
                r_xram_bank_mbc <= (others => '0');
                r_xram_bank <= (others => '0');
                r_reg_selected_mbc <= "000";
                r_soft_reset_rising <= '1';
                r_gpio_out <= (others => '0');

                o_select_mbc <= "000";
            else
                if (i_cyc and not(n_wb_ack)) = '1' then
                    case? i_adr is
                        -- Boot ROM or lower 4kB of bank 0
                        when b"0000_----_----_----" =>
                            if r_boot_rom_accessible = '1' then
                                r_bus_selector <= BS_BOOT_ROM;
                                r_register_ack <= '1';
                            else
                                r_bus_selector <= BS_XRAM;
                                r_xram_bank_force_zero <= '1';
                            end if;

                        -- Upper 12kB of back 0
                        when b"0001_----_----_----" | b"0010_----_----_----" | b"0011_----_----_----" =>
                            r_bus_selector <= BS_XRAM;
                            r_xram_bank_force_zero <= '1';

                        -- Banked DRAM
                        when b"01--_----_----_----" =>
                            r_bus_selector <= BS_XRAM;

                        -- Reserved (previously EFB)
                        when b"1010_0000_----_----" =>
                            r_register_data <= x"00";
                            r_register_ack <= '1';

                        -- MBCH Control 0 reg
                        when b"1010_0001_----_----" =>
                            if i_we = '1' then
                                o_soft_reset_req <= i_dat(7);
                                r_boot_rom_accessible_reg <= i_dat(6);
                                r_reg_selected_mbc <= i_dat(2 downto 0);
                            else
                                r_register_data <= "0" & r_boot_rom_accessible_reg & r_boot_rom_accessible & "00" & r_reg_selected_mbc;
                            end if;
                            r_register_ack <= '1';

                        -- MBCH DRAM bank selection reg
                        when b"1010_0010_----_----" =>
                            if i_we = '1' then
                                r_xram_bank_mbc <= i_dat(6 downto 0);
                                r_xram_bank(0) <= i_dat(7);
                            else
                                r_register_data <= r_xram_bank & r_xram_bank_mbc;
                            end if;
                            r_register_ack <= '1';

                        -- Reserved (previously MBCH DRAM bank sel 1 reg)
                        when b"1010_0011_----_----" =>
                            r_register_data <= x"00";
                            r_register_ack <= '1';

                        -- MBCH GPIO reg
                        when b"1010_0100_----_----" =>
                            if i_we = '1' then
                                r_gpio_out <= i_dat(7 downto 4);
                            else
                                r_register_data <= r_gpio_out & n_gpio_in_sync;
                            end if;
                            r_register_ack <= '1';

                        -- Reserved (mapped to DMA registers)
                        when b"1010_0101_----_----" =>
                            r_register_data <= x"00";
                            r_register_ack <= '1';

                        -- Cart RAM
                        when b"1011_00--_----_----" =>
                            -- Currently not in use
                            -- r_bus_selector <= BS_CART_RAM;
                            r_register_data <= x"00";
                            r_register_ack <= '1';

                        -- Other regions will always read as 0x00 and ignore writes
                        when others =>
                            r_register_data <= x"00";
                            r_register_ack <= '1';
                    end case?;
                end if;

                -- Perform soft reset
                if (i_soft_reset and r_soft_reset_rising) = '1' then
                    r_boot_rom_accessible_reg <= '1';
                    r_boot_rom_accessible <= r_boot_rom_accessible_reg;
                    r_reg_selected_mbc <= "000";
                    r_soft_reset_rising <= '0';

                    o_select_mbc <= r_reg_selected_mbc;
                elsif i_soft_reset = '0' then
                    r_soft_reset_rising <= '1';
                end if;
            end if;
        end if;
    end process;
    
    -- XRAM bank selection
    n_xram_bank_select_zero <= nor_reduce(r_xram_bank) nor nor_reduce(r_xram_bank_mbc);
    n_xram_bank_passthrough <= (n_xram_bank_select_zero nor r_boot_rom_accessible) or r_boot_rom_accessible;

    -- XRAM ports
    -- TODO: look at this again, I don't have the head for it now
    o_xram_adr(13 downto 0) <= i_adr(13 downto 0);
    with n_xram_bank_passthrough & r_xram_bank_force_zero select o_xram_adr(21 downto 14) <=
        (14 => '1', others => '0')  when "00",
        r_xram_bank_mbc & r_xram_bank   when "10",
        (others => '0')             when others;

    -- Bus selection data
    with r_bus_selector select o_dat <=
        n_boot_rom_data   when BS_BOOT_ROM,
        -- n_cart_ram_data   when BS_CART_RAM,
        i_xram_dat      when BS_XRAM,
        r_register_data   when others;

    -- Bus selection ack
    o_ack <= n_wb_ack;
    with r_bus_selector select n_wb_ack <=
        i_xram_ack      when BS_XRAM,
        r_register_ack    when others;

    -- Bus selection CYC_O
    o_xram_cyc <= i_cyc when r_bus_selector = BS_XRAM else '0';
    
end rtl;
