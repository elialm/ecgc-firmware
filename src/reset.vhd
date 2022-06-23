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
        EXT_SOFT    : in std_logic;     -- Connected to reset button
        AUX_SOFT    : in std_logic;     -- Connected to hypervisor reset
        GB_RESETN   : out std_logic;    -- Connected to GB_RST pin
        HYPER_VISOR_RESET   : out std_logic;    -- Connected to hypervisor reset
        PERIPHERAL_RESET    : out std_logic);   -- Connected to all RST(_I)?
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

    signal ext_soft_sync    : std_logic;

    signal reset_counter    : std_logic_vector(3 downto 0) := (others => '0');
    signal in_hard_reset    : std_logic;
    signal in_soft_reset    : std_logic;

begin

    -- Hard reset is released first, then soft reset
    in_hard_reset <= not(reset_counter(reset_counter'high));
    in_soft_reset <= nand_reduce(reset_counter);

    process (SYNC_CLK)
    begin
        if rising_edge(SYNC_CLK) then
            if in_soft_reset = '1' then
                reset_counter <= std_logic_vector(unsigned(reset_counter) + 1);
            end if;

            if (ext_soft_sync or AUX_SOFT) = '1' then
                reset_counter <= (reset_counter'high => '1', others => '0');
            end if;
        end if;
    end process;

    -- Sychronise EXT_SOFT
    EXT_SOFT_SYNCHRONISER : component synchroniser
    port map (
        CLK => SYNC_CLK,
        RST => in_hard_reset,
        DAT_IN(0) => EXT_SOFT,
        DAT_OUT(0) => ext_soft_sync);

    GB_RESETN <= not(in_soft_reset);
    HYPER_VISOR_RESET <= in_soft_reset;
    PERIPHERAL_RESET <= in_hard_reset;
	
end behaviour;
