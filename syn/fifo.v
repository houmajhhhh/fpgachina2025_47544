`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/24 19:39:10
// Design Name: 
// Module Name: fifo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module async_fifo #(
    parameter DATA_WIDTH = 8,      // 数据位宽
    parameter ADDR_WIDTH = 4       // 地址位宽，2^4=16深度
)(
    // 写端口（写时钟域）
    input  wire              wr_clk,     // 写时钟
    input  wire              wr_rst_n,   // 写复位（低有效）
    input  wire              wr_en,      // 写使能
    input  wire [DATA_WIDTH-1:0] wr_data, // 写入数据
    
    // 读端口（读时钟域）
    input  wire              rd_clk,     // 读时钟
    input  wire              rd_rst_n,   // 读复位（低有效）
    input  wire              rd_en,      // 读使能
    output reg  [DATA_WIDTH-1:0] rd_data, // 读出数据
    
    // 状态标志
    output wire             full,       // FIFO满标志（写时钟域）
    output wire             empty       // FIFO空标志（读时钟域）
);

    // 内部信号声明
    reg [ADDR_WIDTH:0] wr_ptr_bin;      // 写指针（二进制）
    reg [ADDR_WIDTH:0] rd_ptr_bin;      // 读指针（二进制）
    reg [ADDR_WIDTH:0] wr_ptr_gray;     // 写指针（格雷码）
    reg [ADDR_WIDTH:0] rd_ptr_gray;     // 读指针（格雷码）
    
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync1; // 同步到写时钟域的读指针（第一级）
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync2; // 同步到写时钟域的读指针（第二级）
    
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync1; // 同步到读时钟域的写指针（第一级）
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync2; // 同步到读时钟域的写指针（第二级）
    
    // 双端口RAM存储数据
    reg [DATA_WIDTH-1:0] fifo_mem [0:(1<<ADDR_WIDTH)-1];
    
    // 二进制转格雷码
    function [ADDR_WIDTH:0] bin_to_gray(input [ADDR_WIDTH:0] bin);
        bin_to_gray = bin ^ (bin >> 1);
    endfunction
    
    // 格雷码转二进制
    function [ADDR_WIDTH:0] gray_to_bin(input [ADDR_WIDTH:0] gray);
        integer i;
        reg [ADDR_WIDTH:0] bin;
        begin
            bin = gray;
            for (i = 1; i <= ADDR_WIDTH; i = i + 1)
                bin = bin ^ (gray >> i);
            gray_to_bin = bin;
        end
    endfunction
    
    // 写操作
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en && !full) begin
            fifo_mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= wr_data;
            wr_ptr_bin <= wr_ptr_bin + 1;
            wr_ptr_gray <= bin_to_gray(wr_ptr_bin + 1);
        end
    end
    
    // 读操作
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin <= 0;
            rd_ptr_gray <= 0;
            rd_data <= 0;
        end else if (rd_en && !empty) begin
            rd_data <= fifo_mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
            rd_ptr_bin <= rd_ptr_bin + 1;
            rd_ptr_gray <= bin_to_gray(rd_ptr_bin + 1);
        end
    end
    
    // 读指针同步到写时钟域（用于判断满状态）
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end
    
    // 写指针同步到读时钟域（用于判断空状态）
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end
    
    // 满状态判断（写时钟域）
    assign full = (wr_ptr_gray == {~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1], 
                                    rd_ptr_gray_sync2[ADDR_WIDTH-2:0]});
    
    // 空状态判断（读时钟域）
    assign empty = (rd_ptr_gray == wr_ptr_gray_sync2);

endmodule
