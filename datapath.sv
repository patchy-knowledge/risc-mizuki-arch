module datapath (
    input  logic [2:0] ALUControlE,
    input  logic [1:0] ResultSrcW,
    input  logic [1:0] ImmSrcD,
    input  logic       AluSrcE,
                       JumpE,
                       BranchE,
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
                       RdE,
                       Rs1D,
                       Rs2D,
                       Rs1E,
                       Rs2E,
                       RdM,
                       PCSrcE,
                       RegWriteW,
                       RegWriteM,
                       ResultSrcE0,
                       BranchPredicted);

    //Fetch stage
    logic [11:0] PCPlus4F, PCTargetE, PCF1, PCF;
    logic [31:0] InstrF;
    Mux2to1 #(12) PCMux(.I0(PCPlus4F), .I1(PCTargetE), .S(PCSrcE), .Y(PCF1));
    Register #(12) PCReg(.D(PCF1), .Q(PCF), .clock(clock), .en(1'b1), .clear(reset));
    //Memory module not instantiated yet
    Register #(12) F_D_PCReg(.D(PCF), .Q(PCD), .clock(clock), .en(~StallD), .clear(FlushD));
    Register #(32) F_D_InstrReg(.D(InstrF), .Q(InstrD), .clock(clock), .en(~StallD), .clear(FlushD));
    Register #(12) F_D_PCPlus4Reg(.D(PCPlus4F), .Q(PCPlus4D), .clock(clock), .en(~StallD), .clear(FlushD));
    
    //end of Fetch stage, begin Decode stage

    

endmodule : datapath