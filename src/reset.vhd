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
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;

entity reset is
    port (
        SYNC_CLK 	: in std_logic;
        EXT_HARD    : in std_logic;     -- Connected to DONE pin?
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
        RESET_VALUE : std_logic := '0');
    port (
        CLK : in std_logic;
        RST : in std_logic;
        DAT_IN : in std_logic_vector(DATA_WIDTH-1 downto 0);
        DAT_OUT : out std_logic_vector(DATA_WIDTH-1 downto 0));
    end component;

    signal ext_hard_sync    : std_logic;
    signal ext_soft_sync    : std_logic;

begin

    -- ???
    -- Resets need to be async, I think...
	EXT_SOFT_SYNCHRONISER : component synchroniser
    port map (
        CLK => SYNC_CLK,
        RST => EXT_HARD,
        DAT_IN => ,
        DAT_OUT => 
    );
	
end behaviour;
