module vertexinput_reg_slice #(
    parameter DATA_WIDTH=32,
    parameter RW_MASK,
    parameter W1C_MASK,
    parameter WO_MASK,
    parameter RC_MASK,
    parameter RO_MASK,
    parameter PULSE_MASK
)
(
    input  logic clk,
    input  logic rst,

    input  logic        mem_w_req,
    input  logic [DATA_WIDTH-1:0] mem_w_data,

    input  logic        mem_r_req,
    output logic [DATA_WIDTH-1:0] mem_r_data_local,

    vertexinput_reg_if.mem_side logic_mem_connect
);

    logic [DATA_WIDTH-1:0] cfg_r;      // flops
    logic [DATA_WIDTH-1:0] cfg_n;      // next-state
    
    logic pulse_clr;
    
    logic [DATA_WIDTH-1:0] rc_pending;
    logic [DATA_WIDTH-1:0] rc_pending_n;
    
    logic [DATA_WIDTH-1:0] w1c_pending;
    logic [DATA_WIDTH-1:0] w1c_pending_n;

    logic mem_r_req_dff;

    always_comb 
    begin
        cfg_n = cfg_r;

        if (mem_w_req) 
        begin
            cfg_n = (cfg_r & ~(RW_MASK | WO_MASK | PULSE_MASK | W1C_MASK)) 
            | (mem_w_data & (RW_MASK | WO_MASK | PULSE_MASK));
            
            w1c_pending_n = w1c_pending | (mem_w_data & W1C_MASK);
        end
        
        w1c_pending_n = w1c_pending_n & logic_mem_connect.data_logic2mem & W1C_MASK;

        // setting clear pulse if pulse bits found
        pulse_clr = |(cfg_r & PULSE_MASK);

        
        if(mem_r_req && ~mem_r_req_dff)
        begin
            rc_pending_n = rc_pending_n | (cfg_r & RC_MASK);
        end
        
        // clear acknowledged RC bits
        rc_pending_n = rc_pending_n & logic_mem_connect.data_logic2mem & RC_MASK;        
        
        //----------------------------------------------------------------------
        // LOGIC-SIDE updates for RO, RC, W1C bits
        //----------------------------------------------------------------------
        cfg_n = ( cfg_n                                        // current working word
            & ~RO_MASK & ~RC_MASK & ~W1C_MASK)                                        // clear RO field
            | (logic_mem_connect.data_logic2mem & RO_MASK)     // live RO value
            | (logic_mem_connect.data_logic2mem & RC_MASK & ~rc_pending_n)    // OR-merge RC
            | (logic_mem_connect.data_logic2mem & W1C_MASK & ~w1c_pending_n);

        //----------------------------------------------------------------------
        // CPU READ-CLEAR for RC bits
        //----------------------------------------------------------------------
        if (mem_r_req) 
        begin
            cfg_n = cfg_n & ~RC_MASK;
        end
    end

    always @(posedge clk) 
    begin
        if (rst) 
        begin
            cfg_r <= 'h0;
            mem_r_data_local <= 'h0;
            mem_r_req_dff <= 1'b0;
            rc_pending <= 'h0;
            w1c_pending <= 'h0;
        end 
        
        else 
        begin
            cfg_r <= (pulse_clr) ? (cfg_n & ~PULSE_MASK) : cfg_n;

            mem_r_req_dff <= mem_r_req;

            if (mem_r_req && ~mem_r_req_dff) 
            begin
                mem_r_data_local <= cfg_r & (RW_MASK | RC_MASK | RO_MASK | W1C_MASK);
            end
            
            rc_pending <= rc_pending_n;
            w1c_pending <= w1c_pending_n;
        end
    end

    assign logic_mem_connect.data_mem2logic = (cfg_r & ~RC_MASK & ~W1C_MASK) | (rc_pending & RC_MASK) | (w1c_pending & W1C_MASK);

endmodule
