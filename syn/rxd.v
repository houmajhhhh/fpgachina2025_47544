`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/22 16:15:54
// Design Name: 
// Module Name: rxd
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

module uart_byte_rx(
	clk,
	reset_n,

	baud_set,
	uart_rx,

	data_byte,
	rx_done
);
	wire reset=~reset_n;

	input clk;    //模块全局时钟输入，50M
	input reset_n;   //复位信号输入，低有效

	input [2:0]baud_set;  //波特率设置
	input uart_rx;   //串口输入信号
	
	output [7:0]data_byte; //串口接收的1byte数据
	output rx_done;   //1byte数据接收完成标志
	
	reg [7:0]data_byte;
	reg rx_done;
	reg uart_rx_sync1;   //同步寄存器
	reg uart_rx_sync2;   //同步寄存器

	reg uart_rx_reg1;    //数据寄存器
	reg uart_rx_reg2;    //数据寄存器

	reg [15:0]bps_DR;    //分频计数最大值	
	reg [15:0]div_cnt;   //分频计数器
	reg bps_clk;   //波特率时钟	
	reg [7:0] bps_cnt;   //波特率时钟计数器	
	reg uart_state;//接收数据状态

	wire uart_rx_nedge;  

	reg [2:0]START_BIT;
	reg [2:0]STOP_BIT;
	reg [2:0]data_byte_pre [7:0];

	//同步串行输入信号，消除亚稳态
	always@(posedge clk or posedge reset)
	if(reset)begin
		uart_rx_sync1 <= 1'b0;
		uart_rx_sync2 <= 1'b0;	
	end
	else begin
		uart_rx_sync1 <= uart_rx;
		uart_rx_sync2 <= uart_rx_sync1;	
	end
	
	//数据寄存器
	always@(posedge clk or posedge reset)
	if(reset)begin
		uart_rx_reg1 <= 1'b0;
		uart_rx_reg2 <= 1'b0;	
	end
	else begin
		uart_rx_reg1 <= uart_rx_sync2;
		uart_rx_reg2 <= uart_rx_reg1;	
	end
	
  //下降沿检测
	assign uart_rx_nedge = !uart_rx_reg1 & uart_rx_reg2;
	
	always@(posedge clk or posedge reset)
	if(reset)
		bps_DR <= 16'd324;
	else begin
		case(baud_set)
			0:bps_DR <= 16'd324;
			1:bps_DR <= 16'd162;
			2:bps_DR <= 16'd80;
			3:bps_DR <= 16'd53;
			4:bps_DR <= 16'd26;   //26
			default:bps_DR <= 16'd324;			
		endcase
	end
	
	//counter
	always@(posedge clk or posedge reset)
	if(reset)
		div_cnt <= 16'd0;
	else if(uart_state)begin
		if(div_cnt == bps_DR)
			div_cnt <= 16'd0;
		else
			div_cnt <= div_cnt + 1'b1;
	end
	else
		div_cnt <= 16'd0;
		
	// bps_clk gen
	always@(posedge clk or posedge reset)
	if(reset)
		bps_clk <= 1'b0;
	else if(div_cnt == 16'd1)
		bps_clk <= 1'b1;
	else
		bps_clk <= 1'b0;
	
	//bps counter
	always@(posedge clk or posedge reset)
	if(reset)	
		bps_cnt <= 8'd0;
	else if(bps_cnt == 8'd159 | (bps_cnt == 8'd12 && (START_BIT > 2)))
		bps_cnt <= 8'd0;
	else if(bps_clk)
		bps_cnt <= bps_cnt + 1'b1;
	else
		bps_cnt <= bps_cnt;

	always@(posedge clk or posedge reset)
	if(reset)
		rx_done <= 1'b0;
	else if(bps_cnt == 8'd159)
		rx_done <= 1'b1;
	else
		rx_done <= 1'b0;	
		
	always@(posedge clk or posedge reset)
	if(reset)begin
		START_BIT <= 3'd0;
		data_byte_pre[0] <= 3'd0;
		data_byte_pre[1] <= 3'd0;
		data_byte_pre[2] <= 3'd0;
		data_byte_pre[3] <= 3'd0;
		data_byte_pre[4] <= 3'd0;
		data_byte_pre[5] <= 3'd0;
		data_byte_pre[6] <= 3'd0;
		data_byte_pre[7] <= 3'd0;
		STOP_BIT <= 3'd0;
	end
	else if(bps_clk)begin
		case(bps_cnt)
			0:begin
        START_BIT <= 3'd0;
        data_byte_pre[0] <= 3'd0;
        data_byte_pre[1] <= 3'd0;
        data_byte_pre[2] <= 3'd0;
        data_byte_pre[3] <= 3'd0;
        data_byte_pre[4] <= 3'd0;
        data_byte_pre[5] <= 3'd0;
        data_byte_pre[6] <= 3'd0;
        data_byte_pre[7] <= 3'd0;
        STOP_BIT <= 3'd0;			
      end
			6 ,7 ,8 ,9 ,10,11:START_BIT <= START_BIT + uart_rx_sync2;
			22,23,24,25,26,27:data_byte_pre[0] <= data_byte_pre[0] + uart_rx_sync2;
			38,39,40,41,42,43:data_byte_pre[1] <= data_byte_pre[1] + uart_rx_sync2;
			54,55,56,57,58,59:data_byte_pre[2] <= data_byte_pre[2] + uart_rx_sync2;
			70,71,72,73,74,75:data_byte_pre[3] <= data_byte_pre[3] + uart_rx_sync2;
			86,87,88,89,90,91:data_byte_pre[4] <= data_byte_pre[4] + uart_rx_sync2;
			102,103,104,105,106,107:data_byte_pre[5] <= data_byte_pre[5] + uart_rx_sync2;
			118,119,120,121,122,123:data_byte_pre[6] <= data_byte_pre[6] + uart_rx_sync2;
			134,135,136,137,138,139:data_byte_pre[7] <= data_byte_pre[7] + uart_rx_sync2;
			150,151,152,153,154,155:STOP_BIT <= STOP_BIT + uart_rx_sync2;
			default:
      begin
        START_BIT <= START_BIT;
        data_byte_pre[0] <= data_byte_pre[0];
        data_byte_pre[1] <= data_byte_pre[1];
        data_byte_pre[2] <= data_byte_pre[2];
        data_byte_pre[3] <= data_byte_pre[3];
        data_byte_pre[4] <= data_byte_pre[4];
        data_byte_pre[5] <= data_byte_pre[5];
        data_byte_pre[6] <= data_byte_pre[6];
        data_byte_pre[7] <= data_byte_pre[7];
        STOP_BIT <= STOP_BIT;
      end
		endcase
	end

	always@(posedge clk or posedge reset)
	if(reset)
		data_byte <= 8'd0;
	else if(bps_cnt == 8'd159)begin
		data_byte[0] <= data_byte_pre[0][2];
		data_byte[1] <= data_byte_pre[1][2];
		data_byte[2] <= data_byte_pre[2][2];
		data_byte[3] <= data_byte_pre[3][2];
		data_byte[4] <= data_byte_pre[4][2];
		data_byte[5] <= data_byte_pre[5][2];
		data_byte[6] <= data_byte_pre[6][2];
		data_byte[7] <= data_byte_pre[7][2];
	end	
	
	always@(posedge clk or posedge reset)
	if(reset)
		uart_state <= 1'b0;
	else if(uart_rx_nedge)
		uart_state <= 1'b1;
	else if(rx_done || (bps_cnt == 8'd12 && (START_BIT > 2)) || (bps_cnt == 8'd155 && (STOP_BIT < 3)))
		uart_state <= 1'b0;
	else
		uart_state <= uart_state;		

endmodule