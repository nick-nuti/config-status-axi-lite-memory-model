`timescale 1ns / 1ps

`include "vertexinput_defines.vh"

module testbench_top();
    
    // testbench signals
    reg aclk;
    reg aresetn;
    
    // AXI LITE MASTER signals
    reg user_start;
    reg user_w_r;
    reg [`DATA_W_BYTES-1:0] user_data_strb;
    reg [`DATA_W-1:0] user_data_in;
    reg [`ADDR_W-1:0] user_addr_in;
    wire user_free;
    wire [1:0] user_status;
    reg [`DATA_W-1:0] user_data_out;
    reg user_data_out_valid;
    reg user_w_r_out;
    reg [`ADDR_W-1:0] user_addr_out;
    
    // Logic signals that go to/come from memory
	logic [1:0] REG_DESC_0_config0_wo; // output from vertexinput_top, mem -> logic
	logic [24:0] REG_DESC_0_config1_rw; // output from vertexinput_top, mem -> logic
	logic [0:0] REG_DESC_0_startpulse_pulse; // output from vertexinput_top, mem -> logic
	logic [1:0] REG_DESC_0_status_ro; // input to vertexinput_top, logic -> mem
	logic [1:0] REG_DESC_0_interruptflag_rc_in; // input to vertexinput_top, logic -> mem
	logic [1:0] REG_DESC_0_interruptflag_rc_clr; // output from vertexinput_top, mem -> logic

	logic [3:0] REG_DESC_1_config_rw; // output from vertexinput_top, mem -> logic
	logic [3:0] REG_DESC_1_logicset_wo; // output from vertexinput_top, mem -> logic
	logic [3:0] REG_DESC_1_readystatus_ro; // input to vertexinput_top, logic -> mem
	logic [3:0] REG_DESC_1_interruptflag_rc_in; // input to vertexinput_top, logic -> mem
	logic [3:0] REG_DESC_1_interruptflag_rc_clr; // output from vertexinput_top, mem -> logic
	logic [0:0] REG_DESC_1_startpipe1_pulse; // output from vertexinput_top, mem -> logic
	logic [8:0] REG_DESC_1_stickybit_w1c_in; // input to vertexinput_top, logic -> mem
	logic [8:0] REG_DESC_1_stickybit_w1c_clr; // output from vertexinput_top, mem -> logic
	logic [0:0] REG_DESC_1_startpipe2_pulse; // output from vertexinput_top, mem -> logic


    initial
    begin
        aclk = 0;
        aresetn = 0;
        
        user_start = 'h0;
        user_w_r = 'h0;
        user_data_strb = 'h0;
        user_data_in = 'h0;
        user_addr_in = 'h0;
        
        user_start = 1'd0;
    end
    
    always
    begin
        #8ns aclk = ~aclk;
    end
    
    initial
    begin
        wait(aclk);
        @(posedge aclk);
        aresetn = 1;
        #5us;
        
        //...Stimulus here...
        
        $finish;
    end
 
    // axi lite master <-> axi lite slave signals
    wire [`ADDR_W-1:0] m_axi_awaddr;
    wire m_axi_awvalid;
    wire m_axi_awready;
    
    wire [`DATA_W-1:0] m_axi_wdata;
    wire [`DATA_W/8-1:0] m_axi_wstrb;
    wire m_axi_wvalid; 
    wire m_axi_wready;
    
    wire [2-1:0] m_axi_bresp;
    wire m_axi_bvalid;
    wire m_axi_bready;
    
    wire [`ADDR_W-1:0] m_axi_araddr;
    wire m_axi_arvalid;
    wire m_axi_arready;
    
    wire m_axi_rready;
    wire [`DATA_W-1:0] m_axi_rdata;
    wire m_axi_rvalid;
    
    wire [2-1:0] m_axi_rresp;

    axilite_master #(.ADDR_W(`ADDR_W), .DATA_W(`DATA_W)) am0
    (
        .m_axi_awaddr(m_axi_awaddr),
        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_awready(m_axi_awready),
        
        .m_axi_wdata(m_axi_wdata),
        .m_axi_wstrb(m_axi_wstrb),
        .m_axi_wvalid(m_axi_wvalid), 
        .m_axi_wready(m_axi_wready), 
        
        .m_axi_bresp(m_axi_bresp),
        .m_axi_bvalid(m_axi_bvalid),
        .m_axi_bready(m_axi_bready),
        
        .m_axi_araddr(m_axi_araddr),
        .m_axi_arvalid(m_axi_arvalid),
        .m_axi_arready(m_axi_arready),
        
        .m_axi_rready(m_axi_rready),
        .m_axi_rdata(m_axi_rdata),
        .m_axi_rvalid(m_axi_rvalid),
        
        .m_axi_rresp(m_axi_rresp),
        
        .aclk(aclk),
        .aresetn(aresetn),
        .user_start(user_start),
        .user_w_r(user_w_r),
        .user_data_strb(user_data_strb),
        .user_data_in(user_data_in),
        .user_addr_in(user_addr_in),
        .user_free(user_free),
        .user_status(user_status),
        .user_data_out(user_data_out),
        .user_data_out_valid(user_data_out_valid),
        .user_w_r_out(user_w_r_out),
        .user_addr_out(user_addr_out)
    );
    
    vertexinput_top t0
    (
        // reg adapter signals
		.REG_DESC_0_config0_wo(REG_DESC_0_config0_wo),
		.REG_DESC_0_config1_rw(REG_DESC_0_config1_rw),
		.REG_DESC_0_startpulse_pulse(REG_DESC_0_startpulse_pulse),
		.REG_DESC_0_status_ro(REG_DESC_0_status_ro),
		.REG_DESC_0_interruptflag_rc_in(REG_DESC_0_interruptflag_rc_in),
		.REG_DESC_0_interruptflag_rc_clr(REG_DESC_0_interruptflag_rc_clr),
		.REG_DESC_1_config_rw(REG_DESC_1_config_rw),
		.REG_DESC_1_logicset_wo(REG_DESC_1_logicset_wo),
		.REG_DESC_1_readystatus_ro(REG_DESC_1_readystatus_ro),
		.REG_DESC_1_interruptflag_rc_in(REG_DESC_1_interruptflag_rc_in),
		.REG_DESC_1_interruptflag_rc_clr(REG_DESC_1_interruptflag_rc_clr),
		.REG_DESC_1_startpipe1_pulse(REG_DESC_1_startpipe1_pulse),
		.REG_DESC_1_stickybit_w1c_in(REG_DESC_1_stickybit_w1c_in),
		.REG_DESC_1_stickybit_w1c_clr(REG_DESC_1_stickybit_w1c_clr),
		.REG_DESC_1_startpipe2_pulse(REG_DESC_1_startpipe2_pulse),

        // AXI LITE SLAVE signals
        .s_axi_awaddr(m_axi_awaddr),
        .s_axi_awvalid(m_axi_awvalid),
        .s_axi_awready(m_axi_awready),
        .s_axi_wdata(m_axi_wdata),
        .s_axi_wstrb(m_axi_wstrb),
        .s_axi_wvalid(m_axi_wvalid),
        .s_axi_wready(m_axi_wready),
        .s_axi_bresp(m_axi_bresp),
        .s_axi_bvalid(m_axi_bvalid),
        .s_axi_bready(m_axi_bready),
        .s_axi_araddr(m_axi_araddr),
        .s_axi_arvalid(m_axi_arvalid),
        .s_axi_arready(m_axi_arready),
        .s_axi_rready(m_axi_rready),
        .s_axi_rdata(m_axi_rdata),
        .s_axi_rvalid(m_axi_rvalid),
        .s_axi_rresp(m_axi_rresp),
        .aclk(aclk),
        .aresetn(aresetn)
    );
    
endmodule
    
