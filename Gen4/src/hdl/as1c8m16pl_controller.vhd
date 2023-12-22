----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 27/11/2023 14:30:11 PM
-- Design Name: Controller for AS1C8M16PL 128Mb memory from Alliance Memory
-- Module Name: as1c8m16pl_controller - rtl
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Documentation
--
-- TODO
--
-- i_tga(0): control the CRE pin on the RAM interface, allowing programming/reading
-- of control registers RCR, BCR and DIDR. The register is selected using A[19:18]
-- (which corresponds to i_adr[20:19] of the Wishbone bus) according to the datasheet.
--
-- i_adr(23) is used to drive the CE# pins of the PSRAM. To ensure proper timings, 
-- no Wishbone burst shall be done crossing a boundary which would make this bit
-- flip. I.e. regions (0x00_0000 - 0x7F_FFFF) and (0x80_0000 - 0xFF_FFFF) shall not
-- be accessed in the same burst. Additionally, this bit can also be used to select
-- a bank for configuration register access to a specific bank.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_misc.all;
use IEEE.math_real.all;

entity as1c8m16pl_controller is
    generic (
        -- Clock frequency of i_clk in MHz (must not exceed 200MHz)
        p_clk_freq : real := 100.0
    );
    port (
        -- Wishbone slave interface
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_cyc : in std_logic;
        i_we  : in std_logic;
        o_ack : out std_logic;
        i_adr : in std_logic_vector(23 downto 0);
        i_tga : in std_logic_vector(0 downto 0);
        i_dat : in std_logic_vector(7 downto 0);
        o_dat : out std_logic_vector(7 downto 0);

        -- RAM interface
        io_ram_adq : inout std_logic_vector(15 downto 0);
        o_ram_a    : out std_logic_vector(5 downto 0);
        o_ram_advn : out std_logic;
        o_ram_ce0n : out std_logic;
        o_ram_ce1n : out std_logic;
        o_ram_clk  : out std_logic;
        o_ram_cre  : out std_logic;
        o_ram_lbn  : out std_logic;
        o_ram_ubn  : out std_logic;
        o_ram_oen  : out std_logic;
        i_ram_wait : in std_logic;
        o_ram_wen  : out std_logic
    );
end entity as1c8m16pl_controller;

architecture rtl of as1c8m16pl_controller is

    type t_ram_state is (s_idle, s_buffer_reg_wr, s_oe_mem_rd, s_await_rd_handshake, s_await_counter);
    type t_ram_reg_buffer_state is (s_adq7_0, s_adq15_8, s_a21_16);

    -- Number of bits in counter based on maximum counter value needed
    constant c_ram_counter_bits : positive := positive(ceil(log2(0.070 * p_clk_freq)));

    -- Clock period in ns
    constant c_t_clk : real := 1000.00 / p_clk_freq;

    -- Take time in ns and convert to value to be used in a timer
    function to_tcomp_ns(tns : real; bc : positive)
        return std_logic_vector is
        variable compensated_tns : real;
    begin
        compensated_tns := tns - c_t_clk;

        -- assert that tns is positive (if negative, another implementation should be attempted)
        assert compensated_tns > 0.0 report "to_tcomp_ns: compensated_tns is less then zero" severity ERROR;

        return std_logic_vector(to_unsigned(natural(ceil(compensated_tns * p_clk_freq / 1000.00)), bc));
    end to_tcomp_ns;

    function to_ns_tcomp(tcomp : std_logic_vector)
        return real is
        variable clock_cycles : natural;
    begin
        clock_cycles := to_integer(unsigned(tcomp)) + 1;
        return real(clock_cycles) * c_t_clk;
    end to_ns_tcomp;

    -- Chip enable to end of WRITE
    constant c_t_comp_cw : std_logic_vector(c_ram_counter_bits - 1 downto 0) := to_tcomp_ns(70.0, c_ram_counter_bits);

    -- Output enable to valid output
    constant c_t_comp_toe : std_logic_vector(c_ram_counter_bits - 1 downto 0) := to_tcomp_ns(20.0, c_ram_counter_bits);

    -- ADV high to OE low time (Taadv - Toe - c_t_clk (to compensate for double state transition))
    constant c_t_comp_aoe : std_logic_vector(c_ram_counter_bits - 1 downto 0) := to_tcomp_ns(70.0 - 20.0 - c_t_clk, c_ram_counter_bits);

    signal r_ack : std_logic;

    signal r_ram_state_current : t_ram_state;
    signal r_ram_state_next : t_ram_state;
    signal r_ram_drive_adq : std_logic;
    signal r_ram_drive_adq_d : std_logic;
    signal r_ram_release : std_logic;
    signal r_ram_adq_out : std_logic_vector(15 downto 0);
    signal r_ram_adq_in : std_logic_vector(15 downto 0);
    signal r_ram_reg_buff_sel : std_logic;
    signal r_ram_cen_oe : std_logic;
    signal r_ram_cen_sel : std_logic;
    signal r_ram_byte_sel : std_logic;
    signal r_ram_rw_oe : std_logic;
    signal r_ram_rw_sel : std_logic;

    signal r_ram_reg_buffer_state : t_ram_reg_buffer_state;
    signal r_ram_counter : std_logic_vector(c_ram_counter_bits - 1 downto 0);
    signal n_ram_counter_elapsed : std_logic;

