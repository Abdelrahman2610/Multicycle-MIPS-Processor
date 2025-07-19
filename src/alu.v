module alu (
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire       ALUSrc,
    input  wire [15:0] imm,
    input  wire [1:0]  ALUOp,
    input  wire [5:0]  funct,
    output reg  [31:0] alu_result,
    output reg        zero
);

    wire [31:0] sign_ext_imm = {{16{imm[15]}}, imm};
    wire [31:0] operand_b = ALUSrc ? sign_ext_imm : B;

    always @(*) begin
        alu_result = 32'b0;
        zero       = 1'b0;

        case (ALUOp)
            2'b00: alu_result = A + operand_b;
            2'b01: begin
                alu_result = A - B;
                zero       = (alu_result == 0);
            end
            2'b10: begin
                case (funct)
                    6'b100000: alu_result = A + B;   // ADD
                    6'b100010: alu_result = A - B;   // SUB
                    6'b100100: alu_result = A & B;   // AND
                    6'b100101: alu_result = A | B;   // OR
                    6'b101010: alu_result = (A < B) ? 32'd1 : 32'd0; // SLT
                    default:   alu_result = 32'd0;
                endcase
            end
            default: alu_result = 32'd0;
        endcase
    end

endmodule
