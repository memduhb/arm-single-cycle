module Controller (
    input  wire [31:0] Instr,       // Instruction fetched from memory
    input  wire        zero_flag,   // Zero flag from the ALU
    input clk, reset,
    // Control signals to drive the datapath
    output wire         PCSrc,       // PC mux control
    output reg [1:0]   RegSrc,      // Register file source select signals
    output wire         RegWrite,    // Write enable for the register file
    output reg         ALUSrc,      // Select between register operand and immediate for the ALU
    output reg         ShiftSrc,    // Select shift control source (e.g., constant vs. instruction field)
    output reg [1:0]   ShamtSrc,    // Selects which shift amount to use
    output reg [1:0]   ImmSrc,      // Controls the immediate extender
    output reg         LinkSrc,     // Controls whether link address (PC+4) is written
    output reg         BXSrc,       // Selects bypass for BX instruction (raw Rm vs ALU result)
    output wire         MemWrite,    // Write enable for data memory
    output reg         MemtoReg,    // Selects between ALU result and memory read data
    output reg [3:0]   ALUControl   // 4-bit ALU control signal
          
);

  localparam AND=4'b0000,
		  SUB=4'b0010,
		  ADD=4'b0100,
		  ORR=4'b1100,
		  MOV=4'b1101,
          CMP = 4'b1010;


    wire [3:0] cond   = Instr[31:28]; // Condition field
    wire [3:0] opcode = Instr[24:21]; // Opcode for data-processing instructions
    wire Sbit    = Instr[20];     // S bit for data-processing instructions
    wire LinkBit       = Instr[24]; // Link bit for branch instructions
    wire [1:0] op     = Instr[27:26];    // op field for dp, memory and branch instructions
    wire [3:0] Rd     = Instr[15:12]; // Destination register
    reg RegW, MemW, FlagW;
    wire FlagWrite;
    wire PCS;
    wire isBX;
    assign isBX = (Instr[27:4] == 24'h12FFF1);  
    reg CondEx;
    reg NoWrite;
    wire ImmBit = Instr[25]; // I prime bit for data-processing instructions
    
    wire unused_instr_bit;
    assign unused_instr_bit = Instr[3:0];
    
    // ALU decoder 
    always @(*) begin
        // Set default control signals (safe defaults)
        ALUControl = 4'b0000;
        FlagW = 1'b0;
        NoWrite = 1'b0;
        if (op == 2'b00) begin
            case (opcode)
                ADD: ALUControl = 4'b0100;
                SUB: ALUControl = 4'b0010;
                AND: ALUControl = 4'b0000;
                ORR: ALUControl = 4'b1100;
                MOV: ALUControl = 4'b1101;
                CMP: ALUControl = 4'b0010;
                default: ALUControl = 4'b0000;
            endcase
        end 
        else if (op == 2'b01) begin
            ALUControl = 4'b0100;
        end 
        else if (op == 2'b10) begin
            ALUControl = 4'b0100;
        end
        // For CMP, assert FlagW unconditionally; otherwise, flag write is governed by SBit.
       if (opcode == CMP) begin
            FlagW = 1'b1;
            NoWrite = 1'b1;
        end else begin
            FlagW = Sbit;
            NoWrite = 1'b0;
        end
    end

    // PC logic
    assign PCS = (((Rd == 4'b1111) && RegW) || (op == 2'b10) || isBX);

    // Combinational main decoder:
    always @(*) begin
        // Set default control signals (safe defaults)
        RegW       = 1'b0;
        ALUSrc     = 1'b0;
        MemW       = 1'b0;
        ImmSrc     = 2'b00;
        LinkSrc    = 1'b0;
        BXSrc      = 1'b0;
        RegSrc     = 2'b00;
        MemtoReg   = 1'b0;
        ShiftSrc   = 1'b0;
        ShamtSrc   = 2'b00;
        
        case(op)
            2'b00: begin // Data-processing instructions
                case(opcode)
                    ADD: begin
                        LinkSrc = 0;
                        RegW = 1;
                        ALUSrc = 1;
                        ImmSrc = 2'b11; // dont care
                        RegSrc = 2'b00;
                        MemW = 0;
                        MemtoReg = 0;
                        ShamtSrc=2'b10;
                        ShiftSrc=1;
                        BXSrc = 1;
                    end
                    SUB: begin
                        LinkSrc = 0;
                        RegW = 1;
                        ALUSrc = 1;
                        ImmSrc = 2'b11; // dont care
                        RegSrc = 2'b00;
                        MemW = 0;
                        MemtoReg = 0;
                        ShamtSrc=2'b10;
                        ShiftSrc=1;
                        BXSrc = 1;
                    end
                    AND: begin
                        LinkSrc = 0;
                        RegW = 1;
                        ALUSrc = 1;
                        ImmSrc = 2'b11; // dont care
                        RegSrc = 2'b00;
                        MemW = 0;
                        MemtoReg = 0;
                        ShamtSrc=2'b10;
                        ShiftSrc=1;
                        BXSrc = 1;
                    end
                    ORR: begin
                        LinkSrc = 0;
                        RegW = 1;
                        ALUSrc = 1;
                        ImmSrc = 2'b11; // dont care
                        RegSrc = 2'b00;
                        MemW = 0;
                        MemtoReg = 0;
                        ShamtSrc=2'b10;
                        ShiftSrc=1;
                        BXSrc = 1;
                    end
                    MOV: begin
                        if (ImmBit) begin //mov immediate
                            LinkSrc = 0;
                            RegW = 1;
                            ALUSrc = 0;
                            ImmSrc = 2'b00;  
                            RegSrc = 2'b00; // dont care
                            MemW = 0;
                            MemtoReg = 0;
                            ShamtSrc=2'b01;
                            ShiftSrc=0;
                            BXSrc = 1;
                        end else begin //mov register
                            LinkSrc = 0;
                            RegW = 1;
                            ALUSrc = 1;
                            ImmSrc = 2'b00; //dont care
                            RegSrc = 2'b00; // bit 2 dont care
                            MemW = 0;
                            MemtoReg = 0;
                            ShamtSrc=2'b10;
                            ShiftSrc=1;
                            BXSrc = 1;
                        end
                    end
                    CMP: begin
                        LinkSrc = 0; // dont care
                        RegW = 0;   // dont care
                        ALUSrc = 1;
                        ImmSrc = 2'b00; // dont care
                        RegSrc = 2'b00; 
                        MemW = 0;
                        MemtoReg = 0;
                        ShamtSrc=2'b00;
                        ShiftSrc=0; // dont care
                        BXSrc = 1;
                    end
                endcase 
            end

            
            2'b01: begin // Memory instructions
                case(Sbit)
                    1'b0: begin // Store
                        RegW = 0;
                        ALUSrc = 0;
                        ImmSrc = 2'b01;
                        RegSrc = 2'b10;
                        MemW = 1;
                        ShamtSrc=2'b00;
                        BXSrc = 0;
                    end
                    1'b1: begin // Load
                        RegW = 1;
                        LinkSrc = 0;
                        ALUSrc = 0;
                        ImmSrc = 2'b01;
                        RegSrc = 2'b10; //or 2'b00
                        MemW = 0;
                        MemtoReg = 1;
                        ShamtSrc=2'b00;
                    end
                endcase
            end

            2'b10: begin // Branch instructions
                if (isBX) begin 
                    RegW = 0;
                    RegSrc = 2'b01; // or 2'b00
                    MemW = 0;
                    MemtoReg = 0;
                    BXSrc = 0;
                end else begin
                    case (LinkBit)
                        1'b0: begin // Branch
                            RegW = 0;
                            ALUSrc = 1;
                            ImmSrc = 2'b10;
                            RegSrc = 2'b11; // or 01 
                            MemW = 0;
                            MemtoReg = 0;
                            ShamtSrc=2'b00;
                            BXSrc = 1;
                            LinkSrc = 1;
                        end
                        1'b1: begin // Branch with link
                            RegW = 1;
                            LinkSrc = 1;
                            ALUSrc = 0;
                            ImmSrc = 2'b10;
                            RegSrc = 2'b01; 
                            MemW = 0;
                            MemtoReg = 0;
                            ShamtSrc=2'b00;
                            BXSrc = 1;
                        end
                    endcase
                end
            end
        endcase 
    end


// ADD THE CONDITIONAL LOGIC HERE 
// THIS LOGIC IS A SEQUENTIAL LOGIC
// INPUTS ARE COND, ZERO_FLAG, FLAGW, PCS, NO_WRITE, MEMW, REGW
// OUTPUTS ARE PCSRC, REGWRITE, MEMWRITE

reg zero_flag_reg;
always @(posedge clk) begin
    if (reset)
        zero_flag_reg <= 1'b0;
    else if (FlagWrite)  
        zero_flag_reg <= zero_flag; 
end


always @(*) begin
    case (cond)
        4'b0000:  CondEx =  (zero_flag_reg == 1'b1);  // EQ
        4'b0001:  CondEx =  (zero_flag_reg == 1'b0);  // NE
        default:  CondEx =  1'b1;                    // AL (or any others)
    endcase
end

assign RegWrite = RegW & CondEx & ~NoWrite;
assign MemWrite = MemW & CondEx;
assign PCSrc = PCS & CondEx;
assign FlagWrite = FlagW & CondEx;

endmodule
