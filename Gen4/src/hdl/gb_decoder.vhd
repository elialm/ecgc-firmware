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

        -- Global signals
        i_clk : in std_logic;
        i_rst : in std_logic;

        -- Wishbone DMA master signals
        o_dma_cyc : out std_logic;
        o_dma_we : out std_logic;
        o_dma_adr : out std_logic_vector(3 downto 0);
        o_dma_dat : out std_logic_vector(7 downto 0);
        i_dma_dat : in std_logic_vector(7 downto 0);
        i_dma_ack : in std_logic;

        -- Wishbone MBCH master signals
        o_mbch_cyc : out std_logic;
        o_mbch_we : out std_logic;
        o_mbch_adr : out std_logic_vector(15 downto 0);
        o_mbch_dat : out std_logic_vector(7 downto 0);
        i_mbch_dat : in std_logic_vector(7 downto 0);
        i_mbch_ack : in std_logic;

        -- Miscellaneous signals
        i_dma_busy     : in std_logic;
        i_selected_mbc : in std_logic_vector(2 downto 0);
        o_wr_timeout   : out std_logic;  -- Indicates that a write timeout has occurred. Asserting i_rst will reset this back to 0.
        o_rd_timeout   : out std_logic   -- Indicates that a read timeout has occurred. Asserting i_rst will reset this back to 0.
    );
end gb_decoder;

architecture rtl of gb_decoder is

    type t_gb_bus_state is (s_await_access_finished, s_idle, s_read_await_ack, s_write_await_falling_edge, s_write_await_ack);

    -- TODO: update with new clock frequency
    constant c_cyc_counter_read : std_logic_vector(3 downto 0) := "1000"; -- 9 cycles
    constant c_cyc_counter_write : std_logic_vector(3 downto 0) := "1000"; -- 9 cycles (I think)

    component synchroniser is
        generic (
            p_ff_count : natural := 2;
            p_data_width : natural := 1;
            p_reset_value : std_logic := '0');
        port (
            i_clk  : in std_logic;
            i_rst  : in std_logic;
            i_din  : in std_logic_vector(p_data_width - 1 downto 0);
            o_dout : out std_logic_vector(p_data_width - 1 downto 0));
    end component;

    -- Synchronised signals from GameBoy
    signal n_gb_clk_sync : std_logic;
    signal n_gb_csn_sync : std_logic;
    signal n_gb_addr_sync : std_logic_vector(2 downto 0);

    -- Access signals
    signal n_gb_access_rom : std_logic;
    signal n_gb_access_ram : std_logic;
    signal n_gb_access_cart : std_logic;
    signal n_gb_access_dma : std_logic;

    signal r_gb_bus_state : t_gb_bus_state;
    signal r_cyc_counter : std_logic_vector(3 downto 0);
    signal n_cyc_timeout : std_logic;
    signal n_ack : std_logic;
    signal n_dat : std_logic_vector(7 downto 0);
    signal r_we : std_logic;
    signal r_dat : std_logic_vector(7 downto 0);
    signal r_adr : std_logic_vector(15 downto 0);

