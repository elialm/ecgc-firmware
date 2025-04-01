----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 27/03/2025 15:28:42 PM
-- Package Name: cart_pkg
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package cart_pkg is

    -- Frequencies used for timing calculations
    constant c_pll_clkop_freq : real := 99.999999;
    constant c_pll_clkok_freq : real := c_pll_clkop_freq / 100.0;

    component spi_core
        generic(
            p_cs_count         : positive  := 3;
            p_cs_release_value : std_logic := '1'
        );
        port(
            i_clk       : in    std_logic;
            i_rst       : in    std_logic;
            i_cyc       : in    std_logic;
            o_ack       : out   std_logic;
            i_we        : in    std_logic;
            i_adr       : in    std_logic_vector(1 downto 0);
            o_dat       : out   std_logic_vector(7 downto 0);
            i_dat       : in    std_logic_vector(7 downto 0);
            io_spi_clk  : inout std_logic;
            io_spi_mosi : inout std_logic;
            io_spi_miso : inout std_logic;
            io_spi_csn  : inout std_logic_vector(p_cs_count - 1 downto 0)
        );
    end component;

    component boot_ram is
        port(
            Clock   : in  std_logic;
            ClockEn : in  std_logic;
            Reset   : in  std_logic;
            WE      : in  std_logic;
            Address : in  std_logic_vector(11 downto 0);
            Data    : in  std_logic_vector(7 downto 0);
            Q       : out std_logic_vector(7 downto 0));
    end component;

    component cart_ram
        port(
            Clock   : in  std_logic;
            ClockEn : in  std_logic;
            Reset   : in  std_logic;
            WE      : in  std_logic;
            Address : in  std_logic_vector(10 downto 0);
            Data    : in  std_logic_vector(7 downto 0);
            Q       : out std_logic_vector(7 downto 0));
    end component;

    component synchroniser is
        generic(
            p_ff_count    : natural   := 2;
            p_data_width  : natural   := 1;
            p_reset_value : std_logic := '0');
        port(
            i_clk  : in  std_logic;
            i_rst  : in  std_logic;
            i_din  : in  std_logic_vector(p_data_width - 1 downto 0);
            o_dout : out std_logic_vector(p_data_width - 1 downto 0));
    end component;

    component pll
        port(
            clk   : in  std_logic;
            clkop : out std_logic;
            clkok : out std_logic;
            lock  : out std_logic
        );
    end component;

    component reset
        generic(
            p_aux_ff_count : positive := 9
        );
        port(
            i_clk        : in  std_logic;
            i_pll_lock   : in  std_logic;
            i_ext_softn  : in  std_logic;
            i_aux_soft   : in  std_logic;
            i_dbg_active : in  std_logic;
            o_gb_resetn  : out std_logic;
            o_soft_reset : out std_logic;
            o_hard_reset : out std_logic
        );
    end component;

    component gb_decoder
        generic(
            p_enable_timeout_detection : boolean := false;
            p_clk_freq                 : real    := c_pll_clkop_freq
        );
        port(
            i_gb_clk       : in  std_logic;
            i_gb_addr      : in  std_logic_vector(15 downto 0);
            i_gb_din       : in  std_logic_vector(7 downto 0);
            o_gb_dout      : out std_logic_vector(7 downto 0);
            i_gb_rdn       : in  std_logic;
            i_gb_csn       : in  std_logic;
            i_clk          : in  std_logic;
            i_rst          : in  std_logic;
            o_dma_cyc      : out std_logic;
            o_dma_we       : out std_logic;
            o_dma_adr      : out std_logic_vector(3 downto 0);
            o_dma_dat      : out std_logic_vector(7 downto 0);
            i_dma_dat      : in  std_logic_vector(7 downto 0);
            i_dma_ack      : in  std_logic;
            o_mbch_cyc     : out std_logic;
            o_mbch_we      : out std_logic;
            o_mbch_adr     : out std_logic_vector(15 downto 0);
            o_mbch_dat     : out std_logic_vector(7 downto 0);
            i_mbch_dat     : in  std_logic_vector(7 downto 0);
            i_mbch_ack     : in  std_logic;
            i_dma_busy     : in  std_logic;
            i_selected_mbc : in  std_logic_vector(2 downto 0);
            o_wr_timeout   : out std_logic;
            o_rd_timeout   : out std_logic
        );
    end component;

    component dma_controller
        port(
            i_clk         : in  std_logic;
            i_rst         : in  std_logic;
            o_dma_cyc     : out std_logic;
            i_dma_ack     : in  std_logic;
            o_dma_we      : out std_logic;
            o_dma_adr     : out std_logic_vector(15 downto 0);
            o_dma_dat     : out std_logic_vector(7 downto 0);
            i_dma_dat     : in  std_logic_vector(7 downto 0);
            i_cfg_cyc     : in  std_logic;
            o_cfg_ack     : out std_logic;
            i_cfg_we      : in  std_logic;
            i_cfg_adr     : in  std_logic_vector(3 downto 0);
            o_cfg_dat     : out std_logic_vector(7 downto 0);
            i_cfg_dat     : in  std_logic_vector(7 downto 0);
            o_status_busy : out std_logic
        );
    end component;

    component uart_debug
        generic(
            p_clk_freq  : real    := c_pll_clkop_freq;
            p_baud_rate : natural := 115200;
            p_parity    : string  := "NONE";
            p_stop_bits : natural := 1
        );
        port(
            i_clk        : in  std_logic;
            i_rst        : in  std_logic;
            o_cyc        : out std_logic;
            i_ack        : in  std_logic;
            o_we         : out std_logic;
            o_adr        : out std_logic_vector(15 downto 0);
            o_dat        : out std_logic_vector(7 downto 0);
            i_dat        : in  std_logic_vector(7 downto 0);
            o_serial_tx  : out std_logic;
            i_serial_rx  : in  std_logic;
            o_dbg_active : out std_logic
        );
    end component;

    component mbch
        port(
            i_clk                : in    std_logic;
            i_rst                : in    std_logic;
            i_dbg_cyc            : in    std_logic;
            i_dbg_we             : in    std_logic;
            o_dbg_ack            : out   std_logic;
            i_dbg_adr            : in    std_logic_vector(15 downto 0);
            i_dbg_dat            : in    std_logic_vector(7 downto 0);
            o_dbg_dat            : out   std_logic_vector(7 downto 0);
            i_dma_cyc            : in    std_logic;
            i_dma_we             : in    std_logic;
            o_dma_ack            : out   std_logic;
            i_dma_adr            : in    std_logic_vector(15 downto 0);
            i_dma_dat            : in    std_logic_vector(7 downto 0);
            o_dma_dat            : out   std_logic_vector(7 downto 0);
            i_gbd_cyc            : in    std_logic;
            i_gbd_we             : in    std_logic;
            o_gbd_ack            : out   std_logic;
            i_gbd_adr            : in    std_logic_vector(15 downto 0);
            i_gbd_dat            : in    std_logic_vector(7 downto 0);
            o_gbd_dat            : out   std_logic_vector(7 downto 0);
            o_xram_cyc           : out   std_logic;
            o_xram_we            : out   std_logic;
            i_xram_ack           : in    std_logic;
            o_xram_adr           : out   std_logic_vector(23 downto 0);
            o_xram_tga           : out   std_logic;
            i_xram_dat           : in    std_logic_vector(7 downto 0);
            o_xram_dat           : out   std_logic_vector(7 downto 0);
            i_gpio               : in    std_logic_vector(3 downto 0);
            o_gpio               : out   std_logic_vector(3 downto 0);
            io_fpga_spi_clk      : inout std_logic;
            io_fpga_spi_miso     : inout std_logic;
            io_fpga_spi_mosi     : inout std_logic;
            o_fpga_spi_flash_csn : out   std_logic;
            o_fpga_spi_rtc_csn   : out   std_logic;
            o_fpga_spi_sd_csn    : out   std_logic;
            o_select_mbc         : out   std_logic_vector(2 downto 0);
            o_soft_reset_req     : out   std_logic;
            i_soft_reset         : in    std_logic;
            i_dbg_active         : in    std_logic;
            i_dma_busy           : in    std_logic
        );
    end component;

    component uart_core
        generic(
            p_clk_freq  : real    := 100.0;
            p_baud_rate : natural := 115200;
            p_parity    : string  := "NONE";
            p_data_bits : natural := 8;
            p_stop_bits : natural := 1
        );
        port(
            i_clk       : in  std_logic;
            i_rst       : in  std_logic;
            i_tx_wr     : in  std_logic;
            i_tx_dat    : in  std_logic_vector(p_data_bits - 1 downto 0);
            o_tx_rdy    : out std_logic;
            i_rx_rd     : in  std_logic;
            o_rx_dat    : out std_logic_vector(p_data_bits - 1 downto 0);
            o_rx_rdy    : out std_logic;
            o_serial_tx : out std_logic;
            i_serial_rx : in  std_logic
        );
    end component;

    component as1c8m16pl_controller
        generic(
            p_clk_freq : real := 100.0
        );
        port(
            i_clk      : in    std_logic;
            i_rst      : in    std_logic;
            i_cyc      : in    std_logic;
            i_we       : in    std_logic;
            o_ack      : out   std_logic;
            i_adr      : in    std_logic_vector(23 downto 0);
            i_tga      : in    std_logic_vector(0 downto 0);
            i_dat      : in    std_logic_vector(7 downto 0);
            o_dat      : out   std_logic_vector(7 downto 0);
            io_ram_adq : inout std_logic_vector(15 downto 0);
            o_ram_a    : out   std_logic_vector(5 downto 0);
            o_ram_advn : out   std_logic;
            o_ram_ce0n : out   std_logic;
            o_ram_ce1n : out   std_logic;
            o_ram_clk  : out   std_logic;
            o_ram_cre  : out   std_logic;
            o_ram_lbn  : out   std_logic;
            o_ram_ubn  : out   std_logic;
            o_ram_oen  : out   std_logic;
            i_ram_wait : in    std_logic;
            o_ram_wen  : out   std_logic
        );
    end component;

    function nor_reduce(slv : std_logic_vector) return std_logic;
    function or_reduce(slv : std_logic_vector) return std_logic;
    function nand_reduce(slv : std_logic_vector) return std_logic;
    function and_reduce(slv : std_logic_vector) return std_logic;

end package cart_pkg;

package body cart_pkg is

    function nor_reduce(slv : std_logic_vector)
    return std_logic is
    begin
        return not or_reduce(slv);
    end function nor_reduce;

    function or_reduce(slv : std_logic_vector)
    return std_logic is
        variable x : std_logic := '0';
    begin
        for i in slv'range loop
            x := x or slv(i);
        end loop;

        return x;
    end function or_reduce;

    function nand_reduce(slv : std_logic_vector)
    return std_logic is
    begin
        return not and_reduce(slv);
    end function nand_reduce;

    function and_reduce(slv : std_logic_vector)
    return std_logic is
        variable x : std_logic := '1';
    begin
        for i in slv'range loop
            x := x and slv(i);
        end loop;

        return x;
    end function and_reduce;

end package body cart_pkg;
