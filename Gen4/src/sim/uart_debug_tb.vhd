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

    signal n_clk       : std_logic := '0';
    signal n_rst       : std_logic;
    signal n_cyc       : std_logic;
    signal n_ack       : std_logic;
    signal n_we        : std_logic;
    signal n_adr       : std_logic_vector(15 downto 0);
    signal n_dat_o     : std_logic_vector(7 downto 0);
    signal n_dat_i     : std_logic_vector(7 downto 0);
    signal n_serial_tx : std_logic;
    signal n_serial_rx : std_logic := '1';

begin

    n_clk <= not(n_clk) after 5 ns;
    n_rst <= '1', '0' after 160 ns;

    process
    begin
        wait on n_clk until n_clk = '1' and n_rst = '0';

        assert n_cyc = '0' report "Unexpected initial condition: n_cyc /= '0'" severity ERROR;
        assert n_serial_tx = '1' report "Unexpected initial condition: n_serial_tx /= '1'" severity ERROR;
        assert n_dbg_active = '0' report "Unexpected initial condition: n_dbg_active /= '0'" severity ERROR;

        -- insert testing steps here

        wait;
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