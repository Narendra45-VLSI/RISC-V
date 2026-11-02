module rv32i_core (
    input         clk, rst,
    output [31:0] pc_o,
    input  [31:0] instr,
    output [31:0] daddr, dwdata,
    output [3:0]  dwe,
    input  [31:0] drdata
);
    localparam LUI=7'b0110111, AUIPC=7'b0010111, JAL=7'b1101111, JALR=7'b1100111,
               BRANCH=7'b1100011, LOAD=7'b0000011, STORE=7'b0100011,
               OPIMM=7'b0010011, OP=7'b0110011;

    reg [31:0] pc;
    reg [31:0] regs [0:31];
    integer k;
    initial for (k = 0; k < 32; k = k + 1) regs[k] = 32'b0;

    wire [6:0] opcode = instr[6:0];
    wire [4:0] rd  = instr[11:7];
    wire [2:0] f3  = instr[14:12];
    wire [4:0] rs1 = instr[19:15];
    wire [4:0] rs2 = instr[24:20];
    wire       f7b5 = instr[30];

    wire [31:0] rs1v = (rs1 == 0) ? 32'b0 : regs[rs1];
    wire [31:0] rs2v = (rs2 == 0) ? 32'b0 : regs[rs2];

    wire [31:0] imm_i = {{20{instr[31]}}, instr[31:20]};
    wire [31:0] imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    wire [31:0] imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
    wire [31:0] imm_u = {instr[31:12], 12'b0};
    wire [31:0] imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

    // ---------- ALU ----------
    wire        is_op = (opcode == OP);
    wire [31:0] b     = is_op ? rs2v : imm_i;
    wire        sub   = is_op & f7b5;
    wire [4:0]  sh    = b[4:0];
    wire signed [31:0] sra = $signed(rs1v) >>> sh;
    reg  [31:0] alu;
    always @* begin
        case (f3)
            3'b000: alu = sub ? (rs1v - b) : (rs1v + b);
            3'b001: alu = rs1v << sh;
            3'b010: alu = ($signed(rs1v) < $signed(b)) ? 32'd1 : 32'd0;
            3'b011: alu = (rs1v < b) ? 32'd1 : 32'd0;
            3'b100: alu = rs1v ^ b;
            3'b101: alu = f7b5 ? sra : (rs1v >> sh);
            3'b110: alu = rs1v | b;
            default: alu = rs1v & b;
        endcase
    end

    // ---------- Branch / next PC ----------
    reg take;
    always @* begin
        case (f3)
            3'b000: take = (rs1v == rs2v);
            3'b001: take = (rs1v != rs2v);
            3'b100: take = ($signed(rs1v) < $signed(rs2v));
            3'b101: take = !($signed(rs1v) < $signed(rs2v));
            3'b110: take = (rs1v < rs2v);
            3'b111: take = !(rs1v < rs2v);
            default: take = 1'b0;
        endcase
    end

    wire [31:0] pc4 = pc + 32'd4;
    reg  [31:0] npc;
    always @* begin
        npc = pc4;
        if (opcode == JAL)                    npc = pc + imm_j;
        else if (opcode == JALR)              npc = (rs1v + imm_i) & 32'hFFFFFFFE;
        else if (opcode == BRANCH && take)    npc = pc + imm_b;
    end

    // ---------- Data memory interface ----------
    assign daddr = rs1v + ((opcode == STORE) ? imm_s : imm_i);
    wire [1:0] off = daddr[1:0];
    assign dwdata = (f3[1:0] == 2'b00) ? {4{rs2v[7:0]}} :
                    (f3[1:0] == 2'b01) ? {2{rs2v[15:0]}} : rs2v;
    assign dwe = (opcode != STORE)     ? 4'b0000 :
                 (f3[1:0] == 2'b00)    ? (4'b0001 << off) :
                 (f3[1:0] == 2'b01)    ? (4'b0011 << off) : 4'b1111;

    wire [31:0] shifted = drdata >> (8 * off);
    reg  [31:0] load_val;
    always @* begin
        case (f3)
            3'b000: load_val = {{24{shifted[7]}},  shifted[7:0]};
            3'b001: load_val = {{16{shifted[15]}}, shifted[15:0]};
            3'b100: load_val = {24'b0, shifted[7:0]};
            3'b101: load_val = {16'b0, shifted[15:0]};
            default: load_val = drdata;
        endcase
    end

    // ---------- Write-back ----------
    reg [31:0] wb;
    reg        wen;
    always @* begin
        wen = 1'b1;
        wb  = alu;
        case (opcode)
            LUI:         wb = imm_u;
            AUIPC:       wb = pc + imm_u;
            JAL, JALR:   wb = pc4;
            LOAD:        wb = load_val;
            OP, OPIMM:   wb = alu;
            default:     wen = 1'b0;
        endcase
    end

    always @(posedge clk) begin
        if (rst) pc <= 32'b0;
        else begin
            pc <= npc;
            if (wen && rd != 0) regs[rd] <= wb;
        end
    end

    assign pc_o = pc;
endmodule
