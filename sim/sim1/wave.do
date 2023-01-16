onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group GB_DECODER /gameboy_tb/CARTRIDGE_INST/GB_SIGNAL_DECODER/USER_RST
add wave -noupdate -expand -group GB_DECODER /gameboy_tb/CARTRIDGE_INST/GB_SIGNAL_DECODER/GB_CLK
add wave -noupdate -expand -group GB_DECODER -radix binary /gameboy_tb/CARTRIDGE_INST/GB_SIGNAL_DECODER/GB_ADDR
add wave -noupdate -expand -group GB_DECODER -radix hexadecimal /gameboy_tb/CARTRIDGE_INST/GB_SIGNAL_DECODER/GB_DATA_IN
add wave -noupdate -expand -group GB_DECODER -radix hexadecimal /gameboy_tb/CARTRIDGE_INST/GB_SIGNAL_DECODER/GB_DATA_OUT
add wave -noupdate -expand -group GB_DECODER /gameboy_tb/CARTRIDGE_INST/GB_SIGNAL_DECODER/GB_RDN
add wave -noupdate -expand -group GB_DECODER /gameboy_tb/CARTRIDGE_INST/GB_SIGNAL_DECODER/GB_CSN
add wave -noupdate -expand -group GB_DECODER /gameboy_tb/CARTRIDGE_INST/GB_SIGNAL_DECODER/CLK_I
add wave -noupdate -expand -group GB_DECODER /gameboy_tb/CARTRIDGE_INST/GB_SIGNAL_DECODER/STB_O
add wave -noupdate -expand -group GB_DECODER /gameboy_tb/CARTRIDGE_INST/GB_SIGNAL_DECODER/CYC_O
add wave -noupdate -expand -group GB_DECODER /gameboy_tb/CARTRIDGE_INST/GB_SIGNAL_DECODER/ACK_I
add wave -noupdate -expand -group GB_DECODER /gameboy_tb/CARTRIDGE_INST/GB_SIGNAL_DECODER/WE_O
add wave -noupdate -expand -group GB_DECODER -radix hexadecimal /gameboy_tb/CARTRIDGE_INST/GB_SIGNAL_DECODER/ADR_O
add wave -noupdate -expand -group GB_DECODER -radix hexadecimal /gameboy_tb/CARTRIDGE_INST/GB_SIGNAL_DECODER/DAT_I
add wave -noupdate -expand -group GB_DECODER -radix hexadecimal /gameboy_tb/CARTRIDGE_INST/GB_SIGNAL_DECODER/DAT_O
add wave -noupdate -expand -group GB_DECODER -radix hexadecimal /gameboy_tb/CARTRIDGE_INST/GB_SIGNAL_DECODER/data_read_register
add wave -noupdate -expand -group GB_DECODER /gameboy_tb/CARTRIDGE_INST/GB_SIGNAL_DECODER/gb_clk_sync
add wave -noupdate -expand -group GB_DECODER /gameboy_tb/CARTRIDGE_INST/GB_SIGNAL_DECODER/gb_csn_sync
add wave -noupdate -expand -group GB_DECODER /gameboy_tb/CARTRIDGE_INST/GB_SIGNAL_DECODER/gb_rdn_sync
add wave -noupdate -expand -group GB_DECODER -radix hexadecimal /gameboy_tb/CARTRIDGE_INST/GB_SIGNAL_DECODER/gb_addr_sync
add wave -noupdate -expand -group GB_DECODER -radix hexadecimal /gameboy_tb/CARTRIDGE_INST/GB_SIGNAL_DECODER/gb_data_sync
add wave -noupdate -expand -group GB_DECODER /gameboy_tb/CARTRIDGE_INST/GB_SIGNAL_DECODER/gb_access_rom
add wave -noupdate -expand -group GB_DECODER /gameboy_tb/CARTRIDGE_INST/GB_SIGNAL_DECODER/gb_access_ram
add wave -noupdate -expand -group GB_DECODER /gameboy_tb/CARTRIDGE_INST/GB_SIGNAL_DECODER/wb_state
add wave -noupdate -group CARTRIDGE_MEMORY_CONTROLLER /gameboy_tb/CARTRIDGE_INST/CARTRIDGE_MEMORY_CONTROLLER/CLK_I
add wave -noupdate -group CARTRIDGE_MEMORY_CONTROLLER /gameboy_tb/CARTRIDGE_INST/CARTRIDGE_MEMORY_CONTROLLER/RST_I
add wave -noupdate -group CARTRIDGE_MEMORY_CONTROLLER /gameboy_tb/CARTRIDGE_INST/CARTRIDGE_MEMORY_CONTROLLER/STB_I
add wave -noupdate -group CARTRIDGE_MEMORY_CONTROLLER /gameboy_tb/CARTRIDGE_INST/CARTRIDGE_MEMORY_CONTROLLER/CYC_I
add wave -noupdate -group CARTRIDGE_MEMORY_CONTROLLER /gameboy_tb/CARTRIDGE_INST/CARTRIDGE_MEMORY_CONTROLLER/ACK_O
add wave -noupdate -group CARTRIDGE_MEMORY_CONTROLLER -radix hexadecimal /gameboy_tb/CARTRIDGE_INST/CARTRIDGE_MEMORY_CONTROLLER/ADR_I
add wave -noupdate -group CARTRIDGE_MEMORY_CONTROLLER -radix hexadecimal /gameboy_tb/CARTRIDGE_INST/CARTRIDGE_MEMORY_CONTROLLER/DAT_I
add wave -noupdate -group CARTRIDGE_MEMORY_CONTROLLER -radix hexadecimal /gameboy_tb/CARTRIDGE_INST/CARTRIDGE_MEMORY_CONTROLLER/DAT_O
add wave -noupdate -group CARTRIDGE_MEMORY_CONTROLLER -radix hexadecimal /gameboy_tb/CARTRIDGE_INST/CARTRIDGE_MEMORY_CONTROLLER/outgoing_data
add wave -noupdate -group CARTRIDGE_MEMORY_CONTROLLER /gameboy_tb/CARTRIDGE_INST/CARTRIDGE_MEMORY_CONTROLLER/rom_within_range
add wave -noupdate -group CARTRIDGE_MEMORY_CONTROLLER /gameboy_tb/CARTRIDGE_INST/CARTRIDGE_MEMORY_CONTROLLER/rom_selected
add wave -noupdate -group CARTRIDGE_MEMORY_CONTROLLER -radix hexadecimal /gameboy_tb/CARTRIDGE_INST/CARTRIDGE_MEMORY_CONTROLLER/rom_data
add wave -noupdate -group CARTRIDGE_MEMORY_CONTROLLER /gameboy_tb/CARTRIDGE_INST/CARTRIDGE_MEMORY_CONTROLLER/stb_delay
add wave -noupdate /gameboy_tb/CARTRIDGE_INST/GB_CLK
add wave -noupdate -radix hexadecimal /gameboy_tb/CARTRIDGE_INST/GB_ADDR
add wave -noupdate -radix hexadecimal /gameboy_tb/CARTRIDGE_INST/GB_DATA
add wave -noupdate /gameboy_tb/CARTRIDGE_INST/GB_WRN
add wave -noupdate /gameboy_tb/CARTRIDGE_INST/GB_RDN
add wave -noupdate /gameboy_tb/CARTRIDGE_INST/GB_CSN
add wave -noupdate /gameboy_tb/CARTRIDGE_INST/WB_CLK_I
add wave -noupdate /gameboy_tb/CARTRIDGE_INST/USER_RST
add wave -noupdate /gameboy_tb/CARTRIDGE_INST/gb_data_outgoing
add wave -noupdate /gameboy_tb/CARTRIDGE_INST/gb_data_incoming
add wave -noupdate /gameboy_tb/CARTRIDGE_INST/wb_adr_o
add wave -noupdate /gameboy_tb/CARTRIDGE_INST/wb_dat_o
add wave -noupdate /gameboy_tb/CARTRIDGE_INST/wb_dat_i
add wave -noupdate /gameboy_tb/CARTRIDGE_INST/rom_stb
add wave -noupdate /gameboy_tb/CARTRIDGE_INST/rom_ack
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2300000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 239
configure wave -valuecolwidth 105
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {2081286 ps} {3049326 ps}
