`include "vertexinput_defines.vh"

module vertexinput_top
(
	output logic [1:0] REG_DESC_0_config0_wo,
	output logic [24:0] REG_DESC_0_config1_rw,
	output logic [0:0] REG_DESC_0_startpulse_pulse,
	input logic [1:0] REG_DESC_0_status_ro,
	input logic [1:0] REG_DESC_0_interruptflag_rc_in,
	output logic [1:0] REG_DESC_0_interruptflag_rc_clr,

	output logic [3:0] REG_DESC_1_config_rw,
	output logic [3:0] REG_DESC_1_logicset_wo,
	input logic [3:0] REG_DESC_1_readystatus_ro,
	input logic [3:0] REG_DESC_1_interruptflag_rc_in,
	output logic [3:0] REG_DESC_1_interruptflag_rc_clr,
	output logic [0:0] REG_DESC_1_startpipe1_pulse,
	input logic [8:0] REG_DESC_1_stickybit_w1c_in,
	output logic [8:0] REG_DESC_1_stickybit_w1c_clr,
	output logic [0:0] REG_DESC_1_startpipe2_pulse,


    /**************** Write Address Channel Signals ****************/
    input wire [`ADDR_W-1:0]              s_axi_awaddr,
    input wire                            s_axi_awvalid,
    output wire                           s_axi_awready,
    /**************** Write Data Channel Signals ****************/
    input wire [`DATA_W-1:0]              s_axi_wdata,
    input wire [`DATA_W_BYTES-1:0]        s_axi_wstrb,
    input wire                            s_axi_wvalid,
    output wire                           s_axi_wready, 
    /**************** Write Response Channel Signals ****************/
    output wire [2-1:0]                   s_axi_bresp,
    output wire                           s_axi_bvalid,
    input wire                            s_axi_bready,
    /**************** Read Address Channel Signals ****************/
    input wire [`ADDR_W-1:0]               s_axi_araddr,
    input wire                            s_axi_arvalid,
    output wire                           s_axi_arready,
    /**************** Read Data Channel Signals ****************/
    input wire                            s_axi_rready,
    output wire [`DATA_W-1:0]              s_axi_rdata,
    output wire                           s_axi_rvalid,
    /**************** Read Response Channel Signals ****************/
    output wire [2-1:0]                   s_axi_rresp,
    /**************** System Signals ****************/
    input wire                            aclk,
    input wire                            aresetn
);

    vertexinput_reg_if reg_bus[`NUMBER_REGISTERS]();

     
    wire mem_w_req;
    reg  mem_w_ack;
    wire mem_r_req;
    reg  mem_r_ack;
    wire [`ADDR_W-1:0] mem_w_addr;
    wire [`DATA_W-1:0] mem_w_data;
    wire [`DATA_W_BYTES-1:0] mem_w_strb;
    wire [`ADDR_W-1:0] mem_r_addr;
    wire [`DATA_W-1:0] mem_r_data;
    
    axilite_slave #(
        .ADDR_W(`ADDR_W),
        .DATA_W(`DATA_W)
    )
    as0
    (
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rready(s_axi_rready),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rresp(s_axi_rresp),
        .aclk(aclk),
        .aresetn(aresetn),
        .mem_w_req(mem_w_req),
        .mem_w_ack(mem_w_ack),
        .mem_r_req(mem_r_req),
        .mem_r_ack(mem_r_ack),
        .mem_w_addr(mem_w_addr),
        .mem_w_data(mem_w_data),
        .mem_w_strb(mem_w_strb),
        .mem_r_addr(mem_r_addr),
        .mem_r_data(mem_r_data)
    );

    vertexinput_reg_generation #(
        .ADDR_WIDTH(`ADDR_W),
        .DATA_WIDTH(`DATA_W),
        .NUMBER_REGISTERS(`NUMBER_REGISTERS)
    ) rg0
    (
        .clk(aclk),
        .rst(~aresetn),
        .mem_w_req(mem_w_req),
        .mem_w_data(mem_w_data),
        .mem_w_addr(mem_w_addr),
        .mem_w_ack(mem_w_ack),

        .mem_r_req(mem_r_req),
        .mem_r_addr(mem_r_addr),
        .mem_r_data(mem_r_data),
        .mem_r_ack(mem_r_ack),

        .reg_ifs_m(reg_bus)
    );

    vertexinput_reg_adapter #(
        .NUMBER_REGISTERS(`NUMBER_REGISTERS)
    ) u_reg_adapter (

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

        .reg_ifs_l(reg_bus)
    );
endmodule
