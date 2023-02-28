----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 06/25/2022 16:17:42 PM
-- Design Name: DRAM controller for AS432M8SA
-- Module Name: as4c32m8sa_controller - behaviour
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Documentation
--
-- AS4C32M8SA DRAM controller. The core provides translation between Wishbone
-- transactions and DRAM commands. For example when reading, the core will
-- figure out which DRAM commands it should send in what order.
--
-- The Wishbone interface has an additional TGA_I bit vector, which is used to
-- select the DRAM bank (the AS4C32M8SA has 4 8MB banks, hence 2 bits).
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use ieee.math_real.all;

entity as4c32m8sa_controller is
    generic (
        CLK_FREQ    : real := 53.20);
    port (
        CLK_I       : in std_logic;
        RST_I       : in std_logic;
        CYC_I       : in std_logic;
        STB_I       : in std_logic;
        WE_I        : in std_logic;
        ADR_I       : in std_logic_vector(22 downto 0); -- 8 MB of addressable memory 
        TGA_I       : in std_logic_vector(1 downto 0);  -- Used to select bank
        DAT_I       : in std_logic_vector(7 downto 0);
        DAT_O       : out std_logic_vector(7 downto 0);
        ACK_O       : out std_logic;

        READY       : out std_logic;    -- Signal that controller is initialised and ready to accept transactions

        CKE         : out std_logic;
        BA          : out std_logic_vector(1 downto 0);
        A           : out std_logic_vector(12 downto 0);
        CSN         : out std_logic;
        RASN        : out std_logic;
        CASN        : out std_logic;
        WEN         : out std_logic;
        DQM         : out std_logic;
        DQ          : inout std_logic_vector(7 downto 0));
end as4c32m8sa_controller;

architecture behaviour of as4c32m8sa_controller is

    type DRAM_STATE_T is (
        DS_AWAIT_STABLE_INIT,
        DS_ISSUE_PRECHARGE_ALL,
        DS_AWAIT_PRECHARGE_ALL,
        DS_AWAIT_MODE_SET,
        DS_AWAIT_AUTO_REFRESH,
        DS_ISSUE_SECOND_AUTO_REFRESH,
        DS_IDLE,
        DS_AWAIT_BANK_ACTIVATE,
        DS_AWAIT_CAS_DELAY);

    -- Number of bits in counter based on maximum counter value needed (noted behind each value)
    constant INIT_COUNTER_BITS      : positive := positive(ceil(log2(200.00 * CLK_FREQ)));  -- stable inputs at startup
    constant GENERIC_COUNTER_BITS   : positive := positive(ceil(log2(0.061 * CLK_FREQ)));   -- longest delay on a command
    constant REFRESH_COUNTER_BITS   : positive := positive(ceil(log2(7.8125 * CLK_FREQ)));  -- maximum time between auto refreshes

    -- Take time in us and convert to value to be used in a timer
    function to_tcomp_us(tus : real; bc : positive)
        return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(natural(ceil(tus * CLK_FREQ)), bc));
    end to_tcomp_us;

    -- Take time in ns and convert to value to be used in a timer
    function to_tcomp_ns(tns : real; bc : positive)
        return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(natural(ceil(tns * CLK_FREQ / 1000.00)), bc));
    end to_tcomp_ns;

    constant T_CLK          : real := 1000.00 / CLK_FREQ;   -- Clock period in ns
    constant T_COMP_INIT    : std_logic_vector(INIT_COUNTER_BITS-1 downto 0) := to_tcomp_us(200.00, INIT_COUNTER_BITS);
    constant T_COMP_RP      : std_logic_vector(GENERIC_COUNTER_BITS-1 downto 0) := to_tcomp_ns(21.00, GENERIC_COUNTER_BITS);
    constant T_COMP_MRD     : std_logic_vector(GENERIC_COUNTER_BITS-1 downto 0) := to_tcomp_ns(14.00, GENERIC_COUNTER_BITS);
    constant T_COMP_RC      : std_logic_vector(GENERIC_COUNTER_BITS-1 downto 0) := to_tcomp_ns(61.00, GENERIC_COUNTER_BITS);
    constant T_COMP_RCD     : std_logic_vector(GENERIC_COUNTER_BITS-1 downto 0) := to_tcomp_ns(21.00, GENERIC_COUNTER_BITS);
    constant T_COMP_CAS     : std_logic_vector(GENERIC_COUNTER_BITS-1 downto 0) := std_logic_vector(to_unsigned(1, GENERIC_COUNTER_BITS));

    -- Time inbetween auto refresh
    -- Compensate delay after refresh (Trc min.) and with duration of 1 read transaction (read takes longer than write)
    -- Auto refresh must occur 8192 times each 64 ms
    constant T_COMP_REFI    : std_logic_vector(REFRESH_COUNTER_BITS-1 downto 0) := to_tcomp_ns(7812.50 - 61.00 - (6.00 * T_CLK), REFRESH_COUNTER_BITS);

    signal dram_state       : DRAM_STATE_T;
    signal dram_state_aar   : DRAM_STATE_T;
    signal dram_ack         : std_logic;
    
    signal init_counter     : std_logic_vector(INIT_COUNTER_BITS-1 downto 0);
    signal generic_counter  : std_logic_vector(GENERIC_COUNTER_BITS-1 downto 0);
    signal refresh_counter  : std_logic_vector(REFRESH_COUNTER_BITS-1 downto 0);
    signal init_elapsed     : std_logic;
    signal generic_elapsed  : std_logic;
    signal refresh_elapsed  : std_logic;

    signal dq_data_out  : std_logic_vector(7 downto 0);
    signal dq_driven    : std_logic;


