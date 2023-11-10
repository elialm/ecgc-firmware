----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 03/31/2022 04:10:42 PM
-- Design Name: Gameboy bus decoder
-- Module Name: gb_decoder - behaviour
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_misc.all;
use IEEE.math_real.all;

entity gb_decoder is
    generic (
        ENABLE_TIMEOUT_DETECTION : boolean := false;
        CLK_FREQ : real := 53.20);
    port (
        -- Gameboy signals
        GB_CLK      : in std_logic;
        GB_ADDR     : in std_logic_vector(15 downto 0);
        GB_DATA_IN  : in std_logic_vector(7 downto 0);
        GB_DATA_OUT : out std_logic_vector(7 downto 0);
        GB_RDN      : in std_logic;
        GB_CSN      : in std_logic;

        -- Wishbone signals
        CLK_I : in std_logic;
        RST_I : in std_logic;
        CYC_O : out std_logic;
        WE_O  : out std_logic;
        ADR_O : out std_logic_vector(15 downto 0);
        DAT_I : in std_logic_vector(7 downto 0);
        DAT_O : out std_logic_vector(7 downto 0);
        ACK_I : in std_logic;

        ACCESS_ROM    : out std_logic;  -- Indicates when address range 0x0000-0x7FFF is being accessed. Only valid when CYC_O = 1.
        ACCESS_RAM    : out std_logic;  -- Indicates when address range 0xA000-0xBFFF is being accessed. Only valid when CYC_O = 1.
        WR_TIMEOUT    : out std_logic;  -- Indicates that a write timeout has occurred. Asserting RST_I will reset this back to 0.
        RD_TIMEOUT    : out std_logic); -- Indicates that a read timeout has occurred. Asserting RST_I will reset this back to 0.
end gb_decoder;

architecture behaviour of gb_decoder is

    type GAMEBOY_BUS_STATE_TYPE is (GBBS_AWAIT_ACCESS_FINISHED, GBBS_IDLE, GBBS_READ_AWAIT_ACK, GBBS_WRITE_AWAIT_FALLING_EDGE, GBBS_WRITE_AWAIT_ACK);

    constant CYC_COUNTER_READ : std_logic_vector(3 downto 0) := "1000"; -- 9 cycles
    constant CYC_COUNTER_WRITE : std_logic_vector(3 downto 0) := "1000"; -- 9 cycles (I think)
    constant RBLOCK_COUNTER_BITS : positive := positive(ceil(log2(0.5 * CLK_FREQ))); -- T = half GB clock cycle

    -- Take time in ns and convert to value to be used in a timer
    function to_tcomp_ns(tns : real; bc : positive)
        return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(natural(ceil(tns * CLK_FREQ / 1000.00)), bc));
    end to_tcomp_ns;

    constant T_COMP_RBLOCK : std_logic_vector(RBLOCK_COUNTER_BITS - 1 downto 0) := to_tcomp_ns(500.0, RBLOCK_COUNTER_BITS);

    component synchroniser is
        generic (
            FF_COUNT : natural := 2;
            DATA_WIDTH : natural := 1;
            RESET_VALUE : std_logic := '0');
        port (
            CLK     : in std_logic;
            RST     : in std_logic;
            DAT_IN  : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            DAT_OUT : out std_logic_vector(DATA_WIDTH - 1 downto 0));
    end component;

    -- Synchronised signals from GameBoy
    signal gb_clk_sync : std_logic;
    signal gb_csn_sync : std_logic;
    signal gb_addr_sync : std_logic_vector(2 downto 0);

    -- Access signals (combinatorial)
    signal gb_access_rom : std_logic;
    signal gb_access_ram : std_logic;
    signal gb_access_cart : std_logic;

    signal gb_bus_state : GAMEBOY_BUS_STATE_TYPE;

    signal cyc_counter : std_logic_vector(3 downto 0);
    signal cyc_timeout : std_logic;
    signal wb_cyc_o : std_logic;

