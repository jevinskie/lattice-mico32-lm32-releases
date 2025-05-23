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
// File             : lm32_monitor.v
// Title            : Debug monitor memory Wishbone interface
// Version          : 6.1.17
//                  : Initial Release
// Version          : 7.0SP2, 3.0
//                  : No Change
// Version          : 3.3
//                  : Removed port mismatch in instantiation of module
//                  : lm32_monitor_ram.
// =============================================================================

`include "system_conf.v"
`include "lm32_include.v"

/////////////////////////////////////////////////////
// Module interface
/////////////////////////////////////////////////////

module lm32_monitor (
    // ----- Inputs -------
    clk_i, 
    rst_i,
    MON_ADR_I,
    MON_CYC_I,
    MON_DAT_I,
    MON_SEL_I,
    MON_STB_I,
    MON_WE_I,
    // ----- Outputs -------
    MON_ACK_O,
    MON_RTY_O,
    MON_DAT_O,
    MON_ERR_O
    );

/////////////////////////////////////////////////////
// Inputs
/////////////////////////////////////////////////////

input clk_i;                                        // Wishbone clock
input rst_i;                                        // Wishbone reset
input [10:2] MON_ADR_I;                             // Wishbone address
input MON_STB_I;                                    // Wishbone strobe
input MON_CYC_I;                                    // Wishbone cycle
input [`LM32_WORD_RNG] MON_DAT_I;                   // Wishbone write data
input [`LM32_BYTE_SELECT_RNG] MON_SEL_I;            // Wishbone byte select
input MON_WE_I;                                     // Wishbone write enable
   
/////////////////////////////////////////////////////
// Outputs
/////////////////////////////////////////////////////

output MON_ACK_O;                                   // Wishbone acknowlege
reg    MON_ACK_O;
output [`LM32_WORD_RNG] MON_DAT_O;                  // Wishbone data output
reg    [`LM32_WORD_RNG] MON_DAT_O;
output MON_RTY_O;                                   // Wishbone retry
wire   MON_RTY_O;       
output MON_ERR_O;                                   // Wishbone error
wire   MON_ERR_O;
   
/////////////////////////////////////////////////////
// Internal nets and registers 
/////////////////////////////////////////////////////

reg [1:0] state;                                    // Current state of FSM
wire [`LM32_WORD_RNG] data, dataB;                  // Data read from RAM
reg write_enable;                                   // RAM write enable
reg [`LM32_WORD_RNG] write_data;                    // RAM write data
 
/////////////////////////////////////////////////////
// Instantiations
/////////////////////////////////////////////////////

lm32_monitor_ram ram (
    // ----- Inputs -------
    .ClockA             (clk_i),
    .ClockB             (clk_i),
    .ResetA             (rst_i),
    .ResetB             (rst_i),
    .ClockEnA           (`TRUE),
    .ClockEnB           (`FALSE),
    .AddressA           (MON_ADR_I[10:2]),
    .AddressB           (9'b0),
    .DataInA            (write_data),
    .DataInB            (32'b0),
    .WrA                (write_enable),
    .WrB                (`FALSE),
    // ----- Outputs -------
    .QA                 (data),
    .QB                 (dataB)
    );

/////////////////////////////////////////////////////
// Combinational Logic
/////////////////////////////////////////////////////

assign MON_RTY_O = `FALSE;
assign MON_ERR_O = `FALSE;

/////////////////////////////////////////////////////
// Sequential Logic
/////////////////////////////////////////////////////

always @(posedge clk_i `CFG_RESET_SENSITIVITY)
begin
    if (rst_i == `TRUE)
    begin
        write_enable <= #1 `FALSE;
        MON_ACK_O <= #1 `FALSE;
        MON_DAT_O <= #1 {`LM32_WORD_WIDTH{1'bx}};
        state <= #1 2'b00;
    end
    else
    begin
        casez (state)
        2'b01:
        begin
            // Output read data to Wishbone
            MON_ACK_O <= #1 `TRUE;
            MON_DAT_O <= #1 data;
            // Sub-word writes are performed using read-modify-write  
            // as the Lattice EBRs don't support byte enables
            if (MON_WE_I == `TRUE)
                write_enable <= #1 `TRUE;
            write_data[7:0] <= #1 MON_SEL_I[0] ? MON_DAT_I[7:0] : data[7:0];
            write_data[15:8] <= #1 MON_SEL_I[1] ? MON_DAT_I[15:8] : data[15:8];
            write_data[23:16] <= #1 MON_SEL_I[2] ? MON_DAT_I[23:16] : data[23:16];
            write_data[31:24] <= #1 MON_SEL_I[3] ? MON_DAT_I[31:24] : data[31:24];
            state <= #1 2'b10;
        end
        2'b10:
        begin
            // Wishbone access occurs in this cycle
            write_enable <= #1 `FALSE;
            MON_ACK_O <= #1 `FALSE;
            MON_DAT_O <= #1 {`LM32_WORD_WIDTH{1'bx}};
            state <= #1 2'b00;
        end
        default:
        begin
           write_enable <= #1 `FALSE;
           MON_ACK_O <= #1 `FALSE;
            // Wait for a Wishbone access
            if ((MON_STB_I == `TRUE) && (MON_CYC_I == `TRUE))
                state <= #1 2'b01;
        end
        endcase        
    end
end

endmodule
