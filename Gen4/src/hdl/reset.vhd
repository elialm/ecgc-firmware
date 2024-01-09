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
--      - MBCH using the RST bit in the MBCH_CTRL register, which pulses i_aux_soft 
--      - Pressing the reset button, pulsing the USER_RESET signal
--      - Activating the debug core, asserting i_dbg_active
--      - Deactivating the debug core, dissasserting i_dbg_active
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity reset is
    generic (
        p_aux_ff_count : positive := 9
    );
    port (
        i_clk        : in std_logic;
        i_pll_lock   : in std_logic;
        i_ext_softn  : in std_logic; -- Connected to reset button
        i_aux_soft   : in std_logic; -- Connected to hypervisor reset
        i_dbg_active : in std_logic; -- Indicates debug core active

        o_gb_resetn  : out std_logic; -- Connected to GB_RST pin
        o_soft_reset : out std_logic; -- Connected to hypervisor reset
        o_hard_reset : out std_logic  -- Connected to all RST(_I)?
    );
end reset;

architecture rtl of reset is

    component synchroniser is
        generic (
            p_ff_count : natural := 2;
            p_data_width : natural := 1;
            p_reset_value : std_logic := '0');
        port (
            i_clk  : in std_logic;
            i_rst  : in std_logic;
            i_din  : in std_logic_vector(p_data_width - 1 downto 0);
            o_dout : out std_logic_vector(p_data_width - 1 downto 0));
    end component;

    signal n_soft_reset : std_logic;
    signal n_hard_reset : std_logic := '1';
    signal n_ext_softn_sync : std_logic;
    signal r_hard_extender : std_logic_vector(3 downto 0) := (others => '1');
    signal r_soft_extender : std_logic_vector(p_aux_ff_count - 1 downto 0);
    signal r_gb_rst_extender : std_logic_vector(8 downto 0);

    signal r_dbg_active : std_logic;
    signal r_aux_internal : std_logic;

begin

    -- Provide hard reset when PLL is not locked
    process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_pll_lock = '0' then
                r_hard_extender <= (others => '1');
            else
                r_hard_extender <= r_hard_extender(r_hard_extender'high - 1 downto 0) & '0';
            end if;
        end if;
    end process;

    -- Sychronise i_ext_softn
    EXT_SOFT_SYNCHRONISER : synchroniser
    port map(
        i_clk     => i_clk,
        i_rst     => n_hard_reset,
        i_din(0)  => i_ext_softn,
        o_dout(0) => n_ext_softn_sync
    );

    -- Extend soft reset to be some clock cycles long
    process (i_clk)
    begin
        if rising_edge(i_clk) then
            if (n_hard_reset or i_aux_soft or r_aux_internal or not(n_ext_softn_sync) or not(i_pll_lock)) = '1' then
                r_soft_extender <= (others => '1');
            else
                r_soft_extender <= r_soft_extender(r_soft_extender'high - 1 downto 0) & '0';
            end if;
        end if;
    end process;

    -- Extend the Gameboy reset to be slow enough for the gameboy
    process (i_clk)
    begin
        if rising_edge(i_clk) then
            if (n_hard_reset or n_soft_reset) = '1' then
                r_gb_rst_extender <= (r_gb_rst_extender'high => '1', others => '0');
            else
                if r_gb_rst_extender(r_gb_rst_extender'high) = '1' then
                    r_gb_rst_extender <= std_logic_vector(unsigned(r_gb_rst_extender) + 1);
                end if;
            end if;
        end if;
    end process;

    -- Handle debug active
    process (i_clk)
    begin
        if rising_edge(i_clk) then
            if n_hard_reset then
                r_dbg_active <= '0';
                r_aux_internal <= '0';
            else
                r_dbg_active <= i_dbg_active;
                r_aux_internal <= i_dbg_active xor r_dbg_active;
            end if;
        end if;
    end process;

    n_soft_reset <= r_soft_extender(r_soft_extender'high);
    n_hard_reset <= r_hard_extender(r_hard_extender'high);

    o_gb_resetn <= not(r_gb_rst_extender(r_gb_rst_extender'high)) and not(i_dbg_active);
    o_soft_reset <= n_soft_reset;
    o_hard_reset <= n_hard_reset;

end rtl;