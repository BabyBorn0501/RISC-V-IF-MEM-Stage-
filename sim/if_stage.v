module if_stage (
    input  wire        clk,
    input  wire        rstn,
    input  wire        en,           // 1 = advance PC, 0 = stall (hold PC)
    input  wire        PCSrcE,       // 1 = take branch/jump target
    input  wire [31:0] PCTargetE,    // branch / jump destination address
    output wire [31:0] InstrF,       // fetched instruction
    output wire [31:0] PCF,          // current PC
    output wire [31:0] PCPlus4F      // PC + 4 (sequential next PC)
);
    wire [31:0] PCNext;

    // Select next PC: sequential (PC+4) or taken branch/jump target
    mux pc_sel_mux (
        .d0(PCPlus4F),
        .d1(PCTargetE),
        .s (PCSrcE),
        .y (PCNext)
    );

    // Program counter register (synchronous reset, load-use stall enable)
    pc pc_reg (
        .clk   (clk),
        .rstn  (rstn),
        .en    (en),
        .PCNext(PCNext),
        .PC    (PCF)
    );

    // PC + 4 adder
    adder pc_inc (
        .a(PCF),
        .b(32'h00000004),
        .y(PCPlus4F)
    );

    // Instruction memory: combinational read at current PC
    instruction_memory imem (
        .rstn(rstn),
        .A   (PCF),
        .RD  (InstrF)
    );
endmodule

module pc (
    input  wire        clk,
    input  wire        rstn,      // active-low synchronous reset
    input  wire        en,        // 1 = update, 0 = hold (pipeline stall)
    input  wire [31:0] PCNext,
    output reg  [31:0] PC
);
    always @(posedge clk) begin
        if (!rstn) begin
            PC <= 32'h00000000;
        end else if (en) begin
            PC <= PCNext;
        end
        // else: en=0, hold current PC (stall)
    end
endmodule

// 2-to-1 MUX: S=0 -> D0, S=1 -> D1
module mux (
    input  wire [31:0] d0,
    input  wire [31:0] d1,
    input  wire        s,
    output wire [31:0] y
);
    assign y = s ? d1 : d0;
endmodule

module adder (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] y
);
    assign y = a + b;
endmodule