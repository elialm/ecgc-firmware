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
        CLK_I       : in std_logic;
        RST_I       : in std_logic;
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

    constant TRIANGLE_INIT      : std_logic_vector(8 downto 0) := "000000001";
    constant TRIANGLE_BOTTOM    : std_logic_vector(8 downto 0) := "000000101";
    constant TRIANGLE_TOP       : std_logic_vector(8 downto 0) := "100011101";
    -- constant SAMPLE_PRESCALER   : std_logic_vector(9 downto 0) := "1001011010"; -- f_sample = 44.115 kHz
    constant SAMPLE_PRESCALER   : std_logic_vector(9 downto 0) := "0001101000"; -- f_sample = 511.538 kHz for sine table ~1kHz tone

    signal triangle_counter     : std_logic_vector(8 downto 0);
    signal triangle_upcounting  : std_logic;
    signal triangle_is_top      : std_logic;
    signal triangle_is_bottom   : std_logic;

    signal sample_counter       : std_logic_vector(7 downto 0);
    signal sample_divider       : std_logic_vector(9 downto 0);
    signal sample_clk           : std_logic;
    signal sample_current       : std_logic_vector(7 downto 0);
    signal sample_offset        : std_logic_vector(8 downto 0);

begin

    SIN_SAMPLES : component sin_table
    port map (
        Address => sample_counter,
        OutClock => CLK_I,
        OutClockEn => '1',
        Reset => RST_I,
        Q => sample_current);

    process (CLK_I)
    begin
        if rising_edge(CLK_I) then
            if RST_I = '1' then
                triangle_counter <= TRIANGLE_INIT;
                triangle_upcounting <= '1';

                sample_divider <= (others => '0');
                sample_clk <= '0';
            else
                -- Sample clock divider
                sample_divider <= std_logic_vector(unsigned(sample_divider) + 1);
                if sample_divider = SAMPLE_PRESCALER then
                    sample_clk <= not(sample_clk);
                    sample_divider <= (others => '0');
                end if;

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
            end if;
        end if;
    end process;

    process (sample_clk)
    begin
        if RST_I = '1' then
            sample_counter <= (others => '0');
        elsif rising_edge(sample_clk) then
            sample_counter <= std_logic_vector(unsigned(sample_counter) + 1);
        end if;
    end process;

    triangle_is_bottom <= '1' when triangle_counter = TRIANGLE_BOTTOM else '0';
    triangle_is_top <= '1' when triangle_counter = TRIANGLE_TOP else '0';

    -- Note: DAC value must be offset by +16
    sample_offset <= std_logic_vector(unsigned('0' & sample_current) + 16);

    AUDIO_OUT <= '1' when unsigned(sample_offset) > unsigned(triangle_counter) else '0';

end behaviour;