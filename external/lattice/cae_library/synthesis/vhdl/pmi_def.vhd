-- --------------------------------------------------------------------
-- >>>>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<
-- --------------------------------------------------------------------
-- Copyright (c) 2005-2011 by Lattice Semiconductor Corporation
-- --------------------------------------------------------------------
--
--
--                     Lattice Semiconductor Corporation
--                     5555 NE Moore Court
--                     Hillsboro, OR 97214
--                     U.S.A.
--
--                     TEL: 1-800-Lattice  (USA and Canada)
--                          1-408-826-6000 (other locations)
--
--                     web: http://www.latticesemi.com/
--                     email: techsupport@latticesemi.com
--
-- --------------------------------------------------------------------
--
-- Component declarations for PMI blocks,
-- necessary for both VHDL synthesis & simulation
-- fpga\vhdl\pkg\vhdsclibs\data\pmi\pmi_def.vhd 1.15 10-OCT-2011 13:38:19 PPUTREVU
--
library IEEE;
use IEEE.std_logic_1164.all;

package pmi_components is 
  component pmi_distributed_dpram is
     generic (
       pmi_addr_depth : integer := 32; 
       pmi_addr_width : integer := 5; 
       pmi_data_width : integer := 8; 
       pmi_regmode : string := "reg"; 
       pmi_init_file : string := "none"; 
       pmi_init_file_format : string := "binary"; 
       pmi_family : string := "EC"; 
       module_type : string := "pmi_distributed_dpram" 
    );
    port (
     WrAddress : in std_logic_vector((pmi_addr_width-1) downto 0);
     Data : in std_logic_vector((pmi_data_width-1) downto 0);
     WrClock: in std_logic;
     WE: in std_logic;
     WrClockEn: in std_logic;
     RdAddress : in std_logic_vector((pmi_addr_width-1) downto 0);
     RdClock: in std_logic;
     RdClockEn: in std_logic;
     Reset: in std_logic;
     Q : out std_logic_vector((pmi_data_width-1) downto 0)
   );
  end component pmi_distributed_dpram;

  component pmi_distributed_rom is
     generic (
       pmi_addr_depth : integer := 32; 
       pmi_addr_width : integer := 5; 
       pmi_data_width : integer := 8; 
       pmi_regmode : string := "reg"; 
       pmi_init_file : string := "none"; 
       pmi_init_file_format : string := "binary"; 
       pmi_family : string := "EC"; 
       module_type : string := "pmi_distributed_rom" 
    );
    port (
     Address : in std_logic_vector((pmi_addr_width-1) downto 0);
     OutClock: in std_logic;
     OutClockEn: in std_logic;
     Reset: in std_logic;
     Q : out std_logic_vector((pmi_data_width-1) downto 0)
   );
  end component pmi_distributed_rom;

  component pmi_distributed_spram is
     generic (
       pmi_addr_depth : integer := 32; 
       pmi_addr_width : integer := 5; 
       pmi_data_width : integer := 8; 
       pmi_regmode : string := "reg"; 
       pmi_init_file : string := "none"; 
       pmi_init_file_format : string := "binary"; 
       pmi_family : string := "EC"; 
       module_type : string := "pmi_distributed_spram" 
    );
    port (
     Address : in std_logic_vector((pmi_addr_width-1) downto 0);
     Data : in std_logic_vector((pmi_data_width-1) downto 0);
     Clock: in std_logic;
     ClockEn: in std_logic;
     WE: in std_logic;
     Reset: in std_logic;
     Q : out std_logic_vector((pmi_data_width-1) downto 0)
   );
  end component pmi_distributed_spram;

  component pmi_distributed_shift_reg is
     generic (
       pmi_data_width : integer := 16; 
       pmi_regmode : string := "reg"; 
       pmi_shiftreg_type : string := "fixed"; 
       pmi_num_shift : integer := 16; 
       pmi_num_width : integer := 4; 
       pmi_max_shift : integer := 16; 
       pmi_max_width : integer := 4; 
       pmi_init_file : string := "none"; 
       pmi_init_file_format : string := "binary"; 
       pmi_family : string := "EC"; 
       module_type : string := "pmi_distributed_shift_reg" 
    );
    port (
     Din : in std_logic_vector((pmi_data_width-1) downto 0);
     Addr : in std_logic_vector((pmi_max_width-1) downto 0);
     Clock: in std_logic;
     ClockEn: in std_logic;
     Reset: in std_logic;
     Q : out std_logic_vector((pmi_data_width-1) downto 0)
   );
  end component pmi_distributed_shift_reg;

  component pmi_constant_mult is
     generic (
       pmi_dataa_width : integer := 8; 
       pmi_datab_width : integer := 8; 
       module_type : string := "pmi_constant_mult"; 
       pmi_sign : string := "on"; 
       pmi_additional_pipeline : integer := 1; 
       pmi_constant_value : integer := 2; 
       pmi_input_reg : string := "on"; 
       pmi_output_reg : string := "on"; 
       pmi_family : string := "EC"; 
       pmi_implementation : string := "LUT" 
    );
    port (
     DataA : in std_logic_vector((pmi_dataa_width-1) downto 0);
     Clock, ClkEn, Aclr : in std_logic;
     Result : out std_logic_vector((pmi_dataa_width + pmi_datab_width - 1) downto 0)
   );
  end component pmi_constant_mult;

  component pmi_mult is
     generic (
       pmi_dataa_width : integer := 8; 
       pmi_datab_width : integer := 8; 
       module_type : string := "pmi_mult"; 
       pmi_sign : string := "on"; 
       pmi_additional_pipeline : integer := 1; 
       pmi_input_reg : string := "on"; 
       pmi_output_reg : string := "on"; 
       pmi_family : string := "EC"; 
       pmi_implementation : string := "LUT" 
    );
    port (
     DataA : in std_logic_vector((pmi_dataa_width-1) downto 0);
     DataB : in std_logic_vector((pmi_datab_width-1) downto 0);
     Clock, ClkEn, Aclr : in std_logic;
     Result : out std_logic_vector((pmi_dataa_width + pmi_datab_width - 1) downto 0)
   );
  end component pmi_mult;

  component pmi_mac is
     generic (
       pmi_dataa_width : integer := 8; 
       pmi_datab_width : integer := 8; 
       pmi_accum_width : integer := 32; 
       module_type : string := "pmi_mac"; 
       pmi_sign : string := "on"; 
       pmi_additional_pipeline : integer := 1; 
       pmi_add_sub : string := "add"; 
       pmi_input_reg : string := "on"; 
       pmi_family : string := "EC"; 
       pmi_implementation : string := "LUT" 
    );
    port (
     DataA : in std_logic_vector((pmi_dataa_width - 1) downto 0);
     DataB : in std_logic_vector((pmi_datab_width - 1) downto 0);
     Clock, ClkEn, Aclr : in std_logic;
     Result : out std_logic_vector((pmi_accum_width - 1) downto 0)
   );
  end component pmi_mac;

  component pmi_multaddsub is
     generic (
       pmi_dataa_width : integer := 8; 
       pmi_datab_width : integer := 8; 
       module_type : string := "pmi_multaddsub"; 
       pmi_sign : string := "on"; 
       pmi_additional_pipeline : integer := 1; 
       pmi_add_sub : string := "add"; 
       pmi_input_reg : string := "on"; 
       pmi_output_reg : string := "on"; 
       pmi_family : string := "EC"; 
       pmi_implementation : string := "LUT" 
    );
    port (
     DataA0 : in std_logic_vector((pmi_dataa_width-1) downto 0);
     DataA1 : in std_logic_vector((pmi_dataa_width-1) downto 0);
     DataB0 : in std_logic_vector((pmi_datab_width-1) downto 0);
     DataB1 : in std_logic_vector((pmi_datab_width-1) downto 0);
     Clock, ClkEn, Aclr : in std_logic;
     Result : out std_logic_vector((pmi_dataa_width + pmi_datab_width) downto 0)
   );
  end component pmi_multaddsub;

  component pmi_multaddsubsum is
     generic (
       pmi_dataa_width : integer := 8; 
       pmi_datab_width : integer := 8; 
       module_type : string := "pmi_multaddsubsum"; 
       pmi_sign : string := "on"; 
       pmi_additional_pipeline : integer := 1; 
       pmi_add_sub0 : string := "add"; 
       pmi_add_sub1 : string := "add"; 
       pmi_input_reg : string := "on"; 
       pmi_output_reg : string := "on"; 
       pmi_family : string := "EC"; 
       pmi_implementation : string := "LUT" 
    );
    port (
     DataA0 : in std_logic_vector((pmi_dataa_width-1) downto 0);
     DataA1 : in std_logic_vector((pmi_dataa_width-1) downto 0);
     DataA2 : in std_logic_vector((pmi_dataa_width-1) downto 0);
     DataA3 : in std_logic_vector((pmi_dataa_width-1) downto 0);
     DataB0 : in std_logic_vector((pmi_datab_width-1) downto 0);
     DataB1 : in std_logic_vector((pmi_datab_width-1) downto 0);
     DataB2 : in std_logic_vector((pmi_datab_width-1) downto 0);
     DataB3 : in std_logic_vector((pmi_datab_width-1) downto 0);
     Clock, ClkEn, Aclr : in std_logic;
     Result : out std_logic_vector((pmi_dataa_width + pmi_datab_width + 1) downto 0)
   );
  end component pmi_multaddsubsum;

  component pmi_complex_mult is
     generic (
       pmi_dataa_width : integer := 8; 
       pmi_datab_width : integer := 8; 
       module_type : string := "pmi_complex_mult"; 
       pmi_sign : string := "on"; 
       pmi_additional_pipeline : integer := 1; 
       pmi_input_reg : string := "on"; 
       pmi_output_reg : string := "on"; 
       pmi_family : string := "EC"; 
       pmi_mult_mode : integer := 3;
       pmi_implementation : string := "LUT" 
    );
    port (
     DataA_Re : in std_logic_vector((pmi_dataa_width-1) downto 0);
     DataA_Im : in std_logic_vector((pmi_dataa_width-1) downto 0);
     DataB_Re : in std_logic_vector((pmi_datab_width-1) downto 0);
     DataB_Im : in std_logic_vector((pmi_datab_width-1) downto 0);
     Clock, ClkEn, Aclr : in std_logic;
     Result_Re : out std_logic_vector((pmi_dataa_width + pmi_datab_width) downto 0);
     Result_Im : out std_logic_vector((pmi_dataa_width + pmi_datab_width) downto 0)
   );
  end component pmi_complex_mult;

  component pmi_add is
     generic (
       pmi_data_width : integer := 8; 
       pmi_result_width : integer := 8; 
       pmi_sign : string := "off"; 
       pmi_family : string := "EC"; 
       module_type : string := "pmi_add"
 
    );
    port (
     DataA : in std_logic_vector(pmi_data_width-1 downto 0);
     DataB : in std_logic_vector(pmi_data_width-1 downto 0);
     Cin: in std_logic;
     Result : out std_logic_vector(pmi_data_width-1 downto 0);
     Cout: out std_logic;
     Overflow: out std_logic
   );
  end component pmi_add;

  component pmi_sub is
     generic (
       pmi_data_width : integer := 8; 
       pmi_result_width : integer := 8; 
       pmi_sign : string := "off"; 
       pmi_family : string := "EC"; 
       module_type : string := "pmi_sub"
 
    );
    port (
     DataA : in std_logic_vector(pmi_data_width-1 downto 0);
     DataB : in std_logic_vector(pmi_data_width-1 downto 0);
     Cin: in std_logic;
     Result : out std_logic_vector(pmi_data_width-1 downto 0);
     Cout: out std_logic;
     Overflow: out std_logic
   );
  end component pmi_sub;

  component pmi_counter is
     generic (
       pmi_data_width : integer := 8; 
       pmi_updown : string := "up"; 
       pmi_family : string := "EC"; 
       module_type : string := "pmi_counter"
 
    );
    port (
     Clock: in std_logic;
     Clk_En: in std_logic;
     Aclr: in std_logic;
     UpDown: in std_logic;
     Q : out std_logic_vector(pmi_data_width-1 downto 0)
   );
  end component pmi_counter;

  component pmi_addsub is
     generic (
       pmi_data_width : integer := 8; 
       pmi_result_width : integer := 8; 
       pmi_sign : string := "off"; 
       pmi_family : string := "EC"; 
       module_type : string := "pmi_addsub"
 
    );
    port (
     DataA : in std_logic_vector(pmi_data_width-1 downto 0);
     DataB : in std_logic_vector(pmi_data_width-1 downto 0);
     Cin: in std_logic;
     Add_Sub: in std_logic;
     Result : out std_logic_vector(pmi_data_width-1 downto 0);
     Cout: out std_logic;
     Overflow: out std_logic
   );
  end component pmi_addsub;

  component pmi_ram_dp is
     generic (
       pmi_wr_addr_depth : integer := 512; 
       pmi_wr_addr_width : integer := 9; 
       pmi_wr_data_width : integer := 18; 
       pmi_rd_addr_depth : integer := 512; 
       pmi_rd_addr_width : integer := 9; 
       pmi_rd_data_width : integer := 18; 
       pmi_regmode : string := "reg"; 
       pmi_gsr : string := "disable"; 
       pmi_resetmode : string := "sync"; 
       pmi_optimization : string := "speed";
       pmi_init_file : string := "none"; 
       pmi_init_file_format : string := "binary"; 
       pmi_family : string := "EC"; 
       module_type : string := "pmi_ram_dp" 
    );
    port (
     Data : in std_logic_vector((pmi_wr_data_width-1) downto 0);
     WrAddress : in std_logic_vector((pmi_wr_addr_width-1) downto 0);
     RdAddress : in std_logic_vector((pmi_rd_addr_width-1) downto 0);
     WrClock: in std_logic;
     RdClock: in std_logic;
     WrClockEn: in std_logic;
     RdClockEn: in std_logic;
     WE: in std_logic;
     Reset: in std_logic;
     Q : out std_logic_vector((pmi_rd_data_width-1) downto 0)
   );
  end component pmi_ram_dp;

  component pmi_ram_dp_be is
     generic (
       pmi_wr_addr_depth : integer := 512; 
       pmi_wr_addr_width : integer := 9; 
       pmi_wr_data_width : integer := 18; 
       pmi_rd_addr_depth : integer := 512; 
       pmi_rd_addr_width : integer := 9; 
       pmi_rd_data_width : integer := 18; 
       pmi_regmode : string := "reg"; 
       pmi_gsr : string := "disable"; 
       pmi_resetmode : string := "sync"; 
       pmi_optimization : string := "speed";
       pmi_init_file : string := "none"; 
       pmi_init_file_format : string := "binary"; 
       pmi_byte_size : integer := 9;
       pmi_family : string := "ECP2"; 
       module_type : string := "pmi_ram_dp_be" 
    );
    port (
     Data : in std_logic_vector((pmi_wr_data_width-1) downto 0);
     WrAddress : in std_logic_vector((pmi_wr_addr_width-1) downto 0);
     RdAddress : in std_logic_vector((pmi_rd_addr_width-1) downto 0);
     WrClock: in std_logic;
     RdClock: in std_logic;
     WrClockEn: in std_logic;
     RdClockEn: in std_logic;
     WE: in std_logic;
     Reset: in std_logic;
     ByteEn : in std_logic_vector(((pmi_wr_data_width+pmi_byte_size-1)/pmi_byte_size-1) downto 0);
     Q : out std_logic_vector((pmi_rd_data_width-1) downto 0)
   );
  end component pmi_ram_dp_be;

  component pmi_ram_dp_true is
     generic (
       pmi_addr_depth_a : integer := 512; 
       pmi_addr_width_a : integer := 9; 
       pmi_data_width_a : integer := 18; 
       pmi_addr_depth_b : integer := 512; 
       pmi_addr_width_b : integer := 9; 
       pmi_data_width_b : integer := 18; 
       pmi_regmode_a : string := "reg"; 
       pmi_regmode_b : string := "reg"; 
       pmi_gsr : string := "disable"; 
       pmi_resetmode : string := "sync"; 
       pmi_optimization : string := "speed";
       pmi_init_file : string := "none"; 
       pmi_init_file_format : string := "binary"; 
       pmi_write_mode_a : string := "normal"; 
       pmi_write_mode_b : string := "normal"; 
       pmi_family : string := "EC"; 
       module_type : string := "pmi_ram_dp_true" 
    );
    port (
     DataInA : in std_logic_vector((pmi_data_width_a-1) downto 0);
     DataInB : in std_logic_vector((pmi_data_width_b-1) downto 0);
     AddressA : in std_logic_vector((pmi_addr_width_a-1) downto 0);
     AddressB : in std_logic_vector((pmi_addr_width_b-1) downto 0);
     ClockA: in std_logic;
     ClockB: in std_logic;
     ClockEnA: in std_logic;
     ClockEnB: in std_logic;
     WrA: in std_logic;
     WrB: in std_logic;
     ResetA: in std_logic;
     ResetB: in std_logic;
     QA : out std_logic_vector((pmi_data_width_a-1) downto 0);
     QB : out std_logic_vector((pmi_data_width_b-1) downto 0)
   );
  end component pmi_ram_dp_true;

  component pmi_ram_dp_true_be is
     generic (
       pmi_addr_depth_a : integer := 512; 
       pmi_addr_width_a : integer := 9; 
       pmi_data_width_a : integer := 18; 
       pmi_addr_depth_b : integer := 512; 
       pmi_addr_width_b : integer := 9; 
       pmi_data_width_b : integer := 18; 
       pmi_regmode_a : string := "reg"; 
       pmi_regmode_b : string := "reg"; 
       pmi_gsr : string := "disable"; 
       pmi_resetmode : string := "sync"; 
       pmi_optimization : string := "speed";
       pmi_init_file : string := "none"; 
       pmi_init_file_format : string := "binary"; 
       pmi_write_mode_a : string := "normal"; 
       pmi_write_mode_b : string := "normal"; 
       pmi_byte_size : integer := 9;
       pmi_family : string := "ECP2"; 
       module_type : string := "pmi_ram_dp_true_be" 
    );
    port (
     DataInA : in std_logic_vector((pmi_data_width_a-1) downto 0);
     DataInB : in std_logic_vector((pmi_data_width_b-1) downto 0);
     AddressA : in std_logic_vector((pmi_addr_width_a-1) downto 0);
     AddressB : in std_logic_vector((pmi_addr_width_b-1) downto 0);
     ClockA: in std_logic;
     ClockB: in std_logic;
     ClockEnA: in std_logic;
     ClockEnB: in std_logic;
     WrA: in std_logic;
     WrB: in std_logic;
     ResetA: in std_logic;
     ResetB: in std_logic;
     ByteEnA : in std_logic_vector(((pmi_data_width_a+pmi_byte_size-1)/pmi_byte_size-1) downto 0);
     ByteEnB : in std_logic_vector(((pmi_data_width_b+pmi_byte_size-1)/pmi_byte_size-1) downto 0);
     QA : out std_logic_vector((pmi_data_width_a-1) downto 0);
     QB : out std_logic_vector((pmi_data_width_b-1) downto 0)
   );
  end component pmi_ram_dp_true_be;

  component pmi_ram_dq is
     generic (
       pmi_addr_depth : integer := 512; 
       pmi_addr_width : integer := 9; 
       pmi_data_width : integer := 18; 
       pmi_regmode : string := "reg"; 
       pmi_gsr : string := "disable"; 
       pmi_resetmode : string := "sync"; 
       pmi_optimization : string := "speed";
       pmi_init_file : string := "none"; 
       pmi_init_file_format : string := "binary"; 
       pmi_write_mode : string := "normal"; 
       pmi_family : string := "EC"; 
       module_type : string := "pmi_ram_dq" 
    );
    port (
     Data : in std_logic_vector((pmi_data_width-1) downto 0);
     Address : in std_logic_vector((pmi_addr_width-1) downto 0);
     Clock: in std_logic;
     ClockEn: in std_logic;
     WE: in std_logic;
     Reset: in std_logic;
     Q : out std_logic_vector((pmi_data_width-1) downto 0)
   );
  end component pmi_ram_dq;

  component pmi_ram_dq_be is
     generic (
       pmi_addr_depth : integer := 512; 
       pmi_addr_width : integer := 9; 
       pmi_data_width : integer := 18; 
       pmi_regmode : string := "reg"; 
       pmi_gsr : string := "disable"; 
       pmi_resetmode : string := "sync"; 
       pmi_optimization : string := "speed";
       pmi_init_file : string := "none"; 
       pmi_init_file_format : string := "binary"; 
       pmi_write_mode : string := "normal"; 
       pmi_byte_size : integer := 9;
       pmi_family : string := "ECP2"; 
       module_type : string := "pmi_ram_dq_be" 
    );
    port (
     Data : in std_logic_vector((pmi_data_width-1) downto 0);
     Address : in std_logic_vector((pmi_addr_width-1) downto 0);
     Clock: in std_logic;
     ClockEn: in std_logic;
     WE: in std_logic;
     Reset: in std_logic;
     ByteEn : in std_logic_vector(((pmi_data_width+pmi_byte_size-1)/pmi_byte_size-1) downto 0);
     Q : out std_logic_vector((pmi_data_width-1) downto 0)
   );
  end component pmi_ram_dq_be;

  component pmi_rom is
     generic (
       pmi_addr_depth : integer := 512; 
       pmi_addr_width : integer := 9; 
       pmi_data_width : integer := 8; 
       pmi_regmode : string := "reg"; 
       pmi_gsr : string := "disable"; 
       pmi_resetmode : string := "sync"; 
       pmi_optimization : string := "speed";
       pmi_init_file : string := "none"; 
       pmi_init_file_format : string := "binary"; 
       pmi_family : string := "EC"; 
       module_type : string := "pmi_rom" 
    );
    port (
     Address : in std_logic_vector((pmi_addr_width-1) downto 0);
     OutClock: in std_logic;
     OutClockEn: in std_logic;
     Reset: in std_logic;
     Q : out std_logic_vector((pmi_data_width-1) downto 0)
   );
  end component pmi_rom;

  component pmi_fifo_dc is
     generic (
       pmi_data_width_w : integer := 18; 
       pmi_data_width_r : integer := 18; 
       pmi_data_depth_w : integer := 256; 
       pmi_data_depth_r : integer := 256; 
       pmi_full_flag : integer := 256; 
       pmi_empty_flag : integer := 0; 
       pmi_almost_full_flag : integer := 252; 
       pmi_almost_empty_flag : integer := 4; 
       pmi_regmode : string := "reg"; 
       pmi_resetmode : string := "async"; 
       pmi_family : string := "EC" ; 
       module_type : string := "pmi_fifo_dc"; 
       pmi_implementation : string := "EBR"
 
    );
    port (
     Data : in std_logic_vector(pmi_data_width_w-1 downto 0);
     WrClock: in std_logic;
     RdClock: in std_logic;
     WrEn: in std_logic;
     RdEn: in std_logic;
     Reset: in std_logic;
     RPReset: in std_logic;
     Q : out std_logic_vector(pmi_data_width_r-1 downto 0);
     Empty: out std_logic;
     Full: out std_logic;
     AlmostEmpty: out std_logic;
     AlmostFull: out std_logic
   );
  end component pmi_fifo_dc;

  component pmi_fifo is
     generic (
       pmi_data_width : integer := 8; 
       pmi_data_depth : integer := 256; 
       pmi_full_flag : integer := 256; 
       pmi_empty_flag : integer := 0; 
       pmi_almost_full_flag : integer := 252; 
       pmi_almost_empty_flag : integer := 4; 
       pmi_regmode : string := "reg"; 
       pmi_family : string := "EC" ; 
       module_type : string := "pmi_fifo"; 
       pmi_implementation : string := "EBR"
    );
    port (
     Data : in std_logic_vector(pmi_data_width-1 downto 0);
     Clock: in std_logic;
     WrEn: in std_logic;
     RdEn: in std_logic;
     Reset: in std_logic;
     Q : out std_logic_vector(pmi_data_width-1 downto 0);
     Empty: out std_logic;
     Full: out std_logic;
     AlmostEmpty: out std_logic;
     AlmostFull: out std_logic
   );
  end component pmi_fifo;

  component pmi_dsp_mac is
     generic (
       pmi_dataa_width : integer := 8; 
       pmi_datab_width : integer := 8; 
       pmi_additional_pipeline : integer := 0; 
       pmi_input_reg : string := "on"; 
       pmi_family : string := "ECP2"; 
       pmi_gsr : string := "enable"; 
       pmi_source_control_a : string := "parallel"; 
       pmi_source_control_b : string := "parallel"; 
       pmi_reg_inputa_clk : string := "CLK0"; 
       pmi_reg_inputa_ce : string := "CE0"; 
       pmi_reg_inputa_rst : string := "RST0"; 
       pmi_reg_inputb_clk : string := "CLK0"; 
       pmi_reg_inputb_ce : string := "CE0"; 
       pmi_reg_inputb_rst : string := "RST0"; 
       pmi_reg_pipeline_clk : string := "CLK0"; 
       pmi_reg_pipeline_ce : string := "CE0"; 
       pmi_reg_pipeline_rst : string := "RST0"; 
       pmi_reg_output_clk : string := "CLK0"; 
       pmi_reg_output_ce : string := "CE0"; 
       pmi_reg_output_rst : string := "RST0"; 
       pmi_reg_signeda_0_clk : string := "CLK0"; 
       pmi_reg_signeda_0_ce : string := "CE0"; 
       pmi_reg_signeda_0_rst : string := "RST0"; 
       pmi_reg_signeda_1_clk : string := "CLK0"; 
       pmi_reg_signeda_1_ce : string := "CE0"; 
       pmi_reg_signeda_1_rst : string := "RST0"; 
       pmi_reg_signedb_0_clk : string := "CLK0"; 
       pmi_reg_signedb_0_ce : string := "CE0"; 
       pmi_reg_signedb_0_rst : string := "RST0"; 
       pmi_reg_signedb_1_clk : string := "CLK0"; 
       pmi_reg_signedb_1_ce : string := "CE0"; 
       pmi_reg_signedb_1_rst : string := "RST0"; 
       pmi_reg_addnsub_0_clk : string := "CLK0"; 
       pmi_reg_addnsub_0_ce : string := "CE0"; 
       pmi_reg_addnsub_0_rst : string := "RST0"; 
       pmi_reg_addnsub_1_clk : string := "CLK0"; 
       pmi_reg_addnsub_1_ce : string := "CE0"; 
       pmi_reg_addnsub_1_rst : string := "RST0"; 
       pmi_reg_accumsload_0_clk : string := "CLK0"; 
       pmi_reg_accumsload_0_ce : string := "CE0"; 
       pmi_reg_accumsload_0_rst : string := "RST0"; 
       pmi_reg_accumsload_1_clk : string := "CLK0"; 
       pmi_reg_accumsload_1_ce : string := "CE0"; 
       pmi_reg_accumsload_1_rst : string := "RST0"; 
       module_type : string := "pmi_dsp_mac" 
    );
    port (
     A : in std_logic_vector((pmi_dataa_width-1) downto 0);
     B : in std_logic_vector((pmi_datab_width-1) downto 0);
     SRIA : in std_logic_vector(17 downto 0);
     SRIB : in std_logic_vector(17 downto 0);
     CLK0: in std_logic;
     CLK1: in std_logic;
     CLK2: in std_logic;
     CLK3: in std_logic;
     CE0: in std_logic;
     CE1: in std_logic;
     CE2: in std_logic;
     CE3: in std_logic;
     RST0: in std_logic;
     RST1: in std_logic;
     RST2: in std_logic;
     RST3: in std_logic;
     SignA: in std_logic;
     SignB: in std_logic;
     SourceA: in std_logic;
     SourceB: in std_logic;
     ADDNSUB: in std_logic;
     LD : in std_logic_vector(((pmi_dataa_width + pmi_datab_width - 1) + 16) downto 0);
     ACCUMSLOAD: in std_logic;
     ACCUM : out std_logic_vector(((pmi_dataa_width + pmi_datab_width - 1) + 16) downto 0);
     OVERFLOW: out std_logic;
     SROA : out std_logic_vector(17 downto 0);
     SROB : out std_logic_vector(17 downto 0)
   );
  end component pmi_dsp_mac;

  component pmi_dsp_mult is
     generic (
       pmi_dataa_width : integer := 8; 
       pmi_datab_width : integer := 8; 
       pmi_additional_pipeline : integer := 0; 
       pmi_input_reg : string := "on"; 
       pmi_output_reg : string := "on"; 
       pmi_family : string := "ECP2"; 
       pmi_gsr : string := "enable"; 
       pmi_source_control_a : string := "parallel"; 
       pmi_source_control_b : string := "parallel"; 
       pmi_reg_inputa_clk : string := "CLK0"; 
       pmi_reg_inputa_ce : string := "CE0"; 
       pmi_reg_inputa_rst : string := "RST0"; 
       pmi_reg_inputb_clk : string := "CLK0"; 
       pmi_reg_inputb_ce : string := "CE0"; 
       pmi_reg_inputb_rst : string := "RST0"; 
       pmi_reg_pipeline_clk : string := "CLK0"; 
       pmi_reg_pipeline_ce : string := "CE0"; 
       pmi_reg_pipeline_rst : string := "RST0"; 
       pmi_reg_output_clk : string := "CLK0"; 
       pmi_reg_output_ce : string := "CE0"; 
       pmi_reg_output_rst : string := "RST0"; 
       pmi_reg_signeda_clk : string := "CLK0"; 
       pmi_reg_signeda_ce : string := "CE0"; 
       pmi_reg_signeda_rst : string := "RST0"; 
       pmi_reg_signedb_clk : string := "CLK0"; 
       pmi_reg_signedb_ce : string := "CE0"; 
       pmi_reg_signedb_rst : string := "RST0"; 
       pmi_pipelined_mode : string := "off";
       module_type : string := "pmi_dsp_mult" 
    );
    port (
     A : in std_logic_vector((pmi_dataa_width-1) downto 0);
     B : in std_logic_vector((pmi_datab_width-1) downto 0);
     SRIA : in std_logic_vector(17 downto 0);
     SRIB : in std_logic_vector(17 downto 0);
     CLK0: in std_logic;
     CLK1: in std_logic;
     CLK2: in std_logic;
     CLK3: in std_logic;
     CE0: in std_logic;
     CE1: in std_logic;
     CE2: in std_logic;
     CE3: in std_logic;
     RST0: in std_logic;
     RST1: in std_logic;
     RST2: in std_logic;
     RST3: in std_logic;
     SignA: in std_logic;
     SignB: in std_logic;
     SourceA: in std_logic;
     SourceB: in std_logic;
     P : out std_logic_vector((pmi_dataa_width + pmi_datab_width - 1) downto 0);
     SROA : out std_logic_vector(17 downto 0);
     SROB : out std_logic_vector(17 downto 0)
   );
  end component pmi_dsp_mult;

  component pmi_dsp_multaddsub is
     generic (
       pmi_dataa_width : integer := 8; 
       pmi_datab_width : integer := 8; 
       pmi_additional_pipeline : integer := 0; 
       pmi_input_reg : string := "on"; 
       pmi_output_reg : string := "on"; 
       pmi_family : string := "ECP2"; 
       pmi_gsr : string := "enable"; 
       pmi_source_control_a0 : string := "parallel"; 
       pmi_source_control_a1 : string := "parallel"; 
       pmi_source_control_b0 : string := "parallel"; 
       pmi_source_control_b1 : string := "parallel"; 
       pmi_reg_inputa0_clk : string := "CLK0"; 
       pmi_reg_inputa0_ce : string := "CE0"; 
       pmi_reg_inputa0_rst : string := "RST0"; 
       pmi_reg_inputa1_clk : string := "CLK0"; 
       pmi_reg_inputa1_ce : string := "CE0"; 
       pmi_reg_inputa1_rst : string := "RST0"; 
       pmi_reg_inputb0_clk : string := "CLK0"; 
       pmi_reg_inputb0_ce : string := "CE0"; 
       pmi_reg_inputb0_rst : string := "RST0"; 
       pmi_reg_inputb1_clk : string := "CLK0"; 
       pmi_reg_inputb1_ce : string := "CE0"; 
       pmi_reg_inputb1_rst : string := "RST0"; 
       pmi_reg_pipeline0_clk : string := "CLK0"; 
       pmi_reg_pipeline0_ce : string := "CE0"; 
       pmi_reg_pipeline0_rst : string := "RST0"; 
       pmi_reg_pipeline1_clk : string := "CLK0"; 
       pmi_reg_pipeline1_ce : string := "CE0"; 
       pmi_reg_pipeline1_rst : string := "RST0"; 
       pmi_reg_output_clk : string := "CLK0"; 
       pmi_reg_output_ce : string := "CE0"; 
       pmi_reg_output_rst : string := "RST0"; 
       pmi_reg_signeda_0_clk : string := "CLK0"; 
       pmi_reg_signeda_0_ce : string := "CE0"; 
       pmi_reg_signeda_0_rst : string := "RST0"; 
       pmi_reg_signeda_1_clk : string := "CLK0"; 
       pmi_reg_signeda_1_ce : string := "CE0"; 
       pmi_reg_signeda_1_rst : string := "RST0"; 
       pmi_reg_signedb_0_clk : string := "CLK0"; 
       pmi_reg_signedb_0_ce : string := "CE0"; 
       pmi_reg_signedb_0_rst : string := "RST0"; 
       pmi_reg_signedb_1_clk : string := "CLK0"; 
       pmi_reg_signedb_1_ce : string := "CE0"; 
       pmi_reg_signedb_1_rst : string := "RST0"; 
       pmi_reg_addnsub_0_clk : string := "CLK0"; 
       pmi_reg_addnsub_0_ce : string := "CE0"; 
       pmi_reg_addnsub_0_rst : string := "RST0"; 
       pmi_reg_addnsub_1_clk : string := "CLK0"; 
       pmi_reg_addnsub_1_ce : string := "CE0"; 
       pmi_reg_addnsub_1_rst : string := "RST0"; 
       pmi_pipelined_mode : string := "off";
       module_type : string := "pmi_dsp_multaddsub" 
    );
    port (
     A0, A1 : in std_logic_vector((pmi_dataa_width-1) downto 0);
     B0, B1 : in std_logic_vector((pmi_datab_width-1) downto 0);
     SRIA : in std_logic_vector(17 downto 0);
     SRIB : in std_logic_vector(17 downto 0);
     CLK0: in std_logic;
     CLK1: in std_logic;
     CLK2: in std_logic;
     CLK3: in std_logic;
     CE0: in std_logic;
     CE1: in std_logic;
     CE2: in std_logic;
     CE3: in std_logic;
     RST0: in std_logic;
     RST1: in std_logic;
     RST2: in std_logic;
     RST3: in std_logic;
     SignA: in std_logic;
     SignB: in std_logic;
     ShiftA0: in std_logic;
     ShiftA1: in std_logic;
     ShiftB0: in std_logic;
     ShiftB1: in std_logic;
     ADDNSUB: in std_logic;
     SUM : out std_logic_vector((pmi_dataa_width + pmi_datab_width) downto 0);
     SROA : out std_logic_vector(17 downto 0);
     SROB : out std_logic_vector(17 downto 0)
   );
  end component pmi_dsp_multaddsub;

  component pmi_dsp_casmultaddsub is
     generic (
       pmi_dataa_width : integer := 18;
       pmi_datab_width : integer := 18;
       pmi_additional_pipeline : integer := 0;
       pmi_input_reg : string := "on";
       pmi_output_reg : string := "on";
       pmi_family : string := "ECP3";
       pmi_gsr : string := "enable";
       pmi_reg_inputa0_clk : string := "CLK0";
       pmi_reg_inputa0_ce : string := "CE0";
       pmi_reg_inputa0_rst : string := "RST0";
       pmi_reg_inputa1_clk : string := "CLK0";
       pmi_reg_inputa1_ce : string := "CE0";
       pmi_reg_inputa1_rst : string := "RST0";
       pmi_reg_inputb0_clk : string := "CLK0";
       pmi_reg_inputb0_ce : string := "CE0";
       pmi_reg_inputb0_rst : string := "RST0";
       pmi_reg_inputb1_clk : string := "CLK0";
       pmi_reg_inputb1_ce : string := "CE0";
       pmi_reg_inputb1_rst : string := "RST0";
       pmi_reg_pipeline0_clk : string := "CLK0";
       pmi_reg_pipeline0_ce : string := "CE0";
       pmi_reg_pipeline0_rst : string := "RST0";
       pmi_reg_pipeline1_clk : string := "CLK0";
       pmi_reg_pipeline1_ce : string := "CE0";
       pmi_reg_pipeline1_rst : string := "RST0";
       pmi_reg_output_clk : string := "CLK0";
       pmi_reg_output_ce : string := "CE0";
       pmi_reg_output_rst : string := "RST0";
       pmi_reg_signeda_0_clk : string := "CLK0";
       pmi_reg_signeda_0_ce : string := "CE0";
       pmi_reg_signeda_0_rst : string := "RST0";
       pmi_reg_signeda_1_clk : string := "CLK0";
       pmi_reg_signeda_1_ce : string := "CE0";
       pmi_reg_signeda_1_rst : string := "RST0";
       pmi_reg_signedb_0_clk : string := "CLK0";
       pmi_reg_signedb_0_ce : string := "CE0";
       pmi_reg_signedb_0_rst : string := "RST0";
       pmi_reg_signedb_1_clk : string := "CLK0";
       pmi_reg_signedb_1_ce : string := "CE0";
       pmi_reg_signedb_1_rst : string := "RST0";
       pmi_reg_addnsub_0_clk : string := "CLK0";
       pmi_reg_addnsub_0_ce : string := "CE0";
       pmi_reg_addnsub_0_rst : string := "RST0";
       pmi_reg_addnsub_1_clk : string := "CLK0";
       pmi_reg_addnsub_1_ce : string := "CE0";
       pmi_reg_addnsub_1_rst : string := "RST0";
       pmi_pipelined_mode : string := "off";
       pmi_cascade_match_reg : string := "off";
       module_type : string := "pmi_dsp_casmultaddsub"
     );
     port (
       A0, A1 : in std_logic_vector((pmi_dataa_width-1) downto 0);
       B0, B1 : in std_logic_vector((pmi_datab_width-1) downto 0);
       SRIA : in std_logic_vector(17 downto 0);
       SRIB : in std_logic_vector(17 downto 0);
       CLK0 : in std_logic;
       CLK1 : in std_logic;
       CLK2 : in std_logic;
       CLK3 : in std_logic;
       CE0 : in std_logic;
       CE1 : in std_logic;
       CE2 : in std_logic;
       CE3 : in std_logic;
       RST0 : in std_logic;
       RST1 : in std_logic;
       RST2 : in std_logic;
       RST3 : in std_logic;
       SignA : in std_logic;
       SignB : in std_logic;
       ShiftA0 : in std_logic;
       ShiftA1 : in std_logic;
       ShiftB0 : in std_logic;
       ShiftB1 : in std_logic;
       ADDNSUB : in std_logic;
       SignCIN : in std_logic;
       CIN : in std_logic_vector(53 downto 0);
       SignSUM : out std_logic;
       SUM : out std_logic_vector(53 downto 0);
       SROA : out std_logic_vector(17 downto 0);
       SROB : out std_logic_vector(17 downto 0)
     );
  end component pmi_dsp_casmultaddsub;

  component pmi_dsp_multaddsubsum is
     generic (
       pmi_dataa_width : integer := 8; 
       pmi_datab_width : integer := 8; 
       pmi_additional_pipeline : integer := 0; 
       pmi_input_reg : string := "on"; 
       pmi_output_reg : string := "on"; 
       pmi_family : string := "ECP2"; 
       pmi_gsr : string := "enable"; 
       pmi_source_control_a0 : string := "parallel"; 
       pmi_source_control_a1 : string := "parallel"; 
       pmi_source_control_a2 : string := "parallel"; 
       pmi_source_control_a3 : string := "parallel"; 
       pmi_source_control_b0 : string := "parallel"; 
       pmi_source_control_b1 : string := "parallel"; 
       pmi_source_control_b2 : string := "parallel"; 
       pmi_source_control_b3 : string := "parallel"; 
       pmi_reg_inputa0_clk : string := "CLK0"; 
       pmi_reg_inputa0_ce : string := "CE0"; 
       pmi_reg_inputa0_rst : string := "RST0"; 
       pmi_reg_inputa1_clk : string := "CLK0"; 
       pmi_reg_inputa1_ce : string := "CE0"; 
       pmi_reg_inputa1_rst : string := "RST0"; 
       pmi_reg_inputa2_clk : string := "CLK0"; 
       pmi_reg_inputa2_ce : string := "CE0"; 
       pmi_reg_inputa2_rst : string := "RST0"; 
       pmi_reg_inputa3_clk : string := "CLK0"; 
       pmi_reg_inputa3_ce : string := "CE0"; 
       pmi_reg_inputa3_rst : string := "RST0"; 
       pmi_reg_inputb0_clk : string := "CLK0"; 
       pmi_reg_inputb0_ce : string := "CE0"; 
       pmi_reg_inputb0_rst : string := "RST0"; 
       pmi_reg_inputb1_clk : string := "CLK0"; 
       pmi_reg_inputb1_ce : string := "CE0"; 
       pmi_reg_inputb1_rst : string := "RST0"; 
       pmi_reg_inputb2_clk : string := "CLK0"; 
       pmi_reg_inputb2_ce : string := "CE0"; 
       pmi_reg_inputb2_rst : string := "RST0"; 
       pmi_reg_inputb3_clk : string := "CLK0"; 
       pmi_reg_inputb3_ce : string := "CE0"; 
       pmi_reg_inputb3_rst : string := "RST0"; 
       pmi_reg_pipeline0_clk : string := "CLK0"; 
       pmi_reg_pipeline0_ce : string := "CE0"; 
       pmi_reg_pipeline0_rst : string := "RST0"; 
       pmi_reg_pipeline1_clk : string := "CLK0"; 
       pmi_reg_pipeline1_ce : string := "CE0"; 
       pmi_reg_pipeline1_rst : string := "RST0"; 
       pmi_reg_pipeline2_clk : string := "CLK0"; 
       pmi_reg_pipeline2_ce : string := "CE0"; 
       pmi_reg_pipeline2_rst : string := "RST0"; 
       pmi_reg_pipeline3_clk : string := "CLK0"; 
       pmi_reg_pipeline3_ce : string := "CE0"; 
       pmi_reg_pipeline3_rst : string := "RST0"; 
       pmi_reg_output_clk : string := "CLK0"; 
       pmi_reg_output_ce : string := "CE0"; 
       pmi_reg_output_rst : string := "RST0"; 
       pmi_reg_signeda_0_clk : string := "CLK0"; 
       pmi_reg_signeda_0_ce : string := "CE0"; 
       pmi_reg_signeda_0_rst : string := "RST0"; 
       pmi_reg_signeda_1_clk : string := "CLK0"; 
       pmi_reg_signeda_1_ce : string := "CE0"; 
       pmi_reg_signeda_1_rst : string := "RST0"; 
       pmi_reg_signedb_0_clk : string := "CLK0"; 
       pmi_reg_signedb_0_ce : string := "CE0"; 
       pmi_reg_signedb_0_rst : string := "RST0"; 
       pmi_reg_signedb_1_clk : string := "CLK0"; 
       pmi_reg_signedb_1_ce : string := "CE0"; 
       pmi_reg_signedb_1_rst : string := "RST0"; 
       pmi_reg_addnsub1_0_clk : string := "CLK0"; 
       pmi_reg_addnsub1_0_ce : string := "CE0"; 
       pmi_reg_addnsub1_0_rst : string := "RST0"; 
       pmi_reg_addnsub1_1_clk : string := "CLK0"; 
       pmi_reg_addnsub1_1_ce : string := "CE0"; 
       pmi_reg_addnsub1_1_rst : string := "RST0"; 
       pmi_reg_addnsub3_0_clk : string := "CLK0"; 
       pmi_reg_addnsub3_0_ce : string := "CE0"; 
       pmi_reg_addnsub3_0_rst : string := "RST0"; 
       pmi_reg_addnsub3_1_clk : string := "CLK0"; 
       pmi_reg_addnsub3_1_ce : string := "CE0"; 
       pmi_reg_addnsub3_1_rst : string := "RST0"; 
       pmi_pipelined_mode : string := "off";
       module_type : string := "pmi_dsp_multaddsubsum" 
    );
    port (
     A0, A1, A2, A3 : in std_logic_vector((pmi_dataa_width-1) downto 0);
     B0, B1, B2, B3 : in std_logic_vector((pmi_datab_width-1) downto 0);
     SRIA : in std_logic_vector(17 downto 0);
     SRIB : in std_logic_vector(17 downto 0);
     CLK0: in std_logic;
     CLK1: in std_logic;
     CLK2: in std_logic;
     CLK3: in std_logic;
     CE0: in std_logic;
     CE1: in std_logic;
     CE2: in std_logic;
     CE3: in std_logic;
     RST0: in std_logic;
     RST1: in std_logic;
     RST2: in std_logic;
     RST3: in std_logic;
     SignA: in std_logic;
     SignB: in std_logic;
     ShiftA0: in std_logic;
     ShiftA1: in std_logic;
     ShiftA2: in std_logic;
     ShiftA3: in std_logic;
     ShiftB0: in std_logic;
     ShiftB1: in std_logic;
     ShiftB2: in std_logic;
     ShiftB3: in std_logic;
     ADDNSUB1: in std_logic;
     ADDNSUB3: in std_logic;
     SUM : out std_logic_vector((pmi_dataa_width + pmi_datab_width + 1) downto 0);
     SROA : out std_logic_vector(17 downto 0);
     SROB : out std_logic_vector(17 downto 0)
   );
  end component pmi_dsp_multaddsubsum;

  component pmi_dsp_preadd_slice is
    generic (
       pmi_data_m0a_width : integer := 18;
       pmi_data_m0b_width : integer := 18;
       pmi_data_m1a_width : integer := 18;
       pmi_data_m1b_width : integer := 18;
       pmi_data_m0c_width : integer := 18;
       pmi_data_m1c_width : integer := 18;
       pmi_gsr : string := "enable";
       pmi_family : string := "ECP4";
       pmi_reg_input_m0a_pre_clk : string := "CLK0";
       pmi_reg_input_m0a_pre_ce : string := "CE0";
       pmi_reg_input_m0a_pre_rst : string := "RST0";
       pmi_reg_input_m0b_pre_clk : string := "CLK0";
       pmi_reg_input_m0b_pre_ce : string := "CE0";
       pmi_reg_input_m0b_pre_rst : string := "RST0";
       pmi_reg_input_m0a_mult_clk : string := "CLK0";
       pmi_reg_input_m0a_mult_ce : string := "CE0";
       pmi_reg_input_m0a_mult_rst : string := "RST0";
       pmi_reg_input_m0b_mult_clk : string := "CLK0";
       pmi_reg_input_m0b_mult_ce : string := "CE0";
       pmi_reg_input_m0b_mult_rst : string := "RST0";
       pmi_reg_input_m1a_pre_clk : string := "CLK0";
       pmi_reg_input_m1a_pre_ce : string := "CE0";
       pmi_reg_input_m1a_pre_rst : string := "RST0";
       pmi_reg_input_m1b_pre_clk : string := "CLK0";
       pmi_reg_input_m1b_pre_ce : string := "CE0";
       pmi_reg_input_m1b_pre_rst : string := "RST0";
       pmi_reg_input_m1a_mult_clk : string := "CLK0";
       pmi_reg_input_m1a_mult_ce : string := "CE0";
       pmi_reg_input_m1a_mult_rst : string := "RST0";
       pmi_reg_input_m1b_mult_clk : string := "CLK0";
       pmi_reg_input_m1b_mult_ce : string := "CE0";
       pmi_reg_input_m1b_mult_rst : string := "RST0";
       pmi_reg_input_m0c_clk : string := "CLK0";
       pmi_reg_input_m0c_ce : string := "CE0";
       pmi_reg_input_m0c_rst : string := "RST0";
       pmi_reg_input_m1c_clk : string := "CLK0";
       pmi_reg_input_m1c_ce : string := "CE0";
       pmi_reg_input_m1c_rst : string := "RST0";
       pmi_reg_input_cfb_clk : string := "CLK0";
       pmi_reg_input_cfb_ce : string := "CE0";
       pmi_reg_input_cfb_rst : string := "RST0";
       pmi_reg_pipeline0_clk : string := "CLK0";
       pmi_reg_pipeline0_ce : string := "CE0";
       pmi_reg_pipeline0_rst : string := "RST0";
       pmi_reg_pipeline1_clk : string := "CLK0";
       pmi_reg_pipeline1_ce : string := "CE0";
       pmi_reg_pipeline1_rst : string := "RST0";
       pmi_reg_output_clk : string := "CLK0";
       pmi_reg_output_ce : string := "CE0";
       pmi_reg_output_rst : string := "RST0";
       pmi_reg_oppre0_clk : string := "CLK0";
       pmi_reg_oppre0_ce : string := "CE0";
       pmi_reg_oppre0_rst : string := "RST0";
       pmi_reg_oppre1_clk : string := "CLK0";
       pmi_reg_oppre1_ce : string := "CE0";
       pmi_reg_oppre1_rst : string := "RST0";
       pmi_reg_opcodein0_clk : string := "CLK0";
       pmi_reg_opcodein0_ce : string := "CE0";
       pmi_reg_opcodein0_rst : string := "RST0";
       pmi_reg_opcodein1_clk : string := "CLK0";
       pmi_reg_opcodein1_ce : string := "CE0";
       pmi_reg_opcodein1_rst : string := "RST0";
       pmi_cascade_match_reg : string := "off";
       pmi_m0_sourceb_mode : string := "B";
       pmi_m1_sourceb_mode : string := "B";
       pmi_m0_sourcea_mode : string := "OPA0";
       pmi_m1_sourcea_mode : string := "OPA1";
       pmi_pre0_sourcea_mode : string := "A_SHIFT";
       pmi_pre0_sourceb_mode : string := "SHIFT";
       pmi_pre0_symmetry_mode : string := "DIRECT";
       pmi_pre1_sourcea_mode : string := "A_SHIFT";
       pmi_pre1_sourceb_mode : string := "SHIFT";
       pmi_pre1_fb_mux : string := "SHIFT";
       pmi_pre1_symmetry_mode : string := "DIRECT";
       pmi_highspeed_clk : string := "NONE";
       pmi_clk0_div : string := "ENABLED";
       pmi_clk1_div : string := "ENABLED";
       pmi_clk2_div : string := "ENABLED";
       pmi_clk3_div : string := "ENABLED";
       module_type : string := "pmi_dsp_preadd_slice"
    );
    port (
       M0A : in std_logic_vector((pmi_data_m0a_width-1) downto 0); 
       M0B : in std_logic_vector((pmi_data_m0b_width-1) downto 0); 
       M1A : in std_logic_vector((pmi_data_m1a_width-1) downto 0); 
       M1B : in std_logic_vector((pmi_data_m1b_width-1) downto 0); 
       M0C : in std_logic_vector((pmi_data_m0c_width-1) downto 0); 
       M1C : in std_logic_vector((pmi_data_m1c_width-1) downto 0); 
       SIGNM0A, SIGNM0B, SIGNM1A, SIGNM1B : in std_logic;
       SOURCEM0A, SOURCEM1A : in std_logic;
       CFB, CIN : in std_logic_vector(53 downto 0);
       SIGNCIN : in std_logic;
       SRIA, SRIB : in std_logic_vector(17 downto 0);
       AMUXSEL, BMUXSEL : in std_logic_vector(1 downto 0);
       CMUXSEL : in std_logic_vector(2 downto 0);
       OPPRE : in std_logic_vector(1 downto 0);
       OP : in std_logic_vector(3 downto 0);
       CLK, CE, RST : in std_logic_vector(3 downto 0);
       R, CO : out std_logic_vector(53 downto 0);
       SIGNR : out std_logic;
       SROA, SROB : out std_logic_vector(17 downto 0)
    );
  end component pmi_dsp_preadd_slice;

  component pmi_pll is
     generic (
       pmi_freq_clki : integer := 100; 
       pmi_freq_clkfb : integer := 100; 
       pmi_freq_clkop : integer := 100; 
       pmi_freq_clkos : integer := 100; 
       pmi_freq_clkok : integer := 50; 
       pmi_family : string := "EC"; 
       pmi_phase_adj : integer := 0; 
       pmi_duty_cycle : integer := 50; 
       pmi_clkfb_source : string := "CLKOP"; 
       pmi_fdel : string := "off"; 
       pmi_fdel_val : integer := 0; 
       module_type : string := "pmi_pll" 
    );
    port (
     CLKI: in std_logic;
     CLKFB: in std_logic;
     RESET: in std_logic;
     CLKOP: out std_logic;
     CLKOS: out std_logic;
     CLKOK: out std_logic;
     CLKOK2: out std_logic;
     LOCK: out std_logic
   );
  end component pmi_pll;

  component pmi_pll_fp is
     generic (
       pmi_freq_clki : string := "100.0"; 
       pmi_freq_clkfb : string := "100.0"; 
       pmi_freq_clkop : string := "100.0"; 
       pmi_freq_clkos : string := "100.0"; 
       pmi_freq_clkok : string := "50.0"; 
       pmi_family : string := "EC"; 
       pmi_phase_adj : string := "0.0"; 
       pmi_duty_cycle : string := "50.0"; 
       pmi_clkfb_source : string := "CLKOP"; 
       pmi_fdel : string := "off"; 
       pmi_fdel_val : integer := 0; 
       module_type : string := "pmi_pll_fp" 
    );
    port (
     CLKI: in std_logic;
     CLKFB: in std_logic;
     RESET: in std_logic;
     CLKOP: out std_logic;
     CLKOS: out std_logic;
     CLKOK: out std_logic;
     CLKOK2: out std_logic;
     LOCK: out std_logic
   );
  end component pmi_pll_fp;

  attribute syn_black_box: boolean ;
  attribute GSR : string;

  component jtaghub16
       generic (
                  LSCC_FAMILY : string := "XO";
                  IP_ENABLE_VAL : string := "0x0000";
                  HUB_00 : string := "0x00";
                  HUB_01 : string := "0x00";
                  HUB_02 : string := "0x00";
                  HUB_03 : string := "0x00";
                  HUB_04 : string := "0x00";
                  HUB_05 : string := "0x00";
                  HUB_06 : string := "0x00";
                  HUB_07 : string := "0x00";
                  HUB_08 : string := "0x00";
                  HUB_09 : string := "0x00";
                  HUB_10 : string := "0x00";
                  HUB_11 : string := "0x00";
                  HUB_12 : string := "0x00";
                  HUB_13 : string := "0x00";
                  HUB_14 : string := "0x00";
                  HUB_15 : string := "0x00"
       );
       port (
	          tcka, tmsa, tdia : in std_logic;
	          er2_tdo : in std_logic_vector (15 downto 0);
	          tdoa, jtck, jtdi, jshift, jupdate, jrstn, jce2, cdn : out std_logic;
	          ip_enable : out std_logic_vector (15 downto 0)
       );
  end component;
  attribute syn_black_box of jtaghub16 : component is true;
  attribute GSR of jtaghub16 : component is "DISABLED";

  component jtagconn16
--	generic (
--	   JTAG_IP : string := "ORCA";
--	   IP_ID   : string := "0";
--	   HUB_ID  : string := "0"
--	);
	port (
	   er2_tdo : in std_logic;
	   jtck, jtdi, jshift, jupdate, jrstn, jce2, ip_enable : out std_logic
	);
  end component;
  attribute syn_black_box of jtagconn16 : component is true;

end package pmi_components;

