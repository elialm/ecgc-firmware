----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 02/01/2024 20:09:43 PM
-- Design Name: Testbench for the uart_debug
-- Module Name: uart_debug_tb - rtl
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_debug_tb is
end entity uart_debug_tb;

architecture rtl of uart_debug_tb is

    constant c_baud_rate : natural := 115200;

    component uart_debug
        generic (
            p_clk_freq : real := 100.0;
            p_baud_rate : natural := c_baud_rate;
            p_parity : string := "NONE";
            p_stop_bits : natural := 1
        );
        port (
            i_clk        : in std_logic;
            i_rst        : in std_logic;
            o_cyc        : out std_logic;
            i_ack        : in std_logic;
            o_we         : out std_logic;
            o_adr        : out std_logic_vector(15 downto 0);
            o_dat        : out std_logic_vector(7 downto 0);
            i_dat        : in std_logic_vector(7 downto 0);
            o_serial_tx  : out std_logic;
            i_serial_rx  : in std_logic;
            o_dbg_active : out std_logic
        );
    end component;

    procedure transmit_serial (
        constant c_data : in std_logic_vector(7 downto 0);
        signal o_serial_tx : out std_logic
    ) is
        constant c_baud_period : time := (1.0 / real(c_baud_rate)) * 1_000_000_000.0 ns;
    begin
        -- start bit
        o_serial_tx <= '0';
        wait for c_baud_period;

        -- data bits
        for i in 0 to 7 loop
            o_serial_tx <= c_data(i);
            wait for c_baud_period;
        end loop;

        -- stop bit
        o_serial_tx <= '1';
        wait for c_baud_period;
    end procedure;

    procedure receive_serial (
        variable v_data : out std_logic_vector(7 downto 0);
        signal i_serial_rx : in std_logic
    ) is
        constant c_baud_period : time := (1.0 / real(c_baud_rate)) * 1_000_000_000.0 ns;
    begin
        -- await start bit, then wait till middle of it
        wait until i_serial_rx = '0';
        wait for c_baud_period / 2;

        -- data bits
        for i in 0 to 7 loop
            wait for c_baud_period;
            v_data(i) := i_serial_rx;
        end loop;

        -- await rest of last data bit + stop bits
        wait for c_baud_period * 1.5;
    end procedure;

    type t_test_data is array (natural range <>) of std_logic_vector(7 downto 0);

    signal n_clk        : std_logic := '0';
    signal n_rst        : std_logic;
    signal n_cyc        : std_logic;
    signal n_ack        : std_logic := '0';
    signal n_we         : std_logic;
    signal n_adr        : std_logic_vector(15 downto 0);
    signal n_dat_o      : std_logic_vector(7 downto 0);
    signal n_dat_i      : std_logic_vector(7 downto 0);
    signal n_serial_tx  : std_logic;
    signal n_serial_rx  : std_logic := '1';
    signal n_dbg_active : std_logic;

    shared variable v_serial_data : t_test_data(0 to 31);
    shared variable v_serial_index : natural := 0;
    shared variable v_serial_length : natural := 0;

begin

    n_clk <= not(n_clk) after 5 ns;
    n_rst <= '1', '0' after 160 ns;

    proc_testbench : process
    begin
        wait on n_clk until n_clk = '1' and n_rst = '0';

        assert n_cyc = '0' report "Unexpected initial condition: n_cyc /= '0'" severity ERROR;
        assert n_serial_tx = '1' report "Unexpected initial condition: n_serial_tx /= '1'" severity ERROR;
        assert n_dbg_active = '0' report "Unexpected initial condition: n_dbg_active /= '0'" severity ERROR;

        -- setup reader
        v_serial_data(0) := x"03";
        v_serial_data(1) := x"00";
        v_serial_data(2) := x"05";
        v_serial_data(3) := x"10";
        v_serial_data(4) := x"03";
        v_serial_data(5) := x"10";
        v_serial_index := 0;
        v_serial_length := 6;

        -- read control register
        transmit_serial(
            c_data => x"02",
            o_serial_tx => n_serial_rx
        );

        -- wait to receive sent command + control register contents
        wait for 170 us;

        -- write control register
        transmit_serial(
            c_data => x"04",
            o_serial_tx => n_serial_rx
        );
        transmit_serial(
            c_data => x"10",
            o_serial_tx => n_serial_rx
        );

        -- wait to receive sent register value
        wait for 85 us;

        -- assert debug enabled
        assert n_dbg_active = '1' report "n_dbg_active is disasserted after core enable bit set" severity ERROR;

        -- read control register
        transmit_serial(
            c_data => x"02",
            o_serial_tx => n_serial_rx
        );

        -- wait to receive sent command + control register contents
        wait for 170 us;

        -- setup reader
        v_serial_data(0) := x"11";
        v_serial_data(1) := x"50";
        v_serial_data(2) := x"01";
        v_serial_index := 0;
        v_serial_length := 3;

        -- set debug address
        transmit_serial(
            c_data => x"10",
            o_serial_tx => n_serial_rx
        );
        transmit_serial(
            c_data => x"50",
            o_serial_tx => n_serial_rx
        );
        transmit_serial(
            c_data => x"01",
            o_serial_tx => n_serial_rx
        );

        -- wait to receive resent high byte of the debug address
        wait for 85 us;

        wait;
    end process;

    proc_serial_reader : process
        variable v_data : std_logic_vector(7 downto 0);
    begin
        receive_serial(
            v_data => v_data,
            i_serial_rx => n_serial_tx
        );

        assert v_serial_index < v_serial_length report "Serial test index exceeds test length" severity FAILURE;
        assert v_data = v_serial_data(v_serial_index) report "Unexpected serial data received (expected = 0x"
            & to_hstring(to_bitvector(v_serial_data(v_serial_index))) & ", actual = 0x"
            & to_hstring(to_bitvector(v_data)) & ", test_index = "
            & integer'image(v_serial_index) & ")" severity ERROR;

        v_serial_index := v_serial_index + 1;
    end process;

    inst_uart_debug : uart_debug
    port map(
        i_clk        => n_clk,
        i_rst        => n_rst,
        o_cyc        => n_cyc,
        i_ack        => n_ack,
        o_we         => n_we,
        o_adr        => n_adr,
        o_dat        => n_dat_o,
        i_dat        => n_dat_i,
        o_serial_tx  => n_serial_tx,
        i_serial_rx  => n_serial_rx,
        o_dbg_active => n_dbg_active
    );

end architecture rtl;