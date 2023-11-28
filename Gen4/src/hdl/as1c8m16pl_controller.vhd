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
-- TGA_I(0): control the CRE pin on the RAM interface, allowing programming/reading
-- of control registers RCR, BCR and DIDR. The register is selected using A[19:18]
-- (which corresponds to ADR_I[19:18] of the Wishbone bus) according to the datasheet.
--
-- ADR_I(23) is used to drive the CE# pins of the PSRAM. To ensure proper timings, 
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
        -- Clock frequency of CLK_I
        CLK_FREQ : real := 100.0
    );
    port (
        -- Wishbone slave interface
        CLK_I : in std_logic;
        RST_I : in std_logic;
        CYC_I : in std_logic;
        WE_I  : in std_logic;
        ACK_O : out std_logic;
        ADR_I : in std_logic_vector(23 downto 0);
        TGA_I : in std_logic_vector(0 downto 0);
        DAT_I : in std_logic_vector(7 downto 0);
        DAT_O : out std_logic_vector(7 downto 0);

        -- RAM interface
        RAM_ADQ  : inout std_logic_vector(15 downto 0);
        RAM_A    : out std_logic_vector(5 downto 0);
        RAM_ADVN : out std_logic;
        RAM_CE0N : out std_logic;
        RAM_CE1N : out std_logic;
        RAM_CLK  : out std_logic;
        RAM_CRE  : out std_logic;
        RAM_LBN  : out std_logic;
        RAM_UBN  : out std_logic;
        RAM_OEN  : out std_logic;
        RAM_WAIT : in std_logic;
        RAM_WEN  : out std_logic
    );
end entity as1c8m16pl_controller;

architecture rtl of as1c8m16pl_controller is

    type ram_state_t is (RS_IDLE, RS_BUFFER_REG_WR, RS_OE_REG_RD, RS_BUFFER_REG_RD, RS_AWAIT_RD_HANDSHAKE, RS_AWAIT_COUNTER);
    type ram_reg_buffer_state_t is (RBS_ADQ7_0, RBS_ADQ15_8, RBS_A21_16);

    -- Number of bits in counter based on maximum counter value needed
    constant RAM_COUNTER_BITS : positive := positive(ceil(log2(0.070 * CLK_FREQ)));

    -- Clock period in ns
    constant T_CLK : real := 1000.00 / CLK_FREQ;

    -- Take time in ns and convert to value to be used in a timer
    function to_tcomp_ns(tns : real; bc : positive)
        return std_logic_vector is
        variable compensated_tns : real;
    begin
        compensated_tns := tns - T_CLK;

        -- assert that tns is positive (if negative, another implementation should be attempted)
        assert compensated_tns > 0.0 report "to_tcomp_ns: compensated_tns is less then zero" severity ERROR;

        return std_logic_vector(to_unsigned(natural(ceil(compensated_tns * CLK_FREQ / 1000.00)), bc));
    end to_tcomp_ns;

    function to_ns_tcomp(tcomp : std_logic_vector)
        return real is
        variable clock_cycles : natural;
    begin
        clock_cycles := to_integer(unsigned(tcomp)) + 1;
        return real(clock_cycles) * T_CLK;
    end to_ns_tcomp;

    -- Chip enable to end of WRITE
    constant T_COMP_CW : std_logic_vector(RAM_COUNTER_BITS - 1 downto 0) := to_tcomp_ns(70.0, RAM_COUNTER_BITS);

    -- Output enable to valid output
    constant T_COMP_TOE : std_logic_vector(RAM_COUNTER_BITS - 1 downto 0) := to_tcomp_ns(20.0, RAM_COUNTER_BITS);

    -- ADV high to OE low time (Taadv - Toe - T_CLK (to compensate for double state transition))
    constant T_COMP_AOE : std_logic_vector(RAM_COUNTER_BITS - 1 downto 0) := to_tcomp_ns(70.0 - 20.0 - T_CLK, RAM_COUNTER_BITS);

    signal wb_ack : std_logic;

    signal ram_state_current : ram_state_t;
    signal ram_state_next : ram_state_t;
    signal ram_drive_adq : std_logic;
    signal ram_release : std_logic;
    signal ram_adq_out : std_logic_vector(15 downto 0);
    signal ram_adq_in : std_logic_vector(15 downto 0);
    signal ram_reg_buff_sel : std_logic;
    signal ram_cen_oe : std_logic;
    signal ram_cen_sel : std_logic;
    signal ram_byte_sel : std_logic;
    signal ram_rw_oe : std_logic;
    signal ram_rw_sel : std_logic;

    signal ram_reg_buffer_state : ram_reg_buffer_state_t;
    signal ram_counter : std_logic_vector(RAM_COUNTER_BITS - 1 downto 0);
    signal ram_counter_elapsed : std_logic;

