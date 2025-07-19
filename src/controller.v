module Control (
    input  wire [5:0] OpCode,
    input  wire [2:0] State,
    output reg        RegDst,
    output reg        Branch,
    output reg        MemRead,
    output reg        MemtoReg,
    output reg [1:0]  ALUOp,
    output reg        MemWrite,
    output reg        ALUSrc,
    output reg        RegWrite,
    output reg        Jump,
    output wire       PCWrite,
    output wire       IRWrite
);

    // State encoding for the MIPS pipeline
    localparam FETCH      = 3'd0;
    localparam DECODE     = 3'd1;
    localparam EXECUTE    = 3'd2;
    localparam MEMORY     = 3'd3;
    localparam WRITEBACK  = 3'd4;

    // Internal control signals
    reg PCWrite_internal, IRWrite_internal;

    // Assign output wires
    assign PCWrite = PCWrite_internal;
    assign IRWrite = IRWrite_internal;

    // Control logic based on state and opcode
    always @(*) begin
        // Default values for all control signals
        RegDst         = 1'b0;
        Branch         = 1'b0;
        MemRead        = 1'b0;
        MemtoReg       = 1'b0;
        ALUOp          = 2'b00;
        MemWrite       = 1'b0;
        ALUSrc         = 1'b0;
        RegWrite       = 1'b0;
        Jump           = 1'b0;
        PCWrite_internal = 1'b0;
        IRWrite_internal = 1'b0;

        case (State)
            FETCH: begin
                IRWrite_internal = 1'b1;
                PCWrite_internal = 1'b1;
            end

            DECODE: begin
                // No changes, signals remain at default
            end

            EXECUTE: begin
                case (OpCode)
                    6'b000000: ALUOp = 2'b10;  // R-type (e.g., ADD, SUB)
                    6'b100011: begin           // Load Word (lw)
                        ALUSrc = 1'b1;
                        ALUOp  = 2'b00;
                    end
                    6'b101011: begin           // Store Word (sw)
                        ALUSrc   = 1'b1;
                        ALUOp    = 2'b00;
                        MemWrite = 1'b1;
                    end
                    6'b000100: begin           // Branch Equal (beq)
                        ALUOp          = 2'b01;
                        Branch         = 1'b1;
                        PCWrite_internal = 1'b1;
                    end
                    6'b001000: begin           // Add Immediate (addi)
                        ALUSrc   = 1'b1;
                        ALUOp    = 2'b00;
                        RegWrite = 1'b1;
                    end
                    6'b000010: begin           // Jump (j)
                        Jump           = 1'b1;
                        PCWrite_internal = 1'b1;
                    end
                endcase
            end

            MEMORY: begin
                case (OpCode)
                    6'b100011: begin // Load Word (lw)
                        MemRead  = 1'b1;
                        MemtoReg = 1'b1;
                    end
                    6'b101011: begin // Store Word (sw)
                        MemWrite = 1'b1;
                    end
                endcase
            end

            WRITEBACK: begin
                case (OpCode)
                    6'b000000: begin // R-type
                        RegDst   = 1'b1;
                        RegWrite = 1'b1;
                    end
                    6'b001000: begin // Add Immediate (addi)
                        RegWrite = 1'b1;
                    end
                endcase
            end

            default: begin
                // Maintain default values for undefined states
            end
        endcase
    end

endmodule
