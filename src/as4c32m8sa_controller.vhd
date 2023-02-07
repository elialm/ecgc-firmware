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
--
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
        CLK_I       : in std_logic;     -- WishBone clock, same as the DRAM CLK
        RST_I       : in std_logic;
        CYC_I       : in std_logic;
        STB_I       : in std_logic;
        WE_I        : in std_logic;
        ADR_I       : in std_logic_vector(22 downto 0); -- 8 MB of addressable memory 
        TGA_I       : in std_logic_vector(1 downto 0);  -- Used to select bank
        DAT_I       : in std_logic_vector(7 downto 0);
        DAT_O       : out std_logic_vector(7 downto 0);
        ACK_O       : out std_logic;
        ERR_O       : out std_logic;

        READY       : out std_logic;    -- Signal that controller is initialised and ready to accept transactions

        CLK_SM      : in std_logic;     -- CLK_I but 180 degrees phase shifted, used by state machine logic
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

    type DRAM_STATE_T is (DS_AWAIT_INIT, DS_CKE_DELAY, DS_PRECHARGE_ALL, DS_MODE_SET, DS_IDLE, DS_AWAIT_TRC, DS_ACTIVATE_BANK, DS_AWAIT_CAS);

    -- TODO: grab largest value
    constant GLOBAL_COUNTER_BITS    : positive := positive(ceil(log2(200.00 * CLK_FREQ)));

    -- Take time in us and convert to value to be stored in global_comp
    function to_tcomp_us(tus : real)
        return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(natural(ceil(tus * CLK_FREQ)), GLOBAL_COUNTER_BITS));
    end to_tcomp_us;

    -- Take time in ns and convert to value to be stored in global_comp
    function to_tcomp_ns(tns : real)
        return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(natural(ceil(tns * CLK_FREQ / 1000.00)), GLOBAL_COUNTER_BITS));
    end to_tcomp_ns;

    constant T_CLK          : real := 1000.00 / CLK_FREQ;   -- Clock period in ns
    constant T_COMP_INIT    : std_logic_vector(GLOBAL_COUNTER_BITS-1 downto 0) := to_tcomp_us(200.00);
    constant T_COMP_RP      : std_logic_vector(GLOBAL_COUNTER_BITS-1 downto 0) := to_tcomp_ns(21.00);
    constant T_COMP_MRD     : std_logic_vector(GLOBAL_COUNTER_BITS-1 downto 0) := to_tcomp_ns(14.00);
    constant T_COMP_RC      : std_logic_vector(GLOBAL_COUNTER_BITS-1 downto 0) := to_tcomp_ns(61.00);

    -- Time inbetween auto refresh
    -- Compensate delay after refresh (Trc min.) and with duration of 1 read transaction (read takes longer than write)
    constant T_COMP_REFI    : std_logic_vector(GLOBAL_COUNTER_BITS-1 downto 0) := to_tcomp_ns(7800.00 - ceil(61.00 / T_CLK) - (6.00 * T_CLK));

    signal dram_state       : DRAM_STATE_T;
    signal state_delay      : std_logic;
    signal idle_delay       : std_logic;
    signal drive_dq         : std_logic;
    signal data_register    : std_logic_vector(7 downto 0);
    
    signal global_counter   : std_logic_vector(GLOBAL_COUNTER_BITS-1 downto 0);
    signal global_comp      : std_logic_vector(GLOBAL_COUNTER_BITS-1 downto 0);
    signal timer_elapsed    : std_logic;

    signal wb_ack           : std_logic;
    signal dram_ack         : std_logic;

