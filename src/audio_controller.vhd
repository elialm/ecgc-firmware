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
        RST_I   : in std_logic);
end audio_controller;

architecture behaviour of audio_controller is

    signal triangle_counter     : std_logic_vector(8 downto 0);
    signal triangle_upcounting  : std_logic;
    signal triangle_is_top      : std_logic;
    signal triangle_is_bottom   : std_logic;

begin

    -- Note: DAC value must be offset by +16

    process (CLK_I)
    begin
        if rising_edge(CLK_I) then
            if RST_I = '1' then
                triangle_counter <= "000000001";
                triangle_upcounting <= '1';
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
            end if;
        end if;
    end process;

    triangle_is_bottom <= '1' when triangle_counter = "000000101" else '0';
    triangle_is_top <= '1' when triangle_counter = "100001101" else '0';

end behaviour;