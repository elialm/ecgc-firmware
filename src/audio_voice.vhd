----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 04/26/2023 11:22:47 PM
-- Design Name: Gameboy cartridge audio voice
-- Module Name: audio_voice - behaviour
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

entity audio_voice is
    port (
        -- Clocks and reset
        CLK_I   : in std_logic;     -- Logic clock
        CLK_S   : in std_logic;     -- Sample clock
        RST_I   : in std_logic;

        -- Ports for connecting to a sample_table
        SMPL_EN     : out std_logic;
        SMPL_A      : out std_logic_vector(7 downto 0);
        SMPL_D      : in std_logic_vector(7 downto 0);
        SMPL_DIV    : in std_logic_vector(10 downto 0);
        SMPL_VOL    : in std_logic_vector(3 downto 0);

        AOUT    : out std_logic);   -- Audio out
end audio_voice;

architecture behaviour of audio_voice is

    constant TRIANGLE_INIT          : std_logic_vector(9 downto 0) := "0000000000";
    constant TRIANGLE_BOTTOM        : std_logic_vector(9 downto 0) := "0000000010";  -- Dec = 2
    constant TRIANGLE_TOP           : std_logic_vector(9 downto 0) := "0100011110";  -- Dec = 286
    -- constant TRIANGLE_TOP           : std_logic_vector(9 downto 0) := "1000011110";  -- Dec = 542
    constant SAMPLE_DIVIDER_INIT    : std_logic_vector(10 downto 0) := "00000011110"; -- f_audio ~= 4kHz

    signal sample_index         : std_logic_vector(7 downto 0);
    signal sample_counter       : std_logic_vector(10 downto 0);
    signal sample_divider       : std_logic_vector(10 downto 0);
    signal sample_offset        : std_logic_vector(8 downto 0);

    signal triangle_counter     : std_logic_vector(9 downto 0);
    signal triangle_upcounting  : std_logic;
    signal triangle_is_top      : std_logic;
    signal triangle_is_bottom   : std_logic;

    signal wb_ack       : std_logic;
    signal wb_dat_o     : std_logic_vector(7 downto 0);

begin

    SMPL_EN <= '1';
    SMPL_A <= sample_index;

    process (CLK_I)
    begin
        if rising_edge(CLK_I) then
            if RST_I = '1' then
                triangle_counter <= TRIANGLE_INIT;
                triangle_upcounting <= '1';
            else
                -- Increment/decrement triangle wave counter
                if triangle_upcounting = '1' then
                    triangle_counter <= std_logic_vector(unsigned(triangle_counter) + 2);
                else
                    triangle_counter <= std_logic_vector(unsigned(triangle_counter) - 2);
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
                    sample_divider <= SMPL_DIV;

                    -- Sample clock process
                    sample_index <= std_logic_vector(unsigned(sample_index) + 1);
                end if;
            end if;
        end if;
    end process;

    triangle_is_bottom <= '1' when triangle_counter = TRIANGLE_BOTTOM else '0';
    triangle_is_top <= '1' when triangle_counter = TRIANGLE_TOP else '0';

    -- Note: DAC value must be offset by +16
    sample_offset <= std_logic_vector(unsigned('0' & SMPL_D) + 16);

    AOUT <= '1' when unsigned(sample_offset) > unsigned(triangle_counter) else '0';

end behaviour;