begin

    -- We only synchronise the upper 3 bits of the address, since only
    -- those are needed for the activation trigger. By the time these are
    -- processed, enough time has passed to safely read the other bits.
    inst_address_synchroniser : synchroniser
    generic map(
        p_data_width => 3
    )
    port map(
        i_clk  => i_clk,
        i_rst  => i_rst,
        i_din  => i_gb_addr(15 downto 13),
        o_dout => n_gb_addr_sync
    );

    inst_clk_synchroniser : synchroniser
    port map(
        i_clk     => i_clk,
        i_rst     => i_rst,
        i_din(0)  => i_gb_clk,
        o_dout(0) => n_gb_clk_sync
    );

    inst_csn_synchroniser : synchroniser
    port map(
        i_clk     => i_clk,
        i_rst     => i_rst,
        i_din(0)  => i_gb_csn,
        o_dout(0) => n_gb_csn_sync
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

    -- or all ack signals, since only one slave is active at any time
    n_ack <= i_dma_ack or i_mbch_ack;

    -- or all dat signals, since only one slave is active at any time
    -- connected slaves must then set their dat_o signals to all zeros, otherwise this won't work
    n_dat <= i_dma_dat or i_mbch_dat;

    -- only valid when n_gb_access_cart = '1' and i_selected_mbc = "000"
    n_gb_access_dma <= '1' when n_gb_access_ram = '1' and i_gb_addr(12 downto 8) = "00101" else '0';

    -- we is for all slaves the same
    o_dma_we <= r_we;
    o_mbch_we <= r_we;

    -- dat is for all slaves the same
    o_dma_dat <= r_dat;
    o_mbch_dat <= r_dat;

    -- adr is for all slaves the same
    o_dma_adr <= r_adr(3 downto 0);
    o_mbch_adr <= r_adr;

    -- Control Wishbone cycles
    process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                r_gb_bus_state <= s_await_access_finished;
                r_cyc_counter <= (others => '1');

                o_gb_dout <= (others => '0');
                o_dma_cyc <= '0';
                o_mbch_cyc <= '0';
                o_rd_timeout <= '0';
                o_wr_timeout <= '0';
                r_we <= '0';
                -- r_dat <= (others => '0');
                -- r_adr <= (others => '0');
            else
                -- Bus decoder state machine
                case r_gb_bus_state is
                    when s_await_access_finished =>
                        if n_gb_access_cart = '0' then
                            r_gb_bus_state <= s_idle;
                        end if;

                    when s_idle =>
                        if n_gb_access_cart = '1' then
                            -- block cart access when DMA is busy
                            if i_dma_busy = '1' and n_gb_access_dma = '0' then
                                o_gb_dout <= x"00";
                                r_gb_bus_state <= s_await_access_finished;
                            else
                                if i_gb_rdn = '0' then
                                    r_gb_bus_state <= s_read_await_ack;
                                    r_we <= '0';
                                    r_cyc_counter <= c_cyc_counter_read;

                                    -- select cyc
                                    o_dma_cyc <= '1' when n_gb_access_dma = '1' and i_selected_mbc = "000" else '0';
                                    o_mbch_cyc <= '1' when n_gb_access_dma = '0' and i_selected_mbc = "000" and i_dma_busy = '0' else '0';
                                else
                                    -- Initiate write to cart
                                    r_gb_bus_state <= s_write_await_falling_edge;
                                end if;

                                r_adr <= i_gb_addr;
                            end if;
                        end if;

                    when s_read_await_ack =>
                        if n_ack = '1' then
                            r_gb_bus_state <= s_await_access_finished;
                            o_dma_cyc <= '0';
                            o_mbch_cyc <= '0';
                            o_gb_dout <= n_dat;
                        end if;

                        if n_cyc_timeout = '1' then
                            o_rd_timeout <= '1';
                        end if;

                    when s_write_await_falling_edge =>
                        if n_gb_clk_sync = '0' then
                            r_gb_bus_state <= s_write_await_ack;
                            r_we <= '1';
                            r_dat <= i_gb_din;
                            r_cyc_counter <= c_cyc_counter_write;

                            -- select cyc
                            o_dma_cyc <= '1' when n_gb_access_dma = '1' and i_selected_mbc = "000" else '0';
                            o_mbch_cyc <= '1' when n_gb_access_dma = '0' and i_selected_mbc = "000" else '0';
                        end if;

                    when s_write_await_ack =>
                        if n_ack = '1' then
                            r_gb_bus_state <= s_await_access_finished;
                            o_dma_cyc <= '0';
                            o_mbch_cyc <= '0';
                        end if;

                        if n_cyc_timeout = '1' then
                            o_wr_timeout <= '1';
                        end if;
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