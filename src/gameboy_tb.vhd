----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/31/2022 02:16:43 PM
-- Design Name: 
-- Module Name: testbench - behaviour
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
use IEEE.NUMERIC_STD.ALL;

entity gameboy_tb is
end gameboy_tb;

architecture behaviour of gameboy_tb is

	signal gb_internal : std_logic := '0';
	signal gb_addr     : std_logic_vector(15 downto 0) := "UUUUUUUUUUUUUUUU";
	signal gb_data     : std_logic_vector(7 downto 0) := "ZZZZZZZZ";
	signal gb_clk      : std_logic := '0';
	signal gb_wrn      : std_logic := '1';
	signal gb_csn      : std_logic := '1';
	signal gb_rdn      : std_logic := '1';
	signal user_rst    : std_logic := '0';

begin

    CARTRIDGE_INST : entity work.cart_tl
    port map (
        GB_CLK => gb_clk,
        GB_ADDR => gb_addr,
        GB_DATA => gb_data,
		GB_RDN => gb_rdn,
		GB_CSN => gb_csn,
		USER_RST => user_rst);
    
	-- GameBoy simulation	
	process
	
		 --Each element is a bitfield
			--0-7		: data (if write)
			--8-23	: address
			--24		: 0 = read, 1 = write
			--25		: 1 = perform cart access, 0 = perform internal access
		type gb_bus_transactions is array (integer range <>) of std_logic_vector(25 downto 0);
		variable test_bus_transactions : gb_bus_transactions(0 to 17) := (
			b"10_0000_0001_0000_0000_0000_0000",	-- NOP
			b"10_0000_0001_0000_0001_0000_0000",	-- JP $0150
			b"10_0000_0001_0000_0010_0000_0000",
			b"10_0000_0001_0000_0011_0000_0000",
			b"00_0000_0000_0000_0000_0000_0000",	-- idle bus...
			b"10_0000_0001_0101_0000_0000_0000",	-- DI 
			b"10_0000_0001_0101_0001_0000_0000",	-- LD SP, $FFFE
			b"10_0000_0001_0101_0010_0000_0000",
			b"10_0000_0001_0101_0011_0000_0000",
			b"10_0000_0001_0101_0100_0000_0000",	-- LD HL, $FF40
			b"10_0000_0001_0101_0101_0000_0000",
			b"10_0000_0001_0101_0110_0000_0000",
			b"10_0000_0001_0101_0111_0000_0000",	-- RES 7, [HL]
			b"10_0000_0001_0101_1000_0000_0000",
			b"00_0000_0000_0000_0000_0000_0000",	-- idle bus...
			b"00_0000_0000_0000_0000_0000_0000",	-- idle bus...
			b"11_0000_0001_0000_0000_1010_0101",	-- not an instruction, just to test if cart correctly ignores writes to ROM
			b"10_0000_0001_0000_0000_0000_0000");	-- followed by a read to see if the cart recovers
			
		type bus_state is (BS_CLK_UP_UP, BS_CLK_UP_DOWN, BS_CLK_HIGH_UP, BS_CLK_HIGH_DOWN, BS_CLK_DOWN_UP, BS_CLK_DOWN_DOWN, BS_CLK_LOW_UP, BS_CLK_LOW_DOWN);
	
		variable current_transaction : std_logic_vector(25 downto 0);
		variable transaction_address : std_logic_vector(15 downto 0);
		variable transaction_data : std_logic_vector(7 downto 0);
		variable transaction_is_idle : boolean;
		variable transaction_is_read : boolean;
	begin
	
		user_rst <= '1';
		for i in 0 to 1 loop
			wait for 500 ns;
			gb_clk <= not(gb_clk);
		end loop;
		user_rst <= '0';
		wait for 875 ns;
	
		for i in test_bus_transactions'low to test_bus_transactions'high loop
			current_transaction := test_bus_transactions(i);
			transaction_address := current_transaction(23 downto 8);
			transaction_data := current_transaction(7 downto 0);
			transaction_is_idle := current_transaction(25) = '0';
			transaction_is_read := current_transaction(24) = '0';
			
			for state in bus_state loop
				wait for 125 ns;
				
				gb_internal <= not(gb_internal);
				if not(transaction_is_idle) then
					case state is
						when BS_CLK_UP_UP =>
							gb_clk <= '1';
							gb_data <= "UUUUUUUU";
							gb_addr(14 downto 0) <= "UUUUUUUUUUUUUUU";
							gb_rdn <= '0';
							gb_addr(15) <= '1';
							gb_csn <= '1';
						when BS_CLK_UP_DOWN =>
							gb_addr(14 downto 0) <= transaction_address(14 downto 0);
							if not(transaction_is_read) then
								gb_rdn <= '1';
							end if;
						when BS_CLK_HIGH_UP =>
							gb_addr(15) <= transaction_address(15);
							gb_csn <= not(transaction_address(15));
							-- Data should be presented during read
							if transaction_is_read then
								gb_data <= "ZZZZZZZZ";
							end if;
						when BS_CLK_HIGH_DOWN =>
							null;
						when BS_CLK_DOWN_UP =>
							gb_clk <= '0';
							if not(transaction_is_read) then
								gb_wrn <= '0';
								gb_data <= transaction_data;
							end if;
						when BS_CLK_DOWN_DOWN =>
							null;
						when BS_CLK_LOW_UP =>
							-- Data is sampled (I think?)
							null;
						when BS_CLK_LOW_DOWN =>
							gb_wrn <= '1';
					end case;
				else
					gb_addr(14 downto 0) <= "UUUUUUUUUUUUUUU";
					gb_addr(15) <= '1';
					gb_csn <= '1';
					gb_data <= "UUUUUUUU";
					gb_rdn <= '0';
					gb_wrn <= '1';
					
					case state is
						when BS_CLK_UP_UP =>
							gb_clk <= '1';
						when BS_CLK_DOWN_UP =>
							gb_clk <= '0';
						when others =>
							null;
					end case;
				end if;
			end loop;
		end loop;
		
		wait;
	end process;
	    
end behaviour;
