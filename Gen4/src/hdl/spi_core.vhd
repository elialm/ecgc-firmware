----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 21/02/2024 16:52:09 PM
-- Design Name: SPI core
-- Module Name: spi_core - rtl
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Documentation
--
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spi_core is
    generic (
        p_cs_count : positive := 1;
        p_cs_release_value : std_logic := '1'
    );
    port (
        -- Clocking and reset
        i_clk : in std_logic;
        i_rst : in std_logic;

        -- Slave Wishbone port
        i_cyc : in std_logic;
        o_ack : out std_logic;
        i_we  : in std_logic;
        i_adr : in std_logic_vector(1 downto 0);
        o_dat : out std_logic_vector(7 downto 0);
        i_dat : in std_logic_vector(7 downto 0);

        -- SPI signals
        io_spi_clk  : inout std_logic;
        io_spi_mosi : inout std_logic;
        io_spi_miso : inout std_logic;
        io_spi_csn  : inout std_logic_vector(p_cs_count - 1 downto 0)
    );
end entity spi_core;

architecture rtl of spi_core is
    
    subtype t_spi_scounter is integer range 0 to 8;
    subtype t_fdiv is integer range 0 to 255;

    signal r_cfg_en : std_logic;    -- core enabled, must be 1 for the registers to be writable
    signal r_cfg_cpol : std_logic;  -- clock polarity, see SPI docs
    signal r_cfg_cpha : std_logic;  -- clock phase, see SPI docs
    signal r_cfg_bord : std_logic;  -- bit shifting order, 0 = MSB first, 1 = LSB first
    signal r_cfg_csrl : std_logic;  -- Chip select release after transmission, set to enable

    signal r_spi_clk : std_logic;
    signal r_spi_shifter : std_logic_vector(7 downto 0);
    signal r_spi_scounter : t_spi_scounter;
    signal r_spi_ccounter : t_spi_scounter;
    signal r_skip_shift : std_logic;
    signal r_skip_clock : std_logic;
    signal r_tristate_mosi : std_logic;
    signal r_slave_sample : std_logic;
    signal r_transmission_busy : std_logic;
    signal r_transmission_done : std_logic;
    signal r_request_release : std_logic;
    signal r_fdiv_counter : t_fdiv;

    signal r_spi_csn : std_logic_vector(p_cs_count - 1 downto 0);
    signal r_fdiv_ceil : t_fdiv;
    signal r_request_wr : std_logic;
    signal r_request_rd : std_logic;
    signal r_ack : std_logic;
    signal r_dat : std_logic_vector(7 downto 0);

