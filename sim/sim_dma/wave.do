onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /dma_controller_tb/DMA_CONTROLLER/CLK_I
add wave -noupdate /dma_controller_tb/DMA_CONTROLLER/RST_I
add wave -noupdate /dma_controller_tb/DMA_CONTROLLER/DMA_CYC_O
add wave -noupdate /dma_controller_tb/DMA_CONTROLLER/DMA_ACK_I
add wave -noupdate /dma_controller_tb/DMA_CONTROLLER/DMA_WE_O
add wave -noupdate -radix hexadecimal -childformat {{/dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(15) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(14) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(13) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(12) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(11) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(10) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(9) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(8) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(7) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(6) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(5) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(4) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(3) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(2) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(1) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(0) -radix hexadecimal}} -subitemconfig {/dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(15) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(14) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(13) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(12) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(11) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(10) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(9) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(8) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(7) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(6) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(5) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(4) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(3) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(2) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(1) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O(0) {-height 15 -radix hexadecimal}} /dma_controller_tb/DMA_CONTROLLER/DMA_ADR_O
add wave -noupdate -radix hexadecimal /dma_controller_tb/DMA_CONTROLLER/DMA_DAT_O
add wave -noupdate -radix hexadecimal /dma_controller_tb/DMA_CONTROLLER/DMA_DAT_I
add wave -noupdate /dma_controller_tb/DMA_CONTROLLER/CFG_CYC_I
add wave -noupdate /dma_controller_tb/DMA_CONTROLLER/CFG_ACK_O
add wave -noupdate /dma_controller_tb/DMA_CONTROLLER/CFG_WE_I
add wave -noupdate -radix hexadecimal /dma_controller_tb/DMA_CONTROLLER/CFG_ADR_I
add wave -noupdate -radix hexadecimal /dma_controller_tb/DMA_CONTROLLER/CFG_DAT_O
add wave -noupdate -radix hexadecimal /dma_controller_tb/DMA_CONTROLLER/CFG_DAT_I
add wave -noupdate /dma_controller_tb/DMA_CONTROLLER/dma_current_state
add wave -noupdate /dma_controller_tb/DMA_CONTROLLER/dma_addr_src_inc
add wave -noupdate /dma_controller_tb/DMA_CONTROLLER/dma_addr_dest_inc
add wave -noupdate -radix unsigned /dma_controller_tb/DMA_CONTROLLER/dma_copy_amount
add wave -noupdate /dma_controller_tb/DMA_CONTROLLER/dma_amount_is_zero
add wave -noupdate /dma_controller_tb/DMA_CONTROLLER/dma_start
add wave -noupdate /dma_controller_tb/DMA_CONTROLLER/dma_is_busy
add wave -noupdate /dma_controller_tb/DMA_CONTROLLER/master_addr_sel
add wave -noupdate -radix hexadecimal -childformat {{/dma_controller_tb/DMA_CONTROLLER/master_addr_src(15) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/master_addr_src(14) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/master_addr_src(13) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/master_addr_src(12) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/master_addr_src(11) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/master_addr_src(10) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/master_addr_src(9) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/master_addr_src(8) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/master_addr_src(7) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/master_addr_src(6) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/master_addr_src(5) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/master_addr_src(4) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/master_addr_src(3) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/master_addr_src(2) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/master_addr_src(1) -radix hexadecimal} {/dma_controller_tb/DMA_CONTROLLER/master_addr_src(0) -radix hexadecimal}} -subitemconfig {/dma_controller_tb/DMA_CONTROLLER/master_addr_src(15) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/master_addr_src(14) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/master_addr_src(13) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/master_addr_src(12) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/master_addr_src(11) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/master_addr_src(10) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/master_addr_src(9) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/master_addr_src(8) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/master_addr_src(7) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/master_addr_src(6) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/master_addr_src(5) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/master_addr_src(4) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/master_addr_src(3) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/master_addr_src(2) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/master_addr_src(1) {-height 15 -radix hexadecimal} /dma_controller_tb/DMA_CONTROLLER/master_addr_src(0) {-height 15 -radix hexadecimal}} /dma_controller_tb/DMA_CONTROLLER/master_addr_src
add wave -noupdate -radix hexadecimal /dma_controller_tb/DMA_CONTROLLER/master_addr_dest
add wave -noupdate -radix hexadecimal /dma_controller_tb/DMA_CONTROLLER/master_data
add wave -noupdate -radix hexadecimal /dma_controller_tb/DMA_CONTROLLER/slave_data
add wave -noupdate /dma_controller_tb/DMA_CONTROLLER/slave_ack
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1060000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
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
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {2310 ns}
