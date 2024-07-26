module hazard_branch_unit(
    input  logic       RdE,
                       Rs1D,
                       Rs2D,
                       Rs1E,
                       Rs2E,
                       RdM,
                       RdW,
                       PCSrcE,
                       RegWriteW,
                       RegWriteM,
                       ResultSrcE0,
                       BranchPredicted,
    output logic [1:0] ForwardAE,
                 [1:0] ForwardBE,
    output logic       StallF,
                       StallD,
                       FlushD,
                       FlushE);
    always_comb begin
        if(((Rs1E == RdM) & RegWriteM) & (Rs1E != 0)) begin
            ForwardAE = 2'b10;
        end
        else if(((Rs1E == RdW) & RegWriteW) & (Rs1E != 0)) begin
            ForwardAE = 2'b01;
        end
        else begin
            ForwardAE = 2'b00;
        end
    end
    logic lwStall;
    assign lwStall = ResultSrcE0 & ((Rs1D == RdE) | (Rs2D == RdE));
    // LW instruction is present in the E stage and destination/source register combo will trigger data hazard
    // Decode and Fetch registers disabled to retain queued instructions
    assign StallD = lwStall;
    assign StallF = lwStall;
    // Execute stage is flushed due to premature data
    assign FlushE = lwStall | PCSrcE;
    // Decode stage is flushed when branch mispredicted (i.e. clear and fetch correct instruction)
    assign FlushD = (PCSrcE != BranchPredicted);
endmodule : hazard_branch_unit