----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 23/02/2024 12:33:25 PM
-- Design Name: SPI core testbench
-- Module Name: spi_core)tb - sim
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spi_core_tb is
end entity spi_core_tb;

architecture sim of spi_core_tb is

    component spi_core
        generic (
            p_cs_count : positive := 1;
            p_cs_release_value : std_logic := '1'
        );
        port (
            i_clk       : in std_logic;
            i_rst       : in std_logic;
            i_cyc       : in std_logic;
            o_ack       : out std_logic;
            i_we        : in std_logic;
            i_adr       : in std_logic_vector(1 downto 0);
            o_dat       : out std_logic_vector(7 downto 0);
            i_dat       : in std_logic_vector(7 downto 0);
            io_spi_clk  : inout std_logic;
            io_spi_mosi : inout std_logic;
            io_spi_miso : inout std_logic;
            io_spi_csn  : inout std_logic_vector(p_cs_count - 1 downto 0)
        );
    end component;

    signal n_clk      : std_logic := '0';
    signal n_rst      : std_logic;
    signal n_cyc      : std_logic := '0';
    signal n_ack      : std_logic;
    signal n_we       : std_logic;
    signal n_adr      : std_logic_vector(1 downto 0);
    signal n_dat_i    : std_logic_vector(7 downto 0);
    signal n_dat_o    : std_logic_vector(7 downto 0);
    signal n_spi_clk  : std_logic;
    signal n_spi_mosi : std_logic;
    signal n_spi_miso : std_logic;
    signal n_spi_csn  : std_logic;
    
begin
    
    n_clk <= not(n_clk) after 10 ns;
    n_rst <= '1', '0' after 160 ns;

    proc_testbench : process
    begin
        n_spi_miso <= '0';
        wait on n_clk until n_clk = '1' and n_rst = '0';

        assert n_ack = '0' report "Unexpected initial condition: n_ack /= '0'" severity ERROR;
        assert n_spi_clk = 'Z' report "Unexpected initial condition: n_spi_clk /= 'Z'" severity ERROR;
        assert n_spi_csn = '1' report "Unexpected initial condition: n_spi_csn /= '1'" severity ERROR;

        -- enable core
        n_cyc <= '1';
        n_we <= '1';
        n_dat_i <= "00000001";
        n_adr <= "00";
        wait on n_clk until n_clk = '1' and n_ack = '1';

        -- assert cs
        n_adr <= "10";
        n_dat_i <= "11111110";
        wait on n_clk until n_clk = '1' and n_ack = '1';

        -- write data and read zeros
        n_adr <= "11";
        n_dat_i <= x"55";
        wait on n_clk until n_clk = '1' and n_ack = '1';
        n_cyc <= '0';

        -- wait a bit for the data to be sent
        wait for 400 ns;

        -- read received data
        n_cyc <= '1';
        n_we <= '0';
        n_adr <= "11";
        wait on n_clk until n_clk = '1' and n_ack = '1';
        n_cyc <= '0';

        assert n_dat_o = x"00" report "Unexpected data received: expected 0x00, got 0x"
            & to_hstring(to_bitvector(n_dat_o)) severity ERROR;

        -- write data and read ones
        n_spi_miso <= '1';
        n_cyc <= '1';
        n_we <= '1';
        n_adr <= "11";
        n_dat_i <= x"AA";
        wait on n_clk until n_clk = '1' and n_ack = '1';
        n_cyc <= '0';

        -- wait a bit for the data to be sent
        wait for 400 ns;

        -- read received data
        n_cyc <= '1';
        n_we <= '0';
        n_adr <= "11";
        wait on n_clk until n_clk = '1' and n_ack = '1';
        n_cyc <= '0';

        assert n_dat_o = x"FF" report "Unexpected data received: expected 0xFF, got 0x"
            & to_hstring(to_bitvector(n_dat_o)) severity ERROR;

        wait;
    end process proc_testbench;

    inst_spi_core : spi_core
    port map(
        i_clk         => n_clk,
        i_rst         => n_rst,
        i_cyc         => n_cyc,
        o_ack         => n_ack,
        i_we          => n_we,
        i_adr         => n_adr,
        o_dat         => n_dat_o,
        i_dat         => n_dat_i,
        io_spi_clk    => n_spi_clk,
        io_spi_mosi   => n_spi_mosi,
        io_spi_miso   => n_spi_miso,
        io_spi_csn(0) => n_spi_csn
    );
    
end architecture sim;