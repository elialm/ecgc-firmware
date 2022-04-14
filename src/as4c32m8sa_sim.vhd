----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/04/2022 19:56:43 PM
-- Design Name: 
-- Module Name: as4c32m8sa_sim - behaviour
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
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;

library STD;
use STD.textio.all;

entity as4c32m8sa_sim is
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
end as4c32m8sa_sim;

architecture behaviour of as4c32m8sa_sim is

	type BACK_STATUS_TYPE is (BS_AWAIT_STABLE, BS_AWAIT_PRECHARGE_ALL, BS_AWAIT_MODE_SET, BS_IDLE, BS_ACTIVE, BS_SELF_REFRESH);
	type BANK_STATUS_ARRAY is array (3 downto 0) of BACK_STATUS_TYPE;
	type REFRESH_COUNTERS_ARRAY is array (3 downto 0) of natural;
	type DRAM_CMD is
		(CMD_BANK_ACTIVATE, CMD_BANK_PRECHARGE, CMD_PRECHARGE_ALL,
		CMD_WRITE, CMD_WRITE_AUTO_PRECHARGE, CMD_READ, CMD_READ_AUTO_PRECHARGE,
		CMD_MODE_REGISTER_SET, CMD_NOP, CMD_BURST_STOP, CMD_DEVICE_DESELECT,
		CMD_AUTO_REFRESH, CMD_SELF_REFRESH_ENTRY, CMD_SELF_REFRESH_EXIT,
		CMD_CLOCK_SUSPEND_MODE_ENTRY, CMD_POWER_DOWN_MODE_ENTRY,
		CMD_CLOCK_SUSPEND_MODE_EXIT, CMD_POWER_DOWN_MODE_EXIT, CMD_OUTPUT_ENABLE,
		CMD_OUTPUT_DISABLE);
		
	type BANK_STATUS_GROUP_TYPE is (BSG_IDLE, BSG_ACTIVE, BSG_ANY);
	type DRAM_CMD_ENCODING_TYPE is record
		previous_cke		: std_logic;
		current_cke			: std_logic;
		dqm					: std_logic;
		ba					: std_logic_vector(1 downto 0);
		a					: std_logic_vector(12 downto 0);
		csn					: std_logic;
		rasn				: std_logic;
		casn				: std_logic;
		wen					: std_logic;
		necessary_state 	: BANK_STATUS_GROUP_TYPE;
		dram_cmd			: DRAM_CMD;
	end record DRAM_CMD_ENCODING_TYPE;
	type DRAM_CMD_ENCODING_ARRAY_TYPE is array (0 to 23) of DRAM_CMD_ENCODING_TYPE;
	
	-- Nano seconds to wait before putting bank into idle
	constant INITIAL_REFRESH_COUNTER_VALUE : natural := 7813;
	
	-- 200000 ns = 200 us
	constant stable_counter_final_value : natural := 200000;
	
	-- DRAM commands encodings lookup table
	constant DRAM_CMD_ENCODINGS : DRAM_CMD_ENCODING_ARRAY_TYPE := (
	--  CKE-1 	CKE  	DQM 	BA(1:0)    	  A(12:0)    CS# 	RAS#	CAS#	WE#		State		Command
		('1',	'-',	'-',	"--",	"-------------", '0',	'0', 	'1', 	'1', 	BSG_IDLE, 	CMD_BANK_ACTIVATE),
		('1',	'-',	'-',	"--",	"----------0--", '0',	'0',	'1',	'0',	BSG_ANY,	CMD_BANK_PRECHARGE),
		('1',	'-',	'-',	"--",	"----------1--", '0',	'0',	'1',	'0',	BSG_ANY,	CMD_PRECHARGE_ALL),
		('1',	'-',	'-',	"--",	"----------0--", '0',	'1',	'0',	'0',	BSG_ACTIVE,	CMD_WRITE),
		('1',	'-',	'-',	"--",	"----------1--", '0',	'1',	'0',	'0',	BSG_ACTIVE,	CMD_WRITE_AUTO_PRECHARGE),
		('1',	'-',	'-',	"--",	"----------0--", '0',	'1',	'0',	'1',	BSG_ACTIVE,	CMD_READ),
		('1',	'-',	'-',	"--",	"----------1--", '0',	'1',	'0',	'1',	BSG_ACTIVE,	CMD_READ_AUTO_PRECHARGE),
		('1',	'-',	'-',	"00",	"000-0001-----", '0',	'0',	'0',	'0',	BSG_IDLE,	CMD_MODE_REGISTER_SET),
		('1',	'-',	'-',	"--",	"-------------", '0',	'1',	'1',	'1',	BSG_ANY,	CMD_NOP),
		('1',	'-',	'-',	"--",	"-------------", '0',	'1',	'1',	'0',	BSG_ACTIVE,	CMD_BURST_STOP),
		('1',	'-',	'-',	"--",	"-------------", '1',	'-',	'-',	'-',	BSG_ANY,	CMD_DEVICE_DESELECT),
		('1',	'1',	'-',	"--",	"-------------", '0',	'0',	'0',	'1',	BSG_IDLE,	CMD_AUTO_REFRESH),
		('1',	'0',	'-',	"--",	"-------------", '0',	'0',	'0',	'1',	BSG_IDLE,	CMD_SELF_REFRESH_ENTRY),
		('0',	'1',	'-',	"--",	"-------------", '1',	'-',	'-',	'-',	BSG_IDLE,	CMD_SELF_REFRESH_EXIT),
		('0',	'1',	'-',	"--",	"-------------", '0',	'1',	'1',	'1',	BSG_IDLE,	CMD_SELF_REFRESH_EXIT),
		('1',	'0',	'-',	"--",	"-------------", '1',	'-',	'-',	'-',	BSG_ACTIVE,	CMD_CLOCK_SUSPEND_MODE_ENTRY),
		('1',	'0',	'-',	"--",	"-------------", '0',	'-',	'-',	'-',	BSG_ACTIVE,	CMD_CLOCK_SUSPEND_MODE_ENTRY),
		('1',	'0',	'-',	"--",	"-------------", '1',	'-',	'-',	'-',	BSG_ANY,	CMD_POWER_DOWN_MODE_ENTRY),
		('1',	'0',	'-',	"--",	"-------------", '0',	'1',	'1',	'1',	BSG_ANY,	CMD_POWER_DOWN_MODE_ENTRY),	
		('0',	'1',	'-',	"--",	"-------------", '-',	'-',	'-',	'-',	BSG_ACTIVE,	CMD_CLOCK_SUSPEND_MODE_ENTRY),
		('0',	'1',	'-',	"--",	"-------------", '1',	'-',	'-',	'-',	BSG_ANY,	CMD_POWER_DOWN_MODE_EXIT),
		('0',	'1',	'-',	"--",	"-------------", '0',	'1',	'1',	'1',	BSG_ANY,	CMD_POWER_DOWN_MODE_EXIT),	
		('1',	'-',	'0',	"--",	"-------------", '-',	'-',	'-',	'-',	BSG_ACTIVE,	CMD_OUTPUT_ENABLE),
		('1',	'-',	'1',	"--",	"-------------", '-',	'-',	'-',	'-',	BSG_ACTIVE,	CMD_OUTPUT_DISABLE)
	);

	signal stable_counter : natural := 0;
	signal passed_stable_initialisation : boolean := false;
	signal dram_is_intialised : boolean := false;
	signal bank_status : BANK_STATUS_ARRAY := (BS_AWAIT_STABLE, BS_AWAIT_STABLE, BS_AWAIT_STABLE, BS_AWAIT_STABLE);
	signal outgoing_data : std_logic_vector(7 downto 0);
	signal bank_is_refreshed : std_logic_vector(3 downto 0);
	shared variable refresh_counters : REFRESH_COUNTERS_ARRAY := (0, 0, 0, 0);
	
	-- Dumps all DRAM entity signals to console
	procedure dump_entity(constant msg : in string) is
		type DECODE_ERROR_REPORT_TYPE is array (natural range <>) of line;
		variable decode_error_report : DECODE_ERROR_REPORT_TYPE(0 to 13);
	begin
		report msg severity error;
		write(decode_error_report(0), string'("       CKE-1   => "));
		write(decode_error_report(0), std_logic'image(CLK'last_value));
		write(decode_error_report(1), string'("       CKE     => "));
		write(decode_error_report(1), std_logic'image(CLK));
		write(decode_error_report(2), string'("       DQM     => "));
		write(decode_error_report(2), std_logic'image(DQM));
		write(decode_error_report(3), string'("       BA(1:0) => """));
		write(decode_error_report(3), to_bstring(BA));
		write(decode_error_report(3), string'(""""));
		write(decode_error_report(4), string'("       A(12:0) => """));
		write(decode_error_report(4), to_bstring(A));
		write(decode_error_report(4), string'(""" (0x"));
		write(decode_error_report(4), to_hstring(A));
		write(decode_error_report(4), string'(")"));
		write(decode_error_report(5), string'("       CS#     => "));
		write(decode_error_report(5), std_logic'image(CSN));
		write(decode_error_report(6), string'("       RAS#    => "));
		write(decode_error_report(6), std_logic'image(RASN));
		write(decode_error_report(7), string'("       CAS#    => "));
		write(decode_error_report(7), std_logic'image(CASN));
		write(decode_error_report(8), string'("       WE#     => "));
		write(decode_error_report(8), std_logic'image(WEN));
		write(decode_error_report(9), string'("       Bank statuses:"));
		write(decode_error_report(10), string'("           00 => "));
		write(decode_error_report(10), BACK_STATUS_TYPE'image(bank_status(0)));
		write(decode_error_report(11), string'("           01 => "));
		write(decode_error_report(11), BACK_STATUS_TYPE'image(bank_status(1)));
		write(decode_error_report(12), string'("           10 => "));
		write(decode_error_report(12), BACK_STATUS_TYPE'image(bank_status(2)));
		write(decode_error_report(13), string'("           11 => "));
		write(decode_error_report(13), BACK_STATUS_TYPE'image(bank_status(3)));
		for i in decode_error_report'range loop
			writeline(output, decode_error_report(i));
		end loop;
	end procedure;

	-- Compare 2 std_logic signals
	-- 		Will return true if both are the same, either one (or both)
	--		are '-'. If either one or both are 'U' or 'X', it returns false.
	function is_same_logic(
		a : std_logic;
		b : std_logic)
		return boolean is
	begin
		if a = 'U' or a = 'X' or b = 'U' or b = 'X' then
			return false;
		elsif a = '1' or a = '0' or b = '1' or b = '0' then
			return a = '-' or b = '-' or a = b;
		else
			return false;
		end if;
	end is_same_logic;

	-- Compare entity inputs with given DRAM_CMD_ENCODING_TYPE
	function compare_entity(encoding : DRAM_CMD_ENCODING_TYPE)
		return boolean is
	begin
		
		return false;
		
	end compare_entity;

	-- Command decoder
	function decode_command
		return DRAM_CMD is
	begin
		for i in DRAM_CMD_ENCODINGS'range loop
			
		end loop;


		return CMD_NOP;
	end decode_command;

begin

	-- Refresh counter update
    process
	begin
		for i in refresh_counters'range loop
			if refresh_counters(i) /= 0 then
				refresh_counters(i) := refresh_counters(i) - 1;
			end if;
		end loop;
		
		wait for 1 ns;
	end process;
	
	BANK_REFRESH_STATUS_BITS: for i in 0 to 3 generate
		bank_is_refreshed(i) <= '1' when refresh_counters(i) /= 0 else '0';
	end generate;
	
	-- Ensure initial stable conditions
	process
		variable previous_ba : std_logic_vector(1 downto 0);
		variable previous_a : std_logic_vector(12 downto 0);
	begin
		loop
			if passed_stable_initialisation then
				dump_entity("Error while decoding command: could not find record matching current entity inputs");
				wait;
			end if;
		
			previous_ba := BA;
			previous_a := A;
			wait for 1 ns;
			
			if CKE /= '0' or CSN /= '1' or RASN /= '1' or CASN /= '1' or WEN /= '1' or previous_ba /= BA or previous_a /= A or DQM /= '1' then
				stable_counter <= 0;
			else
				stable_counter <= stable_counter + 1;
			end if;
		end loop;
	end process;
	
	passed_stable_initialisation <= stable_counter >= stable_counter_final_value;
	
	-- Internal state machine
	BANK_STATE_MACHINE : for i in bank_status'range generate
		process (CLK)
		begin
			if rising_edge(CLK) then
					case bank_status(i) is
						when BS_AWAIT_STABLE =>
							if passed_stable_initialisation then
								bank_status(i) <= BS_AWAIT_PRECHARGE_ALL;
							end if;
						when BS_AWAIT_PRECHARGE_ALL =>
							null;
						when BS_AWAIT_MODE_SET =>
							null;
						when BS_IDLE =>
							null;
						when BS_ACTIVE =>
							null;
						when BS_SELF_REFRESH =>
							null;
					end case;
			end if;
		end process;
	end generate;

end behaviour;
