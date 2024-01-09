----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 01/09/2024 15:36:00 PM
-- Design Name: Testbench for the uart_core
-- Module Name: uart_core_tb - rtl
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_core_tb is
end entity uart_core_tb;

architecture rtl of uart_core_tb is

    constant c_baud_rate : natural := 115200;

    component uart_core
        generic (
            p_clk_freq : real := 100.0;
            p_baud_rate : natural := c_baud_rate;
            p_parity : string := "NONE";
            p_data_bits : natural := 8;
            p_stop_bits : natural := 1
        );
        port (
            i_clk       : in std_logic;
            i_rst       : in std_logic;
            i_cyc       : in std_logic;
            i_we        : in std_logic;
            i_dat       : in std_logic_vector(p_data_bits - 1 downto 0);
            o_dat       : out std_logic_vector(p_data_bits - 1 downto 0);
            o_ack       : out std_logic;
            o_tx_ready  : out std_logic;
            o_rx_ready  : out std_logic;
            o_serial_tx : out std_logic;
            i_serial_rx : in std_logic
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

    signal n_clk : std_logic := '0';
    signal n_rst : std_logic;
    signal n_cyc : std_logic := '0';
    signal n_we : std_logic;
    signal n_din : std_logic_vector(7 downto 0);
    signal n_dout : std_logic_vector(7 downto 0);
    signal n_ack : std_logic;
    signal n_tx_ready : std_logic;
    signal n_rx_ready : std_logic;
    signal n_serial_tx : std_logic;
    signal n_serial_rx : std_logic := '1';

begin

    n_clk <= not(n_clk) after 5 ns;
    n_rst <= '1', '0' after 160 ns;

    process
    begin
        wait on n_clk until n_clk = '1' and n_rst = '0';

        assert n_ack = '0' report "Unexpected initial condition: n_ack /= '0'" severity ERROR;
        assert n_tx_ready = '1' report "Unexpected initial condition: n_tx_ready /= '1'" severity ERROR;
        assert n_rx_ready = '0' report "Unexpected initial condition: n_rx_ready /= '0'" severity ERROR;
        assert n_serial_tx = '0' report "Unexpected initial condition: n_serial_tx /= '0'" severity ERROR;

        -- write data to send to tx
        wait for 20 us;
        n_cyc <= '1';
        n_we <= '1';
        n_din <= x"55";
        wait on n_clk until n_clk = '1' and n_ack = '1';
        n_din <= x"AA";
        wait on n_clk until n_clk = '1' and n_ack = '1';
        n_cyc <= '0';
        n_we <= '0';
        wait on n_clk until n_clk = '1';

        -- transmit data over serial
        wait for 20 us;
        transmit_serial(
            c_data => x"55",
            o_serial_tx => n_serial_rx
        );

        -- attempt to read said data
        wait on n_clk until n_clk = '1' and n_serial_rx = '1';
        n_cyc <= '1';
        wait on n_clk until n_clk = '1' and n_ack = '1';
        assert n_dout = x"55" report "Unexpected rx data: expected = 0x55, actual = 0x" & to_hstring(to_bitvector(n_dout)) severity ERROR;
        n_cyc <= '0';
        wait on n_clk until n_clk = '1';

        -- transmit data over serial
        transmit_serial(
            c_data => x"F0",
            o_serial_tx => n_serial_rx
        );

        -- attempt to read said data
        wait on n_clk until n_clk = '1' and n_serial_rx = '1';
        n_cyc <= '1';
        wait on n_clk until n_clk = '1' and n_ack = '1';
        assert n_dout = x"F0" report "Unexpected rx data: expected = 0xF0, actual = 0x" & to_hstring(to_bitvector(n_dout)) severity ERROR;
        n_cyc <= '0';
        wait on n_clk until n_clk = '1';

        wait;
    end process;

    inst_uart_core : uart_core
    port map(
        i_clk       => n_clk,
        i_rst       => n_rst,
        i_cyc       => n_cyc,
        i_we        => n_we,
        i_dat       => n_din,
        o_dat       => n_dout,
        o_ack       => n_ack,
        o_tx_ready  => n_tx_ready,
        o_rx_ready  => n_rx_ready,
        o_serial_tx => n_serial_tx,
        i_serial_rx => n_serial_rx
    );

end architecture rtl;