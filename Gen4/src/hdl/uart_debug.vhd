----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 01/03/2024 14:38:20 PM
-- Design Name: UART-based debugging core
-- Module Name: uart_debug - rtl
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Documentation
--
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_misc.all;

entity uart_debug is
    generic (
        p_clk_freq : real := 100.0;
        p_baud_rate : natural := 115200;
        p_parity : string := "NONE";
        p_stop_bits : natural := 1
    );
    port (
        -- Clocking and reset
        i_clk : in std_logic;
        i_rst : in std_logic;

        -- Wishbone master
        o_cyc : out std_logic;
        i_ack : in std_logic;
        o_we  : out std_logic;
        o_adr : out std_logic_vector(15 downto 0);
        o_dat : out std_logic_vector(7 downto 0);
        i_dat : in std_logic_vector(7 downto 0);

        -- Serial signals
        o_serial_tx : out std_logic;
        i_serial_rx : in std_logic;

        -- Flags
        o_dbg_active : out std_logic
    );
end entity uart_debug;

architecture rtl of uart_debug is
    
    component uart_core
        generic (
            p_clk_freq : real := p_clk_freq;
            p_baud_rate : natural := p_baud_rate;
            p_parity : string := p_parity;
            p_data_bits : natural := 8;
            p_stop_bits : natural := p_stop_bits
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

    type t_debug_state is (s_await_command, s_await_ctrl_value, s_send_ctrl_value, s_await_adr_value, s_await_byte_count, s_await_wb_read, s_send_read_data, s_await_write_data, s_await_wb_write, s_await_resend_request);

    signal r_debug_state : t_debug_state;
    signal r_cmd_ack : std_logic;
    signal r_resend_request : std_logic;
    signal r_adr_byte_sel : std_logic;
    signal r_cmd_rnw : std_logic;
    signal r_auto_inc : std_logic;
    signal r_dbg_active : std_logic;
    signal r_byte_count : std_logic_vector(7 downto 0);
    signal n_zero_count : std_logic;

    signal r_tx_wr  : std_logic;
    signal r_tx_dat : std_logic_vector(7 downto 0);
    signal n_tx_rdy : std_logic;
    signal r_rx_rd  : std_logic;
    signal n_rx_dat : std_logic_vector(7 downto 0);
    signal n_rx_rdy : std_logic;

    signal r_cyc : std_logic;
    signal r_we  : std_logic;
    signal r_adr : std_logic_vector(15 downto 0);
    signal r_dat : std_logic_vector(7 downto 0);

begin
    
    inst_uart_core : uart_core
    port map(
        i_clk       => i_clk,
        i_rst       => i_rst,
        i_tx_wr     => r_tx_wr,
        i_tx_dat    => r_tx_dat,
        o_tx_rdy    => n_tx_rdy,
        i_rx_rd     => r_rx_rd,
        o_rx_dat    => n_rx_dat,
        o_rx_rdy    => n_rx_rdy,
        o_serial_tx => o_serial_tx,
        i_serial_rx => i_serial_rx
    );

    proc_debug_fsm : process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                r_debug_state <= s_await_command;
                r_cmd_ack <= '0';
                r_resend_request <= '0';
                r_adr_byte_sel <= '0';
                -- r_cmd_rnw <= '0';
                r_auto_inc <= '0';
                r_dbg_active <= '0';
                -- r_byte_count <= (others => '0');
                r_tx_wr <= '0';
                r_rx_rd <= '0';
                -- r_tx_dat <= (others => '0');
                r_cyc <= '0';
                r_we <= '0';
                -- r_adr <= (others => '0');
                -- r_dat <= (others => '0');
            else
                r_tx_wr <= '0';
                r_rx_rd <= '0';
                r_cmd_ack <= '0';

                -- debug state machine
                case r_debug_state is
                    when s_await_command =>
                        if n_rx_rdy = '1' and r_rx_rd = '0' then
                            r_rx_rd <= '1';
                            r_cmd_ack <= '1';
                            r_resend_request <= '1';

                            -- command decoding
                            case n_rx_dat(7 downto 1) is
                                -- CTRL_READ
                                when "0000001" =>
                                    r_debug_state <= s_send_ctrl_value;

                                -- CTRL_WRITE
                                when "0000010" =>
                                    r_debug_state <= s_await_ctrl_value;

                                -- SET_ADDR
                                when "0001000" =>
                                    r_debug_state <= s_await_adr_value;

                                -- READ
                                when "0010000" =>
                                    r_cmd_rnw <= '1';
                                    r_debug_state <= s_await_byte_count;

                                -- WRITE
                                when "0011000" =>
                                    r_cmd_rnw <= '0';
                                    r_debug_state <= s_await_byte_count;

                                when others =>
                                    r_cmd_ack <= '0';
                            end case;
                        end if;

                    when s_send_ctrl_value =>
                        r_tx_wr <= '1';
                        r_tx_dat <= "00" & r_auto_inc & r_dbg_active & "0000";

                        -- await write handshake
                        if n_tx_rdy = '1' and r_resend_request = '0' then
                            r_tx_wr <= '0';
                            r_debug_state <= s_await_command;
                        end if;

                    when s_await_ctrl_value =>
                        if n_rx_rdy = '1' and r_resend_request = '0' then
                            r_rx_rd <= '1';
                            r_auto_inc <= n_rx_dat(5);
                            r_dbg_active <= n_rx_dat(4);
                            r_resend_request <= '1';
                            r_debug_state <= s_await_resend_request;
                        end if;

                    when s_await_adr_value =>
                        if n_rx_rdy = '1' and r_resend_request = '0' then
                            r_rx_rd <= '1';
                            r_resend_request <= '1';

                            -- select low or high byte of address
                            if r_adr_byte_sel = '0' then
                                r_adr(7 downto 0) <= n_rx_dat;
                                r_adr_byte_sel <= '1';
                            else
                                r_adr(15 downto 8) <= n_rx_dat;
                                r_adr_byte_sel <= '0';
                                r_debug_state <= s_await_resend_request;
                            end if;
                        end if;

                    when s_await_byte_count =>
                        if n_rx_rdy = '1' and r_resend_request = '0' then
                            r_rx_rd <= '1';
                            r_resend_request <= '1';
                            r_byte_count <= n_rx_dat;

                            -- select read or write command
                            if r_cmd_rnw = '1' then
                                r_debug_state <= s_await_wb_read;
                            else
                                r_debug_state <= s_await_write_data;
                            end if;
                        end if;

                    when s_await_wb_read =>
                        r_cyc <= '1';
                        r_we <= '0';

                        -- await wb handshake
                        if i_ack = '1' then
                            r_cyc <= '0';
                            r_tx_dat <= i_dat;
                            r_tx_wr <= '1';
                            r_debug_state <= s_send_read_data;

                            -- increment address if enabled
                            if r_auto_inc = '1' then
                                r_adr <= std_logic_vector(unsigned(r_adr) + 1);
                            end if;
                        end if;

                    when s_send_read_data =>
                        -- await uart core tx handshake
                        if n_tx_rdy = '1' then
                            r_byte_count <= std_logic_vector(unsigned(r_byte_count) - 1);

                            -- check whether to keep reading or stop and look for next command
                            if n_zero_count = '0' then
                                r_debug_state <= s_await_wb_read;
                            else
                                r_debug_state <= s_await_command;
                            end if;
                        end if;

                    when s_await_write_data =>
                        if n_rx_rdy = '1' and r_resend_request = '0' then
                            r_rx_rd <= '1';
                            r_resend_request <= '1';
                            r_dat <= n_rx_dat;
                            r_debug_state <= s_await_wb_write;
                        end if;

                    when s_await_wb_write =>
                        r_cyc <= '1';
                        r_we <= '1';

                        -- await wb handshake
                        if i_ack = '1' then
                            r_cyc <= '0';
                            r_we <= '0';

                            -- increment address if enabled
                            if r_auto_inc = '1' then
                                r_adr <= std_logic_vector(unsigned(r_adr) + 1);
                            end if;

                            -- check whether to keep writing or stop and look for next command
                            if n_zero_count = '0' then
                                r_debug_state <= s_await_write_data;
                            else
                                r_debug_state <= s_await_command;
                            end if;
                        end if;

                    when s_await_resend_request =>
                        if r_resend_request = '0' then
                            r_debug_state <= s_await_command;
                        end if;
                end case;

                -- byte resending
                if r_resend_request = '1' then

                    -- await tx handshake
                    if (n_tx_rdy and r_tx_wr) = '1' then
                        r_tx_wr <= '0';
                        r_resend_request <= '0';
                    else
                        r_tx_wr <= '1';
                        r_tx_dat(7 downto 1) <= n_rx_dat(7 downto 1);

                        -- set ack bit if specified
                        if r_cmd_ack = '1' then
                            r_tx_dat(0) <= '1';
                        else
                            r_tx_dat(0) <= n_rx_dat(0);
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process proc_debug_fsm;

    n_zero_count <= nor_reduce(r_byte_count);

    o_cyc        <= r_cyc;
    o_we         <= r_we;
    o_adr        <= r_adr;
    o_dat        <= r_dat;
    o_dbg_active <= r_dbg_active;
    
end architecture rtl;