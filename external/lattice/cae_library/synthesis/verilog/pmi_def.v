// --------------------------------------------------------------------
// >>>>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<
// --------------------------------------------------------------------
// Copyright (c) 2005-2011 by Lattice Semiconductor Corporation
// --------------------------------------------------------------------
//
//
//                     Lattice Semiconductor Corporation
//                     5555 NE Moore Court
//                     Hillsboro, OR 97214
//                     U.S.A.
//
//                     TEL: 1-800-Lattice  (USA and Canada)
//                          1-408-826-6000 (other locations)
//
//                     web: http://www.latticesemi.com/
//                     email: techsupport@latticesemi.com
//
// --------------------------------------------------------------------
//
// Black Box definition for PMI Blocks
// fpga\verilog\pkg\versclibs\data\pmi\pmi_def.v 1.38 20-FEB-2014 15:15:03 FGAO2

module pmi_distributed_dpram 
    #(parameter pmi_addr_depth = 32,
      parameter pmi_addr_width = 5,
      parameter pmi_data_width = 8,
      parameter pmi_regmode = "reg",
      parameter pmi_init_file = "none",
      parameter pmi_init_file_format = "binary",
      parameter pmi_family = "EC",
      parameter module_type = "pmi_distributed_dpram")
  
      (
      input [(pmi_addr_width-1):0] WrAddress,
      input [(pmi_data_width-1):0] Data,
      input WrClock,
      input WE,
      input WrClockEn,
      input [(pmi_addr_width-1):0] RdAddress,
      input RdClock,
      input RdClockEn,
      input Reset,
      output [(pmi_data_width-1):0] Q)/* synthesis syn_black_box */;
  
  endmodule // pmi_distributed_dpram
  
  module pmi_distributed_rom
    #(parameter pmi_addr_depth = 32,
      parameter pmi_addr_width = 5,
      parameter pmi_data_width = 8,
      parameter pmi_regmode = "reg",
      parameter pmi_init_file = "none",
      parameter pmi_init_file_format = "binary",
      parameter pmi_family = "EC",
      parameter module_type = "pmi_distributed_rom")
      (
       input [(pmi_addr_width-1):0] Address,
       input OutClock,
       input OutClockEn,
       input Reset,
       output [(pmi_data_width-1):0] Q)/* synthesis syn_black_box */;
     
  endmodule // pmi_distributed_rom
  
  
  module pmi_distributed_spram 
    #(parameter pmi_addr_depth = 32,
      parameter pmi_addr_width = 5,
      parameter pmi_data_width = 8,
      parameter pmi_regmode = "reg",
      parameter pmi_init_file = "none",
      parameter pmi_init_file_format = "binary",
      parameter pmi_family = "EC",
      parameter module_type = "pmi_distributed_spram")
  
      (
       input [(pmi_addr_width-1):0] Address,
       input [(pmi_data_width-1):0] Data,
       input Clock,
       input ClockEn,
       input WE,
       input Reset,
       output [(pmi_data_width-1):0] Q)/* synthesis syn_black_box */;
  
  endmodule // pmi_distributed_spram
  
  module pmi_distributed_shift_reg
    #(parameter pmi_data_width = 16,
      parameter pmi_regmode = "reg",
      parameter pmi_shiftreg_type = "fixed",
      parameter pmi_num_shift = 16,
      parameter pmi_num_width = 4,
      parameter pmi_max_shift = 16,
      parameter pmi_max_width = 4,
      parameter pmi_init_file = "none",
      parameter pmi_init_file_format = "binary",
      parameter pmi_family = "EC",
      parameter module_type = "pmi_distributed_shift_reg")
    
      (
       input [(pmi_data_width-1):0] Din,
       input [(pmi_max_width-1):0] Addr,
       input Clock,
       input ClockEn,
       input Reset,
       output [(pmi_data_width-1):0] Q)/*synthesis syn_black_box*/;
  
  endmodule // pmi_distributed_shift_reg
  
  module pmi_constant_mult #(parameter pmi_dataa_width = 8, 
                    parameter pmi_datab_width = 8,
                    parameter module_type = "pmi_constant_mult",
                    parameter pmi_sign = "on",
                    parameter pmi_additional_pipeline = 1,
                    parameter pmi_constant_value = 2,
                    parameter pmi_input_reg = "on",
                    parameter pmi_output_reg = "on",
                    parameter pmi_family = "EC",
                    parameter pmi_implementation = "LUT")
  
                (input   [(pmi_dataa_width-1):0]  DataA,
                 input   Clock, ClkEn, Aclr,
                 output  [(pmi_dataa_width + pmi_datab_width - 1):0]  Result)/*synthesis syn_black_box*/;
  
  endmodule // pmi_constant_mult
  
  module pmi_mult #(parameter pmi_dataa_width = 8, 
             parameter pmi_datab_width = 8,
             parameter module_type = "pmi_mult",
             parameter pmi_sign = "on",
             parameter pmi_additional_pipeline = 1,
             parameter pmi_input_reg = "on",
             parameter pmi_output_reg = "on",
             parameter pmi_family = "EC",
             parameter pmi_implementation = "LUT")
  
            (input   [(pmi_dataa_width-1):0]  DataA,
             input   [(pmi_datab_width-1):0]  DataB,
             input   Clock, ClkEn, Aclr,
             output  [(pmi_dataa_width + pmi_datab_width - 1):0]  Result)/*synthesis syn_black_box*/;
  
  endmodule // pmi_mult
  
  module pmi_mac #(parameter pmi_dataa_width = 8,
             parameter pmi_datab_width = 8,
             parameter pmi_accum_width = 32,
             parameter module_type = "pmi_mac",
             parameter pmi_sign = "on",
             parameter pmi_additional_pipeline = 1,
             parameter pmi_add_sub = "add",
             parameter pmi_input_reg = "on",
             parameter pmi_family = "EC",
             parameter pmi_implementation = "LUT")
  
            (input   [(pmi_dataa_width - 1):0]  DataA,
             input   [(pmi_datab_width - 1):0]  DataB,
             input   Clock, ClkEn, Aclr,
             output  [(pmi_accum_width - 1):0]  Result)/*synthesis syn_black_box*/;
  
  endmodule // pmi_mac
  
  module pmi_multaddsub #(parameter pmi_dataa_width = 8, 
             parameter pmi_datab_width = 8,
             parameter module_type = "pmi_multaddsub",
             parameter pmi_sign = "on",
             parameter pmi_additional_pipeline = 1,
             parameter pmi_add_sub = "add",
             parameter pmi_input_reg = "on",
             parameter pmi_output_reg = "on",
             parameter pmi_family = "EC",
             parameter pmi_implementation = "LUT")
  
            (input   [(pmi_dataa_width-1):0]  DataA0,
             input   [(pmi_dataa_width-1):0]  DataA1,
             input   [(pmi_datab_width-1):0]  DataB0,
             input   [(pmi_datab_width-1):0]  DataB1,
             input   Clock, ClkEn, Aclr,
             output  [(pmi_dataa_width + pmi_datab_width):0]  Result)/*synthesis syn_black_box*/;
  
  endmodule // pmi_multaddsub
  
  module pmi_multaddsubsum #(parameter pmi_dataa_width = 8, 
             parameter pmi_datab_width = 8,
             parameter module_type = "pmi_multaddsubsum",
             parameter pmi_sign = "on",
             parameter pmi_additional_pipeline = 1,
             parameter pmi_add_sub0 = "add",
             parameter pmi_add_sub1 = "add",
             parameter pmi_input_reg = "on",
             parameter pmi_output_reg = "on",
             parameter pmi_family = "EC",
             parameter pmi_implementation = "LUT")
  
            (input   [(pmi_dataa_width-1):0]  DataA0,
             input   [(pmi_dataa_width-1):0]  DataA1,
             input   [(pmi_dataa_width-1):0]  DataA2,
             input   [(pmi_dataa_width-1):0]  DataA3,
             input   [(pmi_datab_width-1):0]  DataB0,
             input   [(pmi_datab_width-1):0]  DataB1,
             input   [(pmi_datab_width-1):0]  DataB2,
             input   [(pmi_datab_width-1):0]  DataB3,
             input   Clock, ClkEn, Aclr,
             output  [(pmi_dataa_width + pmi_datab_width + 1):0]  Result)/*synthesis syn_black_box*/;
  
  endmodule // pmi_multaddsubsum
  
  module pmi_complex_mult #(parameter pmi_dataa_width = 8,
             parameter pmi_datab_width = 8,
             parameter module_type = "pmi_complex_mult",
             parameter pmi_sign = "on",
             parameter pmi_additional_pipeline = 1,
             parameter pmi_input_reg = "on",
             parameter pmi_output_reg = "on",
             parameter pmi_family = "EC",
             parameter pmi_mult_mode = 3,
             parameter pmi_implementation = "LUT")
  
            (input   [(pmi_dataa_width-1):0]  DataA_Re,
             input   [(pmi_dataa_width-1):0]  DataA_Im,
             input   [(pmi_datab_width-1):0]  DataB_Re,
             input   [(pmi_datab_width-1):0]  DataB_Im,
             input   Clock, ClkEn, Aclr,
             output  [(pmi_dataa_width + pmi_datab_width):0]  Result_Re,
             output  [(pmi_dataa_width + pmi_datab_width):0]  Result_Im)/*synthesis syn_black_box*/;
  
  endmodule // pmi_complex_mult
  
  module pmi_add 
    #(parameter pmi_data_width = 8,
      parameter pmi_result_width = 8,
      parameter pmi_sign = "off",
      parameter pmi_family = "EC",
      parameter module_type = "pmi_add"
      )
  
      (
       input [pmi_data_width-1:0] DataA,
       input [pmi_data_width-1:0] DataB,
       input Cin,
       output [pmi_data_width-1:0] Result,
       output Cout,
       output Overflow)/*synthesis syn_black_box */;
  endmodule // pmi_add
  
  module pmi_sub 
    #(parameter pmi_data_width = 8,
      parameter pmi_result_width = 8,
      parameter pmi_sign = "off",
      parameter pmi_family = "EC",
      parameter module_type = "pmi_sub"
      )
      
      (
       input [pmi_data_width-1:0] DataA,
       input [pmi_data_width-1:0] DataB,
       input Cin,
       output [pmi_data_width-1:0] Result,
       output Cout,
       output Overflow)/*synthesis syn_black_box */;
  endmodule // pmi_sub
  
  module pmi_counter 
    #(parameter pmi_data_width = 8,
      parameter pmi_updown = "up",
      parameter pmi_family = "EC",
      parameter module_type = "pmi_counter"
      )
  
    (
     input Clock,
     input Clk_En,
     input Aclr,
     input UpDown,
     output [pmi_data_width-1:0] Q)/*synthesis syn_black_box */;
  endmodule // pmi_counter
  
  module pmi_addsub #(parameter pmi_data_width = 8,
              parameter pmi_result_width = 8,
              parameter pmi_sign = "off",
              parameter pmi_family = "EC",
              parameter module_type = "pmi_addsub"
              )
    
    (
     input [pmi_data_width-1:0] DataA,
     input [pmi_data_width-1:0] DataB,
     input Cin,
     input Add_Sub,
     output [pmi_data_width-1:0] Result,
     output Cout,
     output Overflow)/*synthesis syn_black_box */;
  endmodule // pmi_addsub
  
  module pmi_ram_dp
    #(parameter pmi_wr_addr_depth = 512,
      parameter pmi_wr_addr_width = 9,
      parameter pmi_wr_data_width = 18,
      parameter pmi_rd_addr_depth = 512,
      parameter pmi_rd_addr_width = 9,
      parameter pmi_rd_data_width = 18,
      parameter pmi_regmode = "reg",
      parameter pmi_gsr = "disable",
      parameter pmi_resetmode = "sync",
      parameter pmi_optimization = "speed",
      parameter pmi_init_file = "none",
      parameter pmi_init_file_format = "binary",
      parameter pmi_family = "EC",
      parameter module_type = "pmi_ram_dp")
      
      (input [(pmi_wr_data_width-1):0] Data,
       input [(pmi_wr_addr_width-1):0] WrAddress,
       input [(pmi_rd_addr_width-1):0] RdAddress,
       input  WrClock,
       input  RdClock,
       input  WrClockEn,
       input  RdClockEn,
       input  WE,
       input  Reset,
       output [(pmi_rd_data_width-1):0]  Q) /*synthesis syn_black_box*/;
  
  endmodule // pmi_ram_dp
  
  module pmi_ram_dp_be
    #(parameter pmi_wr_addr_depth = 512,
      parameter pmi_wr_addr_width = 9,
      parameter pmi_wr_data_width = 18,
      parameter pmi_rd_addr_depth = 512,
      parameter pmi_rd_addr_width = 9,
      parameter pmi_rd_data_width = 18,
      parameter pmi_regmode = "reg",
      parameter pmi_gsr = "disable",
      parameter pmi_resetmode = "sync",
      parameter pmi_optimization = "speed",
      parameter pmi_init_file = "none",
      parameter pmi_init_file_format = "binary",
      parameter pmi_byte_size = 9,
      parameter pmi_family = "ECP2",
      parameter module_type = "pmi_ram_dp_be")
      
      (input [(pmi_wr_data_width-1):0] Data,
       input [(pmi_wr_addr_width-1):0] WrAddress,
       input [(pmi_rd_addr_width-1):0] RdAddress,
       input  WrClock,
       input  RdClock,
       input  WrClockEn,
       input  RdClockEn,
       input  WE,
       input  Reset,
       input [((pmi_wr_data_width+pmi_byte_size-1)/pmi_byte_size-1):0] ByteEn,
       output [(pmi_rd_data_width-1):0]  Q) /*synthesis syn_black_box*/;
  
  endmodule // pmi_ram_dp_be
  
  module pmi_ram_dp_true
    #(parameter pmi_addr_depth_a = 512,
      parameter pmi_addr_width_a = 9,
      parameter pmi_data_width_a = 18,
      parameter pmi_addr_depth_b = 512,
      parameter pmi_addr_width_b = 9,
      parameter pmi_data_width_b = 18,
      parameter pmi_regmode_a = "reg",
      parameter pmi_regmode_b = "reg",
      parameter pmi_gsr = "disable",
      parameter pmi_resetmode = "sync",
      parameter pmi_optimization = "speed",
      parameter pmi_init_file = "none",
      parameter pmi_init_file_format = "binary",
      parameter pmi_write_mode_a = "normal",
      parameter pmi_write_mode_b = "normal",
      parameter pmi_family = "EC",
      parameter module_type = "pmi_ram_dp_true")
    
      (input [(pmi_data_width_a-1):0]	DataInA,
       input [(pmi_data_width_b-1):0]	DataInB,
       input [(pmi_addr_width_a-1):0] AddressA,
       input [(pmi_addr_width_b-1):0] AddressB,
       input  ClockA,
       input  ClockB,
       input  ClockEnA,
       input  ClockEnB,
       input  WrA,
       input  WrB,
       input  ResetA,
       input  ResetB,
       output [(pmi_data_width_a-1):0]  QA,
       output [(pmi_data_width_b-1):0]  QB)/*synthesis syn_black_box */;
     
  endmodule // pmi_ram_dp_true
  
  module pmi_ram_dp_true_be
    #(parameter pmi_addr_depth_a = 512,
      parameter pmi_addr_width_a = 9,
      parameter pmi_data_width_a = 18,
      parameter pmi_addr_depth_b = 512,
      parameter pmi_addr_width_b = 9,
      parameter pmi_data_width_b = 18,
      parameter pmi_regmode_a = "reg",
      parameter pmi_regmode_b = "reg",
      parameter pmi_gsr = "disable",
      parameter pmi_resetmode = "sync",
      parameter pmi_optimization = "speed",
      parameter pmi_init_file = "none",
      parameter pmi_init_file_format = "binary",
      parameter pmi_write_mode_a = "normal",
      parameter pmi_write_mode_b = "normal",
      parameter pmi_byte_size = 9,
      parameter pmi_family = "ECP2",
      parameter module_type = "pmi_ram_dp_true_be")
    
      (input [(pmi_data_width_a-1):0]	DataInA,
       input [(pmi_data_width_b-1):0]	DataInB,
       input [(pmi_addr_width_a-1):0] AddressA,
       input [(pmi_addr_width_b-1):0] AddressB,
       input  ClockA,
       input  ClockB,
       input  ClockEnA,
       input  ClockEnB,
       input  WrA,
       input  WrB,
       input  ResetA,
       input  ResetB,
       input [((pmi_data_width_a+pmi_byte_size-1)/pmi_byte_size-1):0] ByteEnA,
       input [((pmi_data_width_b+pmi_byte_size-1)/pmi_byte_size-1):0] ByteEnB,
       output [(pmi_data_width_a-1):0]  QA,
       output [(pmi_data_width_b-1):0]  QB)/*synthesis syn_black_box */;
     
  endmodule // pmi_ram_dp_true_be
  
  module pmi_ram_dq
    #(parameter pmi_addr_depth = 512,
      parameter pmi_addr_width = 9,
      parameter pmi_data_width = 18,
      parameter pmi_regmode = "reg",
      parameter pmi_gsr = "disable",
      parameter pmi_resetmode = "sync",
      parameter pmi_optimization = "speed",
      parameter pmi_init_file = "none",
      parameter pmi_init_file_format = "binary",
      parameter pmi_write_mode = "normal",
      parameter pmi_family = "EC",
      parameter module_type = "pmi_ram_dq")
      
      (input [(pmi_data_width-1):0]	Data,
       input [(pmi_addr_width-1):0] Address,
       input  Clock,
       input  ClockEn,
       input  WE,
       input  Reset,
       output [(pmi_data_width-1):0]  Q)/*synthesis syn_black_box*/;
     
  endmodule // pmi_ram_dq
  
  module pmi_ram_dq_be
    #(parameter pmi_addr_depth = 512,
      parameter pmi_addr_width = 9,
      parameter pmi_data_width = 18,
      parameter pmi_regmode = "reg",
      parameter pmi_gsr = "disable",
      parameter pmi_resetmode = "sync",
      parameter pmi_optimization = "speed",
      parameter pmi_init_file = "none",
      parameter pmi_init_file_format = "binary",
      parameter pmi_write_mode = "normal",
      parameter pmi_byte_size = 9,
      parameter pmi_family = "ECP2",
      parameter module_type = "pmi_ram_dq_be")
      
      (input [(pmi_data_width-1):0]	Data,
       input [(pmi_addr_width-1):0] Address,
       input  Clock,
       input  ClockEn,
       input  WE,
       input  Reset,
       input [((pmi_data_width+pmi_byte_size-1)/pmi_byte_size-1):0] ByteEn,
       output [(pmi_data_width-1):0]  Q)/*synthesis syn_black_box*/;
     
  endmodule // pmi_ram_dq_be
  
  module pmi_rom
    #(parameter pmi_addr_depth = 512,
      parameter pmi_addr_width = 9,
      parameter pmi_data_width = 8,
      parameter pmi_regmode = "reg",
      parameter pmi_gsr = "disable",
      parameter pmi_resetmode = "sync",
      parameter pmi_optimization = "speed",
      parameter pmi_init_file = "none",
      parameter pmi_init_file_format = "binary",
      parameter pmi_family = "EC",
      parameter module_type = "pmi_rom")
  
      (input [(pmi_addr_width-1):0]	Address,
       input OutClock,
       input OutClockEn,
       input Reset,
       output [(pmi_data_width-1):0] Q)/*synthesis syn_black_box*/;
  
  endmodule // pmi_rom
  
  module pmi_fifo_dc #(
               parameter pmi_data_width_w = 18,
               parameter pmi_data_width_r = 18,
               parameter pmi_data_depth_w = 256,
               parameter pmi_data_depth_r = 256,
               parameter pmi_full_flag = 256,
               parameter pmi_empty_flag = 0,
               parameter pmi_almost_full_flag = 252,
               parameter pmi_almost_empty_flag = 4,
               parameter pmi_regmode = "reg",
               parameter pmi_resetmode = "async",
               parameter pmi_family = "EC" ,
               parameter module_type = "pmi_fifo_dc",
                parameter pmi_implementation = "EBR"
               )
  
    (input  [pmi_data_width_w-1:0] Data,
     input WrClock,
     input RdClock,
     input WrEn,
     input RdEn,
     input Reset,
     input RPReset,
     output [pmi_data_width_r-1:0] Q,
     output Empty,
     output Full,
     output AlmostEmpty,
     output AlmostFull)/*synthesis syn_black_box */;
  
  endmodule // pmi_fifo_dc
  
  module pmi_fifo #(
               parameter pmi_data_width = 8,
               parameter pmi_data_depth = 256,
               parameter pmi_full_flag = 256,
               parameter pmi_empty_flag = 0,
               parameter pmi_almost_full_flag = 252,
               parameter pmi_almost_empty_flag = 4,
               parameter pmi_regmode = "reg",
               parameter pmi_family = "EC" ,
               parameter module_type = "pmi_fifo",
                parameter pmi_implementation = "EBR")
  
    (input  [pmi_data_width-1:0] Data,
     input Clock,
     input WrEn,
     input RdEn,
     input Reset,
     output [pmi_data_width-1:0] Q,
     output Empty,
     output Full,
     output AlmostEmpty,
     output AlmostFull)/*synthesis syn_black_box */;
  
  endmodule // pmi_fifo
  
  module pmi_dsp_mac #(
  parameter pmi_dataa_width = 8,
     parameter pmi_datab_width = 8,
     parameter pmi_additional_pipeline = 0,
     parameter pmi_input_reg = "on",
     parameter pmi_family = "ECP2",
     parameter pmi_gsr = "enable",
     parameter pmi_source_control_a = "parallel",
     parameter pmi_source_control_b = "parallel",
     parameter pmi_reg_inputa_clk = "CLK0",
     parameter pmi_reg_inputa_ce = "CE0",
     parameter pmi_reg_inputa_rst = "RST0",
     parameter pmi_reg_inputb_clk = "CLK0",
     parameter pmi_reg_inputb_ce = "CE0",
     parameter pmi_reg_inputb_rst = "RST0",
     parameter pmi_reg_pipeline_clk = "CLK0",
     parameter pmi_reg_pipeline_ce = "CE0",
     parameter pmi_reg_pipeline_rst = "RST0",
     parameter pmi_reg_output_clk = "CLK0",
     parameter pmi_reg_output_ce = "CE0",
     parameter pmi_reg_output_rst = "RST0",
     parameter pmi_reg_signeda_0_clk = "CLK0",
     parameter pmi_reg_signeda_0_ce = "CE0",
     parameter pmi_reg_signeda_0_rst = "RST0",
     parameter pmi_reg_signeda_1_clk = "CLK0",
     parameter pmi_reg_signeda_1_ce = "CE0",
     parameter pmi_reg_signeda_1_rst = "RST0",
     parameter pmi_reg_signedb_0_clk = "CLK0",
     parameter pmi_reg_signedb_0_ce = "CE0",
     parameter pmi_reg_signedb_0_rst = "RST0",
     parameter pmi_reg_signedb_1_clk = "CLK0",
     parameter pmi_reg_signedb_1_ce = "CE0",
     parameter pmi_reg_signedb_1_rst = "RST0",
     parameter pmi_reg_addnsub_0_clk = "CLK0",
     parameter pmi_reg_addnsub_0_ce = "CE0",
     parameter pmi_reg_addnsub_0_rst = "RST0",
     parameter pmi_reg_addnsub_1_clk = "CLK0",
     parameter pmi_reg_addnsub_1_ce = "CE0",
     parameter pmi_reg_addnsub_1_rst = "RST0",
     parameter pmi_reg_accumsload_0_clk = "CLK0",
     parameter pmi_reg_accumsload_0_ce = "CE0",
     parameter pmi_reg_accumsload_0_rst = "RST0",
     parameter pmi_reg_accumsload_1_clk = "CLK0",
     parameter pmi_reg_accumsload_1_ce = "CE0",
     parameter pmi_reg_accumsload_1_rst = "RST0",
     parameter module_type = "pmi_dsp_mac")
  
    (input [(pmi_dataa_width-1):0]       A,
     input [(pmi_datab_width-1):0]       B,
     input [17:0]       SRIA,
     input [17:0]       SRIB,
     input CLK0,
     input CLK1,
     input CLK2,
     input CLK3,
     input CE0,
     input CE1,
     input CE2,
     input CE3,
     input RST0,
     input RST1,
     input RST2,
     input RST3,
     input SignA,
     input SignB,
     input SourceA,
     input SourceB,
     input ADDNSUB,
     input [((pmi_dataa_width + pmi_datab_width - 1) + 16):0] LD,
     input ACCUMSLOAD,
     output [((pmi_dataa_width + pmi_datab_width - 1) + 16):0] ACCUM,
     output OVERFLOW,
     output [17:0]  SROA,
     output [17:0]  SROB)/*synthesis syn_black_box */;
  
  endmodule // pmi_dsp_mac
  
  module pmi_dsp_mult
   #(parameter pmi_dataa_width = 8,
     parameter pmi_datab_width = 8,
     parameter pmi_additional_pipeline = 0,
     parameter pmi_input_reg = "on",
     parameter pmi_output_reg = "on",
     parameter pmi_family = "ECP2",
     parameter pmi_gsr = "enable",
     parameter pmi_source_control_a = "parallel",
     parameter pmi_source_control_b = "parallel",
     parameter pmi_reg_inputa_clk = "CLK0",
     parameter pmi_reg_inputa_ce = "CE0",
     parameter pmi_reg_inputa_rst = "RST0",
     parameter pmi_reg_inputb_clk = "CLK0",
     parameter pmi_reg_inputb_ce = "CE0",
     parameter pmi_reg_inputb_rst = "RST0",
     parameter pmi_reg_pipeline_clk = "CLK0",
     parameter pmi_reg_pipeline_ce = "CE0",
     parameter pmi_reg_pipeline_rst = "RST0",
     parameter pmi_reg_output_clk = "CLK0",
     parameter pmi_reg_output_ce = "CE0",
     parameter pmi_reg_output_rst = "RST0",
     parameter pmi_reg_signeda_clk = "CLK0",
     parameter pmi_reg_signeda_ce = "CE0",
     parameter pmi_reg_signeda_rst = "RST0",
     parameter pmi_reg_signedb_clk = "CLK0",
     parameter pmi_reg_signedb_ce = "CE0",
     parameter pmi_reg_signedb_rst = "RST0",
     parameter pmi_pipelined_mode = "off",
     parameter module_type = "pmi_dsp_mult")
  
    (input [(pmi_dataa_width-1):0]       A,
     input [(pmi_datab_width-1):0]       B,
     input [17:0]       SRIA,
     input [17:0]       SRIB,
     input CLK0,
     input CLK1,
     input CLK2,
     input CLK3,
     input CE0,
     input CE1,
     input CE2,
     input CE3,
     input RST0,
     input RST1,
     input RST2,
     input RST3,
     input SignA,
     input SignB,
     input SourceA,
     input SourceB,
     output [(pmi_dataa_width + pmi_datab_width - 1):0]  P,
     output [17:0]  SROA,
     output [17:0]  SROB)/*synthesis syn_black_box */;
  
  endmodule //pmi_dsp_mult
  
  module pmi_dsp_multaddsub
   #(parameter pmi_dataa_width = 8,
     parameter pmi_datab_width = 8,
     parameter pmi_additional_pipeline = 0,
     parameter pmi_input_reg = "on",
     parameter pmi_output_reg = "on",
     parameter pmi_family = "ECP2",
     parameter pmi_gsr = "enable",
     parameter pmi_source_control_a0 = "parallel",
     parameter pmi_source_control_a1 = "parallel",
     parameter pmi_source_control_b0 = "parallel",
     parameter pmi_source_control_b1 = "parallel",
     parameter pmi_reg_inputa0_clk = "CLK0",
     parameter pmi_reg_inputa0_ce = "CE0",
     parameter pmi_reg_inputa0_rst = "RST0",
     parameter pmi_reg_inputa1_clk = "CLK0",
     parameter pmi_reg_inputa1_ce = "CE0",
     parameter pmi_reg_inputa1_rst = "RST0",
     parameter pmi_reg_inputb0_clk = "CLK0",
     parameter pmi_reg_inputb0_ce = "CE0",
     parameter pmi_reg_inputb0_rst = "RST0",
     parameter pmi_reg_inputb1_clk = "CLK0",
     parameter pmi_reg_inputb1_ce = "CE0",
     parameter pmi_reg_inputb1_rst = "RST0",
     parameter pmi_reg_pipeline0_clk = "CLK0",
     parameter pmi_reg_pipeline0_ce = "CE0",
     parameter pmi_reg_pipeline0_rst = "RST0",
     parameter pmi_reg_pipeline1_clk = "CLK0",
     parameter pmi_reg_pipeline1_ce = "CE0",
     parameter pmi_reg_pipeline1_rst = "RST0",
     parameter pmi_reg_output_clk = "CLK0",
     parameter pmi_reg_output_ce = "CE0",
     parameter pmi_reg_output_rst = "RST0",
     parameter pmi_reg_signeda_0_clk = "CLK0",
     parameter pmi_reg_signeda_0_ce = "CE0",
     parameter pmi_reg_signeda_0_rst = "RST0",
     parameter pmi_reg_signeda_1_clk = "CLK0",
     parameter pmi_reg_signeda_1_ce = "CE0",
     parameter pmi_reg_signeda_1_rst = "RST0",
     parameter pmi_reg_signedb_0_clk = "CLK0",
     parameter pmi_reg_signedb_0_ce = "CE0",
     parameter pmi_reg_signedb_0_rst = "RST0",
     parameter pmi_reg_signedb_1_clk = "CLK0",
     parameter pmi_reg_signedb_1_ce = "CE0",
     parameter pmi_reg_signedb_1_rst = "RST0",
     parameter pmi_reg_addnsub_0_clk = "CLK0",
     parameter pmi_reg_addnsub_0_ce = "CE0",
     parameter pmi_reg_addnsub_0_rst = "RST0",
     parameter pmi_reg_addnsub_1_clk = "CLK0",
     parameter pmi_reg_addnsub_1_ce = "CE0",
     parameter pmi_reg_addnsub_1_rst = "RST0",
     parameter pmi_pipelined_mode = "off",
     parameter module_type = "pmi_dsp_multaddsub")
  
    (input [(pmi_dataa_width-1):0]       A0, A1,
     input [(pmi_datab_width-1):0]       B0, B1,
     input [17:0]       SRIA,
     input [17:0]       SRIB,
     input CLK0,
     input CLK1,
     input CLK2,
     input CLK3,
     input CE0,
     input CE1,
     input CE2,
     input CE3,
     input RST0,
     input RST1,
     input RST2,
     input RST3,
     input SignA,
     input SignB,
     input ShiftA0,
     input ShiftA1,
     input ShiftB0,
     input ShiftB1,
     input ADDNSUB,
     output [(pmi_dataa_width + pmi_datab_width):0]  SUM,
     output [17:0]  SROA,
     output [17:0]  SROB)/*synthesis syn_black_box */;
  
  endmodule // pmi_dsp_multaddsub
  
  module pmi_dsp_casmultaddsub
   #(parameter pmi_dataa_width = 18,
     parameter pmi_datab_width = 18,
     parameter pmi_additional_pipeline = 0,
     parameter pmi_input_reg = "on",
     parameter pmi_output_reg = "on",
     parameter pmi_family = "ECP3",
     parameter pmi_gsr = "enable",
     parameter pmi_reg_inputa0_clk = "CLK0",
     parameter pmi_reg_inputa0_ce = "CE0",
     parameter pmi_reg_inputa0_rst = "RST0",
     parameter pmi_reg_inputa1_clk = "CLK0",
     parameter pmi_reg_inputa1_ce = "CE0",
     parameter pmi_reg_inputa1_rst = "RST0",
     parameter pmi_reg_inputb0_clk = "CLK0",
     parameter pmi_reg_inputb0_ce = "CE0",
     parameter pmi_reg_inputb0_rst = "RST0",
     parameter pmi_reg_inputb1_clk = "CLK0",
     parameter pmi_reg_inputb1_ce = "CE0",
     parameter pmi_reg_inputb1_rst = "RST0",
     parameter pmi_reg_pipeline0_clk = "CLK0",
     parameter pmi_reg_pipeline0_ce = "CE0",
     parameter pmi_reg_pipeline0_rst = "RST0",
     parameter pmi_reg_pipeline1_clk = "CLK0",
     parameter pmi_reg_pipeline1_ce = "CE0",
     parameter pmi_reg_pipeline1_rst = "RST0",
     parameter pmi_reg_output_clk = "CLK0",
     parameter pmi_reg_output_ce = "CE0",
     parameter pmi_reg_output_rst = "RST0",
     parameter pmi_reg_signeda_0_clk = "CLK0",
     parameter pmi_reg_signeda_0_ce = "CE0",
     parameter pmi_reg_signeda_0_rst = "RST0",
     parameter pmi_reg_signeda_1_clk = "CLK0",
     parameter pmi_reg_signeda_1_ce = "CE0",
     parameter pmi_reg_signeda_1_rst = "RST0",
     parameter pmi_reg_signedb_0_clk = "CLK0",
     parameter pmi_reg_signedb_0_ce = "CE0",
     parameter pmi_reg_signedb_0_rst = "RST0",
     parameter pmi_reg_signedb_1_clk = "CLK0",
     parameter pmi_reg_signedb_1_ce = "CE0",
     parameter pmi_reg_signedb_1_rst = "RST0",
     parameter pmi_reg_addnsub_0_clk = "CLK0",
     parameter pmi_reg_addnsub_0_ce = "CE0",
     parameter pmi_reg_addnsub_0_rst = "RST0",
     parameter pmi_reg_addnsub_1_clk = "CLK0",
     parameter pmi_reg_addnsub_1_ce = "CE0",
     parameter pmi_reg_addnsub_1_rst = "RST0",
     parameter pmi_pipelined_mode = "off",
     parameter pmi_cascade_match_reg = "off",
     parameter module_type = "pmi_dsp_casmultaddsub")
  
    (input [(pmi_dataa_width-1):0]       A0, A1,
     input [(pmi_datab_width-1):0]       B0, B1,
     input [17:0]       SRIA,
     input [17:0]       SRIB,
     input CLK0,
     input CLK1,
     input CLK2,
     input CLK3,
     input CE0,
     input CE1,
     input CE2,
     input CE3,
     input RST0,
     input RST1,
     input RST2,
     input RST3,
     input SignA,
     input SignB,
     input ShiftA0,
     input ShiftA1,
     input ShiftB0,
     input ShiftB1,
     input ADDNSUB,
     input SignCIN,
     input [53:0] CIN,
     output SignSUM,
     output [53:0]  SUM,
     output [17:0]  SROA,
     output [17:0]  SROB)/*synthesis syn_black_box */;
  
  endmodule // pmi_dsp_casmultaddsub
  
  module pmi_dsp_multaddsubsum
   #(parameter pmi_dataa_width = 8,
     parameter pmi_datab_width = 8,
     parameter pmi_additional_pipeline = 0,
     parameter pmi_input_reg = "on",
     parameter pmi_output_reg = "on",
     parameter pmi_family = "ECP2",
     parameter pmi_gsr = "enable",
     parameter pmi_source_control_a0 = "parallel",
     parameter pmi_source_control_a1 = "parallel",
     parameter pmi_source_control_a2 = "parallel",
     parameter pmi_source_control_a3 = "parallel",
     parameter pmi_source_control_b0 = "parallel",
     parameter pmi_source_control_b1 = "parallel",
     parameter pmi_source_control_b2 = "parallel",
     parameter pmi_source_control_b3 = "parallel",
     parameter pmi_reg_inputa0_clk = "CLK0",
     parameter pmi_reg_inputa0_ce = "CE0",
     parameter pmi_reg_inputa0_rst = "RST0",
     parameter pmi_reg_inputa1_clk = "CLK0",
     parameter pmi_reg_inputa1_ce = "CE0",
     parameter pmi_reg_inputa1_rst = "RST0",
     parameter pmi_reg_inputa2_clk = "CLK0",
     parameter pmi_reg_inputa2_ce = "CE0",
     parameter pmi_reg_inputa2_rst = "RST0",
     parameter pmi_reg_inputa3_clk = "CLK0",
     parameter pmi_reg_inputa3_ce = "CE0",
     parameter pmi_reg_inputa3_rst = "RST0",
     parameter pmi_reg_inputb0_clk = "CLK0",
     parameter pmi_reg_inputb0_ce = "CE0",
     parameter pmi_reg_inputb0_rst = "RST0",
     parameter pmi_reg_inputb1_clk = "CLK0",
     parameter pmi_reg_inputb1_ce = "CE0",
     parameter pmi_reg_inputb1_rst = "RST0",
     parameter pmi_reg_inputb2_clk = "CLK0",
     parameter pmi_reg_inputb2_ce = "CE0",
     parameter pmi_reg_inputb2_rst = "RST0",
     parameter pmi_reg_inputb3_clk = "CLK0",
     parameter pmi_reg_inputb3_ce = "CE0",
     parameter pmi_reg_inputb3_rst = "RST0",
     parameter pmi_reg_pipeline0_clk = "CLK0",
     parameter pmi_reg_pipeline0_ce = "CE0",
     parameter pmi_reg_pipeline0_rst = "RST0",
     parameter pmi_reg_pipeline1_clk = "CLK0",
     parameter pmi_reg_pipeline1_ce = "CE0",
     parameter pmi_reg_pipeline1_rst = "RST0",
     parameter pmi_reg_pipeline2_clk = "CLK0",
     parameter pmi_reg_pipeline2_ce = "CE0",
     parameter pmi_reg_pipeline2_rst = "RST0",
     parameter pmi_reg_pipeline3_clk = "CLK0",
     parameter pmi_reg_pipeline3_ce = "CE0",
     parameter pmi_reg_pipeline3_rst = "RST0",
     parameter pmi_reg_output_clk = "CLK0",
     parameter pmi_reg_output_ce = "CE0",
     parameter pmi_reg_output_rst = "RST0",
     parameter pmi_reg_signeda_0_clk = "CLK0",
     parameter pmi_reg_signeda_0_ce = "CE0",
     parameter pmi_reg_signeda_0_rst = "RST0",
     parameter pmi_reg_signeda_1_clk = "CLK0",
     parameter pmi_reg_signeda_1_ce = "CE0",
     parameter pmi_reg_signeda_1_rst = "RST0",
     parameter pmi_reg_signedb_0_clk = "CLK0",
     parameter pmi_reg_signedb_0_ce = "CE0",
     parameter pmi_reg_signedb_0_rst = "RST0",
     parameter pmi_reg_signedb_1_clk = "CLK0",
     parameter pmi_reg_signedb_1_ce = "CE0",
     parameter pmi_reg_signedb_1_rst = "RST0",
     parameter pmi_reg_addnsub1_0_clk = "CLK0",
     parameter pmi_reg_addnsub1_0_ce = "CE0",
     parameter pmi_reg_addnsub1_0_rst = "RST0",
     parameter pmi_reg_addnsub1_1_clk = "CLK0",
     parameter pmi_reg_addnsub1_1_ce = "CE0",
     parameter pmi_reg_addnsub1_1_rst = "RST0",
     parameter pmi_reg_addnsub3_0_clk = "CLK0",
     parameter pmi_reg_addnsub3_0_ce = "CE0",
     parameter pmi_reg_addnsub3_0_rst = "RST0",
     parameter pmi_reg_addnsub3_1_clk = "CLK0",
     parameter pmi_reg_addnsub3_1_ce = "CE0",
     parameter pmi_reg_addnsub3_1_rst = "RST0",
     parameter pmi_pipelined_mode = "off",
     parameter module_type = "pmi_dsp_multaddsubsum")
  
    (input [(pmi_dataa_width-1):0]       A0, A1, A2, A3,
     input [(pmi_datab_width-1):0]       B0, B1, B2, B3,
     input [17:0]       SRIA,
     input [17:0]       SRIB,
     input CLK0,
     input CLK1,
     input CLK2,
     input CLK3,
     input CE0,
     input CE1,
     input CE2,
     input CE3,
     input RST0,
     input RST1,
     input RST2,
     input RST3,
     input SignA,
     input SignB,
     input ShiftA0,
     input ShiftA1,
     input ShiftA2,
     input ShiftA3,
     input ShiftB0,
     input ShiftB1,
     input ShiftB2,
     input ShiftB3,
     input ADDNSUB1,
     input ADDNSUB3,
     output [(pmi_dataa_width + pmi_datab_width + 1):0]  SUM,
     output [17:0]  SROA,
     output [17:0]  SROB)/*synthesis syn_black_box */;
  
  endmodule //pmi_dsp_multaddsubsum
  
  module pmi_dsp_preadd_slice #(
      parameter pmi_data_m0a_width = 18,
      parameter pmi_data_m0b_width = 18,
      parameter pmi_data_m1a_width = 18,
      parameter pmi_data_m1b_width = 18,
      parameter pmi_data_m0c_width = 18,
      parameter pmi_data_m1c_width = 18,
      parameter pmi_gsr = "enable",
      parameter pmi_family = "ECP5U",
      parameter pmi_reg_input_m0a_pre_clk = "CLK0",
      parameter pmi_reg_input_m0a_pre_ce = "CE0",
      parameter pmi_reg_input_m0a_pre_rst = "RST0",
      parameter pmi_reg_input_m0b_pre_clk = "CLK0",
      parameter pmi_reg_input_m0b_pre_ce = "CE0",
      parameter pmi_reg_input_m0b_pre_rst = "RST0",
      parameter pmi_reg_input_m0a_mult_clk = "CLK0",
      parameter pmi_reg_input_m0a_mult_ce = "CE0",
      parameter pmi_reg_input_m0a_mult_rst = "RST0",
      parameter pmi_reg_input_m0b_mult_clk = "CLK0",
      parameter pmi_reg_input_m0b_mult_ce = "CE0",
      parameter pmi_reg_input_m0b_mult_rst = "RST0",
      parameter pmi_reg_input_m1a_pre_clk = "CLK0",
      parameter pmi_reg_input_m1a_pre_ce = "CE0",
      parameter pmi_reg_input_m1a_pre_rst = "RST0",
      parameter pmi_reg_input_m1b_pre_clk = "CLK0",
      parameter pmi_reg_input_m1b_pre_ce = "CE0",
      parameter pmi_reg_input_m1b_pre_rst = "RST0",
      parameter pmi_reg_input_m1a_mult_clk = "CLK0",
      parameter pmi_reg_input_m1a_mult_ce = "CE0",
      parameter pmi_reg_input_m1a_mult_rst = "RST0",
      parameter pmi_reg_input_m1b_mult_clk = "CLK0",
      parameter pmi_reg_input_m1b_mult_ce = "CE0",
      parameter pmi_reg_input_m1b_mult_rst = "RST0",
      parameter pmi_reg_input_m0c_clk = "CLK0",
      parameter pmi_reg_input_m0c_ce = "CE0",
      parameter pmi_reg_input_m0c_rst = "RST0",
      parameter pmi_reg_input_m1c_clk = "CLK0",
      parameter pmi_reg_input_m1c_ce = "CE0",
      parameter pmi_reg_input_m1c_rst = "RST0",
      parameter pmi_reg_input_cfb_clk = "CLK0",
      parameter pmi_reg_input_cfb_ce = "CE0",
      parameter pmi_reg_input_cfb_rst = "RST0",
      parameter pmi_reg_pipeline0_clk = "CLK0",
      parameter pmi_reg_pipeline0_ce = "CE0",
      parameter pmi_reg_pipeline0_rst = "RST0",
      parameter pmi_reg_pipeline1_clk = "CLK0",
      parameter pmi_reg_pipeline1_ce = "CE0",
      parameter pmi_reg_pipeline1_rst = "RST0",
      parameter pmi_reg_output_clk = "CLK0",
      parameter pmi_reg_output_ce = "CE0",
      parameter pmi_reg_output_rst = "RST0",
      parameter pmi_reg_oppre0_clk = "CLK0",
      parameter pmi_reg_oppre0_ce = "CE0",
      parameter pmi_reg_oppre0_rst = "RST0",
      parameter pmi_reg_oppre1_clk = "CLK0",
      parameter pmi_reg_oppre1_ce = "CE0",
      parameter pmi_reg_oppre1_rst = "RST0",
      parameter pmi_reg_opcodein0_clk = "CLK0",
      parameter pmi_reg_opcodein0_ce = "CE0",
      parameter pmi_reg_opcodein0_rst = "RST0",
      parameter pmi_reg_opcodein1_clk = "CLK0",
      parameter pmi_reg_opcodein1_ce = "CE0",
      parameter pmi_reg_opcodein1_rst = "RST0",
      parameter pmi_cascade_match_reg = "off",
      parameter pmi_m0_sourcea_mode = "OPA0",
      parameter pmi_m1_sourcea_mode = "OPA1",
      parameter pmi_m0_sourceb_mode = "B",
      parameter pmi_m1_sourceb_mode = "B",
      parameter pmi_pre0_sourcea_mode = "A_SHIFT",
      parameter pmi_pre0_sourceb_mode = "SHIFT",
      parameter pmi_pre0_symmetry_mode = "DIRECT",
      parameter pmi_pre1_sourcea_mode = "A_SHIFT",
      parameter pmi_pre1_sourceb_mode = "SHIFT",
      parameter pmi_pre1_fb_mux = "SHIFT",
      parameter pmi_pre1_symmetry_mode = "DIRECT",
      parameter pmi_highspeed_clk = "NONE",
      parameter pmi_clk0_div = "ENABLED",
      parameter pmi_clk1_div = "ENABLED",
      parameter pmi_clk2_div = "ENABLED",
      parameter pmi_clk3_div = "ENABLED",
      parameter module_type = "pmi_dsp_preadd_slice")
  
    (input [pmi_data_m0a_width-1:0] M0A, 
     input [pmi_data_m0b_width-1:0] M0B, 
     input [pmi_data_m1a_width-1:0] M1A, 
     input [pmi_data_m1b_width-1:0] M1B, 
     input [pmi_data_m0c_width-1:0] M0C, 
     input [pmi_data_m1c_width-1:0] M1C, 
     input SIGNM0A, SIGNM0B, SIGNM1A, SIGNM1B,
     input SOURCEM0A, SOURCEM1A,
     input [53:0] CFB, CIN,
     input SIGNCIN,
     input [17:0] SRIA, SRIB,
     input [1:0] AMUXSEL, BMUXSEL,
     input [2:0] CMUXSEL,
     input [1:0] OPPRE,
     input [3:0] OP,
     input [3:0] CLK, CE, RST,
     output [53:0] R, CO,
     output SIGNR,
     output [17:0] SROA, SROB)/*synthesis syn_black_box*/;
  
  endmodule //pmi_dsp_preadd_slice
  
  module pmi_pll
   #(parameter pmi_freq_clki = 100,
     parameter pmi_freq_clkfb = 100,
     parameter pmi_freq_clkop = 100,
     parameter pmi_freq_clkos = 100,
     parameter pmi_freq_clkok = 50,
     parameter pmi_family = "EC",
     parameter pmi_phase_adj = 0,
     parameter pmi_duty_cycle = 50,
     parameter pmi_clkfb_source = "CLKOP",
     parameter pmi_fdel = "off",     // ECP2 Only
     parameter pmi_fdel_val = 0,
     parameter module_type = "pmi_pll")
  
    (input       CLKI,
     input       CLKFB,
     input       RESET,
     output      CLKOP,
     output      CLKOS,
     output      CLKOK,
     output      CLKOK2,
     output      LOCK)/*synthesis syn_black_box */;
  endmodule //pmi_pll
  
  module pmi_pll_fp
   #(parameter pmi_freq_clki = "100.0",
     parameter pmi_freq_clkfb = "100.0",
     parameter pmi_freq_clkop = "100.0",
     parameter pmi_freq_clkos = "100.0",
     parameter pmi_freq_clkok = "50.0",
     parameter pmi_family = "EC",
     parameter pmi_phase_adj = "0.0",
     parameter pmi_duty_cycle = "50.0",
     parameter pmi_clkfb_source = "CLKOP",
     parameter pmi_fdel = "off",     // ECP2 Only
     parameter pmi_fdel_val = 0,
     parameter module_type = "pmi_pll_fp")
  
    (input       CLKI,
     input       CLKFB,
     input       RESET,
     output      CLKOP,
     output      CLKOS,
     output      CLKOK,
     output      CLKOK2,
     output      LOCK)/*synthesis syn_black_box */;
  endmodule //pmi_pll_fp
  
  module jtaghub16 #(
      parameter  LSCC_FAMILY = "XO",
      parameter  IP_ENABLE_VAL = "0x0000",
      parameter  HUB_00 = "0x00",
      parameter  HUB_01 = "0x00",
      parameter  HUB_02 = "0x00",
      parameter  HUB_03 = "0x00",
      parameter  HUB_04 = "0x00",
      parameter  HUB_05 = "0x00",
      parameter  HUB_06 = "0x00",
      parameter  HUB_07 = "0x00",
      parameter  HUB_08 = "0x00",
      parameter  HUB_09 = "0x00",
      parameter  HUB_10 = "0x00",
      parameter  HUB_11 = "0x00",
      parameter  HUB_12 = "0x00",
      parameter  HUB_13 = "0x00",
      parameter  HUB_14 = "0x00",
      parameter  HUB_15 = "0x00")
  (   
      input          tcka,
      input          tmsa,
      input          tdia,
      input [15 :0]  er2_tdo,
  
      output         tdoa,
      output         jtck,
      output         jtdi,
      output         jshift,
      output         jupdate,
      output         jrstn,
      output         jce2,
      output reg     cdn,
      output reg [15 :0] ip_enable
  ) /* synthesis syn_black_box GSR=DISABLED */ ;
  endmodule
  
  module jtagconn16 (er2_tdo, jtck, jtdi, jshift, jupdate, jrstn, jce2, ip_enable); //synthesis syn_black_box
    input er2_tdo;
    output jtck, jtdi, jshift, jupdate, jrstn, jce2, ip_enable;
  
  //  parameter JTAG_IP = "ORCA";
  //  parameter IP_ID   = "0";
  //  parameter HUB_ID  = "0";
  endmodule
  
  