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
// File             : TYPEB.v
// Description:
//    This is one of the two types of cells that are used to create ER1/ER2
//    register bits.
// Dependencies     : None
// Version          : 6.1.17
//   Modified typeb module to remove redundant DATA_OUT port.
// Version          : 7.0SP2, 3.0
//                  : No Change
// Version          : 3.1
//                  : No Change
// =============================================================================
module TYPEB
   (
      input CLK,
      input RESET_N,
      input CLKEN,
      input TDI,
      output TDO,
      input DATA_IN,
      input CAPTURE_DR
   );

   reg tdoInt;

   always @ (negedge CLK or negedge RESET_N)
   begin
      if (RESET_N== 1'b0)
         tdoInt <= #1 1'b0;
      else if (CLK == 1'b0)
         if (CLKEN==1'b1)
            if (CAPTURE_DR==1'b0)
               tdoInt <= #1 TDI;
            else
               tdoInt <= #1 DATA_IN;
   end

   assign TDO = tdoInt;

endmodule

