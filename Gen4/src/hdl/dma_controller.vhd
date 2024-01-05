----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 01/16/2023 03:07:43 PM
-- Design Name: DMA controller
-- Module Name: dma_controller - rtl
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Documentation
--
-- Cartridge's DMA controller for copying data from and to cartridge memory.
-- Used when it is needed to copy large amounts of data around the cartridge.
-- An example use case is when copying a game to DRAM, where the Gameboy's bus
-- only running at 1MHz might be a bottleneck.
--
-- The DMA also provides a Wishbone slave interface for configuration. The core
-- can then be controlled via this interface. The control registers are further
-- documented in /doc/register.md.
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity dma_controller is
    port (
        -- Global signals
        i_clk       : in std_logic;
        i_rst       : in std_logic;

        -- DMA master port
        o_dma_cyc   : out std_logic;
        i_dma_ack   : in std_logic;
        o_dma_we    : out std_logic;
        o_dma_adr   : out std_logic_vector(15 downto 0);
        o_dma_dat   : out std_logic_vector(7 downto 0);
        i_dma_dat   : in std_logic_vector(7 downto 0);
    
        -- Configuration slave port
        i_cfg_cyc   : in std_logic;
        o_cfg_ack   : out std_logic;
        i_cfg_we    : in std_logic;
        i_cfg_adr   : in std_logic_vector(3 downto 0);
        o_cfg_dat   : out std_logic_vector(7 downto 0);
        i_cfg_dat   : in std_logic_vector(7 downto 0);
        
        -- Status signals
        o_status_busy : out std_logic);   -- Indicates that the DMA is busy copying data
end dma_controller;

architecture rtl of dma_controller is

    type DMA_STATE_TYPE is (DMAS_IDLE, DMAS_READ, DMAS_WRITE);

    signal r_dma_current_state    : DMA_STATE_TYPE;
    signal r_dma_addr_src_inc     : std_logic;
    signal r_dma_addr_dest_inc    : std_logic;
    signal r_dma_copy_amount      : std_logic_vector(7 downto 0);
    signal n_dma_amount_is_zero   : std_logic;
    signal r_dma_start            : std_logic;
    signal n_dma_is_busy          : std_logic;

    signal r_master_addr_sel  : std_logic;
    signal r_master_addr_src  : std_logic_vector(15 downto 0);
    signal r_master_addr_dest : std_logic_vector(15 downto 0);
    signal r_master_data      : std_logic_vector(7 downto 0);

    signal r_slave_data       : std_logic_vector(7 downto 0);
    signal r_slave_ack        : std_logic;

begin

    n_dma_amount_is_zero <= nor_reduce(r_dma_copy_amount);
    n_dma_is_busy <= '0' when r_dma_current_state = DMAS_IDLE else '1';

    -- o_dma_adr control
    with r_master_addr_sel select o_dma_adr <=
        r_master_addr_src     when '0',
        r_master_addr_dest    when others;

    process (i_clk)
    begin
        if rising_edge(i_clk) then
            r_slave_ack <= '0';

            if i_rst = '1' then
                r_dma_current_state <= DMAS_IDLE;
                r_dma_addr_src_inc <= '0';
                r_dma_addr_dest_inc <= '0';
                r_dma_copy_amount <= (others => '0');
                r_dma_start <= '0';

                r_master_addr_sel <= '0';
                r_master_addr_src <= (others => '0');
                r_master_addr_dest <= (others => '0');
                r_master_data <= (others => '0');

                r_slave_data <= (others => '0');

                o_dma_cyc <= '0';
                o_dma_we <= '0';
            else
                -- DMA state machine
                case r_dma_current_state is
                    when DMAS_IDLE =>
                        if r_dma_start = '1' then
                            r_dma_start <= '0';
                            -- r_master_addr_sel <= '0';
                            o_dma_cyc <= '1';

                            r_dma_current_state <= DMAS_READ;
                        end if;
                    when DMAS_READ =>
                        if i_dma_ack = '1' then
                            r_dma_copy_amount <= std_logic_vector(unsigned(r_dma_copy_amount) - 1);
                            r_master_addr_sel <= '1';
                            r_master_data <= i_dma_dat;

                            if r_dma_addr_src_inc = '1' then
                                r_master_addr_src <= std_logic_vector(unsigned(r_master_addr_src) + 1);
                            end if;

                            o_dma_we <= '1';

                            r_dma_current_state <= DMAS_WRITE;
                        end if;
                    when DMAS_WRITE =>
                        if i_dma_ack = '1' then
                            r_master_addr_sel <= '0';
                            o_dma_we <= '0';

                            if r_dma_addr_dest_inc = '1' then
                                r_master_addr_dest <= std_logic_vector(unsigned(r_master_addr_dest) + 1);
                            end if;

                            if n_dma_amount_is_zero = '1' then
                                o_dma_cyc <= '0';
                                r_dma_current_state <= DMAS_IDLE;
                            else
                                r_master_addr_sel <= '0';
                                r_dma_current_state <= DMAS_READ;
                            end if;
                        end if;
                end case;

                -- Configuration address decoder
                if (i_cfg_cyc and not(r_slave_ack)) = '1' then
                    case i_cfg_adr is
                        -- Configuration register
                        when b"0000" =>
                            if i_cfg_we = '1' then
                                r_dma_start <= i_cfg_dat(7);
                                r_dma_addr_src_inc <= i_cfg_dat(4);
                                r_dma_addr_dest_inc <= i_cfg_dat(5);
                            else
                                r_slave_data <= r_dma_start & "0" & r_dma_addr_dest_inc & r_dma_addr_src_inc & "000" & n_dma_is_busy;
                            end if;

                        -- Copy amount
                        when b"0001" =>
                            if i_cfg_we = '1' then
                                r_dma_copy_amount <= i_cfg_dat;
                            else
                                r_slave_data <= r_dma_copy_amount;
                            end if;
                        
                        -- Source address low
                        when b"0100" =>
                            if i_cfg_we = '1' then
                                r_master_addr_src(7 downto 0) <= i_cfg_dat;
                            else
                                r_slave_data <= r_master_addr_src(7 downto 0);
                            end if;

                        -- Source address high
                        when b"0101" =>
                            if i_cfg_we = '1' then
                                r_master_addr_src(15 downto 8) <= i_cfg_dat;
                            else
                                r_slave_data <= r_master_addr_src(15 downto 8);
                            end if;

                        -- Destination address low
                        when b"0110" =>
                            if i_cfg_we = '1' then
                                r_master_addr_dest(7 downto 0) <= i_cfg_dat;
                            else
                                r_slave_data <= r_master_addr_dest(7 downto 0);
                            end if;

                        -- Destination address high
                        when b"0111" =>
                            if i_cfg_we = '1' then
                                r_master_addr_dest(15 downto 8) <= i_cfg_dat;
                            else
                                r_slave_data <= r_master_addr_dest(15 downto 8);
                            end if;

                        when others =>
                            r_slave_data <= x"00";
                    end case;

                    r_slave_ack <= '1';
                end if;
            end if;
        end if;
    end process;

    o_dma_dat <= r_master_data;

    o_cfg_dat <= r_slave_data;
    o_cfg_ack <= r_slave_ack;

    o_status_busy <= n_dma_is_busy;

end rtl;