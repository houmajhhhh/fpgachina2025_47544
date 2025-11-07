`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/12 13:59:35
// Design Name: 
// Module Name: spi_top
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


module spi_top (
    input        Clk,
    input        Rst_n,
    input  [7:0] data,
    input        rx_valid,
    
    output       sclk,
    input        miso,
    output         mosi,
    output       cs ,

    output       R_Done,
    output  reg     spi_busy,
    output [7:0] rddata

   
);
// 内部信号声明
   reg  [2:0]  current_state;
   reg [2:0]  last_state;
   wire R_Done_pre;
    
    reg    [23:0]flash_addr;
    reg     [3:0] cmd;
    reg  [2:0]  byte_cnt;
    reg  [23:0] addr;
    wire[3:0]state;
    wire Done_Sig;
    reg [7:0] wrdata;
    // 状态机定义
    localparam 
        IDLE      = 3'b000,
        CMD_W     = 3'b001,
        CMD_R     = 3'b010,
        CMD_I     = 3'b011,
        CMD_S     = 3'b100;
        //CMD_A     = 3'b100;
    
    reg [2:0] next_state;
    assign R_Done=(last_state==CMD_R||last_state==CMD_I)?R_Done_pre:0;
    // 字节计数器逻辑
    always @(posedge Clk or negedge Rst_n) begin   //计数器存疑  0  》1》2》0
        if (!Rst_n) begin
            byte_cnt <= 3'b000;
        end else if (rx_valid) begin
            if (byte_cnt == 3'b100)
                byte_cnt <= 3'b000;
            else
                byte_cnt <= byte_cnt + 1'b1;
        end
    end
    

    
    // 状态机控制逻辑
    always @(posedge Clk or negedge Rst_n) begin
        if (!Rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
     always @(posedge Clk or negedge Rst_n) begin
        if (!Rst_n) begin
            last_state <= IDLE;
        end else if(current_state!=IDLE)begin
            last_state <= current_state;
        end
    end
    
    // 状态转移逻辑
    always @(posedge Clk ) begin
        case (current_state)
            IDLE: 
                if ((rx_valid) && (byte_cnt == 3'b000)) begin    //00》01
                    case (data)
                        8'h57: next_state <= CMD_W; // 'W'
                        8'h52: next_state <= CMD_R; // 'R'
                        8'h49: next_state <= CMD_I; // 'I'
                        8'h53: next_state <= CMD_S; // 'I'
                      //  8'h41: next_state = CMD_A; // 'A'
                        default: next_state <= IDLE;
                    endcase
                end else begin
                    next_state = IDLE;
                end
                
            CMD_W: 
                if (rx_valid && byte_cnt == 3'b100)  ///10》00
                    next_state = IDLE;
                else
                    next_state = CMD_W;
                    
            CMD_R: 
                if (rx_valid && byte_cnt == 3'b100)
                    next_state = IDLE;
                else
                    next_state = CMD_R;
                    
            CMD_I: 
                if (rx_valid && byte_cnt == 3'b100)
                    next_state = IDLE;
                else
                    next_state = CMD_I;
             CMD_S: 
                if (rx_valid && byte_cnt == 3'b100)
                    next_state = IDLE;
                else
                    next_state = CMD_S;  
                    
//            CMD_A: 
//                if (rx_valid && byte_cnt == 2'b00)
//                    next_state = IDLE;
//                else
//                    next_state = CMD_A;
                    
            default: next_state = IDLE;
        endcase
    end
    

    
    // 寄存器地址寄存器设置
    always @(posedge Clk or negedge Rst_n) begin
        if (!Rst_n) begin
            flash_addr <= 24'h000000;
        end else if ((current_state == CMD_W||current_state == CMD_R||current_state == CMD_S) && rx_valid) begin
            case (byte_cnt)
                3'b001: flash_addr[23:16] <= data;
                3'b010: flash_addr[15:8]  <= data;
                3'b011: flash_addr[7:0]  <= data;
                default: ;
            endcase
        end //else flash_addr <= 24'h000000;
    end
    
    // I2C控制请求生成
    always @(posedge Clk or negedge Rst_n) begin
        if (!Rst_n) begin
            cmd<=4'b0000;
            addr      <= 24'h000000;
            wrdata    <= 8'hff;
            spi_busy <= 1'b0;
        end else if (current_state == CMD_W && rx_valid && byte_cnt == 3'b100) begin
                cmd<=4'b0010;
                addr      <= flash_addr;
                wrdata    <= data;
                spi_busy <=1;
        end else if (current_state == CMD_R && rx_valid && byte_cnt == 3'b100) begin
                cmd<=4'b0100;
                spi_busy <=1;
                addr      <= flash_addr;
        end else if (current_state == CMD_I && rx_valid && byte_cnt == 3'b100) begin
                cmd<=4'b0001;
                spi_busy <=1;
                addr      <= 24'h000000;
        end else if (current_state == CMD_S && rx_valid && byte_cnt == 3'b100) begin
                cmd<=4'b1000;
                spi_busy <=1;
                addr      <= flash_addr;
        end  else if(Done_Sig) begin
         cmd<=4'b0000; 
        end else if ((spi_busy==1)&&(state==4'b0000))begin
           spi_busy <= 1'b0;
        end
    end
    
//      always @(posedge Clk or negedge Rst_n) begin
//        if (!Rst_n) begin
//            spi_busy <= 1'b0;
//        end else if ((spi_busy==1)&&(state==4'b0000))
//           spi_busy <= 1'b0;
//        end
        
    // 实例化I2C控制器
    flash flash_inst (
        .CLK(Clk),
        .RSTn(Rst_n),
        .flash_clk(sclk),
        .flash_cs(cs),
        .flash_datain(mosi),
        .Done_Sig(   Done_Sig ),
        .flash_dataout(miso),
        .mydata_o(rddata),
        .myvalid_o(R_Done_pre),
        .flash_addr(addr),
        .state(state),
        .wrdata(wrdata),
        .cmd(cmd)
    );

endmodule
