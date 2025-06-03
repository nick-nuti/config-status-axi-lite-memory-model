`timescale 1ps/1ps

`include "vertexinput_defines.vh"
import vertexinput_reg_desc_pkg::*;

module testbench_top();
    
    // testbench signals
    reg aclk;
    reg aresetn;
    reg [`DATA_W-1:0] rcval2chk;
    
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
        rcval2chk = 0;
        
        user_start = 'h0;
        user_w_r = 'h0;
        user_data_strb = 'hF;
        user_data_in = 'h0;
        user_addr_in = 'h0;
        
        user_start = 1'd0;
        
        // Making sure logic-driven values aren't X
        REG_DESC_0_status_ro = 'h0;
        REG_DESC_0_interruptflag_rc_in = 'h0;
        
        REG_DESC_1_readystatus_ro = 'h0;
        REG_DESC_1_interruptflag_rc_in = 'h0;
        
        REG_DESC_1_stickybit_w1c_in = 'h0;
    end
    
    always
    begin
        #5ns aclk = ~aclk;
    end
    
    initial
    begin
        wait(aclk);
        @(posedge aclk);
        aresetn = 1;
        #5us;
        
        //...Stimulus here...
        
        // Giving Logic RO + RC some values (as if logic were writing to them
        REG_DESC_0_status_ro = 2'b10;
        REG_DESC_0_interruptflag_rc_in = 2'b11;
        
        REG_DESC_1_readystatus_ro = 4'hC;
        REG_DESC_1_interruptflag_rc_in = 4'hD;
        
        REG_DESC_1_stickybit_w1c_in = 'h3FE; // testing readability then writability of w1c bits (also if not written 1, checking if sticks
        
        
        // CPU write to REG_DESC_0
        wait(user_free);
        
        @(posedge aclk);
        
        user_w_r = 'h0;
        user_data_in = user_data_in | 'b11; // set REG_DESC_0_config0_wo
        user_data_in = user_data_in | 'h1BCDEFA << 2; // set REG_DESC_0_config1_rw
        user_data_in = user_data_in | 1'b1 << 27; // set REG_DESC_0_startpulse_pulse
        user_addr_in = REG_DESC_0.address;
        
        user_start = 1'd1;
        
        @(posedge aclk);
        
        user_start = 1'd0;
        
        wait(user_data_out_valid);
        
        $display("Register REG_DESC_0 written");
        $display("CPU WROTE: 'h%X", user_data_in);
        $display("VIEW FROM LOGIC POV: 'h%X\n", t0.reg_bus[0].data_mem2logic);
        $display("NOTE: remember 'REG_DESC_0_startpulse_pulse' or 'user_data_in[27] for address: 'h%X' is a pulse value and will only be high in memory for 1 clock cycle\n", REG_DESC_0.address);
        
        user_data_in = 'h0;
 
        @(posedge aclk);
        
// CPU write to REG_DESC_1
        
        @(posedge aclk);
        user_w_r = 'h0;
        user_data_in = user_data_in | 4'b1010; // set REG_DESC_1_config_rw
        user_data_in = user_data_in | 4'b1001 << 4; // set REG_DESC_1_logicset_wo
        user_data_in = user_data_in | 1'b1 << 16; // set REG_DESC_1_startpipe1_pulse
        user_data_in = user_data_in | 1'b1 << 31; // set REG_DESC_1_startpipe2_pulse
        user_addr_in = REG_DESC_1.address;
        
        user_start = 1'd1;
        
        @(posedge aclk);
        
        user_start = 1'd0;
        
        @(posedge user_data_out_valid);
        
        $display("Register REG_DESC_1 written");
        $display("CPU WROTE: 0x%X", user_data_in);
        $display("VIEW FROM LOGIC POV: 0x%X\n", t0.reg_bus[1].data_mem2logic);
        $display("NOTE: remember 'REG_DESC_1_startpipe2_pulse' or 'user_data_in[31] and 'REG_DESC_1_startpipe1_pulse' or 'user_data_in[16] for address: 'h%X' is a pulse value and will only be high in memory for 1 clock cycle\n", REG_DESC_1.address);
        
        user_data_in = 'h0;
        
        @(posedge aclk);
        
        //------------------------------------------
        
// CPU read from REG_DESC_0

        fork
        begin
                //@(posedge aclk);
                user_w_r = 'h1;
            
                user_addr_in        = REG_DESC_0.address;
                user_start          = 1'd1;
        
                @(posedge aclk);
                user_start          = 1'd0;
                @(posedge aclk);
        end
        
        begin
                @(posedge user_data_out_valid);
                
                $display("CPU READ register 'REG_DESC_0': 0x%X", user_data_out);
                $display("  CPU READ -> REG_DESC_0_config0_wo = 0x%X", user_data_out[1:0]);
                $display("  CPU READ -> REG_DESC_0_config1_rw = 0x%X", user_data_out[26:2]);
                $display("  CPU READ -> REG_DESC_0_startpulse_pulse = 0x%X", user_data_out[27:27]);
                $display("  CPU READ -> REG_DESC_0_status_ro = 0x%X", user_data_out[29:28]);
                $display("  CPU READ -> REG_DESC_0_interruptflag_rc_in = 0x%X\n", user_data_out[31:30]);
        end
        join
        
// CPU read from REG_DESC_1
        
        fork
        begin
                wait(user_free);
                @(posedge aclk);
                user_w_r = 'h1;
            
                user_addr_in        = REG_DESC_1.address;
                user_start          = 1'd1;
        
                @(posedge aclk);
                user_start          = 1'd0;
                @(posedge aclk);
        end
        
        begin
                @(posedge user_data_out_valid);
                
                $display("CPU READ register 'REG_DESC_1': 0x%X", user_data_out);
                $display("  CPU READ -> REG_DESC_1_config_rw = 0x%X", user_data_out[3:0]);
                $display("  CPU READ -> REG_DESC_1_logicset_wo = 0x%X", user_data_out[7:4]);
                $display("  CPU READ -> REG_DESC_1_readystatus_ro = 0x%X", user_data_out[11:8]);
                $display("  CPU READ -> REG_DESC_1_interruptflag_rc_in = 0x%X", user_data_out[15:12]);
                $display("  CPU READ -> REG_DESC_1_startpipe1_pulse = 0x%X", user_data_out[16:16]);
                $display("  CPU READ -> REG_DESC_1_stickybit_w1c_in = 0x%X", user_data_out[25:17]);
                $display("  CPU READ -> REG_DESC_1_startpipe2_pulse = 0x%X\n", user_data_out[31:31]);
        end
        join
        
        #1000us;
        
        //$display("FINAL VALUE FOR 'REG_DESC_0' : mem2logic='h%X logic2mem='h%X", t0.reg_bus[0].data_mem2logic, t0.reg_bus[0].data_logic2mem);
        //$display("FINAL VALUE FOR 'REG_DESC_1' : mem2logic='h%X logic2mem='h%X", t0.reg_bus[1].data_mem2logic, t0.reg_bus[1].data_logic2mem);
        
        @(posedge aclk);
        user_w_r = 'h0;
        user_data_in = 'h3FE0000; // set REG_DESC_1_stickybit_w1c_in
        user_addr_in = REG_DESC_1.address;
        
        user_start = 1'd1;
        
        @(posedge aclk);
        
        user_start = 1'd0;
        
        @(posedge user_data_out_valid);
        
        #100us;
        
        $finish;
    end
    
// pulse signal check for REG_DESC_0
    always@(posedge REG_DESC_0_startpulse_pulse or negedge REG_DESC_0_startpulse_pulse)
    begin
        if(aresetn)
        begin
            if(|REG_DESC_0_startpulse_pulse)
            begin
                $display("***PULSE*** LOGIC SIDE: Signal 'REG_DESC_0_startpulse_pulse' posedge\n");
            end
            
            if(~|REG_DESC_0_startpulse_pulse)
            begin
                $display("***PULSE*** LOGIC SIDE: Signal 'REG_DESC_0_startpulse_pulse' negedge\n");
            end
        end
    end
    
// read clear signal check for REG_RESC_0
    always@(*)
    begin
        if(aresetn)
        begin
            if(|t0.reg_bus[0].data_logic2mem[31:30])
            begin
                $display("%t: ***RC SET*** LOGIC SIDE: Signal 'REG_DESC_0_interruptflag_rc_in' set\n", $realtime);
            end
             
            if(|t0.reg_bus[0].data_mem2logic[31:30])
            begin
                $display("%t: ***RC LOGIC CLEARED*** LOGIC SIDE: RECEIVED CPU CLEAR for 'REG_DESC_0_interruptflag_rc_in'\n", $realtime);
                @(posedge aclk);
                REG_DESC_0_interruptflag_rc_in = REG_DESC_0_interruptflag_rc_in & ~REG_DESC_0_interruptflag_rc_clr;
            end
        end
    end
    
    always@(*)
    begin
        if(|REG_DESC_0_interruptflag_rc_clr)
        begin
            $display("%t: ***RC CPU SENT CLEAR*** LOGIC SIDE: RECEIVED CPU CLEAR for 'REG_DESC_0_interruptflag_rc_in'\n", $realtime);
        end
    end
    
    // pulse signal check for REG_DESC_1
    always@(posedge REG_DESC_1_startpipe1_pulse or negedge REG_DESC_1_startpipe1_pulse)
    begin
        if(aresetn)
        begin
            if(|REG_DESC_1_startpipe1_pulse)
            begin
                $display("***PULSE*** LOGIC SIDE: Signal 'REG_DESC_1_startpipe1_pulse' posedge\n");
            end
            
            if(~|REG_DESC_1_startpipe1_pulse)
            begin
                $display("***PULSE*** LOGIC SIDE: Signal 'REG_DESC_1_startpipe1_pulse' negedge\n");
            end
        end
    end
    
    // pulse signal check for REG_DESC_1
    always@(posedge REG_DESC_1_startpipe2_pulse or negedge REG_DESC_1_startpipe2_pulse)
    begin
        if(aresetn)
        begin
            if(|REG_DESC_1_startpipe2_pulse)
            begin
                $display("***PULSE*** LOGIC SIDE: Signal 'REG_DESC_1_startpipe2_pulse' posedge\n");
            end
            
            if(~|REG_DESC_1_startpipe2_pulse)
            begin
                $display("***PULSE*** LOGIC SIDE: Signal 'REG_DESC_1_startpipe2_pulse' negedge\n");
            end
        end
    end
    
    // read clear signal check for REG_RESC_1
    always@(*)
    begin
        if(aresetn)
        begin
            if(|t0.reg_bus[1].data_logic2mem[15:12])
            begin
                $display("%t: ***RC SET*** LOGIC SIDE: Signal 'REG_DESC_1_interruptflag_rc_in' set\n", $realtime);
            end
            
            if(|t0.reg_bus[1].data_mem2logic[15:12])
            begin
                $display("%t: ***RC LOGIC CLEARED*** LOGIC SIDE: CLEARED 'REG_DESC_1_interruptflag_rc_in'\n", $realtime);
                @(posedge aclk);
                REG_DESC_1_interruptflag_rc_in = REG_DESC_1_interruptflag_rc_in & ~REG_DESC_1_interruptflag_rc_clr;
            end
        end
    end
    
    always@(*)
    begin
        if(|REG_DESC_1_interruptflag_rc_clr)
        begin
            $display("%t: ***RC CPU SENT CLEAR*** LOGIC SIDE: RECEIVED CPU CLEAR for 'REG_DESC_1_interruptflag_rc_in'\n", $realtime);
        end
    end
    
    // write 1 clear signal check for REG_RESC_1
    always@(*)
    begin
        if(aresetn)
        begin
            if(|t0.reg_bus[1].data_logic2mem[25:17])
            begin
                $display("%t: ***W1C SET*** LOGIC SIDE: Signal 'REG_DESC_1_stickybit_w1c_in' set\n", $realtime);
            end
            
            if(|t0.reg_bus[1].data_mem2logic[25:17])
            begin
                $display("%t: ***W1C LOGIC CLEARED*** LOGIC SIDE: CLEARED 'REG_DESC_1_stickybit_w1c_in'\n", $realtime);
                @(posedge aclk);
                REG_DESC_1_stickybit_w1c_in = REG_DESC_1_stickybit_w1c_in & ~REG_DESC_1_stickybit_w1c_clr;
            end
        end
    end
    
    always@(*)
    begin
        if(|REG_DESC_1_stickybit_w1c_clr)
        begin
            $display("%t: ***W1C CPU SENT CLEAR*** LOGIC SIDE: RECEIVED CPU CLEAR for 'REG_DESC_1_stickybit_w1c_in'\n", $realtime);
        end
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
    
