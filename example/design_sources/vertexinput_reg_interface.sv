`include "vertexinput_defines.vh"

`ifndef vertexinput_REG_INTERFACE
`define vertexinput_REG_INTERFACE

	interface vertexinput_reg_if;

		logic [`DATA_W-1:0] data_logic2mem;
		logic [`DATA_W-1:0] data_mem2logic;

		modport mem_side (
			input  data_logic2mem,
			output data_mem2logic
		);

		modport logic_side (
			output data_logic2mem,
			input  data_mem2logic
		);

	endinterface

`endif
