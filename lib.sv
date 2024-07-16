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
// A Synchronizer takes an asynchronous input and changes it to synchronized
module Synchronizer
  (input  logic async, clock,
   output logic sync);

  logic metastable;

  DFlipFlop one(.d(async),
                .q(metastable),
                .clock,
                .preset_L(1'b1),
                .reset_L(1'b1)
               );

  DFlipFlop two(.d(metastable),
                .q(sync),
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

endmodule : ShiftRegisterSIPO

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

endmodule : ShiftRegisterPIPO

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

module demux #(parameter OUT_WIDTH = 32, IN_WIDTH = 5, DEFAULT = 0)(
   input                      in,
   input [IN_WIDTH-1:0]       sel,
   output logic [OUT_WIDTH-1:0] out);

   always_comb begin
      out = (DEFAULT === 1'b0) ? {OUT_WIDTH {1'b0}} : {OUT_WIDTH {1'b1}};
      out[sel] = in;
   end

endmodule : demux

module double_demux #(parameter OUT_WIDTH = 32, IN_WIDTH = 5, DEFAULT = 0)
  (input  logic                 in,
   input  logic [IN_WIDTH-1:0]  sel1,
   input  logic [IN_WIDTH-1:0]  sel2,
   output logic [OUT_WIDTH-1:0] out);
   
  always_comb begin
    out = (DEFAULT === 1'b0) ? {OUT_WIDTH {1'b0}} : {OUT_WIDTH {1'b1}};
    out[sel1] = in;
    out[sel2] = in;
  end

endmodule : double_demux

module Mux2D #(parameter MUX_WIDTH = 2, WORD_WIDTH = 32)
  (input  logic [MUX_WIDTH-1:0] [WORD_WIDTH-1:0] in,
   input  logic [$clog2(MUX_WIDTH)-1:0] sel,
   output logic [WORD_WIDTH-1:0] out);
  
  assign out = in[sel];

endmodule : Mux2D

module memory4096x32
  (input  logic        clock, enable,
   input  logic        we,
   input  logic [31:0] data_in,
   output logic [31:0] data_out,
   input  logic [11:0] address);

  logic [31:0] mem [12'hFFF:12'h000];

  assign data_out = mem[address];

  always_ff @(posedge clock)
    if (enable & we)
      mem[address] <= data_in;

endmodule : memory4096x32

module RegFile 
  (input  logic   [4:0] selA1,
   input  logic   [4:0] selA2,
   input  logic   [4:0] selA3,
   input  logic  [31:0] WD3,
   input  logic         clock, clear,
   output logic  [31:0] RD1,
                        RD2);

  logic [31:0] [31:0] regfile;
  logic [31:0] write_enable;

  demux #(32, 5) demux1(.in(1'b1), .sel(selA3), .out(write_enable));

  assign regfile[0] = 32'b0;
  Register #(32) reg1(.Q(regfile[1]), .D(WD3), .en(write_enable[1]), .clock(clock), .clear(clear));
  Register #(32) reg2(.Q(regfile[2]), .D(WD3), .en(write_enable[2]), .clock(clock), .clear(clear));
  Register #(32) reg3(.Q(regfile[3]), .D(WD3), .en(write_enable[3]), .clock(clock), .clear(clear));
  Register #(32) reg4(.Q(regfile[4]), .D(WD3), .en(write_enable[4]), .clock(clock), .clear(clear));
  Register #(32) reg5(.Q(regfile[5]), .D(WD3), .en(write_enable[5]), .clock(clock), .clear(clear));
  Register #(32) reg6(.Q(regfile[6]), .D(WD3), .en(write_enable[6]), .clock(clock), .clear(clear));
  Register #(32) reg7(.Q(regfile[7]), .D(WD3), .en(write_enable[7]), .clock(clock), .clear(clear));
  Register #(32) reg8(.Q(regfile[8]), .D(WD3), .en(write_enable[8]), .clock(clock), .clear(clear));
  Register #(32) reg9(.Q(regfile[9]), .D(WD3), .en(write_enable[9]), .clock(clock), .clear(clear));
  Register #(32) reg10(.Q(regfile[10]), .D(WD3), .en(write_enable[10]), .clock(clock), .clear(clear));
  Register #(32) reg11(.Q(regfile[11]), .D(WD3), .en(write_enable[11]), .clock(clock), .clear(clear));
  Register #(32) reg12(.Q(regfile[12]), .D(WD3), .en(write_enable[12]), .clock(clock), .clear(clear));
  Register #(32) reg13(.Q(regfile[13]), .D(WD3), .en(write_enable[13]), .clock(clock), .clear(clear));
  Register #(32) reg14(.Q(regfile[14]), .D(WD3), .en(write_enable[14]), .clock(clock), .clear(clear));
  Register #(32) reg15(.Q(regfile[15]), .D(WD3), .en(write_enable[15]), .clock(clock), .clear(clear));
  Register #(32) reg16(.Q(regfile[16]), .D(WD3), .en(write_enable[16]), .clock(clock), .clear(clear));
  Register #(32) reg17(.Q(regfile[17]), .D(WD3), .en(write_enable[17]), .clock(clock), .clear(clear));
  Register #(32) reg18(.Q(regfile[18]), .D(WD3), .en(write_enable[18]), .clock(clock), .clear(clear));
  Register #(32) reg19(.Q(regfile[19]), .D(WD3), .en(write_enable[19]), .clock(clock), .clear(clear));
  Register #(32) reg20(.Q(regfile[20]), .D(WD3), .en(write_enable[20]), .clock(clock), .clear(clear));
  Register #(32) reg21(.Q(regfile[21]), .D(WD3), .en(write_enable[21]), .clock(clock), .clear(clear));
  Register #(32) reg22(.Q(regfile[22]), .D(WD3), .en(write_enable[22]), .clock(clock), .clear(clear));
  Register #(32) reg23(.Q(regfile[23]), .D(WD3), .en(write_enable[23]), .clock(clock), .clear(clear));
  Register #(32) reg24(.Q(regfile[24]), .D(WD3), .en(write_enable[24]), .clock(clock), .clear(clear));
  Register #(32) reg25(.Q(regfile[25]), .D(WD3), .en(write_enable[25]), .clock(clock), .clear(clear));
  Register #(32) reg26(.Q(regfile[26]), .D(WD3), .en(write_enable[26]), .clock(clock), .clear(clear));
  Register #(32) reg27(.Q(regfile[27]), .D(WD3), .en(write_enable[27]), .clock(clock), .clear(clear));
  Register #(32) reg28(.Q(regfile[28]), .D(WD3), .en(write_enable[28]), .clock(clock), .clear(clear));
  Register #(32) reg29(.Q(regfile[29]), .D(WD3), .en(write_enable[29]), .clock(clock), .clear(clear));
  Register #(32) reg30(.Q(regfile[30]), .D(WD3), .en(write_enable[30]), .clock(clock), .clear(clear));
  Register #(32) reg31(.Q(regfile[31]), .D(WD3), .en(write_enable[31]), .clock(clock), .clear(clear));

  Mux2D #(32, 32) mux1(.in(regfile), .sel(selA1), .out(RD1));
  Mux2D #(32, 32) mux2(.in(regfile), .sel(selA2), .out(RD2));

endmodule : RegFile