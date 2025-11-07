`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/31 14:23:52
// Design Name: 
// Module Name: iic_with_fifo
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


`timescale 1ns / 1ps

module iic_with_fifo(
input clk50mhz,
input clk60mhz,
input button,
output i2c_sclk,
inout i2c_sdat,
output [ 7:0] rcv_data,//iic端读出的数据
input [7:0] send_data,//写入FIFO的数据
output      recv_done,
input recv_valid
//output rd_en,
//output reg rd_en_f,
//output  [7:0] txd_data,
//output  [7:0] wrdata
    );
    
wire full1;
wire empty1;
wire rd_en;
reg rd_en_f;
wire [7:0] txd_data;
wire R_Done;
wire W_Done;
wire iic_busy;
reg [1:0] cnt;
i2c_top iic (
        .Clk        (clk50mhz),
        .Rst_n      (button),
        .data       (txd_data),
        .rx_valid   (rd_en_f),
        .i2c_sclk   (i2c_sclk),
        .i2c_sdat   (i2c_sdat),
        .R_Done    (recv_done),
        .W_Done    (W_Done),
        .iic_busy    (iic_busy),
        .rddata     (rcv_data)
        //.wrdata     (      ),
        //.device_id_reg(   ),
       // .reg_addr_reg(   ),
       // .current_state(   )
    );
reg rd_en_g;
assign rd_en = (cnt==2'b11) && (!iic_busy) && (!empty1);

always @(posedge clk50mhz or negedge button) begin
    if (!button) begin
        cnt <= 2'b00;  // 复位时计数器清零
    end else if (cnt==2'b11)begin
        cnt <= 2'b00;  
    end else cnt <= cnt+1;  
end

always @(posedge clk50mhz or negedge button) begin
      if (!button)  rd_en_f <= 0;
      else rd_en_f<=rd_en_g;
end   

always @(posedge clk50mhz or negedge button) begin
      if (!button)  rd_en_g <= 0;
      else rd_en_g<=rd_en;
end        
async_fifo #(
        .DATA_WIDTH(8),       // 数据位宽为8
        .ADDR_WIDTH(4)        // 地址位宽为4（深度16）
    ) send_to_iic (
        // 写端口（clk_wr时钟域）
        .wr_clk(clk60mhz),
        .wr_rst_n(button),
        .wr_en(recv_valid & ~full1), // 仅当FIFO未满时写入
        .wr_data(send_data),
        
        // 读端口（clk_rd时钟域）
        .rd_clk(clk50mhz),
        .rd_rst_n(button),
        .rd_en(rd_en),
        .rd_data(txd_data),
        
        // 状态标志
        .full(full1),
        .empty(empty1)
    );
endmodule