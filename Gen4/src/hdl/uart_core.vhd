----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 01/03/2024 14:38:20 PM
-- Design Name: Serial Transmitter
-- Module Name: uart_core - rtl
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
use IEEE.math_real.all;

entity uart_core is
    generic (
        p_clk_freq : real := 100.0;
        p_baud_rate : natural := 115200;
        p_parity : string := "NONE";
        p_data_bits : natural := 8;
        p_stop_bits : natural := 1
    );
    port (
        -- Clocking and reset
        i_clk : in std_logic;
        i_rst : in std_logic;

        -- Master port for rx data
        i_tx_wr  : in std_logic;
        i_tx_dat : in std_logic_vector(p_data_bits - 1 downto 0);
        o_tx_rdy : out std_logic;

        -- Slave port for tx data
        i_rx_rd  : in std_logic;
        o_rx_dat : out std_logic_vector(p_data_bits - 1 downto 0);
        o_rx_rdy : out std_logic;

        -- Serial signals
        o_serial_tx : out std_logic;
        i_serial_rx : in std_logic
    );
end entity uart_core;

architecture rtl of uart_core is

    constant c_exact_baud_divider : real := (p_clk_freq * 1_000_000.0 / real(p_baud_rate)) - 1.0;
    constant c_rounded_baud_divider : natural := natural(round(c_exact_baud_divider));
    constant c_rounded_baud_divider_div4 : natural := natural(round((real(c_rounded_baud_divider) / 4.0)));
    constant c_baud_difference_percentage : real := ((real(c_rounded_baud_divider) - c_exact_baud_divider) / c_exact_baud_divider) * 100.0;

    component synchroniser is
        generic (
            p_ff_count : natural := 2;
            p_data_width : natural := 1;
            p_reset_value : std_logic := '1'
        );
        port (
            i_clk  : in std_logic;
            i_rst  : in std_logic;
            i_din  : in std_logic_vector(p_data_width - 1 downto 0);
            o_dout : out std_logic_vector(p_data_width - 1 downto 0)
        );
    end component;

    function reverse(a: std_logic_vector)
    return std_logic_vector is
        variable result: std_logic_vector(a'range);
        alias aa : std_logic_vector(a'reverse_range) is a;
    begin
        for i in aa'range loop
            result(i) := aa(i);
        end loop;

        return result;
    end function;

    function create_slv_with_value(len: natural; val: std_logic)
    return std_logic_vector is
        variable result: std_logic_vector(len - 1 downto 0);
    begin
        for i in result'range loop
            result(i) := val;
        end loop;

        return result;
    end function;

    subtype t_tx_baud_divider is integer range 0 to c_rounded_baud_divider;
    subtype t_tx_bit_counter is integer range 0 to (p_data_bits + p_stop_bits + 1);
    subtype t_rx_baud_divider is integer range 0 to c_rounded_baud_divider_div4;
    subtype t_rx_event_counter is integer range 0 to 3;
    subtype t_rx_bit_counter is integer range 0 to (p_data_bits + p_stop_bits);

    signal r_tx_baud_divider : t_tx_baud_divider;
    signal r_tx_bit_counter : t_tx_bit_counter;
    signal r_tx_event : std_logic;
    signal r_tx_read_data : std_logic;

    signal r_rx_baud_divider : t_rx_baud_divider;
    signal r_rx_event_counter : t_rx_event_counter;
    signal r_rx_bit_counter : t_rx_bit_counter;
    signal r_rx_event_sample : std_logic;
    signal r_rx_event_shift : std_logic;
    signal r_rx_event_data : std_logic;
    signal r_rx_in_progress : std_logic;
    signal n_serial_rx_sync : std_logic;

    signal r_rx_samples : std_logic_vector(2 downto 0);
    signal r_rx_bits : std_logic_vector(p_data_bits - 2 downto 0);
    signal r_rx_data : std_logic_vector(p_data_bits - 1 downto 0);
    signal r_rx_data_present : std_logic;
    signal r_tx_bits : std_logic_vector(p_data_bits + p_stop_bits downto 0);

    signal r_tx_data : std_logic_vector(p_data_bits - 1 downto 0);
    signal r_tx_ready : std_logic;

begin

    assert p_data_bits >= 5 and p_data_bits <= 8 report "p_data_bits must be within 5 and 8 bits" severity FAILURE;
    assert p_stop_bits = 1 or p_stop_bits = 2 report "p_stop_bits must be either 1 or 2 bits" severity FAILURE;
    assert p_parity = "NONE" report "Current p_parity value is unsupported, only NONE is supported" severity FAILURE;

    -- report on baud difference for debug
    assert 1 = 0 report "baud rate difference ~= " & to_string(c_baud_difference_percentage, "%.2f") & "%" severity NOTE;
    assert abs(c_baud_difference_percentage) < 10.0 report "Unsupported baud rate, difference exceeds tolerated value of 10%, currently about " & to_string(c_baud_difference_percentage, "%.2f") & "%" severity FAILURE;

    inst_rx_synchroniser : synchroniser
    port map(
        i_clk     => i_clk,
        i_rst     => i_rst,
        i_din(0)  => i_serial_rx,
        o_dout(0) => n_serial_rx_sync
    );

    proc_tx_baud_generation : process (i_clk)
    begin
        if rising_edge(i_clk) then
            r_tx_read_data <= '0';

            if i_rst = '1' then
                r_tx_baud_divider <= c_rounded_baud_divider;
                r_tx_bit_counter <= 0;
                r_tx_event <= '0';
            else
                if r_tx_bit_counter = 0 then
                    -- set r_tx_bit_counter when write data has been received
                    if r_tx_ready = '0' then
                        -- + 1 for the start bit
                        r_tx_bit_counter <= p_data_bits + p_stop_bits + 1;
                        r_tx_read_data <= '1';
                    end if;
                else
                    -- handle the counters for the event signal
                    if r_tx_baud_divider /= 0 then
                        r_tx_baud_divider <= r_tx_baud_divider - 1;
                        r_tx_event <= '0';
                    else
                        r_tx_baud_divider <= c_rounded_baud_divider;
                        r_tx_bit_counter <= r_tx_bit_counter - 1;
                        r_tx_event <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process proc_tx_baud_generation;

    proc_rx_baud_generation : process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                r_rx_baud_divider <= c_rounded_baud_divider_div4;
                r_rx_event_counter <= 3;
                r_rx_bit_counter <= p_data_bits;
                r_rx_in_progress <= '0';
                r_rx_event_sample <= '0';
                r_rx_event_shift <= '0';
                r_rx_event_data <= '0';
            else
                -- latch r_rx_in_progress when rx = '0'
                -- will trigger upon start bit and be left alone during stop bits
                if (n_serial_rx_sync = '0') then
                    r_rx_in_progress <= '1';
                end if;

                -- handle the different counters for the event signals
                r_rx_event_sample <= '0';
                if r_rx_in_progress = '1' then
                    if r_rx_baud_divider /= 0 then
                        r_rx_baud_divider <= r_rx_baud_divider - 1;
                    else
                        r_rx_baud_divider <= c_rounded_baud_divider_div4;
                        r_rx_event_sample <= '1';

                        if r_rx_event_counter /= 0 then
                            r_rx_event_counter <= r_rx_event_counter - 1;
                            r_rx_event_shift <= '0';
                        else
                            r_rx_event_counter <= 3;
                            r_rx_event_shift <= '1';

                            if r_rx_bit_counter /= 0 then
                                r_rx_bit_counter <= r_rx_bit_counter - 1;
                                r_rx_event_data <= '0';
                            else
                                r_rx_bit_counter <= p_data_bits;
                                r_rx_event_data <= '1';
                                r_rx_in_progress <= '0';
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process proc_rx_baud_generation;

    proc_serial_processing: process(i_clk)
        variable v_filtered_bit : std_logic;
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                r_rx_samples <= (others => '0');
                r_rx_bits <= (others => '0');
                r_rx_data <= (others => '0');
                r_rx_data_present <= '0';
                r_tx_bits <= (others => '1');
            else
                -- on rx read
                if i_rx_rd = '1' then
                    r_rx_data_present <= '0';
                end if;

                -- on rx sample event, sample serial rx
                if r_rx_event_sample = '1' then
                    r_rx_samples <= r_rx_samples(1 downto 0) & n_serial_rx_sync;

                    -- on shift event, filter samples into 1 bit and shift that in
                    if r_rx_event_shift = '1' then
                        -- filter samples to be of most occuring value
                        case r_rx_samples is
                            when "000" => v_filtered_bit := '0';
                            when "001" => v_filtered_bit := '0';
                            when "010" => v_filtered_bit := '0';
                            when "011" => v_filtered_bit := '1';
                            when "100" => v_filtered_bit := '0';
                            when "101" => v_filtered_bit := '1';
                            when "110" => v_filtered_bit := '1';
                            when others => v_filtered_bit := '1';   -- "111"
                        end case;
    
                        r_rx_bits <= v_filtered_bit & r_rx_bits(r_rx_bits'high downto 1);

                        -- on data event, write contents of bit shift register into wb dout register
                        if r_rx_event_data = '1' then
                            r_rx_data <= v_filtered_bit & r_rx_bits;
                            r_rx_data_present <= '1';
                        end if;
                    end if;
                end if;

                -- on tx event, shift out data
                if r_tx_event = '1' then
                    r_tx_bits <= '1' & r_tx_bits(r_tx_bits'high downto 1);
                end if;

                -- on new tx data
                if r_tx_read_data = '1' then
                    r_tx_bits <= create_slv_with_value(p_stop_bits, '1') & r_tx_data & '0';
                end if;
            end if;
        end if;
    end process proc_serial_processing;

    proc_tx_port : process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                r_tx_data <= (others => '0');
                r_tx_ready <= '1';
            else
                -- handle tx ready clear
                if r_tx_read_data = '1' then
                    r_tx_ready <= '1';
                end if;

                -- handle tx wr port
                if (i_tx_wr and r_tx_ready) = '1' then
                    r_tx_ready <= '0';
                    r_tx_data <= i_tx_dat;
                end if;
            end if;
        end if;
    end process proc_tx_port;

    o_tx_rdy <= r_tx_ready;
    o_rx_dat <= r_rx_data;
    o_rx_rdy <= r_rx_data_present;
    o_serial_tx <= r_tx_bits(0);

end architecture rtl;