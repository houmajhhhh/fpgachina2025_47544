`timescale 1ns / 1ps

module spi_with_fifo(
input clk50mhz,
input clk60mhz,
input button,

output mosi,
input miso,
output sclk,
output cs,

output [ 7:0] rcv_data,//iic端读出的数据
input [7:0] send_data,//写入FIFO的数据
output    recv_done,
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
//wire W_Done;
wire spi_busy;
wire recv_done_pre;
reg [1:0] cnt;
spi_top spi (
        .Clk        (clk50mhz),
        .Rst_n      (button),
        .data       (txd_data),
        .rx_valid   (rd_en_f),
        .mosi   (mosi),
        .miso   (miso),
        .cs(cs),
        .sclk(sclk),
        .R_Done    (recv_done_pre),
      //  .W_Done    (W_Done),
        .spi_busy    (spi_busy),
        .rddata     (rcv_data)
//        .wrdata     (      ),
//        .device_id_reg(   ),
//        .reg_addr_reg(   ),
       // .current_state(   )
    );
reg rd_en_g;
reg flag;
assign rd_en = (cnt==2'b11) && (!spi_busy) && (!empty1);
assign recv_done=(!flag)&&recv_done_pre;
always @(posedge clk50mhz or negedge button) begin  //毛刺风险？
    if (!button) begin
        flag <= 0;  // 复位时计数器清零
    end else if(recv_done)  flag <= 1;
    else flag <= 0; 
end

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
    ) send_to_spi (
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