----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 27/11/2023 17:10:40 PM
-- Design Name: Testbench for the as1c8m16pl_controller
-- Module Name: as1c8m16pl_controller_tb - rtl
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity as1c8m16pl_controller_tb is
end entity as1c8m16pl_controller_tb;

architecture rtl of as1c8m16pl_controller_tb is

    component as1c8m16pl_controller
        generic (
            p_clk_freq : real := 100.0
        );
        port (
            i_clk      : in std_logic;
            i_rst      : in std_logic;
            i_cyc      : in std_logic;
            i_we       : in std_logic;
            o_ack      : out std_logic;
            i_adr      : in std_logic_vector(23 downto 0);
            i_tga      : in std_logic_vector(0 downto 0);
            i_dat      : in std_logic_vector(7 downto 0);
            o_dat      : out std_logic_vector(7 downto 0);
            io_ram_adq : inout std_logic_vector(15 downto 0);
            o_ram_a    : out std_logic_vector(5 downto 0);
            o_ram_advn : out std_logic;
            o_ram_ce0n : out std_logic;
            o_ram_ce1n : out std_logic;
            o_ram_clk  : out std_logic;
            o_ram_cre  : out std_logic;
            o_ram_lbn  : out std_logic;
            o_ram_ubn  : out std_logic;
            o_ram_oen  : out std_logic;
            i_ram_wait : in std_logic;
            o_ram_wen  : out std_logic
        );
    end component;

    signal n_clk : std_logic := '0';
    signal n_rst : std_logic := '1';
    signal n_cyc : std_logic := '0';
    signal n_we : std_logic := '0';
    signal n_ack : std_logic;
    signal n_adr : std_logic_vector(23 downto 0);
    signal n_tga : std_logic_vector(0 downto 0);
    signal n_din : std_logic_vector(7 downto 0);
    signal n_dout : std_logic_vector(7 downto 0);
    signal n_ram_adq : std_logic_vector(15 downto 0);
    signal n_ram_a : std_logic_vector(5 downto 0);
    signal n_ram_advn : std_logic;
    signal n_ram_ce0n : std_logic;
    signal n_ram_ce1n : std_logic;
    signal n_ram_clk : std_logic;
    signal n_ram_cre : std_logic;
    signal n_ram_lbn : std_logic;
    signal n_ram_ubn : std_logic;
    signal n_ram_oen : std_logic;
    signal n_ram_wait : std_logic := '0';
    signal n_ram_wen : std_logic;

begin

    n_clk <= not(n_clk) after 5 ns;
    n_rst <= '1', '0' after 160 ns;

    -- simulate ram driving ADQ on OE#
    process
    begin
        n_ram_adq <= (others => 'Z');

        wait on n_ram_oen until n_ram_oen = '0';
        wait for 20 ns - 1 ps;
        n_ram_adq <= x"1234";
        wait on n_ram_oen until n_ram_oen = '1';
        wait for 7 ns;
    end process;

    process
    begin
        wait on n_clk until n_clk = '1' and n_rst = '0';

        -- test register write
        n_cyc <= '1';
        n_we <= '1';
        n_tga(0) <= '1';
        n_adr <= (others => '0'); -- address can be whatever
        n_din <= x"35";
        wait on n_clk until n_clk = '1' and n_ack = '1';
        n_din <= x"AC";
        wait on n_clk until n_clk = '1' and n_ack = '1';
        n_din <= x"2F";
        wait on n_clk until n_clk = '1' and n_ack = '1';
        n_cyc <= '0';
        n_we <= '0';
        n_tga(0) <= '0';

        -- wait a bit for the core to write to register
        wait for 100 ns;

        -- test register read (lower byte)
        n_cyc <= '1';
        n_tga(0) <= '1';
        -- bit 0 = upper or lower byte of register
        -- bits 20:19 = select register (see datasheet)
        n_adr <= (0 => '0', others => '0');
        wait on n_clk until n_clk = '1' and n_ack = '1';
        n_cyc <= '0';
        n_tga(0) <= '0';

        -- test register read (upper byte)
        n_cyc <= '1';
        n_tga(0) <= '1';
        n_adr <= (0 => '1', others => '0');
        wait on n_clk until n_clk = '1' and n_ack = '1';
        n_cyc <= '0';
        n_tga(0) <= '0';

        -- test normal write (LBN, CSN0)
        n_cyc <= '1';
        n_we <= '1';
        n_adr <= x"402010";
        n_din <= x"55";
        wait on n_clk until n_clk = '1' and n_ack = '1';
        n_cyc <= '0';
        n_we <= '0';

        -- wait a bit for the core to write to memory
        wait for 100 ns;

        -- test normal write (UBN, CSN1)
        n_cyc <= '1';
        n_we <= '1';
        n_adr <= x"F02013";
        n_din <= x"55";
        wait on n_clk until n_clk = '1' and n_ack = '1';
        n_cyc <= '0';
        n_we <= '0';

        -- wait a bit for the core to write to memory
        wait for 100 ns;

        -- test normal read (LBN, CSN1)
        n_cyc <= '1';
        n_adr <= x"802010";
        wait on n_clk until n_clk = '1' and n_ack = '1';
        n_cyc <= '0';
        n_we <= '0';

        -- test normal read (UBN, CSN0)
        n_cyc <= '1';
        n_adr <= x"402011";
        wait on n_clk until n_clk = '1' and n_ack = '1';
        n_cyc <= '0';
        n_we <= '0';

        wait;
    end process;

    inst_ram_controller : as1c8m16pl_controller
    port map(
        i_clk      => n_clk,
        i_rst      => n_rst,
        i_cyc      => n_cyc,
        i_we       => n_we,
        o_ack      => n_ack,
        i_adr      => n_adr,
        i_tga      => n_tga,
        i_dat      => n_dat,
        o_dat      => n_dat,
        io_ram_adq => no_ram_adq,
        o_ram_a    => n_ram_a,
        o_ram_advn => n_ram_advn,
        o_ram_ce0n => n_ram_ce0n,
        o_ram_ce1n => n_ram_ce1n,
        o_ram_clk  => n_ram_clk,
        o_ram_cre  => n_ram_cre,
        o_ram_lbn  => n_ram_lbn,
        o_ram_ubn  => n_ram_ubn,
        o_ram_oen  => n_ram_oen,
        i_ram_wait => n_ram_wait,
        o_ram_wen  => n_ram_wen
    );

end architecture rtl;