import vertexinput_reg_desc_pkg::*;

module vertexinput_reg_generation #(
    parameter ADDR_WIDTH=32,
    parameter DATA_WIDTH=32,
    parameter NUMBER_REGISTERS=10
)
(
    input clk,
    input rst,
    input  logic        mem_w_req,
    input  logic [DATA_WIDTH-1:0] mem_w_data,
    input  logic [ADDR_WIDTH-1:0] mem_w_addr,
    output logic        mem_w_ack,

    input  logic        mem_r_req,
    input  logic [ADDR_WIDTH-1:0] mem_r_addr,
    output logic [DATA_WIDTH-1:0] mem_r_data,
    output logic        mem_r_ack,

    vertexinput_reg_if.mem_side reg_ifs_m[NUMBER_REGISTERS]
    
);
    logic [DATA_WIDTH-1:0] mem_r_data_from_regslice [NUMBER_REGISTERS-1:0];
        
    always@(posedge clk)
    begin
        if(rst)
        begin
            mem_w_ack <= 'b0;
            mem_r_ack <= 'b0;
        end

        else
        begin
            mem_w_ack <= mem_w_req & ~mem_w_ack;
            
            mem_r_ack <= mem_r_req & ~mem_r_ack;
        end
    end

    for (genvar i = 0; i < NUMBER_REGISTERS; ++i) begin : g_cfg

        localparam vertexinput_reg_desc_t D = get_desc(i);

        vertexinput_reg_slice #(
            .DATA_WIDTH(DATA_WIDTH),
            .RW_MASK    (D.rw_mask),
            .W1C_MASK   (D.w1c_mask),
            .WO_MASK    (D.wo_mask),
            .RC_MASK    (D.rc_mask),
            .RO_MASK    (D.ro_mask),
            .PULSE_MASK (D.pulse_mask)
        ) u_slice 
        (
            .clk(clk),
            .rst(rst),

            //mem_w/r_req && (mem_w_addr[ADDR_WIDTH-1:2] == i)
                // ignoring the bottom two bits because each register is 4 bytes

            .mem_w_req(mem_w_req && (mem_w_addr == D.address)),
            .mem_w_data(mem_w_data),

            // $clog2(DATA_WIDTH / 8) 
                // 4 bytes per word in 32 bit data,
                // first 2 bits signify 4 bytes -> 'b00 byte 1, 'b01 byte 2, 'b10 byte 3, 'b11 byte 4 -> so... 'b100 is the second address
            // -> clog2 calculates the minimum number of bits needed to represent a value...

            .mem_r_req(mem_r_req && (mem_r_addr == D.address)),
            .mem_r_data_local(mem_r_data_from_regslice[i]),

            .logic_mem_connect(reg_ifs_m[i])
        );
    end
    
    logic [NUMBER_REGISTERS-1:0] mem_r_data_select_onehot;

    always_comb begin
        for (int i = 0; i < NUMBER_REGISTERS; i++) begin
            mem_r_data_select_onehot[i] = (mem_r_addr == get_desc(i).address);
        end
        
        mem_r_data = '0;
        
        if(|mem_r_data_select_onehot)
        begin
            for (int i = 0; i < NUMBER_REGISTERS; i++) begin
                if (mem_r_data_select_onehot[i]) begin
                    mem_r_data = mem_r_data_from_regslice[i];
                end
            end
        end
        
        else
        begin
            mem_r_data = 'hBAD_CAFE;
        end
    end
endmodule
