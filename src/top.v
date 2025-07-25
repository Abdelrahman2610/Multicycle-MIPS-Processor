`include "params.v"

module top (
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] writedata,
    output wire [31:0] dataadr,
    output wire        memwrite
);
    // State machine
    reg [2:0] state, next_state;

    // Register file
    wire [31:0] read_data1, read_data2;
    regfile reg_file (
        .clk(clk),
        .reset(reset),
        .RegWrite(RegWrite),
        .RegDst(RegDst),
        .rs(rs),
        .rt(rt),
        .rd(rd),
        .write_data(MemtoReg ? MDR : ALUOut),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // ALU
    wire [31:0] alu_result;
    wire        zero;
    alu alu_unit (
        .A(read_data1),
        .B(read_data2),
        .ALUSrc(ALUSrc),
        .imm(imm),
        .ALUOp(ALUOp),
        .funct(instr_reg[5:0]),
        .alu_result(alu_result),
        .zero(zero)
    );

    // Memory (kept as arrays for now)
    reg [31:0] instr_mem [0:`MEM_SIZE-1];
    reg [31:0] data_mem  [0:`MEM_SIZE-1];

    // Instruction register and pipeline registers
    reg [31:0] pc;
    reg [31:0] instr_reg;
    reg [31:0] ALUOut;
    reg [31:0] MDR;

    // Control signals from controller
    wire       RegDst, Branch, MemRead, MemtoReg, ALUSrc, RegWrite, Jump;
    wire [1:0] ALUOp;
    wire       MemWrite;
    wire       PCWrite;
    wire       IRWrite;

    // Instruction fields
    wire [5:0] opcode = instr_reg[31:26];
    wire [4:0] rs     = instr_reg[25:21];
    wire [4:0] rt     = instr_reg[20:16];
    wire [4:0] rd     = instr_reg[15:11];
    wire [15:0] imm   = instr_reg[15:0];
    wire [31:0] sign_ext_imm = {{16{imm[15]}}, imm};

    integer i;

    initial begin
        pc    = 32'd0;
        state = `FETCH;

        for (i = 0; i < `MEM_SIZE; i = i + 1) begin
            instr_mem[i] = 32'd0;
            data_mem[i]  = 32'd0;
        end

        // Test program
        instr_mem[0]  = 32'h20020007;  // addi $2, $0, 5
        instr_mem[1]  = 32'h2003000c;  // addi $3, $0, 12
        instr_mem[2]  = 32'h2067fff7;  // addi $7, $3, -9
        instr_mem[3]  = 32'h00e22025;  // or   $4, $7, $2
        instr_mem[4]  = 32'h00642824;  // and  $5, $3, $4
        instr_mem[5]  = 32'h00a42820;  // add  $5, $5, $4
        instr_mem[6]  = 32'h10a7000a;  // beq  $5, $7, +10
        instr_mem[7]  = 32'h0064202a;  // slt  $4, $3, $4
        instr_mem[8]  = 32'h10800001;  // beq  $4, $0, +1
        instr_mem[9]  = 32'h20050000;  // addi $5, $0, 0
        instr_mem[10] = 32'h00e2202a;  // slt  $4, $7, $2
        instr_mem[11] = 32'h00853820;  // add  $7, $4, $5
        instr_mem[12] = 32'h00e23822;  // sub  $7, $7, $2
        instr_mem[13] = 32'hac670044;  // sw   $7, 68($3)
        instr_mem[14] = 32'h8c020050;  // lw   $2, 80($0)
        instr_mem[15] = 32'h08000c11;  // j ...
        instr_mem[16] = 32'h20020001;  // addi $2, $0, 1
        instr_mem[17] = 32'hac020054;  // sw   $2, 84($0)
    end

    wire [31:0] instr_mem_out = instr_mem[pc[6:2]];

    Control control_unit (
        .OpCode  (opcode),
        .State   (state),
        .RegDst  (RegDst),
        .Branch  (Branch),
        .MemRead (MemRead),
        .MemtoReg(MemtoReg),
        .ALUOp   (ALUOp),
        .MemWrite(MemWrite),
        .ALUSrc  (ALUSrc),
        .RegWrite(RegWrite),
        .Jump    (Jump),
        .PCWrite (PCWrite),
        .IRWrite (IRWrite)
    );

    // State machine
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= `FETCH;
        else
            state <= next_state;
    end

    always @(*) begin
        case (state)
            `FETCH:    next_state = `DECODE;
            `DECODE:   next_state = `EXECUTE;
            `EXECUTE: begin
                if (MemRead || MemWrite)
                    next_state = `MEMORY;
                else if (RegWrite)
                    next_state = `WRITEBACK;
                else
                    next_state = `FETCH;
            end
            `MEMORY: begin
                if (RegWrite)
                    next_state = `WRITEBACK;
                else
                    next_state = `FETCH;
            end
            `WRITEBACK: next_state = `FETCH;
            default:   next_state = `FETCH;
        endcase
    end

    // Pipeline stages
    always @(posedge clk) begin
        if (!reset) begin
            case (state)
                `FETCH: begin
                    if (IRWrite)
                        instr_reg <= instr_mem_out;
                end
                `DECODE: begin
                    // Use read_data1, read_data2 from regfile
                end
                `EXECUTE: begin
                    ALUOut <= alu_result;
                end
                `MEMORY: begin
                    if (MemRead)
                        MDR <= data_mem[ALUOut[31:2]];
                    if (MemWrite)
                        data_mem[ALUOut[31:2]] <= read_data2;
                end
                `WRITEBACK: begin
                    // Handled by regfile
                end
            endcase
        end
    end

    wire [31:0] pc_plus4      = pc + 4;
    wire [31:0] branch_target = pc_plus4 + (sign_ext_imm << 2);
    wire [31:0] jump_target   = {pc_plus4[31:28], instr_reg[25:0], 2'b00};

    always @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 32'd0;
        else if (PCWrite) begin
            if (Jump)
                pc <= jump_target;
            else if (Branch && zero)
                pc <= branch_target;
            else
                pc <= pc_plus4;
        end
    end

    assign writedata = read_data2;
    assign dataadr   = ALUOut;
    assign memwrite  = (state == `MEMORY) && MemWrite;

endmodule
