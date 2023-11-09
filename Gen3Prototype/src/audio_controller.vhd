----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 03/29/2023 11:03:22 PM
-- Design Name: Gameboy cartridge audio controller
-- Module Name: audio_controller - behaviour
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Documentation
--
-- Cartridge's audio controller for playing audio via the Vout pin on the
-- cartridge's header. The controller contains memory mapped registers for 
-- configuring audio. There are a number of 4 voices with independant controls.
--
-- The audio controller is clocked via 2 sources: CLK_I and CLK_S. CLK_I is the
-- Wishbone clock and follows its specifications. CLK_S is used for clocking
-- samples when playing audio. This clock is then passed through a configurable
-- prescaler for setting the sample playing frequency.
--
-- The produced audio is outputted per channel via the AOUT pins.
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity audio_controller is
    port (
        -- Wishbone signals for configuration
        CLK_I   : in std_logic;
        RST_I   : in std_logic;
        CYC_I   : in std_logic;
        STB_I   : in std_logic;
        ACK_O   : out std_logic;
        WE_I    : in std_logic;
        ADR_I   : in std_logic_vector(3 downto 0);
        DAT_O   : out std_logic_vector(7 downto 0);
        DAT_I   : in std_logic_vector(7 downto 0);

        -- Miscellaneous signals
        CLK_S  : in std_logic;                          -- Sample clock
        AOUT   : out std_logic_vector(3 downto 0));     -- Audio outputs of channels 1-4
end audio_controller;

architecture behaviour of audio_controller is

    component sin_table
    port (
        Address     : in std_logic_vector(7 downto 0); 
        OutClock    : in std_logic;
        OutClockEn  : in std_logic; 
        Reset       : in std_logic;
        Q           : out std_logic_vector(7 downto 0));
    end component;

    component audio_voice
    port (
        CLK_I       : in std_logic;
        CLK_S       : in std_logic;
        RST_I       : in std_logic;
        RST_S       : in std_logic;
        SMPL_EN     : out std_logic;
        SMPL_A      : out std_logic_vector(7 downto 0);
        SMPL_D      : in std_logic_vector(7 downto 0);
        SMPL_DIV    : in std_logic_vector(10 downto 0);
        SMPL_VOL    : in std_logic_vector(3 downto 0);
        AOUT        : out std_logic);
    end component;

    constant SAMPLE_DIVIDER_INIT    : std_logic_vector(10 downto 0) := "00000011110"; -- f_audio ~= 2kHz
    constant SAMPLE_VOLUME_INIT     : std_logic_vector(3 downto 0) := "1111"; -- Max volume

    signal voice_smpl_en        : std_logic_vector(3 downto 0);
    signal voice_smpl_a         : std_logic_vector(31 downto 0);
    signal voice_smpl_d         : std_logic_vector(31 downto 0);
    signal voice_smpl_div       : std_logic_vector(43 downto 0);
    signal voice_smpl_vol       : std_logic_vector(15 downto 0);

    alias voice_selector : std_logic_vector(1 downto 0) is ADR_I(3 downto 2);
    signal vsmpl_div_r  : std_logic_vector(10 downto 0);
    signal vsmpl_div_w  : std_logic_vector(10 downto 0);
    signal vsmpl_vol_r  : std_logic_vector(3 downto 0);
    signal vsmpl_vol_w  : std_logic_vector(3 downto 0);

    signal sample_reset_req     : std_logic;
    signal sample_reset_ext     : std_logic_vector(1 downto 0);
    signal wb_ack       : std_logic;
    signal wb_dat_o     : std_logic_vector(7 downto 0);

