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
            i_tx_wr     : in std_logic;
            i_tx_dat    : in std_logic_vector(p_data_bits - 1 downto 0);
            o_tx_rdy    : out std_logic;
            i_rx_rd     : in std_logic;
            o_rx_dat    : out std_logic_vector(p_data_bits - 1 downto 0);
            o_rx_rdy    : out std_logic;
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

    signal n_clk       : std_logic := '0';
    signal n_rst       : std_logic;
    signal n_tx_wr     : std_logic := '0';
    signal n_tx_dat    : std_logic_vector(7 downto 0);
    signal n_tx_rdy    : std_logic;
    signal n_rx_rd     : std_logic := '0';
    signal n_rx_dat    : std_logic_vector(7 downto 0);
    signal n_rx_rdy    : std_logic;
    signal n_serial_tx : std_logic;
    signal n_serial_rx : std_logic := '1';

begin

    n_clk <= not(n_clk) after 5 ns;
    n_rst <= '1', '0' after 160 ns;

    process
    begin
        wait on n_clk until n_clk = '1' and n_rst = '0';

        assert n_tx_rdy = '1' report "Unexpected initial condition: n_tx_rdy /= '1'" severity ERROR;
        assert n_rx_rdy = '0' report "Unexpected initial condition: n_rx_rdy /= '0'" severity ERROR;
        assert n_serial_tx = '1' report "Unexpected initial condition: n_serial_tx /= '1'" severity ERROR;

        -- write data to send to tx
        wait for 20 us;
        n_tx_wr <= '1';
        n_tx_dat <= x"55";
        wait on n_clk until n_clk = '1';
        n_tx_dat <= x"AA";
        wait on n_clk until n_clk = '1' and n_tx_rdy = '1';
        n_tx_wr <= '0';
        wait on n_clk until n_clk = '1';

        -- transmit data over serial
        wait for 20 us;
        transmit_serial(
            c_data => x"55",
            o_serial_tx => n_serial_rx
        );

        -- attempt to read said data
        wait on n_clk until n_clk = '1' and n_rx_rdy = '1';
        assert n_rx_dat = x"55" report "Unexpected rx data: expected = 0x55, actual = 0x" & to_hstring(to_bitvector(n_rx_dat)) severity ERROR;
        n_rx_rd <= '1';
        wait on n_clk until n_clk = '1';
        n_rx_rd <= '0';
        wait on n_clk until n_clk = '1';

        -- transmit data over serial
        transmit_serial(
            c_data => x"F0",
            o_serial_tx => n_serial_rx
        );

        -- attempt to read said data
        wait on n_clk until n_clk = '1' and n_rx_rdy = '1';
        assert n_rx_dat = x"F0" report "Unexpected rx data: expected = 0xF0, actual = 0x" & to_hstring(to_bitvector(n_rx_dat)) severity ERROR;
        n_rx_rd <= '1';
        wait on n_clk until n_clk = '1';
        n_rx_rd <= '0';
        wait on n_clk until n_clk = '1';

        -- spam transmit data to debug issue with bit misallignment
        n_rx_rd <= '1';
        for i in 0 to 15 loop
            transmit_serial(
                c_data => x"55",
                o_serial_tx => n_serial_rx
            );
        end loop;
        wait on n_clk until n_clk = '1';
        n_rx_rd <= '0';

        wait;
    end process;

    inst_uart_core : uart_core
    port map(
        i_clk       => n_clk,
        i_rst       => n_rst,
        i_tx_wr     => n_tx_wr,
        i_tx_dat    => n_tx_dat,
        o_tx_rdy    => n_tx_rdy,
        i_rx_rd     => n_rx_rd,
        o_rx_dat    => n_rx_dat,
        o_rx_rdy    => n_rx_rdy,
        o_serial_tx => n_serial_tx,
        i_serial_rx => n_serial_rx
    );

end architecture rtl;