begin

    ADDRESS_SYNCHRONISER : component synchroniser
        generic map(
            DATA_WIDTH => 3)
        port map(
            CLK     => CLK_I,
            RST     => RST_I,
            DAT_IN  => GB_ADDR(15 downto 13),
            DAT_OUT => gb_addr_sync);

    CLK_SYNCHRONISER : component synchroniser
        port map(
            CLK        => CLK_I,
            RST        => RST_I,
            DAT_IN(0)  => GB_CLK,
            DAT_OUT(0) => gb_clk_sync);

    CSN_SYNCHRONISER : component synchroniser
        port map(
            CLK        => CLK_I,
            RST        => RST_I,
            DAT_IN(0)  => GB_CSN,
            DAT_OUT(0) => gb_csn_sync);

    -- Signals for determining type of access
    gb_access_rom <= not(gb_addr_sync(2)); -- 0x0000 - 0x7FFF
    gb_access_ram <= not(gb_csn_sync)
        and gb_addr_sync(2)
        and not(gb_addr_sync(1))
        and gb_addr_sync(0); -- 0xA000 - 0xBFFF
    gb_access_cart <= gb_access_rom or gb_access_ram;

    ACCESS_ROM <= gb_access_rom;
    ACCESS_RAM <= gb_access_ram;

    CYC_O <= wb_cyc_o;

    -- Control Wishbone cycles
    process (CLK_I)
    begin
        if rising_edge(CLK_I) then
            if RST_I = '1' then
                gb_bus_state <= GBBS_AWAIT_ACCESS_FINISHED;
                cyc_counter <= (others => '1');
                wb_cyc_o <= '0';

                WE_O <= '0';
                ADR_O <= (others => '0');
                DAT_O <= (others => '0');
                GB_DATA_OUT <= (others => '0');
                RD_TIMEOUT <= '0';
                WR_TIMEOUT <= '0';
            else
                -- Bus decoder state machine
                case gb_bus_state is
                    when GBBS_AWAIT_ACCESS_FINISHED =>
                        if gb_access_cart = '0' then
                            gb_bus_state <= GBBS_IDLE;
                        end if;

                    when GBBS_IDLE =>
                        if gb_access_cart = '1' then
                            if GB_RDN = '0' then
                                -- Initiate read from cart
                                gb_bus_state <= GBBS_READ_AWAIT_ACK;
                                wb_cyc_o <= '1';
                                WE_O <= '0';
                                cyc_counter <= CYC_COUNTER_READ;
                            else
                                -- Initiate write to cart
                                gb_bus_state <= GBBS_WRITE_AWAIT_FALLING_EDGE;
                            end if;

                            ADR_O <= GB_ADDR;
                        end if;

                    when GBBS_READ_AWAIT_ACK =>
                        if ACK_I = '1' then
                            gb_bus_state <= GBBS_AWAIT_ACCESS_FINISHED;
                            wb_cyc_o <= '0';
                            GB_DATA_OUT <= DAT_I;
                        end if;

                        if cyc_timeout = '1' then
                            RD_TIMEOUT <= '1';
                        end if;

                    when GBBS_WRITE_AWAIT_FALLING_EDGE =>
                        if gb_clk_sync = '0' then
                            gb_bus_state <= GBBS_WRITE_AWAIT_ACK;
                            wb_cyc_o <= '1';
                            WE_O <= '1';
                            DAT_O <= GB_DATA_IN;
                            cyc_counter <= CYC_COUNTER_WRITE;
                        end if;

                    when GBBS_WRITE_AWAIT_ACK =>
                        if ACK_I = '1' then
                            gb_bus_state <= GBBS_AWAIT_ACCESS_FINISHED;
                            wb_cyc_o <= '0';
                        end if;

                        if cyc_timeout = '1' then
                            WR_TIMEOUT <= '1';
                        end if;

                    when others =>
                        gb_bus_state <= GBBS_AWAIT_ACCESS_FINISHED;
                        wb_cyc_o <= '0';
                end case;
            end if;

            -- Decrement timeout counter
            if cyc_timeout = '0' and ENABLE_TIMEOUT_DETECTION then
                cyc_counter <= std_logic_vector(unsigned(cyc_counter) - 1);
            end if;
        end if;
    end process;

    CYC_TIMEOUT_SIGNAL : if ENABLE_TIMEOUT_DETECTION generate
        cyc_timeout <= nor_reduce(cyc_counter);
    else generate
        cyc_timeout <= '0';
    end generate;

end behaviour;