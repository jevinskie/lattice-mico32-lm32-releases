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
// File             : jtag_cores.v
// Title            : Instantiates all IP cores on JTAG chain.
// Dependencies     : system_conf.v
// Version          : 6.0.14
//                  : modified to use jtagconn for LM32,
//                  : all technologies 7/10/07
// Version          : 7.0SP2, 3.0
//                  : No Change
// Version          : 3.1
//                  : No Change
// Version          : 3.9
//                  : Support added for 'Fast Download' register in Debugger
// ============================================================================

`include "system_conf.v"
`include "lm32_include.v"

/////////////////////////////////////////////////////
// jtagconn16 Module Definition
/////////////////////////////////////////////////////

module jtagconn16 (er2_tdo, jtck, jtdi, jshift, jupdate, jrstn, jce2, ip_enable) ;
    input  er2_tdo ; 
    output jtck ; 
    output jtdi ; 
    output jshift ; 
    output jupdate ; 
    output jrstn ; 
    output jce2 ; 
    output ip_enable ; 
endmodule

/////////////////////////////////////////////////////
// Module interface
/////////////////////////////////////////////////////

(* syn_hier="hard" *) module jtag_cores (
    // ----- Inputs -------
    reg_d,
    reg_addr_d,
    // ----- Outputs -------    
    reg_update,
    reg_q,
    reg_addr_q,
    jtck,
    jrstn
    );
    
/////////////////////////////////////////////////////
// Inputs
/////////////////////////////////////////////////////

input [7:0] reg_d;
input [2:0] reg_addr_d;

/////////////////////////////////////////////////////
// Outputs
/////////////////////////////////////////////////////
   
output reg_update;
wire   reg_update;
`ifdef CFG_FAST_DOWNLOAD_ENABLED
output [`DOWNLOAD_BUFFER_SIZE-1:0] reg_q;
wire [`DOWNLOAD_BUFFER_SIZE-1:0]   reg_q;
`else
output [7:0] reg_q;
wire [7:0]   reg_q;
`endif
output [2:0] reg_addr_q;
wire   [2:0] reg_addr_q;

output jtck;
wire   jtck; 	/* synthesis syn_keep=1 */
output jrstn;
wire   jrstn;  /* synthesis syn_keep=1 */	

/////////////////////////////////////////////////////
// Instantiations
/////////////////////////////////////////////////////

wire jtdi;          /* synthesis syn_keep=1 */
wire er2_tdo2;      /* synthesis syn_keep=1 */
wire jshift;        /* synthesis syn_keep=1 */
wire jupdate;       /* synthesis syn_keep=1 */
wire jce2;          /* synthesis syn_keep=1 */
wire ip_enable;     /* synthesis syn_keep=1 */

(* JTAG_IP="LM32", IP_ID="0", HUB_ID="0", syn_noprune=1 *) jtagconn16 jtagconn16_lm32_inst (
    .er2_tdo        (er2_tdo2),
    .jtck           (jtck),
    .jtdi           (jtdi),
    .jshift         (jshift),
    .jupdate        (jupdate),
    .jrstn          (jrstn),
    .jce2           (jce2),
    .ip_enable      (ip_enable)
);

(* syn_noprune=1 *) jtag_lm32 jtag_lm32_inst (
    .JTCK           (jtck),
    .JTDI           (jtdi),
    .JTDO2          (er2_tdo2),
    .JSHIFT         (jshift),
    .JUPDATE        (jupdate),
    .JRSTN          (jrstn),
    .JCE2           (jce2),
    .JTAGREG_ENABLE (ip_enable),
    .CONTROL_DATAN  (),
    .REG_UPDATE     (reg_update),
    .REG_D          (reg_d),
    .REG_ADDR_D     (reg_addr_d),
    .REG_Q          (reg_q),
    .REG_ADDR_Q     (reg_addr_q)
    );
    
endmodule
