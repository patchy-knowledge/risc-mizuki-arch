`default_nettype none
/*
 * ALU operations:
 0: res = A
 1: res = B
 2: res = A+B
 3: res = A-B 
 4: res = A*B

 5: res = A&B
 6: res = A|B
 7: res = A^B
 8: res = ~A

 9: res = A==B
 10: res = A<B

 11: res = A<<B
 12: res = A>>B

 13:
 14:
 15:
 */

 module ALU
   (input logic [31:0] A, B,
    input logic [3:0] op,
    output logic [31:0] res);

    logic [31:0] R0, R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12, R13, R14, R15;
    MagComp #(.WIDTH(32)) mc(.A(A), .B(B), .AeqB(R9), .AltB(R10), .AgtB());
    Adder #(.WIDTH(32)) add(.A(A), .B(B), .cin(0), .sum(R2), .cout());
    Subtracter #(.WIDTH(32)) sub(.A(A), .B(B), .bin(0), .sum(R3), .bout());
    BarrelShifter #(.WIDTH(32)) shift(.V(A), .by(B), .S(R11));
    assign R0 = A;
    assign R1 = B;
    assign R5 = A & B;
    assign R6 = A | B;
    assign R7 = A ^ B;
    assign R8 = ~A;

    always_comb begin
      case (op)
        0: res = R0;
        1: res = R1;
        2: res = R2;
        3: res = R3;
        4: res = R4;
        5: res = R5;
        6: res = R6;
        7: res = R7;
        8: res = R8;
        9: res = R9;
        10: res = R10;
        11: res = R11;
        12: res = R12;
        13: res = R13;
        14: res = R14;
        15: res = R15;
      endcase
    end
    
endmodule : ALU