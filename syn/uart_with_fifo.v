`timescale 1ns / 1ps

module uart_with_fifo(
input clk50mhz,
input clk60mhz,
input button,
input rxd,
output txd,
output [ 7:0] rcv_data,//uart端收到的数据
input [7:0] send_data,//需要uart发送的数据
output      recv_done,
output uart_idle,
input recv_valid


    );
    
wire full1;
wire empty1;
wire rd_en;
reg rd_en_f;
wire [7:0] txd_data;

uart_top  uart(
.clk(clk50mhz),
.reset_n(button),
.uart_rx(rxd),
.uart_tx(txd),
.send_en(rd_en_f),
.recv_done(recv_done),
.rcv_data(rcv_data),
.send_data(txd_data),
.uart_idle(uart_idle)
);

assign rd_en = (!rd_en_f) && (!uart_idle) && (!empty1);

always @(posedge clk50mhz or negedge button) begin
      if (!button)  rd_en_f <= 0;
      else rd_en_f<=rd_en;
end   
      
async_fifo #(
        .DATA_WIDTH(8),       // 数据位宽为8
        .ADDR_WIDTH(4)        // 地址位宽为4（深度16）
    ) send_to_uart (
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
