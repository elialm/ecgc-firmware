----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 01/16/2023 03:07:43 PM
-- Design Name: DMA controller
-- Module Name: dma_controller - behaviour
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
        CLK_I       : in std_logic;
        RST_I       : in std_logic;

        -- DMA master port
        DMA_CYC_O   : out std_logic;
        DMA_ACK_I   : in std_logic;
        DMA_WE_O    : out std_logic;
        DMA_ADR_O   : out std_logic_vector(15 downto 0);
        DMA_DAT_O   : out std_logic_vector(7 downto 0);
        DMA_DAT_I   : in std_logic_vector(7 downto 0);
    
        -- Configuration slave port
        CFG_CYC_I   : in std_logic;
        CFG_ACK_O   : out std_logic;
        CFG_WE_I    : in std_logic;
        CFG_ADR_I   : in std_logic_vector(3 downto 0);
        CFG_DAT_O   : out std_logic_vector(7 downto 0);
        CFG_DAT_I   : in std_logic_vector(7 downto 0);
        
        -- Status signals
        STATUS_BUSY : out std_logic);   -- Indicates that the DMA is busy copying data
end dma_controller;

architecture behaviour of dma_controller is

    type DMA_STATE_TYPE is (DMAS_IDLE, DMAS_READ, DMAS_WRITE);

    signal dma_current_state    : DMA_STATE_TYPE;
    signal dma_addr_src_inc     : std_logic;
    signal dma_addr_dest_inc    : std_logic;
    signal dma_copy_amount      : std_logic_vector(7 downto 0);
    signal dma_amount_is_zero   : std_logic;
    signal dma_start            : std_logic;
    signal dma_is_busy          : std_logic;

    signal master_addr_sel  : std_logic;
    signal master_addr_src  : std_logic_vector(15 downto 0);
    signal master_addr_dest : std_logic_vector(15 downto 0);
    signal master_data      : std_logic_vector(7 downto 0);

    signal slave_data       : std_logic_vector(7 downto 0);
    signal slave_ack        : std_logic;

begin

    dma_amount_is_zero <= nor_reduce(dma_copy_amount);
    dma_is_busy <= '0' when dma_current_state = DMAS_IDLE else '1';

    -- DMA_ADR_O control
    with master_addr_sel select DMA_ADR_O <=
        master_addr_src     when '0',
        master_addr_dest    when others;

    process (CLK_I)
    begin
        if rising_edge(CLK_I) then
            slave_ack <= '0';

            if RST_I = '1' then
                dma_current_state <= DMAS_IDLE;
                dma_addr_src_inc <= '0';
                dma_addr_dest_inc <= '0';
                dma_copy_amount <= (others => '0');
                dma_start <= '0';

                master_addr_sel <= '0';
                master_addr_src <= (others => '0');
                master_addr_dest <= (others => '0');
                master_data <= (others => '0');

                slave_data <= (others => '0');

                DMA_CYC_O <= '0';
                DMA_WE_O <= '0';
            else
                -- DMA state machine
                case dma_current_state is
                    when DMAS_IDLE =>
                        if dma_start = '1' then
                            dma_start <= '0';
                            -- master_addr_sel <= '0';
                            DMA_CYC_O <= '1';

                            dma_current_state <= DMAS_READ;
                        end if;
                    when DMAS_READ =>
                        if DMA_ACK_I = '1' then
                            dma_copy_amount <= std_logic_vector(unsigned(dma_copy_amount) - 1);
                            master_addr_sel <= '1';
                            master_data <= DMA_DAT_I;

                            if dma_addr_src_inc = '1' then
                                master_addr_src <= std_logic_vector(unsigned(master_addr_src) + 1);
                            end if;

                            DMA_WE_O <= '1';

                            dma_current_state <= DMAS_WRITE;
                        end if;
                    when DMAS_WRITE =>
                        if DMA_ACK_I = '1' then
                            master_addr_sel <= '0';
                            DMA_WE_O <= '0';

                            if dma_addr_dest_inc = '1' then
                                master_addr_dest <= std_logic_vector(unsigned(master_addr_dest) + 1);
                            end if;

                            if dma_amount_is_zero = '1' then
                                DMA_CYC_O <= '0';
                                dma_current_state <= DMAS_IDLE;
                            else
                                master_addr_sel <= '0';
                                dma_current_state <= DMAS_READ;
                            end if;
                        end if;
                end case;

                -- Configuration address decoder
                if (CFG_CYC_I and not(slave_ack)) = '1' then
                    case CFG_ADR_I is
                        -- Configuration register
                        when b"0000" =>
                            if CFG_WE_I = '1' then
                                dma_start <= CFG_DAT_I(7);
                                dma_addr_src_inc <= CFG_DAT_I(4);
                                dma_addr_dest_inc <= CFG_DAT_I(5);
                            else
                                slave_data <= dma_start & "0" & dma_addr_dest_inc & dma_addr_src_inc & "000" & dma_is_busy;
                            end if;

                        -- Copy amount
                        when b"0001" =>
                            if CFG_WE_I = '1' then
                                dma_copy_amount <= CFG_DAT_I;
                            else
                                slave_data <= dma_copy_amount;
                            end if;
                        
                        -- Source address low
                        when b"0100" =>
                            if CFG_WE_I = '1' then
                                master_addr_src(7 downto 0) <= CFG_DAT_I;
                            else
                                slave_data <= master_addr_src(7 downto 0);
                            end if;

                        -- Source address high
                        when b"0101" =>
                            if CFG_WE_I = '1' then
                                master_addr_src(15 downto 8) <= CFG_DAT_I;
                            else
                                slave_data <= master_addr_src(15 downto 8);
                            end if;

                        -- Destination address low
                        when b"0110" =>
                            if CFG_WE_I = '1' then
                                master_addr_dest(7 downto 0) <= CFG_DAT_I;
                            else
                                slave_data <= master_addr_dest(7 downto 0);
                            end if;

                        -- Destination address high
                        when b"0111" =>
                            if CFG_WE_I = '1' then
                                master_addr_dest(15 downto 8) <= CFG_DAT_I;
                            else
                                slave_data <= master_addr_dest(15 downto 8);
                            end if;

                        when others =>
                            slave_data <= x"00";
                    end case;

                    slave_ack <= '1';
                end if;
            end if;
        end if;
    end process;

    DMA_DAT_O <= master_data;

    CFG_DAT_O <= slave_data;
    CFG_ACK_O <= slave_ack;

    STATUS_BUSY <= dma_is_busy;

end behaviour;