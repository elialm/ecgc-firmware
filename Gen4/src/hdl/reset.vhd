----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 06/22/2022 17:03:42 PM
-- Design Name: Reset controller
-- Module Name: reset - rtl
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Documentation
--
-- Uses some FF guaranteed to be 0 at startup to extend a reset pulse to
-- a couple of cycles. This generates a reset pulse to be transmitted to the
-- entire system at startup.
--
-- It also handles the soft reset. This reset will only reset a select number
-- of components. This used in many cases e.g. when switching active MBCs or
-- enabling/disabling the debug core. This enables part of the system to always
-- remain operational (e.g. the MBCH which needs to be able to keep track of
-- when the Gameboy resets for the bootloader to function properly).
--
-- The following happens during a soft reset:
--      - GB_RSTN is asserted low, putting the Gameboy in reset
--      - The active MBC is switched with the selected MBC written to MBCH_CFG0
--      - If the boot rom cut-off bit was set to '1', the following also happens
--          - MBCH will disallow access to boot rom
--          - Bank 0 will be used to access DRAM
--      - GB_RSTN is asserted high, allowing the Gameboy to boot
--
-- Signals capable of generating a soft reset are:
--      - MBCH using the RST bit in the MBCH_CTRL register, which pulses AUX_SOFT 
--      - Pressing the reset button, pulsing the USER_RESET signal
--      - Activating the debug core, asserting DBG_ACTIVE
--      - Deactivating the debug core, dissasserting DBG_ACTIVE
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity reset is
    generic (
        GSR_FF      : positive := 8;
        AUX_FF      : positive := 9;
        SIMULATION  : boolean := false);
    port (
        SYNC_CLK    : in std_logic;
        PLL_LOCK    : in std_logic;
        EXT_SOFT    : in std_logic;     -- Connected to reset button
        AUX_SOFT    : in std_logic;     -- Connected to hypervisor reset
        DBG_ACTIVE  : in std_logic;     -- Indicates debug core active

        GB_RESETN   : out std_logic;    -- Connected to GB_RST pin
        SOFT_RESET  : out std_logic;    -- Connected to hypervisor reset
        HARD_RESET  : out std_logic);   -- Connected to all RST(_I)?
end reset;

architecture rtl of reset is

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

    component FD1P3AY is
    port (
        D   : in std_logic;
        SP  : in std_logic;
        CK  : in std_logic;
        Q   : out std_logic);
    end component;

    signal soft_reset_s     : std_logic;
    signal hard_reset_s     : std_logic := '1';
    signal ext_soft_sync    : std_logic;
    signal soft_extender    : std_logic_vector(AUX_FF - 1 downto 0);
    signal gb_rst_extender  : std_logic_vector(8 downto 0);

    signal dbg_active_d     : std_logic;
    signal aux_internal     : std_logic;

begin

    -- Provide GSR while PLL is not locked
    process (SYNC_CLK)
    begin
        if rising_edge(SYNC_CLK) then
            if PLL_LOCK = '1' then
                hard_reset_s <= '0';
            end if;
        end if;
    end process;

    -- Sychronise EXT_SOFT
    EXT_SOFT_SYNCHRONISER : component synchroniser
    port map (
        CLK => SYNC_CLK,
        RST => hard_reset_s,
        DAT_IN(0) => EXT_SOFT,
        DAT_OUT(0) => ext_soft_sync
    );

    -- Extend soft reset to be some clock cycles long
    process (SYNC_CLK)
    begin
        if rising_edge(SYNC_CLK) then
            if (hard_reset_s or AUX_SOFT or aux_internal or ext_soft_sync) = '1' then
                soft_extender <= (others => '1');
            else
                soft_extender <= soft_extender(soft_extender'high - 1 downto 0) & '0';
            end if;
        end if;
    end process;

    -- Extend the Gameboy reset
    process (SYNC_CLK)
    begin
        if rising_edge(SYNC_CLK) then
            if (hard_reset_s or soft_reset_s) = '1' then
                gb_rst_extender <= (gb_rst_extender'high => '1', others => '0');
            else
                if gb_rst_extender(gb_rst_extender'high) = '1' then
                    gb_rst_extender <= std_logic_vector(unsigned(gb_rst_extender) + 1);
                end if;
            end if;
        end if;
    end process;

    -- Handle debug active
    process (SYNC_CLK)
    begin
        if rising_edge(SYNC_CLK) then
            if hard_reset_s then
                dbg_active_d <= '0';
            else
                dbg_active_d <= DBG_ACTIVE;
                aux_internal <= DBG_ACTIVE xor dbg_active_d;
            end if;
        end if;
    end process;

    soft_reset_s <= soft_extender(soft_extender'high);

    GB_RESETN <= not(gb_rst_extender(gb_rst_extender'high)) and not(DBG_ACTIVE);
    SOFT_RESET <= soft_reset_s;
    HARD_RESET <= hard_reset_s;
    
end rtl;
