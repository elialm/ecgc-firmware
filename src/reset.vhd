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
    generic (
        RESET_FF    : positive := 8);
    port (
        SYNC_CLK 	: in std_logic;
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

    component FD1P3AY is
    port (
        D   : in std_logic;
        SP  : in std_logic;
        CK  : in std_logic;
        Q   : out std_logic);
    end component;

    signal ff_stages    : std_logic_vector(RESET_FF-1 downto 0);

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

    -- GSR preset FF used for reset pulse
    GSR_RST_FF_0 : component FD1P3AY
    port map (
        D => '0',
        SP => '1',
        CK => SYNC_CLK,
        Q => ff_stages(0));

    GSR_RST_FF_STAGES : for i in 1 to RESET_FF-1 generate
        GSR_RST_FF_X : component FD1P3AY
        port map (
            D => ff_stages(i-1),
            SP => '1',
            CK => SYNC_CLK,
            Q => ff_stages(i));
    end generate;

    -- Sychronise EXT_SOFT
    EXT_SOFT_SYNCHRONISER : component synchroniser
    port map (
        CLK => SYNC_CLK,
        RST => ff_stages(ff_stages'high),
        DAT_IN(0) => EXT_SOFT,
        DAT_OUT(0) => ext_soft_sync);

    -- Delay the Auxilary reset
    process (SYNC_CLK)
    begin
        if rising_edge(SYNC_CLK) then
            if ff_stages(ff_stages'high) = '1' then
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
    HARD_RESET <= ff_stages(ff_stages'high);
	
end behaviour;
