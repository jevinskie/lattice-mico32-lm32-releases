//   ==================================================================
//   >>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<
//   ------------------------------------------------------------------
//   Copyright (c) 2006-2011 by Lattice Semiconductor Corporation
//   ALL RIGHTS RESERVED 
//   ------------------------------------------------------------------
//
//   IMPORTANT: THIS FILE IS AUTO-GENERATED BY THE LATTICEMICO SYSTEM.
//
//   Permission:
//
//      Lattice Semiconductor grants permission to use this code
//      pursuant to the terms of the Lattice Semiconductor Corporation
//      Open Source License Agreement.  
//
//   Disclaimer:
//
//      Lattice Semiconductor provides no warranty regarding the use or
//      functionality of this code. It is the user's responsibility to
//      verify the user's design for consistency and functionality through
//      the use of formal verification methods.
//
//   --------------------------------------------------------------------
//
//                  Lattice Semiconductor Corporation
//                  5555 NE Moore Court
//                  Hillsboro, OR 97214
//                  U.S.A
//
//                  TEL: 1-800-Lattice (USA and Canada)
//                         503-286-8001 (other locations)
//
//                  web: http://www.latticesemi.com/
//                  email: techsupport@latticesemi.com
//
//   --------------------------------------------------------------------
//                         FILE DETAILS
// Project          : LatticeMico32
// File             : lm32_trace.v
// Title            : PC Trace and associated logic.
// Dependencies     : lm32_include.v, lm32_functions.v
// Version          : 6.1.17
//                  : Initial Release
// Version          : 7.0SP2, 3.0
//                  : No Change
// Version          : 3.1
//                  : No Change
// Version          : 3.7
//                  : Removed syntax error.
// =============================================================================

`include "lm32_include.v"
`include "system_conf.v"

