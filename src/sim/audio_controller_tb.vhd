----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/29/2023 11:03:22 PM
-- Design Name: 
-- Module Name: audio_controller_tb - behaviour
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: audio_controller_tb.vhd
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity audio_controller_tb is
end audio_controller_tb;

architecture behaviour of audio_controller_tb is

    signal transaction_id   : natural := 0;

    signal clk  : std_logic := '0';
    signal rst  : std_logic := '1';

begin

    DRAM_INST : entity work.audio_controller
    port map (
        CLK_I => clk,
        RST_I => rst);
            
    -- Main clock
    process
    begin
        loop
            -- wait for 18.796992 ns;
            wait for 9.398496 ns;
            clk <= not(clk);
        end loop;
    end process;

    -- Bus transactions
    process (clk)
    begin
        if falling_edge(clk) then
            transaction_id <= transaction_id + 1;

            case transaction_id is
                when 0 =>
                    null;
                when 1 =>
                    null;
                when 2 =>
                    null;
                when 3 =>
                    null;
                when 4 =>
                    null;
                when 5 =>
                    null;
                when 6 =>
                    null;
                when 7 =>
                    rst <= '0';
                when others =>
                    transaction_id <= transaction_id;
            end case;
        end if;
    end process;
        
end behaviour;
