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

    signal clk_i    : std_logic := '0';
    signal rst_i    : std_logic := '1';
    signal cyc_i    : std_logic := '0';
    signal stb_i    : std_logic := '1';
    signal ack_o    : std_logic;
    signal we_i     : std_logic := '0';
    signal adr_i    : std_logic_vector(3 downto 0) := (others => '0');
    signal dat_o    : std_logic_vector(7 downto 0);
    signal dat_i    : std_logic_vector(7 downto 0) := (others => '0');
    signal clk_s    : std_logic := '0';
    signal aout     : std_logic_vector(3 downto 0);

begin

    AUDIO_CTRL_INST : entity work.audio_controller
    port map (
        CLK_I => clk_i,
        RST_I => rst_i,
        CYC_I => cyc_i,
        STB_I => stb_i,
        ACK_O => ack_o,
        WE_I => we_i,
        ADR_I => adr_i,
        DAT_O => dat_o,
        DAT_I => dat_i,
        CLK_S => clk_s,
        AOUT => aout);
            
    -- Main clock
    process
    begin
        loop
            -- wait for 18.796992 ns;
            wait for 9.398496 ns;
            clk_i <= not(clk_i);
        end loop;
    end process;

    -- Sample clock
    process
    begin
        loop
            -- wait for 32.894737 ns;
            wait for 16.447368 ns;
            clk_s <= not(clk_s);
        end loop;
    end process;

    -- Bus transactions
    process (clk_i)
    begin
        if falling_edge(clk_i) then
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
                    rst_i <= '0';
                when others =>
                    transaction_id <= transaction_id;
            end case;
        end if;
    end process;
        
end behaviour;
