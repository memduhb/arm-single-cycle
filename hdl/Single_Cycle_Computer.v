module Single_Cycle_Computer(
    input clk, reset,
    input [3:0] debug_reg_select,
    output [31:0] debug_reg_out,
    output [31:0] fetchPC
    );

// Connection wires
wire PCSrc;
wire [1:0] RegSrc;
wire RegWrite;
wire ALUSrc;
wire ShiftSrc;
wire [1:0] ShamtSrc;
wire [1:0] ImmSrc;
wire LinkSrc;
wire BXSrc;
wire MemWrite;
wire MemtoReg;
wire [3:0] ALUControl;
wire zero_flag;
wire [31:0] PC; 
wire [31:0] Instr; 
wire WriteSrc;
assign fetchPC = PC;


Datapath my_datapath(
    .clk(clk),
    .reset(reset),
    .PCSrc(PCSrc),
    .RegSrc(RegSrc),
    .RegWrite(RegWrite),
    .ALUSrc(ALUSrc),
    .ShiftSrc(ShiftSrc),
    .ShamtSrc(ShamtSrc),
    .ImmSrc(ImmSrc),
    .LinkSrc(LinkSrc),
    .BXSrc(BXSrc),
    .MemWrite(MemWrite),
    .MemtoReg(MemtoReg),
    .ALUControl(ALUControl),
    .debug_source_select(debug_reg_select),
    .Instr_out(Instr),
    .zero_flag_out(zero_flag),
    .debug_out(debug_reg_out),
    .PC_out(PC)
    );

Controller my_controller(
    .clk(clk),
    .reset(reset),
    .Instr(Instr),
    .zero_flag(zero_flag),
    .PCSrc(PCSrc),
    .RegSrc(RegSrc),
    .RegWrite(RegWrite),
    .ALUSrc(ALUSrc),
    .ShiftSrc(ShiftSrc),
    .ShamtSrc(ShamtSrc),
    .ImmSrc(ImmSrc),
    .LinkSrc(LinkSrc),
    .BXSrc(BXSrc),
    .MemWrite(MemWrite),
    .MemtoReg(MemtoReg),
    .ALUControl(ALUControl)
    );



endmodule