begin

    assert c_t_clk >= 5.0 report "c_t_clk is smaller than Tvp, which could lead to undefined behaviour with the current implementation" severity ERROR;
    assert c_t_clk >= 5.0 report "c_t_clk is smaller than Tavs, which could lead to undefined behaviour with the current implementation" severity ERROR;

    o_ack <= r_ack;
    o_dat <= r_ram_adq_in(7 downto 0) when r_ram_rw_sel = '0' else r_ram_adq_in(15 downto 8);

    o_ram_clk <= '0';
    io_ram_adq <= r_ram_adq_out when r_ram_drive_adq_d = '1' else (others => 'Z');
    o_ram_ce0n <= r_ram_cen_sel when r_ram_cen_oe = '1' else '1';
    o_ram_ce1n <= not(r_ram_cen_sel) when r_ram_cen_oe = '1' else '1';
    o_ram_wen <= not(r_ram_rw_sel) when r_ram_rw_oe = '1' else '1';
    o_ram_oen <= r_ram_rw_sel when r_ram_rw_oe = '1' else '1';

    process (i_clk)
    begin
        if rising_edge(i_clk) then
            r_ack <= '0';
            r_ram_drive_adq <= '0';
            r_ram_drive_adq_d <= r_ram_drive_adq;
            o_ram_advn <= '1';

            if i_rst = '1' then
                r_ram_state_current <= s_idle;
                r_ram_state_next <= s_idle;
                r_ram_release <= '0';
                r_ram_adq_out <= (others => '0');
                r_ram_adq_in <= (others => '0');
                r_ram_reg_buff_sel <= '1';
                r_ram_cen_oe <= '0';
                r_ram_cen_sel <= '0';
                r_ram_byte_sel <= '0';
                r_ram_rw_oe <= '0';
                r_ram_rw_sel <= '0';
                r_ram_reg_buffer_state <= s_adq7_0;
                r_ram_counter <= (others => '0');

                o_ram_a <= (others => '0');
                o_ram_cre <= '0';
                o_ram_lbn <= '1';
                o_ram_ubn <= '1';
            else
                case r_ram_state_current is
                    -- idle and await cycle start
                    when s_idle =>
                        if i_cyc = '1' then
                            -- select between memory access and register access
                            if i_tga(0) = '0' then
                                -- memory operation
                                if i_we = '1' then
                                    r_ram_state_current <= s_await_counter;
                                    r_ram_state_next <= s_idle;

                                    -- Start ADNV pulse (in the next clock cycle, address will be latched)
                                    o_ram_advn <= '0';
                                    r_ram_drive_adq <= '1';
                                    r_ram_drive_adq_d <= '1';
                                    r_ram_cen_oe <= '1';
                                    r_ram_rw_oe <= '1';
                                    o_ram_lbn <= i_adr(0);
                                    o_ram_ubn <= not(i_adr(0));

                                    -- Initialise counter to idle after write finished
                                    r_ram_counter <= c_t_comp_cw;

                                    -- release ram bus after timer elapsed
                                    r_ram_release <= '1';

                                    -- acknowledge to release the bus
                                    r_ack <= '1';
                                else
                                    r_ram_state_current <= s_await_counter;
                                    r_ram_state_next <= s_oe_mem_rd;

                                    -- Start ADNV pulse (in the next clock cycle, address will be latched)
                                    o_ram_advn <= '0';
                                    r_ram_drive_adq <= '1';
                                    r_ram_drive_adq_d <= '1';
                                    r_ram_cen_oe <= '1';
                                    o_ram_lbn <= i_adr(0);
                                    o_ram_ubn <= not(i_adr(0));

                                    -- Initialise counter to wait until OE# may be asserted
                                    r_ram_counter <= c_t_comp_aoe;
                                end if;
                            else
                                -- register operation
                                if i_we = '1' then
                                    r_ram_state_current <= s_buffer_reg_wr;
                                    r_ack <= '1';
                                else
                                    r_ram_state_current <= s_await_counter;
                                    r_ram_state_next <= s_oe_mem_rd;

                                    -- Start ADNV pulse (in the next clock cycle, address will be latched)
                                    o_ram_advn <= '0';
                                    r_ram_drive_adq <= '1';
                                    r_ram_drive_adq_d <= '1';
                                    o_ram_cre <= '1';
                                    r_ram_cen_oe <= '1';
                                    o_ram_lbn <= '0';
                                    o_ram_ubn <= '0';

                                    -- Initialise counter to wait until OE# may be asserted
                                    r_ram_counter <= c_t_comp_aoe;
                                end if;
                            end if;

                            -- latch address
                            o_ram_a <= i_adr(22 downto 17);
                            r_ram_adq_out <= i_adr(16 downto 1);

                            -- latch correct chip select
                            r_ram_cen_sel <= i_adr(23);

                            -- latch correct lower/upper byte
                            r_ram_byte_sel <= i_adr(0);

                            -- latch we for later use
                            r_ram_rw_sel <= i_we;
                        end if;

                    -- buffer the bytes for writing value to a register
                    when s_buffer_reg_wr =>
                        if i_cyc = '1' then
                            case r_ram_reg_buffer_state is
                                when s_adq7_0 =>
                                    r_ram_adq_out(7 downto 0) <= i_dat;
                                    r_ram_reg_buffer_state <= s_adq15_8;
                                    r_ack <= '1';

                                when s_adq15_8 =>
                                    r_ram_adq_out(15 downto 8) <= i_dat;
                                    r_ram_reg_buffer_state <= s_a21_16;
                                    r_ack <= '1';

                                when s_a21_16 =>
                                    o_ram_a <= i_dat(5 downto 0);
                                    r_ram_state_current <= s_await_counter;
                                    r_ram_state_next <= s_idle;

                                    -- Start ADNV pulse (in the next clock cycle, address will be latched)
                                    o_ram_advn <= '0';
                                    r_ram_drive_adq <= '1';
                                    r_ram_drive_adq_d <= '1';
                                    o_ram_cre <= '1';
                                    r_ram_cen_oe <= '1';
                                    r_ram_rw_oe <= '1';
                                    o_ram_lbn <= '0';
                                    o_ram_ubn <= '0';

                                    -- Initialise counter to idle after write finished
                                    r_ram_counter <= c_t_comp_cw;

                                    -- release ram bus after timer elapsed
                                    r_ram_release <= '1';

                                    r_ack <= '0';
                            end case;
                        end if;

                    -- assert OE after waiting a bit
                    when s_oe_mem_rd =>
                        r_ram_state_current <= s_await_counter;
                        r_ram_state_next <= s_await_rd_handshake;
                        r_ram_rw_oe <= '1';

                        -- Initialise counter to idle until data is available
                        r_ram_counter <= c_t_comp_toe;

                        -- release ram bus after timer elapsed
                        r_ram_release <= '1';

                    -- await Wishbone handshake after
                    when s_await_rd_handshake =>
                        r_ack <= '1';

                        -- check for handshake
                        if (i_cyc and r_ack) = '1' then
                            r_ack <= '0';
                            r_ram_state_current <= s_idle;
                        end if;

                    -- wait for the counter to elapse and jump to next state
                    when s_await_counter =>
                        if n_ram_counter_elapsed = '1' then
                            r_ram_state_current <= r_ram_state_next;
                            if r_ram_release = '1' then
                                r_ram_release <= '0';
                                r_ram_cen_oe <= '0';
                                r_ram_rw_oe <= '0';
                                o_ram_cre <= '0';
                                o_ram_lbn <= '1';
                                o_ram_ubn <= '1';
                                r_ram_adq_in <= io_ram_adq;
                            end if;
                        end if;
                end case;

                if n_ram_counter_elapsed = '0' then
                    r_ram_counter <= std_logic_vector(unsigned(r_ram_counter) - 1);
                end if;
            end if;
        end if;
    end process;

    n_ram_counter_elapsed <= nor_reduce(r_ram_counter);

end architecture rtl;