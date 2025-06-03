module vertexinput_reg_adapter #(
	parameter NUMBER_REGISTERS=2
)
(
	// ports to/from logic
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

	// interface to/from memory
	vertexinput_reg_if.logic_side reg_ifs_l[NUMBER_REGISTERS]
);

	assign REG_DESC_0_config0_wo = reg_ifs_l[0].data_mem2logic[1:0];
	assign REG_DESC_0_config1_rw = reg_ifs_l[0].data_mem2logic[26:2];
	assign REG_DESC_0_startpulse_pulse = reg_ifs_l[0].data_mem2logic[27:27];
	assign reg_ifs_l[0].data_logic2mem[29:28] = REG_DESC_0_status_ro;
	assign reg_ifs_l[0].data_logic2mem[31:30] = REG_DESC_0_interruptflag_rc_in;
	assign REG_DESC_0_interruptflag_rc_clr = reg_ifs_l[0].data_mem2logic[31:30];

	assign REG_DESC_1_config_rw = reg_ifs_l[1].data_mem2logic[3:0];
	assign REG_DESC_1_logicset_wo = reg_ifs_l[1].data_mem2logic[7:4];
	assign reg_ifs_l[1].data_logic2mem[11:8] = REG_DESC_1_readystatus_ro;
	assign reg_ifs_l[1].data_logic2mem[15:12] = REG_DESC_1_interruptflag_rc_in;
	assign REG_DESC_1_interruptflag_rc_clr = reg_ifs_l[1].data_mem2logic[15:12];
	assign REG_DESC_1_startpipe1_pulse = reg_ifs_l[1].data_mem2logic[16:16];
	assign reg_ifs_l[1].data_logic2mem[25:17] = REG_DESC_1_stickybit_w1c_in;
	assign REG_DESC_1_stickybit_w1c_clr = reg_ifs_l[1].data_mem2logic[25:17];
	assign REG_DESC_1_startpipe2_pulse = reg_ifs_l[1].data_mem2logic[31:31];


endmodule
