// =========================================================
//  Copyright (C): 2025 Elijah Almeida Coimbra
// =========================================================

interface gb_bus_io;
    logic clk;
    logic rdn;
    logic wrn;
    logic csn;
    logic [7:0] data;
    logic [15:0] addr;

    modport device (
        output clk,
        output rdn,
        output wrn,
        output csn,
        inout data,
        output addr
    );

    modport cart (
        input clk,
        input rdn,
        input wrn,
        input csn,
        inout data,
        input addr
    );
endinterface : gb_bus_io

interface wishbone_io #(
    parameter DATA_WIDTH=8,
    parameter ADDR_WIDTH=16
) (
    input clk,
    input rst
);

    logic cyc;
    logic we;
    logic ack;
    logic [DATA_WIDTH-1:0] mdata;
    logic [DATA_WIDTH-1:0] sdata;
    logic [ADDR_WIDTH-1:0] addr;

    modport master (
        output cyc, we, mdata, addr,
        input ack, sdata,
        import master_reset
    );

    modport slave (
        input cyc, we, mdata, addr,
        output ack, sdata,
        import slave_reset
    );

    task slave_reset;
        slave.ack <= 0;
    endtask

    task master_reset;
        master.cyc <= 0;
        master.we <= 0;
    endtask

    task master_initiate_write;
        master.cyc <= 1;
        master.we <= 1;
    endtask

    task master_initiate_read;
        master.cyc <= 1;
        master.we <= 0;
    endtask

endinterface : wishbone_io

module cdc_sync #(
    parameter STAGE_COUNT=2,
    parameter DATA_WIDTH=1,
    parameter logic RESET_VALUE=1'b0
) (
    input clk,
    input rst,
    input logic [DATA_WIDTH-1:0] i,
    output logic [DATA_WIDTH-1:0] o
);

    (* async_reg *)
    logic [STAGE_COUNT-1:0] shifter;

    always_ff @(posedge clk) begin
        if (rst == 1) begin
            shifter <= 0;
        end
        else begin
            shifter <= {shifter[STAGE_COUNT-2:0], i};
        end
    end

    assign o = shifter[STAGE_COUNT-1];

endmodule : cdc_sync

module gb_decoder #(
    parameter bit enable_timeout_detection=1'b0,
    parameter real clk_freq=100.0
) (
    input clk,
    input rst,
    gb_bus_io.cart gb_bus_if,
    wishbone_io wishbone_if,
    input dma_busy,
    input selected_mbc,
    output wr_timeout,
    output rd_timeout
);

    typedef enum {
        STATE_AWAIT_ACCESS_FINISHED,
        STATE_IDLE,
        STATE_READ_AWAIT_ACK,
        STATE_WRITE_AWAIT_FALLING_EDGE,
        STATE_WRITE_AWAIT_ACK
    } state_t;

    state_t state;

    logic [15:13] gb_addr_sync;
    logic gb_clk_sync;
    logic gb_csn_sync;

    cdc_sync #(
    .DATA_WIDTH($size(gb_addr_sync))
    ) cdc_sync_addr (
        .clk(clk),
        .rst(rst),
        .i(gb_bus_if.addr[15:13]),
        .o(gb_addr_sync)
    );

    cdc_sync #(
    .DATA_WIDTH(1)
    ) cdc_sync_clk (
        .clk(clk),
        .rst(rst),
        .i(gb_bus_if.clk),
        .o(gb_clk_sync)
    );

    cdc_sync #(
    .DATA_WIDTH(1)
    ) cdc_sync_csn (
        .clk(clk),
        .rst(rst),
        .i(gb_bus_if.csn),
        .o(gb_csn_sync)
    );

    logic gb_access_rom;
    logic gb_access_ram;
    // logic gb_access_dma;
    logic gb_access_cart;
    logic [7:0] gb_outgoing_data;

    assign gb_access_rom = !gb_addr_sync[15];
    assign gb_access_ram = !gb_csn_sync && gb_addr_sync == 3'b101;
    // assign gb_access_dma = gb_access_ram && gb_bus_if.addr[12:8] == 5'b00101;
    assign gb_access_cart = gb_access_rom || gb_access_ram;
    assign gb_bus_if.data = gb_access_cart && !gb_bus_if.rdn ? gb_outgoing_data : 'z;

    always_ff @(posedge clk) begin
        if (rst == 1) begin
            state <= STATE_AWAIT_ACCESS_FINISHED;
            wishbone_if.master_reset();
        end
        else begin
            case (state)
                STATE_AWAIT_ACCESS_FINISHED:
                if (!gb_access_cart)
                    state <= STATE_IDLE;

                STATE_IDLE:
                if (gb_access_cart) begin
                    if (!gb_bus_if.rdn) begin
                        state <= STATE_READ_AWAIT_ACK;
                        wishbone_if.master_initiate_read();
                    end else begin
                        state <= STATE_WRITE_AWAIT_FALLING_EDGE;
                    end

                    wishbone_if.addr <= gb_bus_if.addr;
                end

                STATE_READ_AWAIT_ACK:
                if (wishbone_if.ack) begin
                    state <= STATE_AWAIT_ACCESS_FINISHED;
                    wishbone_if.master_reset();
                    gb_outgoing_data <= wishbone_if.sdata;
                end

                STATE_WRITE_AWAIT_FALLING_EDGE:
                if (!gb_clk_sync) begin
                    state <= STATE_WRITE_AWAIT_ACK;
                    wishbone_if.mdata <= gb_bus_if.data;
                    wishbone_if.master_initiate_write();
                end

                STATE_WRITE_AWAIT_ACK:
                if (wishbone_if.ack) begin
                    state <= STATE_AWAIT_ACCESS_FINISHED;
                    wishbone_if.master_reset();
                end
            endcase
        end
    end

endmodule
