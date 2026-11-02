module tb;
    reg clk = 0, rst = 1;
    wire [31:0] pc, daddr, dwdata;
    wire [3:0]  dwe;
    reg  [31:0] mem [0:4095];
    reg  [31:0] w;

    wire [31:0] instr  = mem[pc[13:2]];
    wire [31:0] drdata = mem[daddr[13:2]];

    rv32i_core cpu (.clk(clk), .rst(rst), .pc_o(pc), .instr(instr),
                    .daddr(daddr), .dwdata(dwdata), .dwe(dwe), .drdata(drdata));

    always #5 clk = ~clk;

    initial begin
        $readmemh("prog.hex", mem);
        $dumpfile("wave.vcd");
        $dumpvars(0, tb);
        #22 rst = 0;
        #2000000 $display("TIMEOUT");
        $finish;
    end

    always @(posedge clk) if (|dwe) begin
        if (daddr == 32'h10000000)
            $write("%c", dwdata[7:0]);
        else if (daddr == 32'h10000004) begin
            $display("\nHALT, exit code = %0d", dwdata);
            $finish;
        end else if (daddr[31:14] == 0) begin
            w = mem[daddr[13:2]];
            if (dwe[0]) w[7:0]   = dwdata[7:0];
            if (dwe[1]) w[15:8]  = dwdata[15:8];
            if (dwe[2]) w[23:16] = dwdata[23:16];
            if (dwe[3]) w[31:24] = dwdata[31:24];
            mem[daddr[13:2]] <= w;
        end
    end
endmodule
