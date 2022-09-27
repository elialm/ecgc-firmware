----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/31/2022 04:10:42 PM
-- Design Name: 
-- Module Name: gb_decoder - behaviour
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
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity gb_decoder is
    generic (
        ENABLE_TIMEOUT_DETECTION	: boolean := false);
    port (
        GB_CLK      : in std_logic;
        GB_ADDR     : in std_logic_vector(15 downto 0);
        GB_DATA_IN  : in std_logic_vector(7 downto 0);
        GB_DATA_OUT : out std_logic_vector(7 downto 0);
        GB_RDN      : in std_logic;
        GB_CSN      : in std_logic;
        
        CLK_I 		: in std_logic;
        RST_I 		: in std_logic;
        CYC_O 		: out std_logic;
        WE_O  		: out std_logic;
        ADR_O 		: out std_logic_vector(15 downto 0);
        DAT_I 		: in std_logic_vector(7 downto 0);
        DAT_O 		: out std_logic_vector(7 downto 0);
        ACK_I 		: in std_logic;
        
        ACCESS_ROM	: out std_logic;
        ACCESS_RAM	: out std_logic;
        WB_TIMEOUT	: out std_logic);
end gb_decoder;

architecture behaviour of gb_decoder is

    type WB_STATE_TYPE is (WBS_AWAIT_RISING_CLK, WBS_IDLE, WBS_AWAIT_GB_WRITE, WBS_AWAIT_SLAVE, WBS_AWAIT_FALLING_CLK);

    component synchroniser is
    generic (
        FF_COUNT : natural := 2;
        DATA_WIDTH : natural := 1;
        RESET_VALUE : std_logic := '0');
    port (
        CLK : in std_logic;
        RST : in std_logic;
        DAT_IN : in std_logic_vector(DATA_WIDTH-1 downto 0);
        DAT_OUT : out std_logic_vector(DATA_WIDTH-1 downto 0));
    end component;
    
    -- Output register for latching read data from WishBone
    signal data_read_register : std_logic_vector(7 downto 0);
    
    -- Synchronised signals from GameBoy
    signal gb_clk_sync : std_logic;
    signal gb_csn_sync : std_logic;
    signal gb_addr_sync : std_logic_vector(2 downto 0);
    signal gb_data_sync : std_logic_vector(7 downto 0);
    
    -- Access signals (comnbinatorial)
    signal gb_access_rom 	: std_logic;
    signal gb_access_ram 	: std_logic;
    signal gb_access_cart	: std_logic;
    
    -- WishBone signals
    signal wb_state : WB_STATE_TYPE;
    signal wb_cyc   : std_logic;

    signal cyc_counter	: std_logic_vector(3 downto 0);
    signal cyc_timeout	: std_logic;

begin

    ADDRESS_SYNCHRONISER : component synchroniser
    generic map (
        DATA_WIDTH => 3)
    port map (
        CLK => CLK_I,
        RST => RST_I,
        DAT_IN => GB_ADDR(15 downto 13),
        DAT_OUT => gb_addr_sync);
        
    CLK_SYNCHRONISER : component synchroniser
    port map (
        CLK => CLK_I,
        RST => RST_I,
        DAT_IN(0) => GB_CLK,
        DAT_OUT(0) => gb_clk_sync);
        
    CSN_SYNCHRONISER : component synchroniser
    port map (
        CLK => CLK_I,
        RST => RST_I,
        DAT_IN(0) => GB_CSN,
        DAT_OUT(0) => gb_csn_sync);
        
    GB_DATA_OUT <= data_read_register;
    
    -- Signals for determining type of access
    gb_access_rom <= not(gb_addr_sync(2));												-- A15
    gb_access_ram <= not(gb_csn_sync) and not(gb_addr_sync(1)) and gb_addr_sync(0);		-- ... not(A14) and A13;
    gb_access_cart <= gb_access_rom or gb_access_ram;

    ACCESS_ROM <= gb_access_rom;
    ACCESS_RAM <= gb_access_ram;
    
    -- Control Wishbone cycles
    process (CLK_I)
    begin
        if rising_edge(CLK_I) then
            if RST_I = '1' then
                data_read_register <= "00000000";
                wb_state <= WBS_AWAIT_RISING_CLK;
                wb_cyc <= '0';
                cyc_counter <= (others => '0');
                WE_O <= '0';
                WB_TIMEOUT <= '0';
            else
                -- NOTE: WBS_AWAIT_RISING_CLK and WBS_IDLE could be implemented into 1 state... probably...
                case wb_state is
                    when WBS_AWAIT_RISING_CLK =>
                        if gb_clk_sync = '1' then
                            wb_state <= WBS_IDLE;
                        end if;
                    when WBS_IDLE =>
                        if gb_access_cart = '1' then
                            if GB_RDN = '0' then
                                -- Reading from cart
                                wb_cyc <= '1';
                                wb_state <= WBS_AWAIT_SLAVE;
                                cyc_counter <= "1001";
                            else
                                -- Writing to cart
                                wb_state <= WBS_AWAIT_GB_WRITE;
                            end if;
                        end if;
                    when WBS_AWAIT_GB_WRITE =>
                        if gb_clk_sync = '0' then
                            -- Start write on falling edge
                            wb_cyc <= '1';
                            WE_O <= '1';
                            DAT_O <= GB_DATA_IN;
                            wb_state <= WBS_AWAIT_SLAVE;
                            cyc_counter <= "1001";
                        end if;
                    when WBS_AWAIT_SLAVE =>
                        if ACK_I = '1' then
                            wb_cyc <= '0';
                            WE_O <= '0';
                            data_read_register <= DAT_I;
                            wb_state <= WBS_AWAIT_FALLING_CLK;
                        elsif cyc_timeout = '1' then
                            -- WishBone timeout occurred							
                            WB_TIMEOUT <= '1';
                        end if;
                    when WBS_AWAIT_FALLING_CLK =>
                        if gb_clk_sync = '0' then
                            wb_state <= WBS_AWAIT_RISING_CLK;
                        end if;
                end case;
            end if;

            -- Decrement counter
            if cyc_timeout = '0' and ENABLE_TIMEOUT_DETECTION then
                cyc_counter <= std_logic_vector(unsigned(cyc_counter) - 1);
            end if;
        end if;
    end process;

    CYC_TIMEOUT_SIGNAL : if ENABLE_TIMEOUT_DETECTION generate
        cyc_timeout <= nor_reduce(cyc_counter);
    else generate
        cyc_timeout <= '0';
    end generate;

    CYC_O <= wb_cyc;
    
    -- TODO: test whether it is really necessary to only output when
    --			in a cycle. The slave should ignore it otherwise
    --			anyways. GB_ADDR being asychronous to CLK_I could 
    --			introduce wierd glitches, who knows...
    ADR_O <= GB_ADDR when wb_cyc = '1' else x"0000";
    
end behaviour;
