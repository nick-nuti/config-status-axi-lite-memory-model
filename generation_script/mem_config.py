import json
import argparse
import os
import sys

def generate_defines(data, outdir_path):
    module_name = data["module_name"]
    data_width = data["data_width"]
    number_registers = len(data["registers"])

    defines_string = f"""\
{0*'\t'}`ifndef {module_name}_DEFINES
{0*'\t'}`define {module_name}_DEFINES

{0*'\t'}`define ADDR_W {data["address_width"]}
{0*'\t'}`define DATA_W {data["data_width"]}
{0*'\t'}`define BYTE 8
{0*'\t'}`define DATA_W_BYTES `DATA_W/`BYTE
{0*'\t'}`define NUMBER_REGISTERS {number_registers}

{0*'\t'}`endif
"""
    file2create_abs = os.path.join(outdir_path, f"{module_name}_defines.vh")

    with open(file2create_abs, 'w') as f:
        f.write(defines_string)

    print(f"Generated: {file2create_abs}")


def generate_register_interface(data, outdir_path):
    module_name = data["module_name"]
    data_width = data["data_width"]
    number_registers = len(data["registers"])

    register_interface_string = f"""\
{0*'\t'}`include "{module_name}_defines.vh"

{0*'\t'}`ifndef {module_name}_REG_INTERFACE
{0*'\t'}`define {module_name}_REG_INTERFACE

{1*'\t'}interface {module_name}_reg_if;

{2*'\t'}logic [`DATA_W-1:0] data_logic2mem;
{2*'\t'}logic [`DATA_W-1:0] data_mem2logic;

{2*'\t'}modport mem_side (
{3*'\t'}input  data_logic2mem,
{3*'\t'}output data_mem2logic
{2*'\t'});

{2*'\t'}modport logic_side (
{3*'\t'}output data_logic2mem,
{3*'\t'}input  data_mem2logic
{2*'\t'});

{1*'\t'}endinterface

{0*'\t'}`endif
"""
    file2create_abs = os.path.join(outdir_path, f"{module_name}_reg_interface.sv")

    with open(file2create_abs, 'w') as f:
        f.write(register_interface_string)

    print(f"Generated: {file2create_abs}")


def generate_register_generation(data, outdir_path):
    module_name = data["module_name"]
    data_width = data["data_width"]
    number_registers = len(data["registers"])

    register_generation_string = f"""\
import {module_name}_reg_desc_pkg::*;

module {module_name}_reg_generation #(
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

    {module_name}_reg_if.mem_side reg_ifs_m[NUMBER_REGISTERS]
    
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

        localparam {module_name}_reg_desc_t D = get_desc(i);

        {module_name}_reg_slice #(
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
"""
    file2create_abs = os.path.join(outdir_path, f"{module_name}_reg_generation.sv")

    with open(file2create_abs, 'w') as f:
        f.write(register_generation_string)

    print(f"Generated: {file2create_abs}")


def generate_register_slice(data, outdir_path):
    module_name = data["module_name"]
    data_width = data["data_width"]
    number_registers = len(data["registers"])

    register_slice_string = f"""\
module {module_name}_reg_slice #(
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

    {module_name}_reg_if.mem_side logic_mem_connect
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
"""
    file2create_abs = os.path.join(outdir_path, f"{module_name}_reg_slice.sv")

    with open(file2create_abs, 'w') as f:
        f.write(register_slice_string)

    print(f"Generated: {file2create_abs}") 


def format_val(val, datawidth):

    if isinstance(val, str):
        prefixcheck = val.strip().lower()

        if prefixcheck.startswith("0x"):
            base = 16
            prefix = "'h"
        elif prefixcheck.startswith("0b"):
            base = 2
            prefix = "'b"
        elif prefixcheck.startswith("0o"):
            base = 8
            prefix = "'o"
        else:
            base = 10
            prefix = "'d"

        val = int(val, 0) # "0x" and "0b" works
    
    else:
        base = 10
        prefix = "'d"

    data_width_mask = (1 << datawidth) - 1

    val_out = val & data_width_mask

    if base == 16:
        val_str = f"{val_out:X}"
    elif base == 2:
        val_str = f"{val_out:b}"
    elif base == 8:
        val_str = f"{val_out:o}"
    else:
        val_str = str(val_out)

    return f"{datawidth}{prefix}{val_str}"