begin

    -- Wishbone state machine
    process (CLK_I)
    begin
        if rising_edge(CLK_I) then
            wb_ack <= dram_ack;

            if RST_I = '1' then
                ERR_O <= '0';
            else
                null;
            end if;
        end if;
    end process;

    ACK_O <= wb_ack;
    DAT_O <= DQ;

    -- DRAM state machine
    process (CLK_SM)
    begin
        if rising_edge(CLK_SM) then
            CSN <= '1';
            DQM <= '1';
            drive_dq <= '0';
            dram_ack <= '0';

            if RST_I = '1' then
                dram_state <= DS_AWAIT_INIT;
                state_delay <= '0';
                idle_delay <= '1';
                data_register <= (others => '0');
                global_counter <= (others => '0');
                global_comp <= T_COMP_INIT;

                READY <= '0';

                CKE <= '0';
                BA <= "00";
                A <= (others => '0');
                RASN <= '1';
                CASN <= '1';
                WEN <= '1';
                -- DQ <= (others => 'Z');
            else
                case dram_state is
                    when DS_AWAIT_INIT =>
                        if timer_elapsed = '1' then
                            dram_state <= DS_CKE_DELAY;
                            CKE <= '1';
                        end if;

                    when DS_CKE_DELAY =>
                        dram_state <= DS_PRECHARGE_ALL;
                        global_counter <= (others => '0');
                        global_comp <= T_COMP_RP;

                        -- Initiate Precharge All command
                        
                        CSN <= '0';
                        RASN <= '0';
                        WEN <= '0';
                        A(10) <= '1';
                    
                    when DS_PRECHARGE_ALL =>
                        if timer_elapsed = '1' then
                            dram_state <= DS_MODE_SET;
                            global_counter <= (others => '0');
                            global_comp <= T_COMP_MRD;

                            -- Initiate Mode Register Set command
                            CSN <= '0';
                            -- RASN <= '0';
                            CASN <= '0';
                            -- WEN <= '0';
                            BA <= "00";                 -- Reserved
                            A(12 downto 10) <= "000";   -- Reserved
                            A(9) <= '1';                -- Burst-Read-Single-Write
                            A(8 downto 7) <= "00";      -- Normal mode
                            A(6 downto 4) <= "010";     -- CAS latency of 2 clocks
                            A(3) <= '0';                -- Sequential bursts
                            A(2 downto 0) <= "000";     -- Burst length of 1
                        end if;

                    when DS_MODE_SET =>
                        if timer_elapsed = '1' then
                            dram_state <= DS_AWAIT_TRC;
                            global_counter <= (others => '0');
                            global_comp <= T_COMP_RC;

                            -- Initiate Auto Refresh
                            CSN <= '0';
                            RASN <= '0';
                            CASN <= '0';
                            WEN <= '1';
                        end if;

                    when DS_IDLE =>
                        idle_delay <= '1';
                        READY <= '1';
                        
                        if (CYC_I and STB_I and idle_delay) = '1' then
                            dram_state <= DS_ACTIVATE_BANK;
                            state_delay <= '0';
                            idle_delay <= '0';

                            -- Initiate Activate Bank
                            CSN <= '0';
                            RASN <= '0';
                            CASN <= '1';
                            WEN <= '1';
                            BA <= TGA_I;
                            A <= ADR_I(22 downto 10);   -- Row address
                        elsif timer_elapsed = '1' then
                            dram_state <= DS_AWAIT_TRC;
                            global_counter <= (others => '0');
                            global_comp <= T_COMP_RC;

                            -- Initiate Auto Refresh
                            CSN <= '0';
                            RASN <= '0';
                            CASN <= '0';
                            WEN <= '1';
                        end if;

                    when DS_AWAIT_TRC =>
                        -- Send NOP
                        CSN <= '0';
                        RASN <= '1';
                        CASN <= '1';
                        WEN <= '1';

                        if timer_elapsed = '1' then
                            dram_state <= DS_IDLE;
                            global_counter <= (others => '0');
                            global_comp <= T_COMP_REFI;
                        end if;

                    when DS_ACTIVATE_BANK =>
                        if state_delay = '0' then
                            state_delay <= '1';
                        else
                            state_delay <= '0';

                            if WE_I = '0' then
                                -- Initiate Read and Auto Precharge
                                dram_state <= DS_AWAIT_CAS;
                                WEN <= '1';
                            else
                                -- Initiate Write and Auto Precharge
                                dram_state <= DS_IDLE;
                                data_register <= DAT_I;
                                drive_dq <= '1';
                                WEN <= '0';
                                dram_ack <= '1';
                            end if;

                            -- Assignments common to read and write
                            CSN <= '0';
                            RASN <= '1';
                            CASN <= '0';
                            DQM <= '0';
                            A(10) <= '1';                       -- Enable auto precharge
                            A(9 downto 0) <= ADR_I(9 downto 0); -- Column address
                        end if;

                    when DS_AWAIT_CAS =>
                        dram_state <= DS_IDLE;
                        dram_ack <= '1';
                end case;

                if timer_elapsed = '0' then
                    global_counter <= std_logic_vector(unsigned(global_counter) + 1);
                end if;
            end if;
        end if;
    end process;

    timer_elapsed <= '1' when global_counter = global_comp else '0';

    DQ <= data_register when drive_dq = '1' else (others => 'Z');
    
end behaviour;
