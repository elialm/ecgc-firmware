----------------------------------------------------------------------------------
-- Engineer: Elijah Almeida Coimbra
-- 
-- Create Date: 06/26/2022 15:30:20 PM
-- Design Name: Reset controller
-- Module Name: reset - behaviour
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Documentation
--
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity as4c32m8sa_controller_tb is
end as4c32m8sa_controller_tb;

architecture behaviour of as4c32m8sa_controller_tb is

    signal dram_clk_i   : std_logic := '0';
    signal dram_rst_i   : std_logic := '1';
    signal dram_cyc_i   : std_logic := '0';
    signal dram_we_i    : std_logic := '0';
    signal dram_adr_i   : std_logic_vector(22 downto 0) := (others => '0');
    signal dram_tga_i   : std_logic_vector(1 downto 0) := (others => '0');
    signal dram_dat_i   : std_logic_vector(7 downto 0) := (others => '0');
    signal dram_dat_o   : std_logic_vector(7 downto 0);
    signal dram_err_o   : std_logic;
    signal dram_ack_o   : std_logic;

    signal dram_ready   : std_logic;
    
    signal dram_cke     : std_logic;
    signal dram_ba      : std_logic_vector(1 downto 0);
    signal dram_a       : std_logic_vector(12 downto 0);
    signal dram_csn     : std_logic;
    signal dram_rasn    : std_logic;
    signal dram_casn    : std_logic;
    signal dram_wen     : std_logic;
    signal dram_dqm     : std_logic;
    signal dram_dq      : std_logic_vector(7 downto 0);

    signal reset_extend : natural := 0;

begin

    DRAM_CONTROLLER : entity work.as4c32m8sa_controller
    port map (
        CLK_I => dram_clk_i,
        RST_I => dram_rst_i,
        CYC_I => dram_cyc_i,
        WE_I => dram_we_i,
        ADR_I => dram_adr_i,
        TGA_I => dram_tga_i,
        DAT_I => dram_dat_i,
        DAT_O => dram_dat_o,
        ERR_O => dram_err_o,
        ACK_O => dram_ack_o,

        READY => dram_ready,

        CKE => dram_cke,
        BA => dram_ba,
        A => dram_a,
        CSN => dram_csn,
        RASN => dram_rasn,
        CASN => dram_casn,
        WEN => dram_wen,
        DQM => dram_dqm,
        DQ => dram_dq);

    -- Clock generator
    process
    begin
        -- wait for 18.79699248 ns;
        wait for 9.398496241 ns;
        dram_clk_i <= not(dram_clk_i);
    end process;

    -- Reset generator
    process (dram_clk_i)
    begin
        if rising_edge(dram_clk_i) then
            if reset_extend < 16 then
                reset_extend <= reset_extend + 1;
                dram_rst_i <= '1';
            else
                dram_rst_i <= '0';
            end if;
        end if;
    end process;

    -- DRAM access test
    process (dram_clk_i)
    begin
        if rising_edge(dram_clk_i) and dram_ready = '1' then
            -- much stuff
        end if;
    end process;
	
end behaviour;