def generate_reg_desc_package(data, outdir_path):
    module_name = data["module_name"]
    data_width = data["data_width"]
    registers = data["registers"]
    number_registers = len(registers)

    reg_desc_pkg_template = f"""\
{0*'\t'}`include "{module_name}_defines.vh"

{0*'\t'}`ifndef {module_name}_REG_DESC_PKG
{0*'\t'}`define {module_name}_REG_DESC_PKG

{1*'\t'}package {module_name}_reg_desc_pkg;

{2*'\t'}typedef struct packed
{2*'\t'}{{
{3*'\t'}logic [`DATA_W-1:0] rw_mask;
{3*'\t'}logic [`DATA_W-1:0] w1c_mask;
{3*'\t'}logic [`DATA_W-1:0] wo_mask;
{3*'\t'}logic [`DATA_W-1:0] rc_mask;
{3*'\t'}logic [`DATA_W-1:0] ro_mask;
{3*'\t'}logic [`DATA_W-1:0] pulse_mask;
{3*'\t'}logic [`ADDR_W-1:0] address;
{2*'\t'}}} {module_name}_reg_desc_t;

{0*'\t'}***struct_param_list***

{2*'\t'}function automatic {module_name}_reg_desc_t get_desc(input logic [`ADDR_W-1:0] index);
{2*'\t'}case (index)
{0*'\t'}***read_case_list***
{3*'\t'}default: return '0;
{2*'\t'}endcase
{2*'\t'}endfunction

{1*'\t'}endpackage

{0*'\t'}`endif
"""

    struct_param_list = []

    for reg in registers:

        struct_param = f"""\
{2*'\t'}localparam {module_name}_reg_desc_t {reg['name'].upper()} = '{{
{3*'\t'}rw_mask     : {format_val(reg['rw_mask'], data_width)},
{3*'\t'}w1c_mask    : {format_val(reg['w1c_mask'], data_width)},
{3*'\t'}wo_mask     : {format_val(reg['wo_mask'], data_width)},
{3*'\t'}rc_mask     : {format_val(reg['rc_mask'], data_width)},
{3*'\t'}ro_mask     : {format_val(reg['ro_mask'], data_width)},
{3*'\t'}pulse_mask  : {format_val(reg['pulse_mask'], data_width)},
{3*'\t'}address     : {format_val(reg['address'], data_width)}
{2*'\t'}}};
"""

        struct_param_list.append(struct_param)

    read_case_list = []

    for idx, reg in enumerate(registers):

        read_case = f"{3*'\t'}{idx}: return {reg['name'].upper()};"""

        read_case_list.append(read_case)

    reg_desc_pkg_template_final = reg_desc_pkg_template.replace("***struct_param_list***", "\n".join(struct_param_list))
    reg_desc_pkg_template_final = reg_desc_pkg_template_final.replace("***read_case_list***", "\n".join(read_case_list))

    
    file2create_abs = os.path.join(outdir_path, f"{module_name}_reg_desc_pkg.sv")

    with open(file2create_abs, 'w') as f:
        f.write(reg_desc_pkg_template_final)

    print(f"Generated: {file2create_abs}")


