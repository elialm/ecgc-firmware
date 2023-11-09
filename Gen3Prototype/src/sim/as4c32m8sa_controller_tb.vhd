----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 06/26/2022 15:30:20 PM
-- Design Name: Reset controller
-- Module Name: reset - behaviour
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

entity as4c32m8sa_controller_tb is
end as4c32m8sa_controller_tb;

architecture behaviour of as4c32m8sa_controller_tb is

    type DRAM_CMD is
        (CMD_BANK_ACTIVATE, CMD_BANK_PRECHARGE, CMD_PRECHARGE_ALL,
        CMD_WRITE, CMD_WRITE_AUTO_PRECHARGE, CMD_READ, CMD_READ_AUTO_PRECHARGE,
        CMD_MODE_REGISTER_SET, CMD_NOP, CMD_BURST_STOP, CMD_DEVICE_DESELECT,
        CMD_AUTO_REFRESH, CMD_SELF_REFRESH_ENTRY, CMD_SELF_REFRESH_EXIT,
        CMD_CLOCK_SUSPEND_MODE_ENTRY, CMD_POWER_DOWN_MODE_ENTRY,
        CMD_CLOCK_SUSPEND_MODE_EXIT, CMD_POWER_DOWN_MODE_EXIT, CMD_OUTPUT_ENABLE,
        CMD_OUTPUT_DISABLE, CMD_UNKNOWN);
    type DRAM_CMD_ENCODING_TYPE is record
        previous_cke        : std_logic;
        current_cke         : std_logic;
        dqm                 : std_logic;
        ba                  : std_logic_vector(1 downto 0);
        a                   : std_logic_vector(12 downto 0);
        csn                 : std_logic;
        rasn                : std_logic;
        casn                : std_logic;
        wen                 : std_logic;
        dram_cmd            : DRAM_CMD;
    end record DRAM_CMD_ENCODING_TYPE;
    type DRAM_CMD_ENCODING_ARRAY_TYPE is array (0 to 23) of DRAM_CMD_ENCODING_TYPE;

    -- DRAM commands encodings lookup table
    constant DRAM_CMD_ENCODINGS : DRAM_CMD_ENCODING_ARRAY_TYPE := (
    --  CKE-1   CKE     DQM     BA(1:0)       A(12:0)    CS#    RAS#    CAS#    WE#	    Command
        ('1',   '-',    '-',    "--",   "-------------", '0',   '0',    '1',    '1',    CMD_BANK_ACTIVATE),
        ('1',   '-',    '-',    "--",   "--0----------", '0',   '0',    '1',    '0',    CMD_BANK_PRECHARGE),
        ('1',   '-',    '-',    "--",   "--1----------", '0',   '0',    '1',    '0',    CMD_PRECHARGE_ALL),
        ('1',   '-',    '-',    "--",   "--0----------", '0',   '1',    '0',    '0',    CMD_WRITE),
        ('1',   '-',    '-',    "--",   "--1----------", '0',   '1',    '0',    '0',    CMD_WRITE_AUTO_PRECHARGE),
        ('1',   '-',    '-',    "--",   "--0----------", '0',   '1',    '0',    '1',    CMD_READ),
        ('1',   '-',    '-',    "--",   "--1----------", '0',   '1',    '0',    '1',    CMD_READ_AUTO_PRECHARGE),
        ('1',   '-',    '-',    "00",   "000-0001-----", '0',   '0',    '0',    '0',    CMD_MODE_REGISTER_SET),
        ('1',   '-',    '-',    "--",   "-------------", '0',   '1',    '1',    '1',    CMD_NOP),
        ('1',   '-',    '-',    "--",   "-------------", '0',   '1',    '1',    '0',    CMD_BURST_STOP),
        ('1',   '-',    '-',    "--",   "-------------", '1',   '-',    '-',    '-',    CMD_DEVICE_DESELECT),
        ('1',   '1',    '-',    "--",   "-------------", '0',   '0',    '0',    '1',    CMD_AUTO_REFRESH),
        ('1',   '0',    '-',    "--",   "-------------", '0',   '0',    '0',    '1',    CMD_SELF_REFRESH_ENTRY),
        ('0',   '1',    '-',    "--",   "-------------", '1',   '-',    '-',    '-',    CMD_SELF_REFRESH_EXIT),
        ('0',   '1',    '-',    "--",   "-------------", '0',   '1',    '1',    '1',    CMD_SELF_REFRESH_EXIT),
        ('1',   '0',    '-',    "--",   "-------------", '1',   '-',    '-',    '-',    CMD_CLOCK_SUSPEND_MODE_ENTRY),
        ('1',   '0',    '-',    "--",   "-------------", '0',   '-',    '-',    '-',    CMD_CLOCK_SUSPEND_MODE_ENTRY),
        ('1',   '0',    '-',    "--",   "-------------", '1',   '-',    '-',    '-',    CMD_POWER_DOWN_MODE_ENTRY),
        ('1',   '0',    '-',    "--",   "-------------", '0',   '1',    '1',    '1',    CMD_POWER_DOWN_MODE_ENTRY),
        ('0',   '1',    '-',    "--",   "-------------", '-',   '-',    '-',    '-',    CMD_CLOCK_SUSPEND_MODE_ENTRY),
        ('0',   '1',    '-',    "--",   "-------------", '1',   '-',    '-',    '-',    CMD_POWER_DOWN_MODE_EXIT),
        ('0',   '1',    '-',    "--",   "-------------", '0',   '1',    '1',    '1',    CMD_POWER_DOWN_MODE_EXIT),
        ('1',   '-',    '0',    "--",   "-------------", '-',   '-',    '-',    '-',    CMD_OUTPUT_ENABLE),
        ('1',   '-',    '1',    "--",   "-------------", '-',   '-',    '-',    '-',    CMD_OUTPUT_DISABLE)
    );

    signal dram_clk_i   : std_logic := '0';
    signal dram_rst_i   : std_logic := '1';
    signal dram_cyc_i   : std_logic := '0';
    signal dram_stb_i   : std_logic := '0';
    signal dram_we_i    : std_logic := '0';
    signal dram_adr_i   : std_logic_vector(22 downto 0) := (others => '0');
    signal dram_tga_i   : std_logic_vector(1 downto 0) := (others => '0');
    signal dram_dat_i   : std_logic_vector(7 downto 0) := (others => '0');
    signal dram_dat_o   : std_logic_vector(7 downto 0);
    signal dram_ack_o   : std_logic;

    signal dram_ready   : std_logic;
    
    signal dram_cke_pre : std_logic;
    signal dram_cke     : std_logic;
    signal dram_ba      : std_logic_vector(1 downto 0);
    signal dram_a       : std_logic_vector(12 downto 0);
    signal dram_csn     : std_logic;
    signal dram_rasn    : std_logic;
    signal dram_casn    : std_logic;
    signal dram_wen     : std_logic;
    signal dram_dqm     : std_logic;
    signal dram_dq      : std_logic_vector(7 downto 0);

    signal reset_extend : natural := 0;
    signal decoded_cmd  : DRAM_CMD := CMD_UNKNOWN;
    signal transaction  : natural := 0;

    -- Compare entity inputs with given DRAM_CMD_ENCODING_TYPE
    impure function compare_entity(encoding : DRAM_CMD_ENCODING_TYPE)
        return boolean is
    begin
        if std_match(dram_cke_pre, encoding.previous_cke)
            and std_match(dram_cke, encoding.current_cke)
            and std_match(dram_dqm, encoding.dqm)
            and std_match(dram_ba, encoding.ba)
            and std_match(dram_a, encoding.a)
            and std_match(dram_csn, encoding.csn)
            and std_match(dram_rasn, encoding.rasn)
            and std_match(dram_casn, encoding.casn)
            and std_match(dram_wen, encoding.wen)
        then
            return true;
        else
            return false;
        end if;
    end compare_entity;

    -- Command decoder
    impure function decode_command
        return DRAM_CMD is
    begin
        for i in DRAM_CMD_ENCODINGS'range loop
            if compare_entity(DRAM_CMD_ENCODINGS(i)) then
                return DRAM_CMD_ENCODINGS(i).dram_cmd;
            end if;
        end loop;

        -- dump_entity("Error while decoding command: could not find record matching current entity inputs");
        return CMD_UNKNOWN;
    end decode_command;

