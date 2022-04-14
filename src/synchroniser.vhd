----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/31/2022 03:12:42 PM
-- Design Name: 
-- Module Name: multi_bit_synchroniser - behaviour
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity synchroniser is
    generic (
        -- Configuration for determining the amount of flip-flops between 
        -- DAT_IN(..) and DAT_OUT(..). Increasing this number will reduce
        -- the change for metastability, but also increase the clock
        -- cycle delay between in- and output.
        FF_COUNT : natural := 2;
        
        -- Configuration for the width of DAT_IN and DAT_OUT.
        DATA_WIDTH : natural := 1;
        
        -- Configuration for the value the flip-flops will be set to
        -- when resetting.
        RESET_VALUE : std_logic := '0');
    port (
        CLK : in std_logic;
        RST : in std_logic;
        DAT_IN : in std_logic_vector(DATA_WIDTH-1 downto 0);
        DAT_OUT : out std_logic_vector(DATA_WIDTH-1 downto 0));
end synchroniser;

architecture behaviour of synchroniser is

    -- Note: we subtract FF_COUNT by 2, since DAT_OUT will also be made from flip flops
    type logic_vector_array is array (integer range <>) of std_logic_vector(FF_COUNT-2 downto 0);

    signal shifters : logic_vector_array(DATA_WIDTH-1 downto 0);

begin

    process (CLK)
    begin
        if rising_edge(CLK) then
            if RST = '1' then
                for i in shifters'low to shifters'high loop
                    shifters(i) <= (others => RESET_VALUE);
                end loop;
                
                DAT_OUT <= (others => RESET_VALUE);
            else
                for i in shifters'low to shifters'high loop
                    shifters(i) <= shifters(i)(shifters(i)'high-1 downto 0) & DAT_IN(i);
                end loop;
                
                for i in shifters'low to shifters'high loop
                    DAT_OUT(i) <= shifters(i)(shifters(i)'high);
                end loop;
            end if;
        end if;
    end process;
    
end behaviour;
