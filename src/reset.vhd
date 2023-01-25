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
-- Uses some FF guaranteed to be 0 at startup to extend a reset pulse to
-- a couple of cycles. This generates a reset pulse to be transmitted to the
-- entire system at startup.
--
-- It also handles the soft reset triggered by the button on the cart or
-- by a write to the reset bit. The following happens during a soft reset:
--      - GB_RSTN is asserted low, putting the Gameboy in reset
--      - The active MBC is switched with the selected MBC written to MBCH_CFG0
--      - If the boot rom cut-off bit was set to '1', the following also happens
--          - MBCH will disallow access to boot rom
--          - Bank 0 will be used to access DRAM
--      - GB_RSTN is asserted high, allowing the Gameboy to boot
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity reset is
    generic (
        RESET_FF    : positive := 8;
        AUX_FF      : positive := 9;
        SIMULATION  : boolean := false);
    port (
        SYNC_CLK 	: in std_logic;
        PLL_LOCK    : in std_logic;
        EXT_SOFT    : in std_logic;     -- Connected to reset button
        AUX_SOFT    : in std_logic;     -- Connected to hypervisor reset
        DBG_ACTIVE  : in std_logic;     -- Indicates debug core active

        GB_RESETN   : out std_logic;    -- Connected to GB_RST pin
        SOFT_RESET  : out std_logic;    -- Connected to hypervisor reset
        HARD_RESET  : out std_logic);   -- Connected to all RST(_I)?
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

    component FD1P3AY is
    port (
        D   : in std_logic;
        SP  : in std_logic;
        CK  : in std_logic;
        Q   : out std_logic);
    end component;

    signal ff_stages    : std_logic_vector(RESET_FF-1 downto 0) := (others => '1');

    signal soft_reset_s     : std_logic;
    signal ext_soft_sync    : std_logic;
    signal aux_extender     : std_logic_vector(AUX_FF-1 downto 0);

    signal dbg_active_d     : std_logic;
    signal aux_internal     : std_logic;

begin

    GSR_RST_FF : if SIMULATION = true generate
        -- In simulation, treat as shift register (initialisation is done at signal)
        process (SYNC_CLK)
        begin
            if rising_edge(SYNC_CLK) then
                ff_stages <= ff_stages(ff_stages'high-1 downto 0) & '0';
            end if;
        end process;
    else generate
        -- GSR preset FF used for reset pulse
        GSR_RST_FF_0 : component FD1P3AY
        port map (
            D => '0',
            SP => PLL_LOCK,
            CK => SYNC_CLK,
            Q => ff_stages(0));
    
        GSR_RST_FF_STAGES : for i in 1 to RESET_FF-1 generate
            GSR_RST_FF_X : component FD1P3AY
            port map (
                D => ff_stages(i-1),
                SP => PLL_LOCK,
                CK => SYNC_CLK,
                Q => ff_stages(i));
        end generate;
    end generate;

    -- Sychronise EXT_SOFT
    EXT_SOFT_SYNCHRONISER : component synchroniser
    port map (
        CLK => SYNC_CLK,
        RST => ff_stages(ff_stages'high),
        DAT_IN(0) => EXT_SOFT,
        DAT_OUT(0) => ext_soft_sync);

    -- Extend the auxilary reset
    process (SYNC_CLK)
    begin
        if rising_edge(SYNC_CLK) then
            if (ff_stages(ff_stages'high) or AUX_SOFT or aux_internal) = '1' then
                aux_extender <= (aux_extender'high => '1', others => '0');
            else
                if aux_extender(aux_extender'high) = '1' then
                    aux_extender <= std_logic_vector(unsigned(aux_extender) + 1);
                end if;
            end if;
        end if;
    end process;

    -- Handle debug active
    process (SYNC_CLK)
    begin
        if rising_edge(SYNC_CLK) then
            if ff_stages(ff_stages'high) = '1' then
                dbg_active_d <= '0';
            else
                dbg_active_d <= DBG_ACTIVE;
                aux_internal <= DBG_ACTIVE xor dbg_active_d;
            end if;
        end if;
    end process;

    soft_reset_s <= ext_soft_sync or aux_extender(aux_extender'high);

    GB_RESETN <= not(soft_reset_s) and not(DBG_ACTIVE);
    SOFT_RESET <= soft_reset_s;
    HARD_RESET <= ff_stages(ff_stages'high);
    
end behaviour;
