----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 06/22/2022 17:03:42 PM
-- Design Name: Reset controller
-- Module Name: reset - behaviour
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Documentation
--
-- Not working :(
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity reset is
    port (
        SYNC_CLK 	: in std_logic;
        PUR         : in std_logic;
        EXT_SOFT    : in std_logic;     -- Connected to reset button
        AUX_SOFT    : in std_logic;     -- Connected to hypervisor reset

        GB_RESETN   : out std_logic;    -- Connected to GB_RST pin
        SOFT_RESET  : out std_logic;    -- Connected to hypervisor reset
        HARD_RESET  : out std_logic);   -- Connected to all RST(_I)?
end reset;

architecture behaviour of reset is

    component synchroniser is
    generic (
        FF_COUNT : natural := 2;
        DATA_WIDTH : natural := 1;
        RESET_VALUE : std_logic := '1');
    port (
        CLK : in std_logic;
        RST : in std_logic;
        DAT_IN : in std_logic_vector(DATA_WIDTH-1 downto 0);
        DAT_OUT : out std_logic_vector(DATA_WIDTH-1 downto 0));
    end component;

    signal soft_reset_s     : std_logic;
    signal ext_soft_sync    : std_logic;
    signal pur_sync         : std_logic;
    signal ps_0             : std_logic;
    signal ps_1             : std_logic;

    -- Auxilary reset delay
    signal aux_d1   : std_logic;
    signal aux_d2   : std_logic;
    signal aux_d3   : std_logic;

begin

    -- Sychronise PUR
    process (SYNC_CLK, PUR)
    begin
        if PUR = '1' then
            pur_sync <= '1';
            ps_0 <= '1';
            ps_1 <= '1';
        elsif rising_edge(SYNC_CLK) then
            ps_0 <= '0';
            ps_1 <= ps_0;
            pur_sync <= ps_1;
        end if;
    end process;

    -- Sychronise EXT_SOFT
    EXT_SOFT_SYNCHRONISER : component synchroniser
    port map (
        CLK => SYNC_CLK,
        RST => pur_sync,
        DAT_IN(0) => EXT_SOFT,
        DAT_OUT(0) => ext_soft_sync);

    -- Delay the Auxilary reset
    process (SYNC_CLK)
    begin
        if rising_edge(SYNC_CLK) then
            if pur_sync = '1' then
                aux_d1 <= '1';
                aux_d2 <= '1';
                aux_d3 <= '1';
            else
                aux_d1 <= AUX_SOFT;
                aux_d2 <= aux_d1;
                aux_d3 <= aux_d2;
            end if;
        end if;
    end process;

    soft_reset_s <= ext_soft_sync or aux_d3;

    GB_RESETN <= not(soft_reset_s);
    SOFT_RESET <= soft_reset_s;
    HARD_RESET <= pur_sync;
	
end behaviour;
