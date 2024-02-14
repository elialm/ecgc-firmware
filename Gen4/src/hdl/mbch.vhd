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
-- It has access to the entire system, including XRAM, SPI and Flash. It also provides
-- access to the boot ROM, which initialised the system using this hypervisor level
-- access.
--
-- The MBCH is also used to access the MBCH control registers. These include functions
-- such as XRAM banking and soft reset control. The control registers are further
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

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;

entity mbch is
    port (
        -- Main slave interface
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_cyc : in std_logic;
        i_we  : in std_logic;
        o_ack : out std_logic;
        i_adr : in std_logic_vector(15 downto 0);
        i_dat : in std_logic_vector(7 downto 0);
        o_dat : out std_logic_vector(7 downto 0);

        -- Master interface to external RAM controller
        o_xram_cyc : out std_logic;
        o_xram_we  : out std_logic;
        i_xram_ack : in std_logic;
        o_xram_adr : out std_logic_vector(23 downto 0);
        o_xram_tga : out std_logic;
        i_xram_dat : in std_logic_vector(7 downto 0);
        o_xram_dat : out std_logic_vector(7 downto 0);

        -- General I/O
        i_gpio : in std_logic_vector(3 downto 0);
        o_gpio : out std_logic_vector(3 downto 0);

        -- Miscellaneous signals
        o_select_mbc     : out std_logic_vector(2 downto 0);
        o_soft_reset_req : out std_logic;
        i_soft_reset     : in std_logic;
        i_dbg_active     : in std_logic
    );
end mbch;

architecture rtl of mbch is

    type t_bus_selector is (s_boot_rom, s_cart_ram, s_xram);

    component boot_ram is
        port (
            Clock   : in std_logic;
            ClockEn : in std_logic;
            Reset   : in std_logic;
            WE      : in std_logic;
            Address : in std_logic_vector(11 downto 0);
            Data    : in std_logic_vector(7 downto 0);
            Q       : out std_logic_vector(7 downto 0));
    end component;

    component cart_ram
    port (
        Clock       : in std_logic;
        ClockEn     : in std_logic; 
        Reset       : in std_logic;
        WE          : in std_logic; 
        Address     : in std_logic_vector(10 downto 0); 
        Data        : in std_logic_vector(7 downto 0); 
        Q           : out std_logic_vector(7 downto 0));
    end component;

    component synchroniser is
        generic (
            p_ff_count : natural := 2;
            p_data_width : natural := 4;
            p_reset_value : std_logic := '0'
        );
        port (
            i_clk  : in std_logic;
            i_rst  : in std_logic;
            i_din  : in std_logic_vector(p_data_width - 1 downto 0);
            o_dout : out std_logic_vector(p_data_width - 1 downto 0)
        );
    end component;

    -- boot ram and cart ram signals
    signal n_boot_rom_enabled : std_logic;
    signal n_boot_rom_data : std_logic_vector(7 downto 0);
    signal n_boot_rom_we : std_logic;
    signal n_cart_ram_data : std_logic_vector(7 downto 0);

    -- decoder signals
    signal r_bus_selector : t_bus_selector;
    signal r_busy : std_logic;
    signal r_ack : std_logic;
    signal r_dat : std_logic_vector(7 downto 0);

    -- xram signals
    signal r_xram_cyc : std_logic;
    signal r_xram_we  : std_logic;
    signal r_xram_adr : std_logic_vector(23 downto 0);
    signal r_xram_tga : std_logic;

    -- gpio signals
    signal r_gpio_out : std_logic_vector(3 downto 0);
    signal n_gpio_in_sync : std_logic_vector(3 downto 0);

    -- cart registers and soft reset handling
    signal r_boot_rom_accessible : std_logic;
    signal r_soft_reset_req : std_logic;
    signal r_soft_reset_rising : std_logic;
    signal r_current_mbc : std_logic_vector(2 downto 0);
    signal r_next_mbc : std_logic_vector(2 downto 0);
    signal r_xram_bank : std_logic_vector(9 downto 0);

