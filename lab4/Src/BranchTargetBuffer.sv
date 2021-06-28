`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB 
// Engineer: Xiao Tong
// 
// Design Name: RISCV-Pipline CPU
// Module Name: ALU
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: ALU unit of RISCV CPU
//////////////////////////////////////////////////////////////////////////////////

module BranchTargetBuffer #(
    parameter BTB_ADDR_LEN = 5                     // BTB Entry 个数
)(
    input clk,
    input rst,
    input BranchE,
    input BTB_HitE,
    input BHT_HitE,
    input BrInstE,
    input [31:0] PCF,                           //PCF 用于索引查找 该指令是否可以预测
    input [31:0] PCE,                           //PCE 用于更新 BTB
    input [31:0] BrNPC,                         //BrachPC 用于更新 BTB
    output [31:0] PredictPC,                    //PredictPC 用于输出索引查找
    output reg BTB_HitF,                        //标识 Branch 是否成功
    output BHT_HitF
);
localparam BTB_SIZE = 1 << BTB_ADDR_LEN;

wire we;
wire clear;
wire [BTB_ADDR_LEN - 1:0] PCF_addr, PCE_addr;

assign PCF_addr = {PCF[BTB_ADDR_LEN - 1:0]};
assign PCE_addr = {PCE[BTB_ADDR_LEN - 1:0]};
assign we = (BranchE & ~BTB_HitE);
assign clear = (~BranchE & BTB_HitE & BrInstE);
assign BHT_HitF = 1'b1;
assign PredictPC = BTB_HitF ? BTB[PCF_addr][31:0] : 32'dx;

reg [64:0] BTB [0:BTB_SIZE - 1];      // reg[64] 为有效位, reg[63:32] 为 PC, reg[31:0] 为 predict_PC

always @(*) begin
    if (rst) begin
        BTB_HitF = 1'b0;
    end
    else begin
        /*
        for (integer i = 0; i < BTB_SIZE; i++) begin
            if (PCF == BTB[i][63:32] && BTB[i][64] == 1'b1) begin
                if (we == 1'b1 && PCE == BTB[i][63:32]) begin
                    PredictPC <= BrNPC;
                end
                else begin
                    PredictPC <= BTB[i][31:0];
                end
                BTB_HitF = 1'b1;
                break;
            end
            else begin
                PredictPC <= 32'dx;
                BTB_HitF = 1'b0;
            end
        end
        */
        if (BTB[PCF_addr][64] == 1'b1 && PCF == BTB[PCF_addr][63:32]) begin
            BTB_HitF = 1'b1;
        end
        else begin
            BTB_HitF = 1'b0;
        end
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (integer i = 0; i < BTB_SIZE; i++) begin
            BTB[i] <= 65'd0;
        end
    end
    else begin
        /*
        for (integer i = 0; i < BTB_SIZE; i++) begin
            if (we == 1'b1 && PCE == BTB[i][63:32] && BTB[i][64] == 1'b1) begin
                BTB[i][31:0] <= BrNPC;
                break;
            end
            else if (clear == 1'b1 && PCE == BTB[i][63:32] && BTB[i][64] == 1'b1) begin
                BTB[i][64] <= 1'b0;
            end
            else if (we == 1'b1 && BTB[i][64] == 1'b0) begin
                BTB[i][64] <= 1'b1;
                BTB[i][63:32] <= PCE;
                BTB[i][31:0] <= BrNPC;
                break;
            end
        end
        */
        if (BranchE == 1'b1 && BTB_HitE == 1'b0) begin
            /*
            BTB[PCE_addr][64] <= 1'b1;
            BTB[PCE_addr][63:32] <= PCE;
            BTB[PCE_addr][31:0] <= BrNPC;
            */
            BTB[PCE_addr] <= {1'b1, PCE, BrNPC};
        end
        else if (clear == 1'b1) begin
            BTB[PCE_addr][64] <= 1'b0;
        end
    end
end
    
endmodule