begin

    DRAM_CONTROLLER : entity work.as4c32m8sa_controller
    port map (
        CLK_I => dram_clk_i,
        RST_I => dram_rst_i,
        CYC_I => dram_cyc_i,
        STB_I => dram_stb_i,
        WE_I => dram_we_i,
        ADR_I => dram_adr_i,
        TGA_I => dram_tga_i,
        DAT_I => dram_dat_i,
        DAT_O => dram_dat_o,
        ACK_O => dram_ack_o,

        READY => dram_ready,

        CKE => dram_cke,
        BA => dram_ba,
        A => dram_a,
        CSN => dram_csn,
        RASN => dram_rasn,
        CASN => dram_casn,
        WEN => dram_wen,
        DQM => dram_dqm,
        DQ => dram_dq);

    -- Clock generator
    process
    begin
        -- wait for 18.79699248 ns;
        wait for 9.398496241 ns;
        dram_clk_i <= not(dram_clk_i);
    end process;

    -- Reset generator
    process (dram_clk_i)
    begin
        if rising_edge(dram_clk_i) then
            if reset_extend < 16 then
                reset_extend <= reset_extend + 1;
                dram_rst_i <= '1';
            else
                dram_rst_i <= '0';
            end if;
        end if;
    end process;

    -- Assign previous CKE
    process (dram_clk_i)
    begin
        if rising_edge(dram_clk_i) then
            dram_cke_pre <= dram_cke;
        end if;
    end process;

    -- Decode command currently on the bus
    process (dram_cke_pre, dram_cke, dram_dqm, dram_ba, dram_a, dram_csn, dram_rasn, dram_casn, dram_wen)
    begin
        decoded_cmd <= decode_command;
    end process;

    -- DRAM access test
    process (dram_clk_i)
    begin
        if rising_edge(dram_clk_i) and dram_ready = '1' then
            case transaction is
                when 0 =>
                    -- Test a read
                    dram_cyc_i <= '1';
                    dram_stb_i <= '1';
                    dram_we_i <= '0';
                    dram_adr_i <= b"0000000000000_0000000000";
                    dram_tga_i <= "00";
                    dram_dq <= x"C3";       -- Test data to be read

                    if dram_ack_o = '1' then
                        transaction <= transaction + 1;
                        dram_cyc_i <= '0';
                        dram_stb_i <= '0';
                        dram_dq <= "ZZZZZZZZ";   -- Release the bus
                    end if;
                when 1 =>
                    -- Test a write
                    dram_cyc_i <= '1';
                    dram_stb_i <= '1';
                    dram_we_i <= '1';
                    dram_adr_i <= b"0000000000000_0000000000";
                    dram_tga_i <= "00";
                    dram_dat_i <= x"E1";    -- Test data to be written

                    if dram_ack_o = '1' then
                        transaction <= transaction + 1;
                        dram_cyc_i <= '0';
                        dram_stb_i <= '0';
                    end if;
                when others =>
                    null;
            end case;
        end if;
    end process;
    
end behaviour;
