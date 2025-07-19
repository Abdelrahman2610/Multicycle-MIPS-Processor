module regfile (
    input  wire        clk,
    input  wire        reset,
    input  wire        RegWrite,
    input  wire        RegDst,
    input  wire [4:0]  rs,
    input  wire [4:0]  rt,
    input  wire [4:0]  rd,
    input  wire [31:0] write_data,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);

    reg [31:0] registers [0:`REG_SIZE-1];

    integer i;

    // Initialize registers to zero
    initial begin
        for (i = 0; i < `REG_SIZE; i = i + 1) begin
            registers[i] = 32'd0;
        end
    end

    // Asynchronous read
    assign read_data1 = registers[rs];
    assign read_data2 = registers[rt];

    // Synchronous write
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < `REG_SIZE; i = i + 1) begin
                registers[i] <= 32'd0;
            end
        end else if (RegWrite) begin
            registers[RegDst ? rd : rt] <= write_data;
        end
    end

endmodule