`ifdef CFG_TRACE_ENABLED
module lm32_trace(
		  // ----- Inputs -------
		  clk_i,
		  rst_i,
		  stb_i,
		  we_i,
		  sel_i,
		  dat_i,
		  adr_i,
		  
		  trace_pc,
		  trace_eid,
		  trace_eret,
		  trace_bret,
		  trace_pc_valid,
		  trace_exception,
		  
		  // -- outputs
		  ack_o,
		  dat_o);

   input clk_i;   
   input rst_i;   
   input stb_i;
   input we_i;   
   input [3:0] sel_i;
   input [`LM32_WORD_RNG] dat_i;
   input [`LM32_WORD_RNG] adr_i;
   input [`LM32_PC_RNG]   trace_pc;
   input [`LM32_EID_RNG]  trace_eid;
   input 		  trace_eret;
   input 		  trace_bret;
   input 		  trace_pc_valid;
   input 		  trace_exception;
   // -- outputs
   output 		  ack_o;
   output [`LM32_WORD_RNG] dat_o;
   reg 			   ovrflw;
   
   function integer clogb2;
      input [31:0] value;
      begin
	 for (clogb2 = 0; value > 0; clogb2 = clogb2 + 1)
           value = value >> 1;
      end
   endfunction 
  
  // instantiate the trace memory
  parameter mem_data_width = `LM32_PC_WIDTH;
  parameter mem_addr_width = clogb2(`CFG_TRACE_DEPTH-1);
   
   wire [`LM32_PC_RNG] 	     trace_dat_o;
   wire [mem_addr_width-1:0] trace_raddr;
   wire [mem_addr_width-1:0] trace_waddr;
   reg  		     trace_we;
   wire 		     trace_be, trace_last;   
   wire 		     rw_creg = adr_i[12]; 
   
   lm32_ram #(.data_width    (mem_data_width),
	      .address_width (mem_addr_width)) 
     trace_mem (.read_clk  	(clk_i),
		.write_clk 	(clk_i),
		.reset     	(rst_i),
		.read_address 	(adr_i[mem_addr_width+1:2]),
		.write_address  (trace_waddr),
		.enable_read 	(`TRUE),
		.enable_write 	((trace_we | trace_be) & trace_pc_valid & !trace_last),
		.write_enable 	(`TRUE),
		.write_data   	(trace_pc),
		.read_data    	(trace_dat_o));

   // trigger type & stop type
   //  trig_type [0] = start capture when bret
   //  trig_type [1] = start capture when eret
   //  trig_type [2] = start capture when PC within a range
   //  trig_type [3] = start when an exception happens (other than breakpoint)
   //  trig_type [4] = start when a breakpoint exception happens

   
   reg [4:0]	        trig_type;	   // at address  0
   reg [4:0] 	        stop_type;         // at address 16   
   reg [`LM32_WORD_RNG] trace_len;   	   // at address  4
   reg [`LM32_WORD_RNG]   pc_low;	   // at address  8
   reg [`LM32_WORD_RNG]   pc_high;	   // at address 12
   reg 		        trace_start,trace_stop;
   reg 		        ack_o;
   reg 			mem_valid;   
   reg [`LM32_WORD_RNG] reg_dat_o;
   reg started;
   reg capturing;
   assign 		dat_o = (rw_creg ? reg_dat_o : trace_dat_o);
   
   initial begin
      trig_type <= #1 0;
      stop_type <= #1 0;
      trace_len <= #1 0;
      pc_low    <= #1 0;
      pc_high   <= #1 0;
      trace_start <= #1 0;
      trace_stop  <= #1 0;
      ack_o 	<= #1 0;
      reg_dat_o <= #1 0;
      mem_valid <= #1 0;
      started   <= #1 0;
      capturing <= #1 0;
   end
   
   // the host side control
   always @(posedge clk_i `CFG_RESET_SENSITIVITY)
     begin
	if (rst_i == `TRUE) begin
	   trig_type   <= #1 0;
	   trace_stop  <= #1 0;
	   trace_start <= #1 0;
	   pc_low      <= #1 0;
	   pc_high     <= #1 0;
	   ack_o       <= #1 0;
	end else begin
	   if (stb_i == `TRUE && ack_o == `FALSE) begin
	      if (rw_creg) begin // control register access
		 ack_o <= #1 `TRUE;		    
		 if (we_i == `TRUE) begin
		    case ({adr_i[11:2],2'b0})
		      // write to trig type
		      12'd0:
			begin
			   if (sel_i[0]) begin
			      trig_type[4:0] <= #1 dat_i[4:0];
                           end
                           if (sel_i[3]) begin
                              trace_start <= #1 dat_i[31];
                              trace_stop  <= #1 dat_i[30];
                           end
			end
		      12'd8:
			begin
			   if (sel_i[3]) pc_low[31:24] <= #1 dat_i[31:24];
			   if (sel_i[2]) pc_low[23:16] <= #1 dat_i[23:16];
			   if (sel_i[1]) pc_low[15:8]  <= #1 dat_i[15:8];
			   if (sel_i[0]) pc_low[7:0]   <= #1 dat_i[7:0];			 
			end
		      12'd12:
			begin
			   if (sel_i[3]) pc_high[31:24] <= #1 dat_i[31:24];
			   if (sel_i[2]) pc_high[23:16] <= #1 dat_i[23:16];
			   if (sel_i[1]) pc_high[15:8]  <= #1 dat_i[15:8];
			   if (sel_i[0]) pc_high[7:0]   <= #1 dat_i[7:0];			 
			end
		      12'd16:
                        begin
			   if (sel_i[0])begin
                               stop_type[4:0] <= #1 dat_i[4:0];
                           end
                        end
		    endcase
		 end else begin // read control registers
		    case ({adr_i[11:2],2'b0})
		      // read the trig type
		      12'd0:
                        reg_dat_o <= #1 {22'b1,capturing,mem_valid,ovrflw,trace_we,started,trig_type};
		      12'd4:
                        reg_dat_o <= #1 trace_len;			 
		      12'd8:
			reg_dat_o <= #1 pc_low;
		      12'd12:
			reg_dat_o <= #1 pc_high;		      
		      default:
			reg_dat_o <= #1 {27'b0,stop_type};
		    endcase
		 end // else: !if(we_i == `TRUE)		 
	      end else // read / write memory
		if (we_i == `FALSE) begin
		   ack_o <= #1 `TRUE;
		end else
		  ack_o <= #1 `FALSE;	      
	      // not allowed to write to trace memory
	   end else begin // if (stb_i == `TRUE)
	      trace_start  <= #1 `FALSE;
	      trace_stop   <= #1 `FALSE;
	      ack_o        <= #1 `FALSE;	      
	   end // else: !if(stb_i == `TRUE)	   
	end // else: !if(rst_i == `TRUE)
     end 
   
   wire [`LM32_WORD_RNG] trace_pc_tmp = {trace_pc,2'b0};
   
   // trace state machine
   reg [2:0] tstate;
   wire      pc_in_range = {trace_pc,2'b0} >= pc_low &&
	                   {trace_pc,2'b0} <= pc_high;
   
   assign    trace_waddr = trace_len[mem_addr_width-1:0];

   wire trace_begin = ((trig_type[0] & trace_bret) ||
		       (trig_type[1] & trace_eret) ||
		       (trig_type[2] & pc_in_range & trace_pc_valid) ||
		       (trig_type[3] & trace_exception & (trace_eid != `LM32_EID_BREAKPOINT)) ||
                       (trig_type[4] & trace_exception & (trace_eid == `LM32_EID_BREAKPOINT))
                      );
   

   wire trace_end = (trace_stop  ||
		      (stop_type[0] & trace_bret) ||
		      (stop_type[1] & trace_eret) ||
		      (stop_type[2] & !pc_in_range & trace_pc_valid) ||
		      (stop_type[3] & trace_exception & (trace_eid != `LM32_EID_BREAKPOINT)) ||
                      (stop_type[4] & trace_exception & (trace_eid == `LM32_EID_BREAKPOINT))
                    );

   assign trace_be = (trace_begin & (tstate == 3'd1));
   assign trace_last = (trace_stop & (tstate == 3'd2));
   
   always @(posedge clk_i `CFG_RESET_SENSITIVITY)
     begin
	if (rst_i == `TRUE) begin
	   tstate    <= #1 0;
	   trace_we  <= #1 0;
	   trace_len <= #1 0;	   
	   ovrflw    <= #1 `FALSE;
	   mem_valid <= #1 0;
           started   <= #1 0;
           capturing <= #1 0;
	end else begin
	   case (tstate)
	   3'd0:
	     // start capture	     
	     if (trace_start) begin
		tstate <= #1 3'd1;
		mem_valid <= #1 0;
                started   <= #1 1;
	     end
	   3'd1:
	     begin
		// wait for trigger
		if (trace_begin) begin
                   capturing <= #1 1;
		   tstate    <= #1 3'd2;
		   trace_we  <= #1 `TRUE;
		   trace_len <= #1 0;		
		   ovrflw    <= #1 `FALSE;			      
		end
	     end // case: 3'd1	     

	   3'd2:
	     begin
		if (trace_pc_valid) begin
		   if (trace_len[mem_addr_width])
		     trace_len <= #1 0;
		   else
		     trace_len <= #1 trace_len + 1;
		end
		if (!ovrflw) ovrflw <= #1 trace_len[mem_addr_width];		
		// wait for stop condition
		if (trace_end) begin
		   tstate    <= #1 3'd0;
		   trace_we  <= #1 0;
		   mem_valid <= #1 1;
                   started   <= #1 0;
                   capturing <= #1 0;
		end
	     end // case: 3'd2
	   endcase
	end // else: !if(rst_i == `TRUE)
     end
endmodule
`endif
