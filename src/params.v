`ifndef PARAMS_V
`define PARAMS_V

// State machine parameters
`define FETCH     3'd0
`define DECODE    3'd1
`define EXECUTE   3'd2
`define MEMORY    3'd3
`define WRITEBACK 3'd4

// Memory and register sizes
`define MEM_SIZE  32  // 32 words of 32-bit memory
`define REG_SIZE  32  // 32 registers

// Opcode definitions (partial list for reference)
`define OPCODE_RTYPE  6'b000000
`define OPCODE_LW     6'b100011
`define OPCODE_SW     6'b101011
`define OPCODE_BEQ    6'b000100
`define OPCODE_ADDI   6'b001000
`define OPCODE_J      6'b000010

// Funct codes for R-type instructions
`define FUNCT_ADD     6'b100000
`define FUNCT_SUB     6'b100010
`define FUNCT_AND     6'b100100
`define FUNCT_OR      6'b100101
`define FUNCT_SLT     6'b101010

`endif
