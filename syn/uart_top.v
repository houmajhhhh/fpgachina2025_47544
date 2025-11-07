`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/25 19:22:48
// Design Name: 
// Module Name: uart_top
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




module uart_top(
    input clk,
    input reset_n,
    output uart_idle,
    output[7:0] rcv_data,
    input  [7:0] send_data,
    input uart_rx,
    output uart_tx,
    input send_en,
    output recv_done
);

    // 循环队列参数
    parameter FIFO_DEPTH = 8;
    parameter ADDR_WIDTH = 3;
    
    // 内部信号声明

    wire [2:0] baud_set;
    reg send_en_f;
    assign baud_set=4;
    // 实例化接收模块
    uart_byte_rx uart_rx_inst (
        .clk(clk),
        .reset_n(reset_n),
        .baud_set(baud_set),
        .uart_rx(uart_rx),
        .data_byte(rcv_data),
        .rx_done(recv_done)
    );
    
    // 实例化发送模块
    uart_byte_tx uart_tx_inst (
        .clk(clk),
        .reset_n(reset_n),
        .data_byte(send_data),
        .send_en(send_en),
        .baud_set(baud_set),
        .uart_tx(uart_tx),
        .tx_done(  ),
        .uart_state(uart_idle)
    );
    
    
         
      
      
      // 读取要发送的数据
   // always @(posedge clk or negedge reset_n) begin
   //     if (!reset_n) begin
    //        tx_data <= 8'h00;
     //   end else if (send_en) begin
    //        tx_data <= fifo_mem[rd_ptr];
     //   end
   // end
    // 循环队列写操作 - 接收数据存入FIFO
 //   always @(posedge recv_valid or negedge reset_n) begin
  //      if (!reset_n) begin
  //          wr_ptr <= 0;
  //      end else if (!fifo_full) begin
  //          fifo_mem[wr_ptr] <= mem_data;
   //         wr_ptr <= (wr_ptr + 1)%FIFO_DEPTH;
   //         rx_done_flag <= 1'b1;
   //     end else begin
   //         rx_done_flag <= 1'b0;
   //     end
  //  end
    
    // 循环队列读操作 - 从FIFO取数据发送
 //   always @(posedge clk or negedge reset_n) begin
 //       if (!reset_n) begin
 //           rd_ptr <= 0;
 //       end else if (send_en) begin
  //          rd_ptr <= (rd_ptr + 1)%FIFO_DEPTH;
//        end
  //  end
    
    // 发送使能控制
  // always @(posedge clk or negedge reset_n) begin
   //if (!reset_n) begin
   //  send_en <=0;
   //end else if( (!uart_idle) && (!fifo_empty))begin
   // send_en <=1;
    //end
   //else  send_en <=0;
   // end
   //assign send_en = (!uart_idle) && (!fifo_empty);
    

    
    
    // 发送完成标志
   // always @(posedge clk or negedge reset_n) begin
   //     if (!reset_n) begin
   //         tx_done_flag <= 1'b0;
      //  end else begin
   //         tx_done_flag <= tx_done;
   //     end
   // end
    
    // FIFO状态判断
//   assign fifo_empty = (wr_ptr == rd_ptr);
 //   assign fifo_full = ((wr_ptr + 1) == rd_ptr) || ((wr_ptr == (FIFO_DEPTH-1)) && (rd_ptr == 0));

endmodule