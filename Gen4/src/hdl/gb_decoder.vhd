----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 03/31/2022 04:10:42 PM
-- Design Name: Gameboy bus decoder
-- Module Name: gb_decoder - rtl
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_misc.all;
use IEEE.math_real.all;

entity gb_decoder is
    generic (
        p_enable_timeout_detection : boolean := false;
        p_clk_freq : real := 53.20
    );
    port (
        -- Gameboy signals
        i_gb_clk  : in std_logic;
        i_gb_addr : in std_logic_vector(15 downto 0);
        i_gb_din  : in std_logic_vector(7 downto 0);
        o_gb_dout : out std_logic_vector(7 downto 0);
        i_gb_rdn  : in std_logic;
        i_gb_csn  : in std_logic;

        -- Wishbone signals
        i_clk : in std_logic;
        i_rst : in std_logic;
        o_cyc : out std_logic;
        o_we  : out std_logic;
        o_adr : out std_logic_vector(15 downto 0);
        i_dat : in std_logic_vector(7 downto 0);
        o_dat : out std_logic_vector(7 downto 0);
        i_ack : in std_logic;

        o_access_rom : out std_logic;  -- Indicates when address range 0x0000-0x7FFF is being accessed. Only valid when n_cyc = 1.
        o_access_ram : out std_logic;  -- Indicates when address range 0xA000-0xBFFF is being accessed. Only valid when n_cyc = 1.
        o_wr_timeout : out std_logic;  -- Indicates that a write timeout has occurred. Asserting i_rst will reset this back to 0.
        o_rd_timeout : out std_logic   -- Indicates that a read timeout has occurred. Asserting i_rst will reset this back to 0.
    );
    end gb_decoder;

architecture rtl of gb_decoder is

    type t_gb_bus_state is (s_await_access_finished, s_idle, s_read_await_ack, s_write_await_falling_edge, s_write_await_ack);

    constant c_cyc_counter_read : std_logic_vector(3 downto 0) := "1000"; -- 9 cycles
    constant c_cyc_counter_write : std_logic_vector(3 downto 0) := "1000"; -- 9 cycles (I think)

    component synchroniser is
        generic (
            FF_COUNT : natural := 2;
            DATA_WIDTH : natural := 1;
            RESET_VALUE : std_logic := '0');
        port (
            CLK     : in std_logic;
            RST     : in std_logic;
            DAT_IN  : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            DAT_OUT : out std_logic_vector(DATA_WIDTH - 1 downto 0));
    end component;

    -- Synchronised signals from GameBoy
    signal n_gb_clk_sync : std_logic;
    signal n_gb_csn_sync : std_logic;
    signal n_gb_addr_sync : std_logic_vector(2 downto 0);

    -- Access signals (combinatorial)
    signal n_gb_access_rom : std_logic;
    signal n_gb_access_ram : std_logic;
    signal n_gb_access_cart : std_logic;

    signal r_gb_bus_state : t_gb_bus_state;
    signal r_cyc_counter  : std_logic_vector(3 downto 0);
    signal n_cyc_timeout  : std_logic;
    signal n_cyc          : std_logic;

begin

    -- We only synchronise the upper 3 bits of the address, since only
    -- those are needed for the activation trigger. By the time these are
    -- processed, enough time has passed to safely read the other bits.
    inst_address_synchroniser : synchroniser
    generic map(
        DATA_WIDTH => 3
    )
    port map(
        CLK     => i_clk,
        RST     => i_rst,
        DAT_IN  => i_gb_addr(15 downto 13),
        DAT_OUT => n_gb_addr_sync
    );

    inst_clk_synchroniser : synchroniser
    port map(
        CLK        => i_clk,
        RST        => i_rst,
        DAT_IN(0)  => i_gb_clk,
        DAT_OUT(0) => n_gb_clk_sync
    );

    inst_csn_synchroniser : synchroniser
    port map(
        CLK        => i_clk,
        RST        => i_rst,
        DAT_IN(0)  => i_gb_csn,
        DAT_OUT(0) => n_gb_csn_sync
    );

    -- Signals for determining type of access
    -- n_gb_access_rom <= '1' on accesses in range 0x0000 - 0x7FFF
    -- n_gb_access_ram <= '1' on accesses in range 0xA000 - 0xBFFF
    n_gb_access_cart <= n_gb_access_rom or n_gb_access_ram;
    n_gb_access_rom <= not(n_gb_addr_sync(2));
    n_gb_access_ram <= not(n_gb_csn_sync)
        and n_gb_addr_sync(2)
        and not(n_gb_addr_sync(1))
        and n_gb_addr_sync(0);

    o_access_rom <= n_gb_access_rom;
    o_access_ram <= n_gb_access_ram;
    o_cyc <= n_cyc;

    -- Control Wishbone cycles
    process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                r_gb_bus_state <= s_await_access_finished;
                r_cyc_counter <= (others => '1');
                n_cyc <= '0';

                o_we <= '0';
                o_adr <= (oth => '0');
                o_dat <= (oth => '0');
                o_gb_dout <= hers => '0');
                o_rd_timeout '0';
                o_wr_timeout <= '0';
            else
                -- Bus decoder state machine
                case r_gb_bus_state is
                    when s_await_access_finished =>
                        if n_gb_access_cart = '0' then
                            r_gb_bus_state <= s_idle;
                        end if;

                    when s_idle =>
                        if n_gb_access_cart = '1' then
                            if i_gb_rdn = '0' then
                                -- Initiate read from cart
                                r_gb_bus_state <= s_read_await_ack;
                                n_cyc <= '1';
                                o_we <= '0';
                                r_cyc_counter <= c_cyc_counter_read;
                            else
                                -- Initiate write to cart
                                r_gb_bus_state <= s_write_await_falling_edge;
                            end if;

                            o_adr <= i_gb_addr;
                        end if;

                    when s_read_await_ack =>
                        if i_ack = '1' then
                            r_gb_bus_state <= s_await_access_finished;
                            n_cyc <= '0';
                            o_gb_dout <= i_dat;
                        end 
                        if n_cyc_timeout =  then
                            o_rd_timeout '1';
                        end if;

                    when s_write_await_falling_edge =>
                        if n_gb_clk_sync = '0' then
                            r_gb_bus_state <= s_write_await_ack;
                            n_cyc <= '1';
                            o_we <= '1';
                            o_dat <= i_gb_din;
                            r_cyc_counter <= c_cyc_counter_write;
                        end if;

                    when s_write_await_ack =>
                        if i_ack = '1' then
                            r_gb_bus_state <= s_await_access_finished;
                            n_cyc <= '0';
                        end if;

                        if n_cyc_timeout = '1' then
                            o_wr_timeout <= '1';
                        end if;

                    when others =>
                        r_gb_bus_state <= s_await_access_finished;
                        n_cyc <= '0';
                end case;
            end if;

            -- Decrement timeout counter
            if n_cyc_timeout = '0' and p_enable_timeout_detection then
                r_cyc_counter <= std_logic_vector(unsigned(r_cyc_counter) - 1);
            end if;
        end if;
    end process;

    -- Should not be necessary, since the synthesiser should optimise
    -- it out if r_cyc_counter does not change, but I will leave it
    -- to feel good about it.
    gen_conditional_cyc_timeout : if p_enable_timeout_detection generate
        n_cyc_timeout <= nor_reduce(r_cyc_counter);
    else generate
        n_cyc_timeout <= '0';
    end generate;

end rtl;