def append_signal_info(reg_dict):
    # check the masks and figure out port type
    # append port direction
    
    rw = int(reg_dict["rw_mask"], 0)
    w1c = int(reg_dict["w1c_mask"], 0)
    wo = int(reg_dict["wo_mask"], 0)
    rc = int(reg_dict["rc_mask"], 0)
    ro = int(reg_dict["ro_mask"], 0)
    pulse = int(reg_dict["pulse_mask"], 0)

    newlist = []

    for signal in reg_dict["signal_list"]:
        signal_mask = 0
        for i in range(signal["low_bit"], signal["high_bit"]+1):
            signal_mask |= (1 << i)

        if signal_mask & rw:
            signal["type"] = "rw"
            signal["direction"] = "output"
            newlist.append(signal)
        elif signal_mask & w1c:
            newsignal = signal.copy()
            signal["type"] = "w1c_in"
            signal["direction"] = "input"
            
            newlist.append(signal)

            newsignal["type"] = "w1c_clr"
            newsignal["direction"] = "output"

            newlist.append(newsignal)
        elif signal_mask & wo:
            signal["type"] = "wo"
            signal["direction"] = "output"
            newlist.append(signal)
        elif signal_mask & rc:
            newsignal = signal.copy()
            signal["type"] = "rc_in"
            signal["direction"] = "input"
            
            newlist.append(signal)

            newsignal["type"] = "rc_clr"
            newsignal["direction"] = "output"
            
            newlist.append(newsignal)
        elif signal_mask & ro:
            signal["type"] = "ro"
            signal["direction"] = "input"
            newlist.append(signal)
        elif signal_mask & pulse:
            signal["type"] = "pulse"
            signal["direction"] = "output"
            newlist.append(signal)
        else:
            print(f"ERROR: Could not match signal '{signal["name"]}' from register '{reg_dict["name"]}' with a mask.\n Exiting...\n")
            sys.exit()
    return newlist
    

def generate_register_adapter(data, outdir_path):
    
    module_name = data["module_name"]
    data_width = data["data_width"]
    address_width = data["address_width"]
    registers = data["registers"]
    number_registers = len(registers)

    reg_adapter_template = f"""\
{0*'\t'}module {module_name}_reg_adapter #(
{1*'\t'}parameter NUMBER_REGISTERS={number_registers}
{0*'\t'})
{0*'\t'}(
{1*'\t'}// ports to/from logic
{0*'\t'}***port_list***
{1*'\t'}// interface to/from memory
{1*'\t'}{module_name}_reg_if.logic_side reg_ifs_l[NUMBER_REGISTERS]
{0*'\t'});

{0*'\t'}***assign_list***

{0*'\t'}endmodule
"""

    port_list=[]
    instance_list=[]

    for reg in registers:
        reg["signal_list"] = append_signal_info(reg)
        #print(f"reg = {reg}")

        for signal in reg["signal_list"]:
            signal["portname"] =f"{reg["name"]}_{signal["name"]}_{signal["type"]}"
            port = f"{1*'\t'}{signal["direction"]} logic [{signal["high_bit"]-signal["low_bit"]}:0] {signal["portname"]},"
            port_list.append(port)

            instance = f"{2*'\t'}.{signal["portname"]}({signal["portname"]}),"
            instance_list.append(instance)

        port_list.append("")

    assign_list=[]

    for index, reg in enumerate(registers):
        for signal in reg["signal_list"]:
            if(signal["direction"] == "output"):
                assign = f"{1*'\t'}assign {signal["portname"]} = reg_ifs_l[{index}].data_mem2logic[{signal["high_bit"]}:{signal["low_bit"]}];"
            else:
                assign = f"{1*'\t'}assign reg_ifs_l[{index}].data_logic2mem[{signal["high_bit"]}:{signal["low_bit"]}] = {signal["portname"]};"
            assign_list.append(assign)
        assign_list.append("")

    reg_adapter_template_final = reg_adapter_template.replace("***port_list***", "\n".join(port_list))
    reg_adapter_template_final = reg_adapter_template_final.replace("***assign_list***", "\n".join(assign_list))
    
    file2create_abs = os.path.join(outdir_path, f"{module_name}_reg_adapter.sv")

    with open(file2create_abs, 'w') as f:
        f.write(reg_adapter_template_final)

    print(f"Generated: {file2create_abs}")

    return port_list, instance_list


