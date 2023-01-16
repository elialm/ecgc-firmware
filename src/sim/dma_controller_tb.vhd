----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/16/2023 03:33:43 PM
-- Design Name: 
-- Module Name: dma_controller_tb - behaviour
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;

entity dma_controller_tb is
end dma_controller_tb;

architecture behaviour of dma_controller_tb is

    signal clk_i        : std_logic := '0';
    signal rst_i        : std_logic := '1';

    signal dma_cyc_o    : std_logic;
    signal dma_ack_i    : std_logic := '0';
    signal dma_we_o     : std_logic;
    signal dma_adr_o    : std_logic_vector(15 downto 0);
    signal dma_dat_o    : std_logic_vector(7 downto 0);
    signal dma_dat_i    : std_logic_vector(7 downto 0) := (others => '0');

    signal cfg_cyc_i    : std_logic := '0';
    signal cfg_ack_o    : std_logic;
    signal cfg_we_i     : std_logic := '0';
    signal cfg_adr_i    : std_logic_vector(7 downto 0) := (others => '0');
    signal cfg_dat_o    : std_logic_vector(7 downto 0);
    signal cfg_dat_i    : std_logic_vector(7 downto 0) := (others => '0');

    signal transaction_id : natural := 0;

begin

    DMA_CONTROLLER : entity work.dma_controller
    port map (
        CLK_I => clk_i,
        RST_I => rst_i,
        DMA_CYC_O => dma_cyc_o,
        DMA_ACK_I => dma_ack_i,
        DMA_WE_O => dma_we_o,
        DMA_ADR_O => dma_adr_o,
        DMA_DAT_O => dma_dat_o,
        DMA_DAT_I => dma_dat_i,
        CFG_CYC_I => cfg_cyc_i,
        CFG_ACK_O => cfg_ack_o,
        CFG_WE_I => cfg_we_i,
        CFG_ADR_I => cfg_adr_i,
        CFG_DAT_O => cfg_dat_o,
        CFG_DAT_I => cfg_dat_i);

    -- Main clock
    process
    begin
        loop
            wait for 20 ns;
            clk_i <= not(clk_i);
        end loop;
    end process;

    -- Bus transactions
    process (clk_i)
    begin
        if rising_edge(clk_i) then
            transaction_id <= transaction_id + 1;

            case transaction_id is
                when 0 =>
                    null;
                when 1 =>
                    rst_i <= '0';
                when others =>
                    transaction_id <= transaction_id;
            end case;
        end if;
    end process;

end behaviour;