begin

    SAMPLE_TABLES : for i in 0 to 3 generate
        SAMPLE_TABLE_X : component sin_table
        port map (
            Address => voice_smpl_a(((i + 1) * 8 - 1) downto (i * 8)),
            OutClock => CLK_I,
            OutClockEn => voice_smpl_en(i),
            Reset => RST_I,
            Q => voice_smpl_d(((i + 1) * 8 - 1) downto (i * 8)));
    end generate SAMPLE_TABLES;

    VOICES : for i in 0 to 3 generate
        VOICE_X : component audio_voice
        port map (
            CLK_I => CLK_I,
            CLK_S => CLK_S,
            RST_I => RST_I,
            RST_S => sample_reset_req,
            SMPL_EN => voice_smpl_en(i),
            SMPL_A => voice_smpl_a(((i + 1) * 8 - 1) downto (i * 8)),
            SMPL_D => voice_smpl_d(((i + 1) * 8 - 1) downto (i * 8)),
            SMPL_DIV => voice_smpl_div(((i + 1) * 11 - 1) downto (i * 11)),
            SMPL_VOL => voice_smpl_vol(((i + 1) * 4 - 1) downto (i * 4)),
            AOUT => AOUT(i));
    end generate VOICES;

    -- Select which voice divider is read from
    with voice_selector select vsmpl_div_r <=
        voice_smpl_div(10 downto 0) when "00",
        voice_smpl_div(21 downto 11) when "01",
        voice_smpl_div(32 downto 22) when "10",
        voice_smpl_div(43 downto 33) when "11",
        "11111111111" when others;

    -- Select which voice volume is read from
    with voice_selector select vsmpl_vol_r <=
        voice_smpl_vol(3 downto 0) when "00",
        voice_smpl_vol(7 downto 4) when "01",
        voice_smpl_vol(11 downto 8) when "10",
        voice_smpl_vol(15 downto 12) when "11",
        "1111" when others;

    sample_reset_req <= or_reduce(sample_reset_ext);

    process (CLK_I)
    begin
        if rising_edge(CLK_I) then
            wb_ack <= '0';

            if RST_I = '1' then
                voice_smpl_div(10 downto 0) <= SAMPLE_DIVIDER_INIT;
                voice_smpl_div(21 downto 11) <= SAMPLE_DIVIDER_INIT;
                voice_smpl_div(32 downto 22) <= SAMPLE_DIVIDER_INIT;
                voice_smpl_div(43 downto 33) <= SAMPLE_DIVIDER_INIT;
                vsmpl_div_w <= SAMPLE_DIVIDER_INIT;

                voice_smpl_vol(3 downto 0) <= SAMPLE_VOLUME_INIT;
                voice_smpl_vol(7 downto 4) <= SAMPLE_VOLUME_INIT;
                voice_smpl_vol(11 downto 8) <= SAMPLE_VOLUME_INIT;
                voice_smpl_vol(15 downto 12) <= SAMPLE_VOLUME_INIT;
                vsmpl_vol_w <= SAMPLE_VOLUME_INIT;
                
                sample_reset_ext <= (others => '0');
                wb_dat_o <= (others => '0');
            else
                -- Decrement sample reset extender
                if sample_reset_req = '1' then
                    sample_reset_ext <= std_logic_vector(unsigned(sample_reset_ext) - 1);
                end if;

                -- Wishbone interface
                if (CYC_I and STB_I and not(wb_ack)) = '1' then
                    vsmpl_div_w <= vsmpl_div_r;
                    vsmpl_vol_w <= vsmpl_vol_r;

                    case? ADR_I is
                        -- Low frequency bits
                        when "--00" =>
                            if WE_I = '1' then
                                vsmpl_div_w(7 downto 0) <= DAT_I;
                                sample_reset_ext <= (others => '1');
                            else
                                wb_dat_o <= vsmpl_div_r(7 downto 0);
                            end if;

                        -- High frequency bits and volume control
                        when "--01" =>
                            if WE_I = '1' then
                                vsmpl_div_w(10 downto 8) <= DAT_I(2 downto 0);
                                vsmpl_vol_w <= DAT_I(7 downto 4);
                                sample_reset_ext <= (others => '1');
                            else
                                wb_dat_o <= vsmpl_vol_r & '0' & vsmpl_div_r(10 downto 8);
                            end if;

                        when others =>
                            wb_dat_o <= x"00";
                    end case?;
                    
                    wb_ack <= '1';
                end if;

                -- Update write values
                if wb_ack = '1' then
                    case voice_selector is
                        when "00" =>
                            voice_smpl_div(10 downto 0) <= vsmpl_div_w;
                            voice_smpl_vol(3 downto 0) <= vsmpl_vol_w;
                        when "01" =>
                            voice_smpl_div(21 downto 11) <= vsmpl_div_w;
                            voice_smpl_vol(7 downto 4) <= vsmpl_vol_w;
                        when "10" =>
                            voice_smpl_div(32 downto 22) <= vsmpl_div_w;
                            voice_smpl_vol(11 downto 8) <= vsmpl_vol_w;
                        when "11" =>
                            voice_smpl_div(43 downto 33) <= vsmpl_div_w;
                            voice_smpl_vol(15 downto 12) <= vsmpl_vol_w;
                        when others =>
                            null;
                    end case;
                end if;
            end if;
        end if;
    end process;

    DAT_O <= wb_dat_o;
    ACK_O <= wb_ack;

end behaviour;