begin

    -- ROM instance containing boot code
    inst_boot_rom : boot_ram
    port map(
        Clock   => i_clk,
        ClockEn => n_boot_rom_enabled,
        Reset   => i_rst,
        WE      => n_boot_rom_we,
        Address => i_adr(11 downto 0),
        Data    => i_dat,
        Q       => n_boot_rom_data
    );

    n_boot_rom_enabled <= r_boot_rom_accessible and i_cyc;
    n_boot_rom_we <= i_we and i_dbg_active;

    -- Cart RAM instance, for DMA buffering and reset management
    inst_cart_ram : cart_ram
    port map (
        Clock   => i_clk,
        ClockEn => i_cyc,
        Reset   => i_rst,
        WE      => i_we,
        Address => i_adr(10 downto 0),
        Data    => i_dat,
        Q       => n_cart_ram_data
    );

    -- slave wishbone bus
    o_ack <= r_ack;
    o_dat <= r_dat;

    -- XRAM wishbone bus
    o_xram_cyc <= r_xram_cyc;
    o_xram_we  <= r_xram_we;
    o_xram_adr <= r_xram_adr;
    o_xram_tga <= r_xram_tga;
    o_xram_dat <= r_dat;

    -- address decoder and wishbone handler
    -- also handle soft reset routine
    process (i_clk)
    begin
        if rising_edge(i_clk) then
            r_soft_reset_req <= '0';

            if i_rst = '1' then
                -- r_bus_selector <= s_boot_rom;
                r_busy <= '0';
                r_ack <= '0';
                -- r_dat <= (others => '0');
                r_xram_cyc <= '0';
                -- r_xram_we <= '0';
                r_xram_adr(23 downto 16) <= (others => '0');
                -- r_xram_adr(15 downto 0) <= (others => '0');
                r_xram_tga <= '0';
                r_gpio_out <= (others => '0');
                r_boot_rom_accessible <= '1';
                r_soft_reset_rising <= '1';
                r_current_mbc <= "000";
                r_next_mbc <= "000";
                r_xram_bank <= (others => '0');
            else
                -- initiate wishbone transaction on i_cyc rising edge or after a successfull handshake
                if (i_cyc and not(r_busy)) = '1' then
                    -- mark busy to indicate that decoding has been done
                    r_busy <= '1';

                    -- address decoder
                    case? i_adr(15 downto 8) is
                        -- Boot ROM or lower 4kB of bank 0
                        when b"0000_----" =>
                            if r_boot_rom_accessible = '1' then
                                r_bus_selector <= s_boot_rom;
                            else
                                r_bus_selector <= s_xram;
                                r_xram_cyc <= '1';
                                r_xram_we <= i_we;
                                r_xram_adr(23 downto 14) <= "00" & x"00";
                                r_xram_adr(13 downto 0) <= i_adr(13 downto 0);
                                r_dat <= i_dat;
                            end if;

                        -- Upper 12kB of back 0
                        when b"0001_----" | b"0010_----" | b"0011_----" =>
                            r_bus_selector <= s_xram;
                            r_xram_cyc <= '1';
                            r_xram_we <= i_we;
                            r_xram_adr(23 downto 14) <= "00" & x"00";
                            r_xram_adr(13 downto 0) <= i_adr(13 downto 0);
                            r_dat <= i_dat;

                        -- Banked XRAM
                        when b"01--_----" =>
                            r_bus_selector <= s_xram;
                            r_xram_cyc <= '1';
                            r_xram_we <= i_we;
                            r_xram_adr(23 downto 14) <= r_xram_bank;
                            r_xram_adr(13 downto 0) <= i_adr(13 downto 0);
                            r_dat <= i_dat;

                        -- Reserved (previously EFB)
                        when b"1010_0000" =>
                            r_ack <= '1';

                        -- MBCH control 0 reg
                        when b"1010_0001" =>
                            if i_we = '1' then
                                r_soft_reset_req <= i_dat(7);
                                r_boot_rom_accessible <= i_dat(6);
                                r_next_mbc <= i_dat(2 downto 0);
                            end if;
                            r_dat <= '0' & r_boot_rom_accessible & "000" & r_next_mbc;
                            r_ack <= '1';

                        -- XRAM control 0 reg
                        when b"1010_0010" =>
                            if i_we = '1' then
                                r_xram_bank(9 downto 8) <= i_dat(5 downto 4);
                                r_xram_tga <= i_dat(0);
                            end if;
                            r_dat <= "00" & r_xram_bank(9 downto 8) & "000" & r_xram_tga;
                            r_ack <= '1';

                        -- XRAM control 1 reg
                        when b"1010_0011" =>
                            if i_we = '1' then
                                r_xram_bank(7 downto 0) <= i_dat;
                            end if;
                            r_dat <= r_xram_bank(7 downto 0);
                            r_ack <= '1';

                        -- MBCH GPIO reg
                        when b"1010_0100" =>
                            if i_we = '1' then
                                r_gpio_out <= i_dat(7 downto 4);
                            end if;
                            r_dat <= r_gpio_out & n_gpio_in_sync;
                            r_ack <= '1';

                        -- Reserved (mapped to DMA registers)
                        when b"1010_0101" =>
                            r_ack <= '1';

                        -- Cart RAM
                        when b"1011_0---" =>
                            r_bus_selector <= s_cart_ram;

                        -- Other regions will always read as 0x00 and ignore writes
                        when others =>
                            r_dat <= x"00";
                            r_ack <= '1';
                    end case?;
                end if;

                -- if busy (done with decoding), perform operations for the selected bus
                if (r_busy and not(r_ack)) = '1' then
                    case r_bus_selector is
                        when s_boot_rom =>
                            r_dat <= n_boot_rom_data;
                            r_ack <= '1';

                        when s_cart_ram =>
                            r_dat <= n_cart_ram_data;
                            r_ack <= '1';

                        when s_xram =>
                            if i_xram_ack = '1' then
                                r_xram_cyc <= '0';
                                r_ack <= '1';
                                r_dat <= i_xram_dat;
                            end if;
                    end case;
                end if;

                -- on ack, clear busy and free decoder for next transaction
                if r_ack = '1' then
                    r_busy <= '0';
                    r_ack <= '0';
                end if;

                -- soft reset
                if (i_soft_reset and r_soft_reset_rising) = '1' then
                    r_current_mbc <= r_next_mbc;
                    r_next_mbc <= "000";
                    r_soft_reset_rising <= '0';
                elsif i_soft_reset = '0' then
                    r_soft_reset_rising <= '1';
                end if;
            end if;
        end if;
    end process;

    -- GPIO input synchroniser
    inst_gpio_synchroniser : synchroniser
    port map(
        i_clk  => i_clk,
        i_rst  => i_rst,
        i_din  => i_gpio,
        o_dout => n_gpio_in_sync
    );

    -- remaining out port assignments
    o_gpio <= r_gpio_out;
    o_select_mbc <= r_current_mbc;
    o_soft_reset_req <= r_soft_reset_req;

end rtl;