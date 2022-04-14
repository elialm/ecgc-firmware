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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity gb_decoder is
    port (
        USER_RST    : in std_logic;
        GB_CLK      : in std_logic;
        GB_ADDR     : in std_logic_vector(15 downto 0);
        GB_DATA_IN  : in std_logic_vector(7 downto 0);
        GB_DATA_OUT : out std_logic_vector(7 downto 0);
        GB_RDN      : in std_logic;
		GB_CSN      : in std_logic;
        
        CLK_I : in std_logic;
		STB_O : out std_logic;
		CYC_O : out std_logic;
		WE_O  : out std_logic;
        ADR_O : out std_logic_vector(15 downto 0);
        DAT_I : in std_logic_vector(7 downto 0);
        DAT_O : out std_logic_vector(7 downto 0);
        ACK_I : in std_logic);
end gb_decoder;

architecture behaviour of gb_decoder is

	type WB_STATE_TYPE is (WBS_AWAIT_RISING_CLK, WBS_IDLE, WBS_AWAIT_SLAVE, WBS_AWAIT_FALLING_CLK);

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
	signal gb_rdn_sync : std_logic;
	signal gb_addr_sync : std_logic_vector(15 downto 0);
	signal gb_data_sync : std_logic_vector(7 downto 0);
	
	-- Access signals (comnbinatorial)
	signal gb_access_rom : std_logic;
	signal gb_access_ram : std_logic;
	
	-- WishBone signals
	signal wb_state : WB_STATE_TYPE;

begin

    ADDRESS_SYNCHRONISER : component synchroniser
    generic map (
        DATA_WIDTH => 16)
    port map (
        CLK => CLK_I,
        RST => USER_RST,
        DAT_IN => GB_ADDR,
        DAT_OUT => gb_addr_sync);
        
    DATA_SYNCHRONISER : component synchroniser
    generic map (
        DATA_WIDTH => 8)
    port map (
        CLK => CLK_I,
        RST => USER_RST,
        DAT_IN => GB_DATA_IN,
        DAT_OUT => gb_data_sync);
		
	CLK_SYNCHRONISER : component synchroniser
	--generic map (
        --FF_COUNT => 3)
	port map (
		CLK => CLK_I,
		RST => USER_RST,
		DAT_IN(0) => GB_CLK,
		DAT_OUT(0) => gb_clk_sync);
		
	CSN_SYNCHRONISER : component synchroniser
	port map (
		CLK => CLK_I,
		RST => USER_RST,
		DAT_IN(0) => GB_CSN,
		DAT_OUT(0) => gb_csn_sync);
		
	RDN_SYNCHRONISER : component synchroniser
	port map (
		CLK => CLK_I,
		RST => USER_RST,
		DAT_IN(0) => GB_RDN,
		DAT_OUT(0) => gb_rdn_sync);
        
    GB_DATA_OUT <= data_read_register;
	
	-- Signals for determining type of access
	gb_access_rom <= not(gb_addr_sync(15));
	gb_access_ram <= not(gb_csn_sync) and not(gb_addr_sync(14)) and gb_addr_sync(13);	
	
	-- Control Wishbone cycles
	process (CLK_I)
	begin
		if rising_edge(CLK_I) then
			if USER_RST = '1' then
				data_read_register <= "00000000";
				wb_state <= WBS_AWAIT_RISING_CLK;
				STB_O <= '0';
				CYC_O <= '0';
				WE_O <= '0';
			else
				-- TODO: implement write state
				-- NOTE: WBS_AWAIT_RISING_CLK and WBS_IDLE could be implemented into 1 state
				case wb_state is
					when WBS_AWAIT_RISING_CLK =>
						if gb_clk_sync = '1' then
							wb_state <= WBS_IDLE;
						end if;
					when WBS_IDLE =>
						if (gb_access_rom or gb_access_ram) = '1' then
							STB_O <= '1';
							CYC_O <= '1';
							--WE_O <= gb_rdn_sync;
							WE_O <= '0';
							wb_state <= WBS_AWAIT_SLAVE;
						end if;
					when WBS_AWAIT_SLAVE =>
						if ACK_I = '1' then
							STB_O <= '0';
							CYC_O <= '0';
							WE_O <= '0';
							data_read_register <= DAT_I;
							wb_state <= WBS_AWAIT_FALLING_CLK;
						end if;
					when WBS_AWAIT_FALLING_CLK =>
						if gb_clk_sync = '0' then
							wb_state <= WBS_AWAIT_RISING_CLK;
						end if;
				end case;
			end if;
		end if;
	end process;
	
	ADR_O <= gb_addr_sync;
    
end behaviour;