begin

    -- there must not be more then 8 chip selects, since that doesn't fit inside a register
    assert p_cs_count <= 8 report "Current implementation does not support more than 8 CS pins" severity FAILURE;
    
    proc_data_shifting : process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                r_spi_clk <= '0';
                -- r_spi_shifter <= (others => '0');
                r_spi_scounter <= 0;
                r_spi_ccounter <= 0;
                r_skip_shift <= '0';
                r_skip_clock <= '0';
                r_tristate_mosi <= '1';
                -- r_slave_sample <= '0';
                r_transmission_busy <= '0';
                r_transmission_done <= '0';
                r_request_release <= '0';
                r_fdiv_counter <= 0;
            else
                r_request_release <= '0';

                -- write request from wishbone port, initiates transaction
                if r_request_wr = '1' then
                    -- load shifter based on set bit order
                    if r_cfg_bord = '0' then
                        -- MSB first
                        r_spi_shifter <= i_dat;
                    else
                        -- LSB first
                        for i in 0 to 7 loop
                            r_spi_shifter(i) <= i_dat(7 - i);
                        end loop;
                    end if;

                    r_spi_scounter <= 8;
                    r_spi_ccounter <= 8;
                    r_skip_shift <= r_cfg_cpha;
                    r_skip_clock <= '1';
                    r_tristate_mosi <= '0';
                    r_transmission_busy <= '1';
                    r_fdiv_counter <= r_fdiv_ceil;
                end if;

                -- read transaction, clears transmission done bit
                if r_request_rd = '1' then
                    r_transmission_done <= '0';
                end if;

                -- increment fdiv counter when transmission busy
                if r_transmission_busy = '1' then
                    r_fdiv_counter <= r_fdiv_counter + 1;
                end if;

                -- perform when transmission is busy
                -- and fdiv counter value matches the ceiling
                if r_transmission_busy = '1' and r_fdiv_counter = r_fdiv_ceil then
                    -- clear fdiv counter
                    r_fdiv_counter <= 0;

                    -- skip the first clock to give mosi time
                    -- only clock 8 times
                    if r_skip_clock = '1' then
                        r_skip_clock <= '0';
                    elsif r_spi_ccounter /= 0 then
                        r_spi_clk <= not(r_spi_clk);
                    end if;

                    -- decrement clock counter on each falling edge
                    if r_spi_clk = '1' then
                        r_spi_ccounter <= r_spi_ccounter - 1;
                    end if;

                    -- always skip first sample/shift cycle
                    -- and there are still samples to be made
                    if r_skip_clock = '0' and r_spi_scounter /= 0 then
                        -- r_spi_clk = r_cfg_cpha       (r_cfg_cpha = 0)
                        --      - sample cycle
                        -- r_spi_clk = not(r_cfg_cpha)  (r_cfg_cpha = 1)
                        --      - shift cycle

                        if r_spi_clk = not(r_cfg_cpha) and r_skip_shift = '1' then
                            -- skip first bit shift
                            r_skip_shift <= '0';
                        elsif r_spi_clk = not(r_cfg_cpha) and r_skip_shift = '0' then
                            -- shift data
                            r_spi_shifter <= r_spi_shifter(r_spi_shifter'high - 1 downto 0) & r_slave_sample;
                        elsif r_spi_clk = r_cfg_cpha then
                            -- sample data
                            r_slave_sample <= io_spi_miso;
                            r_spi_scounter <= r_spi_scounter - 1;
                        end if;
                    end if;

                    -- when sample counter reaches 0, tristate bus
                    if r_spi_scounter = 0 then
                        r_tristate_mosi <= '1';
                    end if;

                    -- end transmission when clock counter reaches 0
                    if r_spi_ccounter = 0 then
                        r_transmission_busy <= '0';
                        r_transmission_done <= '1';
                        r_request_release <= r_cfg_csrl;
                    end if;
                end if;
                
                -- flag done when transmission busy and no bits are present
                if r_spi_scounter = 0 and r_transmission_busy = '1' then
                    r_transmission_busy <= '0';
                    r_transmission_done <= '1';
                    r_request_release <= r_cfg_csrl;
                end if;
            end if;
        end if;
    end process proc_data_shifting;

    proc_wishbone_slave : process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                r_cfg_en <= '0';
                r_cfg_cpol <= '0';
                r_cfg_cpha <= '0';
                r_cfg_bord <= '0';
                r_cfg_csrl <= '0';
                r_spi_csn <= (others => '1');
                r_fdiv_ceil <= 0;
                r_request_wr <= '0';
                r_request_rd <= '0';
                r_ack <= '0';
                -- r_dat <= (others => '0');
            else
                r_request_wr <= '0';
                r_request_rd <= '0';
                r_ack <= '0';

                -- release all cs when requested by the shifter
                if r_request_release = '1' then
                    r_spi_csn <= (others => '1');
                end if;

                -- wishbone handler
                if i_cyc = '1' and r_ack = '0' then
                    case i_adr is
                        -- CTRL
                        when "00" =>
                            if i_we = '1' then
                                r_cfg_cpol <= i_dat(7);
                                r_cfg_cpha <= i_dat(6);
                                r_cfg_bord <= i_dat(5);
                                r_cfg_csrl <= i_dat(4);
                                r_cfg_en <= i_dat(0);
                            else
                                r_dat(7) <= r_cfg_cpol;
                                r_dat(6) <= r_cfg_cpha;
                                r_dat(5) <= r_cfg_bord;
                                r_dat(4) <= r_cfg_csrl;
                                r_dat(3) <= '0';
                                r_dat(2) <= r_transmission_busy;
                                r_dat(1) <= r_transmission_done;
                                r_dat(0) <= r_cfg_en;
                            end if;

                        -- FDIV
                        when "01" =>
                            if i_we = '1' then
                                r_fdiv_ceil <= to_integer(unsigned(i_dat));
                            else
                                r_dat <= std_logic_vector(to_unsigned(r_fdiv_ceil, 8));
                            end if;

                        -- CS
                        when "10" =>
                            if i_we = '1' then
                                r_spi_csn <= i_dat(p_cs_count - 1 downto 0);
                            else
                                for i in 0 to 7 loop
                                    r_dat(i) <= r_spi_csn(i) when i < p_cs_count else '1';
                                end loop;
                            end if;

                        -- DATA
                        when "11" =>
                            if i_we = '1' then
                                r_request_wr <= '1';
                            else
                                r_request_rd <= '1';
                                r_dat <= r_spi_shifter;
                            end if;

                        when others =>
                            null;
                    end case;

                    r_ack <= '1';
                end if;
            end if;
        end if;
    end process proc_wishbone_slave;

    o_ack <= r_ack;
    o_dat <= r_dat;

    -- drive CSNs with their appropriate values
    gen_drive_csn : for i in 0 to p_cs_count - 1 generate
        io_spi_csn(i) <= '0' when r_spi_csn(i) = '0' and r_cfg_en = '1' else p_cs_release_value;
    end generate gen_drive_csn;

    -- drive spi clock based on CPOL, busy transmission and core enable
    io_spi_clk <= r_spi_clk when r_cfg_cpol = '0' else not(r_spi_clk);

    -- drive spi mosi based on no bits in shifter and core enable
    io_spi_mosi <= r_spi_shifter(r_spi_shifter'high) when r_tristate_mosi = '0' and r_cfg_en = '1' else 'Z';

    -- keep miso tri-stated to act as input
    io_spi_miso <= 'Z';
    
end architecture rtl;