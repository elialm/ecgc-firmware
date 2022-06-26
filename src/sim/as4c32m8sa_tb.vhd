----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/04/2022 20:21:43 PM
-- Design Name: 
-- Module Name: as4c32m8sa_tb - behaviour
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: as4c32m8sa_sim.vhd
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity as4c32m8sa_tb is
end as4c32m8sa_tb;

architecture behaviour of as4c32m8sa_tb is

	-- Clock cycles to wait before issuing commands
	constant INITIALISATION_COUNTER_TOP : natural := 5002;

	component as4c32m8sa_sim is
		port (
			CLK		: in std_logic;
			CKE		: in std_logic;
			BA		: in std_logic_vector(1 downto 0);
			A		: in std_logic_vector(12 downto 0);
			CSN		: in std_logic;
			RASN	: in std_logic;
			CASN	: in std_logic;
			WEN		: in std_logic;
			DQM		: in std_logic;
			DQ		: inout std_logic_vector(7 downto 0));
	end component;

	signal dram_clk 	: std_logic	:= '0';
	signal dram_cke		: std_logic := '0';
	signal dram_ba		: std_logic_vector(1 downto 0) := "00";
	signal dram_a		: std_logic_vector(12 downto 0) := "0000000000000";
	signal dram_csn		: std_logic := '1';
	signal dram_rasn	: std_logic := '1';
	signal dram_casn	: std_logic := '1';
	signal dram_wen		: std_logic := '1';
	signal dram_dqm		: std_logic := '1';
	signal dram_dq		: std_logic_vector(7 downto 0) := "ZZZZZZZZ";

	signal initialisation_counter : natural := 0;
	signal initialisation_counter_expired : boolean := false;

	signal transaction_id : natural := 0;

begin

    DRAM_INST : component as4c32m8sa_sim
		port map (
			CLK => dram_clk,
			CKE => dram_cke,
			BA => dram_ba,
			A => dram_a,
			CSN => dram_csn,
			RASN => dram_rasn,
			CASN => dram_casn,
			WEN => dram_wen,
			DQM => dram_dqm,
			DQ => dram_dq);
			
	-- Main clock
	process
	begin
		loop
			wait for 20 ns;
			dram_clk <= not(dram_clk);
		end loop;
	end process;

	-- Wait for appr. 200us beforehand
	process (dram_clk)
	begin
		if rising_edge(dram_clk) then
			if initialisation_counter /= INITIALISATION_COUNTER_TOP  then
				initialisation_counter <= initialisation_counter + 1;
			else
				initialisation_counter_expired <= true;
			end if;
		end if;
	end process;

	-- Bus transactions
	process (dram_clk)
	begin
		if falling_edge(dram_clk) and initialisation_counter_expired then
			transaction_id <= transaction_id + 1;
			dram_csn <= '1';

			case transaction_id is
				when 0 =>
					dram_csn <= '0';
					dram_cke <= '1';
				when 1 =>
					dram_csn <= '0';
					dram_rasn <= '0';
					dram_wen <= '0';
					dram_a(10) <= '1';
				when 2 =>
					dram_csn <= '0';
					dram_a(10) <= '0';
					dram_a(5) <= '1';
					dram_casn <= '0';
				when others =>
					transaction_id <= transaction_id;
			end case;
		end if;
	end process;
	    
end behaviour;
