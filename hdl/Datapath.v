module Datapath #(parameter WIDTH=32) 
    (
    input clk, reset, 
    input PCSrc, 
    input [1:0] RegSrc, 
    input RegWrite,
    input ALUSrc,
    input ShiftSrc, 
    input [1:0] ShamtSrc,
    input [1:0] ImmSrc,
    input LinkSrc, 
    input BXSrc,
    input MemWrite,
    input MemtoReg,
    input [3:0] ALUControl,
    input [3:0] debug_source_select,
    output wire [WIDTH-1:0] Instr_out,
    output wire zero_flag_out,
    output wire [WIDTH-1:0] debug_out,
    output wire [WIDTH-1:0] PC_out
    );
    

wire [31:0] PC;
assign PC_out = PC;
wire [31:0] PCprime;
wire [31:0] PCplus4;
wire [31:0] PCplus8;
wire [31:0] Instr; 
wire [3:0] Rn   = Instr[19:16];
wire [3:0] Rd   = Instr[15:12];
wire [3:0] Rm   = Instr[3:0];
wire [23:0] Imm = Instr[23:0];
wire [3:0] RA1, RA2, RA3;
wire [31:0] ExtImm;
wire [4:0] shamt = Instr[11:7];
wire [4:0] shifter_shamt;
wire [4:0] rot_shifted = {Instr[11:8], 1'b0};
wire [1:0] shift_ctrl = Instr[6:5];
wire [1:0] shifter_control;
wire [31:0] shifter_in;
wire [31:0] SrcA, SrcB;
wire [31:0] RD2;
wire [31:0] ALUResult;
wire [31:0] WriteData;
wire [31:0] ReadData;
wire [31:0] BXResult;
wire [31:0] Result;
wire [31:0] WD3;
wire zero_flag;


assign Instr_out = Instr;
assign zero_flag_out = zero_flag;


// Instantiate the PC MUX using Mux_2to1 module
Mux_2to1 #(.WIDTH(32)) PC_MUX 
    (
    .select(PCSrc),
    .input_0(PCplus4),
    .input_1(Result),
    .output_value(PCprime)
    );

// Instantiate the PC register using Register_reset module
Register_reset #(.WIDTH(32)) PC_reg
    (
    .clk(clk),
    .reset(reset),
    .DATA(PCprime),
    .OUT(PC)
    );

// Instantiate the Instruction Memory module
Instruction_memory #(.BYTE_SIZE(4), .ADDR_WIDTH(32)) Inst_mem
    (
    .ADDR(PC),
    .RD(Instr)
    );

// Instantiate the adder module for PC+4
Adder #(.WIDTH(32)) PCPlus4_adder (.DATA_A(PC), .DATA_B(32'b100), .OUT(PCplus4));

// Instantiate the adder module for PC+8
Adder #(.WIDTH(32)) PCPlus8_adder (.DATA_A(PCplus4), .DATA_B(32'b100), .OUT(PCplus8));

// Instantiate the MUXes for RA1, RA2, RA3
Mux_2to1 #(.WIDTH(4)) RA1_MUX (.select(RegSrc[0]), .input_0(Rn), .input_1(4'b1111), .output_value(RA1));
Mux_2to1 #(.WIDTH(4)) RA2_MUX (.select(RegSrc[1]), .input_0(Rm), .input_1(Rd), .output_value(RA2));
Mux_2to1 #(.WIDTH(4)) RA3_MUX (.select(LinkSrc), .input_0(Rd), .input_1(4'b1110), .output_value(RA3));

// Instantiate the MUX for WD3 (chooses between result or PCplus4)
Mux_2to1 #(.WIDTH(32)) WD3_MUX (.select(LinkSrc), .input_0(Result), .input_1(PCplus4), .output_value(WD3));

// Instantiate the Register File module
Register_file #(.WIDTH(32)) Reg_file
    (
    .clk(clk),
    .reset(reset),
    .write_enable(RegWrite),
    .Source_select_0(RA1),
    .Source_select_1(RA2),
    .Destination_select(RA3),
    .Debug_Source_select(debug_source_select),
    .DATA(WD3),
    .Reg_15(PCplus8),
    .out_0(SrcA),
    .out_1(RD2),
    .Debug_out(debug_out)
    );

// Instantiate the extender module
Extender Extender
    (
    .select(ImmSrc),
    .DATA(Imm),
    .Extended_data(ExtImm)
    );

// Instantiate the ALU Source MUX using Mux_2to1 module (RM and ExtImm)
Mux_2to1 #(.WIDTH(32)) SHIFTER_IN_MUX (.select(ALUSrc), .input_0(ExtImm), .input_1(RD2), .output_value(shifter_in));

// Instantiate the ShamtSrc MUX
Mux_4to1 #(.WIDTH(5)) SHAMT_MUX (.select(ShamtSrc), .input_0(5'b0), .input_1(rot_shifted), .input_2(shamt), .input_3(5'b0), .output_value(shifter_shamt));

// Instantiate the ALU Source MUXes using Mux_2to1 module (using 11 (rr) and sh)
Mux_2to1 #(.WIDTH(2)) SHIFTER_CTRL_MUX (.select(ShiftSrc), .input_0(2'b11), .input_1(shift_ctrl), .output_value(shifter_control));

// Instantiate the shifter module
shifter #(.WIDTH(32)) shifter
    (
    .control(shifter_control),
    .shamt(shifter_shamt),
    .DATA(shifter_in),
    .OUT(SrcB)
    );

// Instantiate the ALU module
ALU #(.WIDTH(32)) ALU
    (
    .control(ALUControl),
    .CI(1'b0),
    .DATA_A(SrcA),
    .DATA_B(SrcB),
    .OUT(ALUResult),
    .CO(),
    .OVF(),
    .N(),
    .Z(zero_flag)
    );

// Instantiate the Data Memory module
Memory #(.BYTE_SIZE(4), .ADDR_WIDTH(32)) Data_memory
    (
    .clk(clk),
    .WE(MemWrite),
    .ADDR(ALUResult),
    .WD(RD2),
    .RD(ReadData)
    );

// Instantiate the MUX for BXResult (chooses between RD2 (Rm) and ALUResult)
Mux_2to1 #(.WIDTH(32)) BX_MUX (.select(BXSrc), .input_0(RD2), .input_1(ALUResult), .output_value(BXResult));

// Instantiate the MUX for the result (chooses between ALUResult and ReadData)
Mux_2to1 #(.WIDTH(32)) RESULT_MUX (.select(MemtoReg), .input_0(BXResult), .input_1(ReadData), .output_value(Result));

endmodule