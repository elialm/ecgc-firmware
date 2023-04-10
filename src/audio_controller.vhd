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
-- TODO
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity audio_controller is
    port (
        CLK_I   : in std_logic;
        RST_I   : in std_logic;
        CYC_I   : in std_logic;
        STB_I   : in std_logic;
        ACK_O   : out std_logic;
        WE_I    : in std_logic;
        ADR_I   : in std_logic_vector(3 downto 0);
        DAT_O   : out std_logic_vector(7 downto 0);
        DAT_I   : in std_logic_vector(7 downto 0);

        CLK_S       : in std_logic;
        AUDIO_OUT   : out std_logic);
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

    constant TRIANGLE_INIT          : std_logic_vector(8 downto 0) := "000000001";
    constant TRIANGLE_BOTTOM        : std_logic_vector(8 downto 0) := "000000101";
    constant TRIANGLE_TOP           : std_logic_vector(8 downto 0) := "100011101";
    -- constant SAMPLE_DIVIDER_INIT   : std_logic_vector(10 downto 0) := "00100101001"; -- f_audio ~= 200Hz
    constant SAMPLE_DIVIDER_INIT    : std_logic_vector(10 downto 0) := "00000011110"; -- f_audio ~= 2kHz
    -- constant SAMPLE_DIVIDER_INIT   : std_logic_vector(10 downto 0) := "00000000011"; -- f_audio ~= 20kHz

    signal triangle_counter     : std_logic_vector(8 downto 0);
    signal triangle_upcounting  : std_logic;
    signal triangle_is_top      : std_logic;
    signal triangle_is_bottom   : std_logic;

    signal sample_index         : std_logic_vector(7 downto 0);
    signal sample_counter       : std_logic_vector(10 downto 0);
    signal sample_divider_sh    : std_logic_vector(10 downto 0);
    signal sample_divider       : std_logic_vector(10 downto 0);
    signal sample_current       : std_logic_vector(7 downto 0);
    signal sample_offset        : std_logic_vector(8 downto 0);

    signal wb_ack       : std_logic;
    signal wb_dat_o     : std_logic_vector(7 downto 0);

begin

    SIN_SAMPLES : component sin_table
    port map (
        Address => sample_index,
        OutClock => CLK_I,
        OutClockEn => '1',
        Reset => RST_I,
        Q => sample_current);

    process (CLK_I)
    begin
        if rising_edge(CLK_I) then
            wb_ack <= '0';

            if RST_I = '1' then
                triangle_counter <= TRIANGLE_INIT;
                triangle_upcounting <= '1';

                sample_divider_sh <= SAMPLE_DIVIDER_INIT;
            else
                -- Increment/decrement triangle wave counter
                if triangle_upcounting = '1' then
                    triangle_counter <= std_logic_vector(unsigned(triangle_counter) + 4);
                else
                    triangle_counter <= std_logic_vector(unsigned(triangle_counter) - 4);
                end if;

                if triangle_is_bottom = '1' then
                    triangle_upcounting <= '1';
                end if;

                if triangle_is_top = '1' then
                    triangle_upcounting <= '0';
                end if;

                -- Wishbone interface
                if (CYC_I and STB_I and not(wb_ack)) = '1' then
                    case ADR_I is
                        when "0000" =>
                            if WE_I = '1' then
                                sample_divider_sh(7 downto 0) <= DAT_I;
                            else
                                wb_dat_o <= sample_divider_sh(7 downto 0);
                            end if;

                        when "0001" =>
                            if WE_I = '1' then
                                sample_divider_sh(10 downto 8) <= DAT_I(2 downto 0);
                            else
                                wb_dat_o <= "00000" & sample_divider_sh(10 downto 8);
                            end if;

                        when others =>
                            wb_dat_o <= x"00";
                    end case;
                    
                    wb_ack <= '1';
                end if;
            end if;
        end if;
    end process;

    process (CLK_S)
    begin
        if rising_edge(CLK_S) then
            if RST_I = '1' then
                sample_counter <= (others => '0');
                sample_divider <= SAMPLE_DIVIDER_INIT;
                sample_index <= (others => '0');
            else
                -- Sample clock divider
                sample_counter <= std_logic_vector(unsigned(sample_counter) + 1);
                if sample_counter = sample_divider then
                    sample_counter <= (others => '0');
                    sample_divider <= sample_divider_sh;

                    -- Sample clock process
                    sample_index <= std_logic_vector(unsigned(sample_index) + 1);
                end if;
            end if;
        end if;
    end process;

    triangle_is_bottom <= '1' when triangle_counter = TRIANGLE_BOTTOM else '0';
    triangle_is_top <= '1' when triangle_counter = TRIANGLE_TOP else '0';

    -- Note: DAC value must be offset by +16
    sample_offset <= std_logic_vector(unsigned('0' & sample_current) + 16);

    AUDIO_OUT <= '1' when unsigned(sample_offset) > unsigned(triangle_counter) else '0';

    DAT_O <= wb_dat_o;
    ACK_O <= wb_ack;

end behaviour;