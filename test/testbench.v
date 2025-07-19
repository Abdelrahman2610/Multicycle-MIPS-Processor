module testbench();
    reg clk;
    reg reset;
    wire [31:0] writedata;
    wire [31:0] dataadr;
    wire        memwrite;

    top dut (
        .clk      (clk),
        .reset    (reset),
        .writedata(writedata),
        .dataadr  (dataadr),
        .memwrite (memwrite)
    );

    // Generate clock signal
    always begin
        clk <= 1; #5;
        clk <= 0; #5;
    end

    initial begin
        reset = 1;
        #22;
        reset = 0;

        $display("\n--- Simulation Start ---");
        $display("time   dataadr   writedata");
        $monitor("%d   %d   %d", $time, dataadr, writedata);
    end

    // Check for successful write to address 84 with data 7
    always @(negedge clk) begin
        if (memwrite) begin
            if (dataadr === 84 && writedata === 7) begin
                $display("Simulation succeeded");
                $stop;
            end
        end
    end

endmodule
