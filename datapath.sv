`include "lib.sv"
`include "controller.sv"
`include "hazard_branch_unit.sv"
module datapath (
    input  logic [2:0] ALUControlE,
    input  logic [1:0] ResultSrcW,
    input  logic [1:0] ImmSrcD,
    input  logic       AluSrcE,
                       JumpE,
                       BranchE,
                       PCSrcE,
                       MemWriteM,
                       RegWriteW,
                       clock,
                       reset,
                       StallF,
                       StallD,
                       FlushE,
                       FlushD,
    output logic [6:0] op,
    output logic [2:0] funct3,
    output logic       funct7_5, 
    output logic [4:0] RdE,
                       Rs1D,
                       Rs2D,
                       Rs1E,
                       Rs2E,
                       RdM);

    //Fetch stage
    logic [11:0] PCPlus4F, PCTargetE, PCF1, PCF;
    logic [31:0] InstrF;
    Mux2to1 #(12) PCMux(.I0(PCPlus4F), .I1(PCTargetE), .S(PCSrcE), .Y(PCF1));
    Register #(12) PCReg(.D(PCF1), .Q(PCF), .clock(clock), .en(1'b1), .clear(reset));
    //Memory module not instantiated yet
    memory4096x32 InstrMem(.clock(clock), .enable(1'b1), .we(1'b0), .data_in(32'hx), .address(PCF), .data_out(InstrF));
    logic [11:0] PCPlus4D, PCD;
    logic [31:0] InstrD;
    Register #(12) F_D_PCReg(.D(PCF), .Q(PCD), .clock(clock), .en(~StallD), .clear(FlushD));
    Register #(32) F_D_InstrReg(.D(InstrF), .Q(InstrD), .clock(clock), .en(~StallD), .clear(FlushD));
    Register #(12) F_D_PCPlus4Reg(.D(PCPlus4F), .Q(PCPlus4D), .clock(clock), .en(~StallD), .clear(FlushD));
    
    //end of Fetch stage, begin Decode stage
    logic [4:0] RdD;
    assign op = InstrD[6:0];
    assign funct3 = InstrD[14:12];
    assign funct7_5 = InstrD[30];
    assign Rs1D = InstrD[19:15];
    assign Rs2D = InstrD[24:20];
    assign RdD = InstrD[11:7];

endmodule : datapath