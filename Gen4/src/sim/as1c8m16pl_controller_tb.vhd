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
            CLK_FREQ : real := 100.0
        );
        port (
            CLK_I    : in std_logic;
            RST_I    : in std_logic;
            CYC_I    : in std_logic;
            WE_I     : in std_logic;
            ACK_O    : out std_logic;
            ADR_I    : in std_logic_vector(23 downto 0);
            TGA_I    : in std_logic_vector(0 downto 0);
            DAT_I    : in std_logic_vector(7 downto 0);
            DAT_O    : out std_logic_vector(7 downto 0);
            RAM_ADQ  : inout std_logic_vector(15 downto 0);
            RAM_A    : out std_logic_vector(5 downto 0);
            RAM_ADVN : out std_logic;
            RAM_CE0N : out std_logic;
            RAM_CE1N : out std_logic;
            RAM_CLK  : out std_logic;
            RAM_CRE  : out std_logic;
            RAM_LBN  : out std_logic;
            RAM_UBN  : out std_logic;
            RAM_OEN  : out std_logic;
            RAM_WAIT : in std_logic;
            RAM_WEN  : out std_logic
        );
    end component;

    signal clk_i : std_logic := '0';
    signal rst_i : std_logic := '1';
    signal cyc_i : std_logic := '0';
    signal we_i : std_logic := '0';
    signal ack_o : std_logic;
    signal adr_i : std_logic_vector(23 downto 0);
    signal tga_i : std_logic_vector(0 downto 0);
    signal dat_i : std_logic_vector(7 downto 0);
    signal dat_o : std_logic_vector(7 downto 0);
    signal ram_adq : std_logic_vector(15 downto 0);
    signal ram_a : std_logic_vector(5 downto 0);
    signal ram_advn : std_logic;
    signal ram_ce0n : std_logic;
    signal ram_ce1n : std_logic;
    signal ram_clk : std_logic;
    signal ram_cre : std_logic;
    signal ram_lbn : std_logic;
    signal ram_ubn : std_logic;
    signal ram_oen : std_logic;
    signal ram_wait : std_logic := '0';
    signal ram_wen : std_logic;

begin

    clk_i <= not(clk_i) after 5 ns;
    rst_i <= '1', '0' after 160 ns;

    -- simulate ram driving ADQ on OE#
    process
    begin
        ram_adq <= (others => 'Z');

        wait on ram_oen until ram_oen = '0';
        wait for 20 ns - 1 ps;
        ram_adq <= x"1234";
        wait on ram_oen until ram_oen = '1';
        wait for 7 ns;
    end process;

    process
    begin
        wait on clk_i until clk_i = '1' and rst_i = '0';

        -- test register write
        cyc_i <= '1';
        we_i <= '1';
        tga_i(0) <= '1';
        adr_i <= (others => '0'); -- address can be whatever
        dat_i <= x"35";
        wait on clk_i until clk_i = '1' and ack_o = '1';
        dat_i <= x"AC";
        wait on clk_i until clk_i = '1' and ack_o = '1';
        dat_i <= x"2F";
        wait on clk_i until clk_i = '1' and ack_o = '1';
        cyc_i <= '0';
        we_i <= '0';
        tga_i(0) <= '0';

        -- wait a bit for the core to write to register
        wait for 100 ns;

        -- test register read (lower byte)
        cyc_i <= '1';
        tga_i(0) <= '1';
        -- bit 0 = upper or lower byte of register
        -- bits 20:19 = select register (see datasheet)
        adr_i <= (0 => '0', others => '0');
        wait on clk_i until clk_i = '1' and ack_o = '1';
        cyc_i <= '0';
        tga_i(0) <= '0';

        -- test register read (upper byte)
        cyc_i <= '1';
        tga_i(0) <= '1';
        adr_i <= (0 => '1', others => '0');
        wait on clk_i until clk_i = '1' and ack_o = '1';
        cyc_i <= '0';
        tga_i(0) <= '0';

        -- test normal write (LBN, CSN0)
        cyc_i <= '1';
        we_i <= '1';
        adr_i <= x"402010";
        dat_i <= x"55";
        wait on clk_i until clk_i = '1' and ack_o = '1';
        cyc_i <= '0';
        we_i <= '0';

        -- wait a bit for the core to write to memory
        wait for 100 ns;

        -- test normal write (UBN, CSN1)
        cyc_i <= '1';
        we_i <= '1';
        adr_i <= x"F02013";
        dat_i <= x"55";
        wait on clk_i until clk_i = '1' and ack_o = '1';
        cyc_i <= '0';
        we_i <= '0';

        -- wait a bit for the core to write to memory
        wait for 100 ns;

        -- test normal read (LBN, CSN1)
        cyc_i <= '1';
        adr_i <= x"802010";
        wait on clk_i until clk_i = '1' and ack_o = '1';
        cyc_i <= '0';
        we_i <= '0';

        -- test normal read (UBN, CSN0)
        cyc_i <= '1';
        adr_i <= x"402011";
        wait on clk_i until clk_i = '1' and ack_o = '1';
        cyc_i <= '0';
        we_i <= '0';

        wait;
    end process;

    inst_ram_controller : as1c8m16pl_controller
    port map(
        CLK_I    => clk_i,
        RST_I    => rst_i,
        CYC_I    => cyc_i,
        WE_I     => we_i,
        ACK_O    => ack_o,
        ADR_I    => adr_i,
        TGA_I    => tga_i,
        DAT_I    => dat_i,
        DAT_O    => dat_o,
        RAM_ADQ  => ram_adq,
        RAM_A    => ram_a,
        RAM_ADVN => ram_advn,
        RAM_CE0N => ram_ce0n,
        RAM_CE1N => ram_ce1n,
        RAM_CLK  => ram_clk,
        RAM_CRE  => ram_cre,
        RAM_LBN  => ram_lbn,
        RAM_UBN  => ram_ubn,
        RAM_OEN  => ram_oen,
        RAM_WAIT => ram_wait,
        RAM_WEN  => ram_wen
    );

end architecture rtl;