begin

    assert T_CLK >= 5.0 report "T_CLK is smaller than Tvp, which could lead to undefined behaviour with the current implementation" severity ERROR;
    assert T_CLK >= 5.0 report "T_CLK is smaller than Tavs, which could lead to undefined behaviour with the current implementation" severity ERROR;

    ACK_O <= wb_ack;
    DAT_O <= ram_adq_in(7 downto 0) when ram_rw_sel = '0' else ram_adq_in(15 downto 8);

    RAM_CLK <= '0';
    RAM_ADQ <= ram_adq_out when ram_drive_adq = '1' else (others => 'Z');
    RAM_CE0N <= ram_cen_sel when ram_cen_oe = '1' else '1';
    RAM_CE1N <= not(ram_cen_sel) when ram_cen_oe = '1' else '1';
    RAM_WEN <= not(ram_rw_sel) when ram_rw_oe = '1' else '1';
    RAM_OEN <= ram_rw_sel when ram_rw_oe = '1' else '1';

    process (CLK_I)
    begin
        if rising_edge(CLK_I) then
            wb_ack <= '0';
            RAM_ADVN <= '1';

            if RST_I = '1' then
                ram_state_current <= RS_IDLE;
                ram_state_next <= RS_IDLE;
                ram_drive_adq <= '0';
                ram_release <= '0';
                ram_adq_out <= (others => '0');
                ram_reg_buff_sel <= '1';
                ram_cen_oe <= '0';
                ram_cen_sel <= '0';
                ram_byte_sel <= '0';
                ram_rw_oe <= '0';
                ram_rw_sel <= '0';
                ram_reg_buffer_state <= RBS_ADQ7_0;
                ram_counter <= (others => '0');

                RAM_A <= (others => '0');
                RAM_CRE <= '0';
                RAM_LBN <= '1';
                RAM_UBN <= '1';
            else
                case ram_state_current is
                    -- idle and await cycle start
                    when RS_IDLE =>
                        if CYC_I = '1' then
                            -- select between memory access and register access
                            if TGA_I(0) = '0' then
                                -- memory operation
                                if WE_I = '1' then
                                    ram_state_current <= RS_AWAIT_COUNTER;
                                    ram_state_next <= RS_IDLE;

                                    -- Start ADNV pulse (in the next clock cycle, address will be latched)
                                    RAM_ADVN <= '0';
                                    ram_cen_oe <= '1';
                                    ram_rw_oe <= '1';
                                    RAM_LBN <= ADR_I(0);
                                    RAM_UBN <= not(ADR_I(0));

                                    -- Initialise counter to idle after write finished
                                    ram_counter <= T_COMP_CW;

                                    -- release ram bus after timer elapsed
                                    ram_release <= '1';

                                    -- acknowledge to release the bus
                                    wb_ack <= '1';
                                else
                                    ram_state_current <= RS_AWAIT_COUNTER;
                                    ram_state_next <= RS_OE_REG_RD;

                                    -- Start ADNV pulse (in the next clock cycle, address will be latched)
                                    RAM_ADVN <= '0';
                                    ram_cen_oe <= '1';
                                    RAM_LBN <= ADR_I(0);
                                    RAM_UBN <= not(ADR_I(0));

                                    -- Initialise counter to wait until OE# may be asserted
                                    ram_counter <= T_COMP_AOE;
                                end if;
                            else
                                -- register operation
                                if WE_I = '1' then
                                    ram_state_current <= RS_BUFFER_REG_WR;
                                    wb_ack <= '1';
                                else
                                    ram_state_current <= RS_AWAIT_COUNTER;
                                    ram_state_next <= RS_OE_REG_RD;

                                    -- Start ADNV pulse (in the next clock cycle, address will be latched)
                                    RAM_ADVN <= '0';
                                    RAM_CRE <= '1';
                                    ram_cen_oe <= '1';
                                    RAM_LBN <= '0';
                                    RAM_UBN <= '0';

                                    -- Initialise counter to wait until OE# may be asserted
                                    ram_counter <= T_COMP_AOE;
                                end if;
                            end if;

                            -- latch correct chip select
                            ram_cen_sel <= ADR_I(23);

                            -- latch correct lower/upper byte
                            ram_byte_sel <= ADR_I(0);

                            -- latch we for later use
                            ram_rw_sel <= WE_I;
                        end if;

                    -- buffer the bytes for writing value to a register
                    when RS_BUFFER_REG_WR =>
                        if CYC_I = '1' then
                            case ram_reg_buffer_state is
                                when RBS_ADQ7_0 =>
                                    ram_adq_out(7 downto 0) <= DAT_I;
                                    ram_reg_buffer_state <= RBS_ADQ15_8;
                                    wb_ack <= '1';

                                when RBS_ADQ15_8 =>
                                    ram_adq_out(15 downto 8) <= DAT_I;
                                    ram_reg_buffer_state <= RBS_A21_16;
                                    wb_ack <= '1';

                                when RBS_A21_16 =>
                                    RAM_A <= DAT_I(5 downto 0);
                                    ram_state_current <= RS_AWAIT_COUNTER;
                                    ram_state_next <= RS_IDLE;

                                    -- Start ADNV pulse (in the next clock cycle, address will be latched)
                                    RAM_ADVN <= '0';
                                    RAM_CRE <= '1';
                                    ram_cen_oe <= '1';
                                    ram_rw_oe <= '1';
                                    RAM_LBN <= '0';
                                    RAM_UBN <= '0';

                                    -- Initialise counter to idle after write finished
                                    ram_counter <= T_COMP_CW;

                                    -- release ram bus after timer elapsed
                                    ram_release <= '1';

                                    wb_ack <= '0';
                            end case;
                        end if;

                    -- assert OE after waiting a bit
                    when RS_OE_REG_RD =>
                        ram_state_current <= RS_AWAIT_COUNTER;
                        ram_state_next <= RS_BUFFER_REG_RD when TGA_I(0) = '1' else RS_AWAIT_RD_HANDSHAKE;
                        ram_rw_oe <= '1';

                        -- Initialise counter to idle until data is available
                        ram_counter <= T_COMP_TOE;

                        -- release ram bus after timer elapsed
                        ram_release <= '1';

                    -- send buffered reg to master
                    when RS_BUFFER_REG_RD =>
                        wb_ack <= '1';
                        ram_rw_sel <= '0';

                        -- check for handshake
                        if (CYC_I and wb_ack) = '1' then
                            if ram_rw_sel = '0' then
                                ram_rw_sel <= '1';
                            else
                                wb_ack <= '0';
                                ram_state_current <= RS_IDLE;
                            end if;
                        end if;

                    -- await Wishbone handshake after
                    when RS_AWAIT_RD_HANDSHAKE =>
                        wb_ack <= '1';

                        -- check for handshake
                        if (CYC_I and wb_ack) = '1' then
                            wb_ack <= '0';
                            ram_state_current <= RS_IDLE;
                        end if;

                    -- wait for the counter to elapse and jump to next state
                    when RS_AWAIT_COUNTER =>
                        if ram_counter_elapsed = '1' then
                            ram_state_current <= ram_state_next;
                            if ram_release = '1' then
                                ram_release <= '0';
                                ram_cen_oe <= '0';
                                ram_rw_oe <= '0';
                                RAM_CRE <= '0';
                                RAM_LBN <= '1';
                                RAM_UBN <= '1';
                                ram_adq_in <= RAM_ADQ;
                            end if;
                        end if;
                end case;

                if ram_counter_elapsed = '0' then
                    ram_counter <= std_logic_vector(unsigned(ram_counter) - 1);
                end if;
            end if;
        end if;
    end process;

    ram_counter_elapsed <= nor_reduce(ram_counter);

end architecture rtl;