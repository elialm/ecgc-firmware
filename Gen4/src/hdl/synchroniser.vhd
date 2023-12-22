----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 03/31/2022 03:12:42 PM
-- Design Name: Synchroniser
-- Module Name: synchroniser - rtl
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity synchroniser is
    generic (
        -- Configuration for determining the amount of flip-flops between 
        -- i_din(..) and o_dout(..). Increasing this number will reduce
        -- the change for metastability, but also increase the clock
        -- cycle delay between in- and output. Using less than 2 renders
        -- the synchroniser useless.
        p_ff_count : natural := 2;
        
        -- Configuration for the width of i_din and o_dout.
        p_data_width : natural := 1;
        
        -- Configuration for the value the flip-flops will be set to
        -- when resetting.
        p_reset_value : std_logic := '0'
    );
    port (
        i_clk  : in std_logic;
        i_rst  : in std_logic;
        i_din  : in std_logic_vector(p_data_width - 1 downto 0);
        o_dout : out std_logic_vector(p_data_width - 1 downto 0)
    );
end synchroniser;

architecture rtl of synchroniser is

    -- Note: we subtract p_ff_count by 2, since o_dout will also be made from flip flops
    type t_vector_array is array (integer range <>) of std_logic_vector(p_ff_count - 2 downto 0);

    signal r_shifters : t_vector_array(p_data_width - 1 downto 0);

begin

    process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                for i in r_shifters'range loop
                    r_shifters(i) <= (others => p_reset_value);
                end loop;
                
                o_dout <= (others => p_reset_value);
            else
                for i in r_shifters'range loop
                    r_shifters(i) <= r_shifters(i)(r_shifters(i)'high - 1 downto 0) & i_din(i);
                end loop;
                
                for i in r_shifters'range loop
                    o_dout(i) <= r_shifters(i)(r_shifters(i)'high);
                end loop;
            end if;
        end if;
    end process;
    
end rtl;
