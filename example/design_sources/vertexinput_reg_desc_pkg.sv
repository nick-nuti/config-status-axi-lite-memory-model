`include "vertexinput_defines.vh"

`ifndef vertexinput_REG_DESC_PKG
`define vertexinput_REG_DESC_PKG

	package vertexinput_reg_desc_pkg;

		typedef struct packed
		{
			logic [`DATA_W-1:0] rw_mask;
			logic [`DATA_W-1:0] w1c_mask;
			logic [`DATA_W-1:0] wo_mask;
			logic [`DATA_W-1:0] rc_mask;
			logic [`DATA_W-1:0] ro_mask;
			logic [`DATA_W-1:0] pulse_mask;
			logic [`ADDR_W-1:0] address;
		} vertexinput_reg_desc_t;

		localparam vertexinput_reg_desc_t REG_DESC_0 = '{
			rw_mask     : 32'h7FFFFFC,
			w1c_mask    : 32'h0,
			wo_mask     : 32'h3,
			rc_mask     : 32'hC0000000,
			ro_mask     : 32'h30000000,
			pulse_mask  : 32'h8000000,
			address     : 32'h0
		};

		localparam vertexinput_reg_desc_t REG_DESC_1 = '{
			rw_mask     : 32'hF,
			w1c_mask    : 32'h3FE0000,
			wo_mask     : 32'hF0,
			rc_mask     : 32'hF000,
			ro_mask     : 32'hF00,
			pulse_mask  : 32'h80010000,
			address     : 32'h8
		};


		function automatic vertexinput_reg_desc_t get_desc(input logic [`ADDR_W-1:0] index);
		case (index)
			0: return REG_DESC_0;
			1: return REG_DESC_1;
			default: return '0;
		endcase
		endfunction

	endpackage

`endif