def generate_top(data, outdir_path, port_list, instance_list):
    module_name = data["module_name"]
    data_width = data["data_width"]
    number_registers = len(data["registers"])

    top_string = f"""\
`include "{module_name}_defines.vh"

module {module_name}_top
(
***reg_adapter portlist***

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

    {module_name}_reg_if reg_bus[`NUMBER_REGISTERS]();

     
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

    {module_name}_reg_generation #(
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

    {module_name}_reg_adapter #(
        .NUMBER_REGISTERS(`NUMBER_REGISTERS)
    ) u_reg_adapter (

***reg_adapter instance port list***

        .reg_ifs_l(reg_bus)
    );
endmodule
"""
    top_string_final = top_string.replace("***reg_adapter portlist***", "\n".join(port_list))
    top_string_final = top_string_final.replace("***reg_adapter instance port list***", "\n".join(instance_list))

    file2create_abs = os.path.join(outdir_path, f"{module_name}_top.sv")

    with open(file2create_abs, 'w') as f:
        f.write(top_string_final)

    print(f"Generated: {file2create_abs}")

    return port_list, instance_list


def generate_testbench(data, outdir_path, port_list, instance_list):
    module_name = data["module_name"]
    data_width = data["data_width"]
    number_registers = len(data["registers"])

    testbench_string = f"""\
`timescale 1ns / 1ps

`include "{module_name}_defines.vh"

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
***reg_adapter portlist***

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
    
    {module_name}_top t0
    (
        // reg adapter signals
***reg_adapter instance port list***

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
    """

    for index, i in enumerate(port_list):
        if i.startswith("\toutput "):
            i = i.replace("\toutput ", "\t", 1)
            i = i.replace(",", ";")
            i += f" // output from {module_name}_top, mem -> logic"
            port_list[index] = i
        elif i.startswith("\tinput "):
            i = i.replace("\tinput ", "\t", 1)
            i = i.replace(",", ";")
            i += f" // input to {module_name}_top, logic -> mem"
            port_list[index] = i
        elif i.strip() == "":
            # need to skip when "" is seen
            continue
        else:
            print(f"ERROR: port type '{i}' is incompatible with this script. Ports should be input/output.\nExiting...")
            sys.exit()

    testbench_string_final = testbench_string.replace("***reg_adapter portlist***", "\n".join(port_list))
    testbench_string_final = testbench_string_final.replace("***reg_adapter instance port list***", "\n".join(instance_list))

    file2create_abs = os.path.join(outdir_path, f"{module_name}_testbench.sv")

    with open(file2create_abs, 'w') as f:
        f.write(testbench_string_final)

    print(f"Generated: {file2create_abs}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--in_json", required=True, type=str)
    parser.add_argument("-o", "--out_dir", default=".", type=str)

    args = parser.parse_args()
    abs_path_in = os.path.abspath(args.in_json)
    abs_path_out = os.path.abspath(args.out_dir)

    if not os.path.exists(abs_path_in):
        print(f"Path for --in_json arg: {abs_path_in} doesn't exist. Exiting...")
        sys.exit(1)

    with open(abs_path_in, 'r') as f:
        json_data = json.load(f)

    #create a function to analyze the json and make sure it's correct

    print(f"Creating output directory: {abs_path_out}")
    if not os.path.exists(abs_path_out):
        os.mkdir(abs_path_out)

    generate_defines(json_data, abs_path_out)
    generate_register_interface(json_data, abs_path_out)
    generate_register_generation(json_data, abs_path_out)
    generate_register_slice(json_data, abs_path_out)
    generate_reg_desc_package(json_data, abs_path_out)
    port_list, instance_list = generate_register_adapter(json_data, abs_path_out)
    generate_top(json_data, abs_path_out, port_list, instance_list)
    generate_testbench(json_data, abs_path_out, port_list, instance_list)



# MAIN ENTRY POINT
if __name__ == "__main__":
    main()