begin

    process (CLK_I)
    begin
        if rising_edge(CLK_I) then
            dram_ack <= '0';
            dq_driven <= '0';
            CSN <= '1';
            RASN <= '1';
            CASN <= '1';
            WEN <= '1';

            if RST_I = '1' then
                dram_state <= DS_AWAIT_STABLE_INIT;
                dram_state_aar <= DS_AWAIT_STABLE_INIT;
                init_counter <= T_COMP_INIT;
                generic_counter <= (others => '0');
                refresh_counter <= (others => '0');
                dq_data_out <= (others => '0');

                READY <= '0';
                CKE <= '0';
                BA <= "00";
                A <= (others => '0');
                DQM <= '1';
            else
                case dram_state is
                    when DS_AWAIT_STABLE_INIT =>
                        if init_elapsed = '1' then
                            dram_state <= DS_ISSUE_PRECHARGE_ALL;
                            CKE <= '1';
                        end if;

                    when DS_ISSUE_PRECHARGE_ALL =>
                        dram_state <= DS_AWAIT_PRECHARGE_ALL;
                        generic_counter <= T_COMP_RP;

                        -- Issue precharge all command
                        CSN <= '0';
                        RASN <= '0';
                        WEN <= '0';
                        A(10) <= '1';

                    when DS_AWAIT_PRECHARGE_ALL =>
                        if generic_elapsed = '1' then
                            dram_state <= DS_AWAIT_MODE_SET;
                            generic_counter <= T_COMP_MRD;

                            -- Issue mode set command
                            CSN <= '0';
                            RASN <= '0';
                            CASN <= '0';
                            WEN <= '0';
                            A(12 downto 10) <= "000";   -- Reserved
                            A(9) <= '1';                -- Burst-Read-Single-Write
                            A(8 downto 7) <= "00";      -- Normal mode
                            A(6 downto 4) <= "010";     -- CAS latency of 2 clocks
                            A(3) <= '0';                -- Sequential bursts
                            A(2 downto 0) <= "000";     -- Burst length of 1
                        end if;

                    when DS_AWAIT_MODE_SET =>
                        if generic_elapsed = '1' then
                            dram_state <= DS_AWAIT_AUTO_REFRESH;
                            dram_state_aar <= DS_ISSUE_SECOND_AUTO_REFRESH;
                            generic_counter <= T_COMP_RC;

                            -- Issue auto refresh command
                            CSN <= '0';
                            RASN <= '0';
                            CASN <= '0';
                        end if;

                    when DS_AWAIT_AUTO_REFRESH =>
                        if generic_elapsed = '1' then
                            dram_state <= dram_state_aar;
                            refresh_counter <= T_COMP_REFI;
                        end if;

                    when DS_ISSUE_SECOND_AUTO_REFRESH =>
                        dram_state <= DS_AWAIT_AUTO_REFRESH;
                        dram_state_aar <= DS_IDLE;
                        generic_counter <= T_COMP_RC;

                        -- Issue auto refresh command
                        CSN <= '0';
                        RASN <= '0';
                        CASN <= '0';

                    when DS_IDLE =>
                        READY <= '1';
                        DQM <= '0';

                        if (CYC_I and STB_I and not(dram_ack)) = '1' then
                            dram_state <= DS_AWAIT_BANK_ACTIVATE;
                            generic_counter <= T_COMP_RCD;

                            -- Issue bank activate command
                            CSN <= '0';
                            RASN <= '0';
                            BA <= TGA_I;
                            A(12 downto 0) <= ADR_I(22 downto 10);

                        elsif refresh_elapsed = '1' then
                            -- Auto refresh timer expired, must issue another refresh
                            dram_state <= DS_AWAIT_AUTO_REFRESH;
                            dram_state_aar <= DS_IDLE;
                            generic_counter <= T_COMP_RC;

                            -- Issue auto refresh
                            CSN <= '0';
                            RASN <= '0';
                            CASN <= '0';
                        end if;

                    when DS_AWAIT_BANK_ACTIVATE =>
                        if generic_elapsed = '1' then
                            dram_state <= DS_AWAIT_CAS_DELAY;
                            generic_counter <= T_COMP_CAS;

                            -- Issue read/write and auto precharge
                            CSN <= '0';
                            CASN <= '0';
                            WEN <= not(WE_I);   -- Write enable signal
                            A(10) <= '1';
                            A(9 downto 0) <= ADR_I(9 downto 0);

                            -- Drive DQ with data on write
                            dq_driven <= WE_I;
                            dq_data_out <= DAT_I;
                        end if;

                    when DS_AWAIT_CAS_DELAY =>
                        if generic_elapsed = '1' then
                            dram_state <= DS_IDLE;
                            dram_ack <= '1';
                        end if;

                    when others =>
                        -- TODO: make fallback work
                        dram_state <= DS_IDLE;
                end case;
            end if;

            if init_elapsed = '0' then
                init_counter <= std_logic_vector(unsigned(init_counter) - 1);
            end if;

            if generic_elapsed = '0' then
                generic_counter <= std_logic_vector(unsigned(generic_counter) - 1);
            end if;

            if refresh_elapsed = '0' then
                refresh_counter <= std_logic_vector(unsigned(refresh_counter) - 1);
            end if;
        end if;
    end process;

    init_elapsed <= nor_reduce(init_counter);
    generic_elapsed <= nor_reduce(generic_counter);
    refresh_elapsed <= nor_reduce(refresh_counter);
    DQ <= dq_data_out when dq_driven = '1' else (others => 'Z');
    ACK_O <= dram_ack;
    DAT_O <= DQ;
    
end behaviour;
