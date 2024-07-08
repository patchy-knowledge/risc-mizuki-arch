`default_nettype none

/*
 * A library of components, usable for many future hardware designs.
 */

// A comparator checks if two inputs are equal, bit-for-bit.
module Comparator
  #(parameter WIDTH=4)
   (output logic             AeqB,
    input  logic [WIDTH-1:0] A, B);
    
  MagComp mc(.A,
             .B,
             .AeqB,
             .AltB(),
             .AgtB()
            );
            
endmodule: Comparator
    
// A Magnitude Comparator does an unsigned comparison of two input values.
module MagComp
  #(parameter   WIDTH = 8)
  (output logic             AltB, AeqB, AgtB,
   input  logic [WIDTH-1:0] A, B);

  always_comb
    if ($isunknown(A) || $isunknown(B))
      {AeqB, AltB, AgtB} = 3'bxxx;
    else begin
      AeqB = (A == B);
      AltB = (A <  B);
      AgtB = (A >  B);
    end

endmodule: MagComp

// An Adder is a combinational sum generator.
module Adder
  #(parameter WIDTH=8)
  (input  logic [WIDTH-1:0] A, B,
   input  logic             cin,
   output logic [WIDTH-1:0] sum,
   output logic             cout);

  always_comb
    if ($isunknown(A) || $isunknown(B) || $isunknown(cin)) begin
      cout = 1'bx;
      sum = 'x;
      end
    else
      {cout, sum} = A + B + cin;

endmodule : Adder

module Subtracter
  #(parameter WIDTH=8)
  (input  logic [WIDTH:0] A, B,
   input  logic           bin,
   output logic [WIDTH:0] diff,
   output logic           bout);

   assign {bout, diff} = A - B - bin;

endmodule : Subtracter

module BarrelShifter
  (input logic [31:0] in,
   input logic [4:0]  shift,
   input logic        left,
   input logic        R_arith,
   output logic [31:0] out);

   assign out = left ? (R_arith ? in >>> shift : in >> shift) : in << shift;

endmodule : BarrelShifter

// The Multiplexer chooses one of WIDTH bits
module Multiplexer
  #(parameter WIDTH=8)
  (input  logic [WIDTH-1:0]         I,
   input  logic [$clog2(WIDTH)-1:0] S,
   output logic                     Y);

   assign Y = I[S];

endmodule : Multiplexer

// The 2-to-1 Multiplexer chooses one of two multi-bit inputs.
module Mux2to1
  #(parameter WIDTH = 8)
  (input  logic [WIDTH-1:0] I0, I1,
   input  logic             S,
   output logic [WIDTH-1:0] Y);

  assign Y = (S) ? I1 : I0;

endmodule : Mux2to1


// The Decoder converts from binary to one-hot codes.
module Decoder
  #(parameter WIDTH=8)
  (input  logic [$clog2(WIDTH)-1:0] I,
   input  logic                     en,
   output logic [WIDTH-1:0]         D);

  always_comb begin
    D = '0;
    if (en)
      D = 1'b1 << I;
      // or D[I] = 1'b1;
  end

endmodule : Decoder

// A DFlipFlop stores the input bit synchronously with the clock signal.
// preset and reset are asynchronous inputs.
module DFlipFlop
  (input  logic d,
   input  logic preset_L, reset_L, clock,
   output logic q);

  always_ff @(posedge clock, negedge preset_L, negedge reset_L)
    if (~preset_L & reset_L)
      q <= 1'b1;
    else if (~reset_L & preset_L)
      q <= 1'b0;
    else if (~reset_L & ~preset_L)
      q <= 1'bX;
    else
      q <= d;

endmodule : DFlipFlop

// A Register stores a multi-bit value.
// Enable has priority over Clear
module Register
  #(parameter WIDTH=8)
  (input  logic [WIDTH-1:0] D,
   input  logic             en, clear, clock,
   output logic [WIDTH-1:0] Q);

  always_ff @(posedge clock)
    if (en)
      Q <= D;
    else if (clear)
      Q <= '0;

endmodule : Register

// A binary up-down counter.
// Clear has priority over Load, which has priority over Enable
module Counter
  #(parameter WIDTH=8)
  (input  logic [WIDTH-1:0] D,
   input  logic             en, clear, load, clock, up,
   output logic [WIDTH-1:0] Q);

  always_ff @(posedge clock)
    if (clear)
      Q <= {WIDTH {1'b0}};
    else if (load)
      Q <= D;
    else if (en)
      if (up)
        Q <= Q + 1'b1;
      else
        Q <= Q - 1'b1;

endmodule : Counter

// A Synchronizer takes an asynchronous input and changes it to synchronized
module Synchronizer
  (input  logic async, clock,
   output logic sync);

  logic metastable;

  DFlipFlop one(.D(async),
                .Q(metastable),
                .clock,
                .preset_L(1'b1),
                .reset_L(1'b1)
               );

  DFlipFlop two(.D(metastable),
                .Q(sync),
                .clock,
                .preset_L(1'b1),
                .reset_L(1'b1)
               );

endmodule : Synchronizer

// A SIPO Shift Register, with controllable shift direction
// Load has priority over shifting.
module ShiftRegisterSIPO
  #(parameter WIDTH=8)
  (input  logic             serial,
   input  logic             en, left, clock,
   output logic [WIDTH-1:0] Q);

  always_ff @(posedge clock)
    if (en)
      if (left)
        Q <= {Q[WIDTH-2:0], serial};
      else
        Q <= {serial, Q[WIDTH-1:1]};

endmodule : ShiftRegister_SIPO

// A PIPO Shift Register, with controllable shift direction
// Load has priority over shifting.
module ShiftRegisterPIPO
  #(parameter WIDTH=8)
  (input  logic [WIDTH-1:0] D,
   input  logic             en, left, load, clock,
   output logic [WIDTH-1:0] Q);

  always_ff @(posedge clock)
    if (load)
      Q <= D;
    else if (en)
      if (left)
        Q <= {Q[WIDTH-2:0], 1'b0};
      else
        Q <= {1'b0, Q[WIDTH-1:1]};

endmodule : ShiftRegister_PIPO

// A BSR shifts bits to the left by a variable amount
module BarrelShiftRegister
  #(parameter WIDTH=8)
  (input  logic [WIDTH-1:0] D,
   input  logic             en, load, clock,
   input  logic [      1:0] by,
   output logic [WIDTH-1:0] Q);

  logic [WIDTH-1:0] shifted;
  always_comb
    case (by)
      default: shifted = Q;
      2'b01: shifted = {Q[WIDTH-2:0], 1'b0};
      2'b10: shifted = {Q[WIDTH-3:0], 2'b0};
      2'b11: shifted = {Q[WIDTH-4:0], 3'b0};
    endcase

  always_ff @(posedge clock)
    if (load)
        Q <= D;
    else if (en)
        Q <= shifted;

endmodule : BarrelShiftRegister

module half_adder
  (input  logic a, b,
   output logic sum, carry);

  assign {carry, sum} = a + b;
endmodule : half_adder

module full_adder
  (input  logic a, b, cin,
   output logic sum, cout);

  logic c1, c2;

  half_adder ha1(.a(a), .b(b), .sum(c1), .carry(c2));
  half_adder ha2(.a(c1), .b(cin), .sum(sum), .carry(cout));

endmodule : full_adder

module memory4096x32
  (input  logic        clock, enable,
   input  logic        we,
   input  logic [31:0] data_in,
   output logic [31:0] data_out,
   input  logic [11:0] address);

  logic [31:0] mem [10'hFFF:10'h000];

  assign data_out = mem[address];

  always_ff @(posedge clock)
    if (enable & we)
      mem[address] <= data_in;

endmodule : memory4096x32
