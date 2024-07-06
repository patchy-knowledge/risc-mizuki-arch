module Controller (
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    input  logic       funct7_5,
    output logic [2:0] AluControlD,
    output logic [1:0] ResultSrcD,
    output logic [1:0] ImmSrcD,
    output logic       RegWriteD,
                       MemWriteD,
                       JumpD,
                       BranchD,
                       AluSrcD);
    
    
endmodule : Controller