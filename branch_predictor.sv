module branch_predictor (
    input  logic clock,
                 clear,
                 decision,
                 en,
    output logic prediction);
    //decision and prediction: 1 for taken, 0 for not taken
    logic [1:0] D, Q;
    Register #(2) reg(.*);
    always_comb begin
        unique case (Q)
            2'b00: D = decision ? 2'b01 : 2'b00;
            2'b01: D = decision ? 2'b10 : 2'b00;
            2'b10: D = decision ? 2'b11 : 2'b01;
            2'b11: D = decision ? 2'b11 : 2'b10;
        endcase
    end
    assign prediction = Q[1];

endmodule : branch_predictor