`default_nettype none

//32 bit unsigned multiplier. Result is truncated to 32 bits, will indicate overflow with a flag.

//4 to 8 bit Wallace Tree Multiplier submodule

module wallace_4_bit
  (input logic [3:0] A, B,
   output logic [7:0] P);
   logic [7:0]  