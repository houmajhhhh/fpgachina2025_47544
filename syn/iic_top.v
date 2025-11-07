`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/29 14:36:10
// Design Name: 
// Module Name: iic_top
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


module i2c_top (
    input        Clk,
    input        Rst_n,
    input  [7:0] data,
    input        rx_valid,
    
    output       i2c_sclk,
    inout        i2c_sdat,
    output       R_Done,
    output       W_Done,
    output  reg     iic_busy,
    output [7:0] rddata

);

    // 内部信号声明
    
    reg  [7:0]  wrdata;
    reg  [7:0]  device_id_reg;
    reg  [15:0] reg_addr_reg;
    reg  [2:0]  current_state;
    reg  [1:0]  byte_cnt;
    //reg  [7:0]  cmd_buffer [0:2];
    reg         wrreg_req, rdreg_req;
    reg  [15:0] addr;
  //  reg         addr_mode;
   
    
    // 状态机定义
    localparam 
        IDLE      = 3'b000,
        CMD_W     = 3'b001,
        CMD_R     = 3'b010,
        CMD_I     = 3'b011;
        //CMD_A     = 3'b100;
    
    reg [2:0] next_state;
    
    // 字节计数器逻辑
    always @(posedge Clk or negedge Rst_n) begin   //计数器存疑  0  》1》2》0
        if (!Rst_n) begin
            byte_cnt <= 2'b00;
        end else if (rx_valid) begin
            if (byte_cnt == 2'b11)
                byte_cnt <= 2'b00;
            else
                byte_cnt <= byte_cnt + 1'b1;
        end
    end
    
    // 命令缓冲区存储
//    always @(posedge Clk or negedge Rst_n) begin
//        if (!Rst_n) begin
//            cmd_buffer[0] <= 8'h00;
//            cmd_buffer[1] <= 8'h00;
//            cmd_buffer[2] <= 8'h00;
//        end else if (rx_valid) begin
//            cmd_buffer[byte_cnt] <= data;
//        end
//    end
    
    // 状态机控制逻辑
    always @(posedge Clk or negedge Rst_n) begin
        if (!Rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    // 状态转移逻辑
    always @(posedge Clk ) begin
        case (current_state)
            IDLE: 
                if ((rx_valid) && (byte_cnt == 2'b00)) begin    //00》01
                    case (data)
                        8'h57: next_state <= CMD_W; // 'W'
                        8'h52: next_state <= CMD_R; // 'R'
                        8'h49: next_state <= CMD_I; // 'I'
                      //  8'h41: next_state = CMD_A; // 'A'
                        default: next_state <= IDLE;
                    endcase
                end else begin
                    next_state = IDLE;
                end
                
            CMD_W: 
                if (rx_valid && byte_cnt == 2'b11)  ///10》00
                    next_state = IDLE;
                else
                    next_state = CMD_W;
                    
            CMD_R: 
                if (rx_valid && byte_cnt == 2'b11)
                    next_state = IDLE;
                else
                    next_state = CMD_R;
                    
            CMD_I: 
                if (rx_valid && byte_cnt == 2'b11)
                    next_state = IDLE;
                else
                    next_state = CMD_I;
                    
//            CMD_A: 
//                if (rx_valid && byte_cnt == 2'b00)
//                    next_state = IDLE;
//                else
//                    next_state = CMD_A;
                    
            default: next_state = IDLE;
        endcase
    end
    
    // 寄存器地址模式设置
//    always @(posedge Clk or negedge Rst_n) begin
//        if (!Rst_n) begin
//            addr_mode <= 1'b0;
//        end else if (current_state == CMD_A && rx_valid && byte_cnt == 2'b00) begin
//            addr_mode <= data[0]; // 地址模式位
//        end
//    end
    
    // 设备地址寄存器设置
    always @(posedge Clk or negedge Rst_n) begin
        if (!Rst_n) begin
            device_id_reg <= 8'h00; // 默认设备地址
        end else if (current_state == CMD_I && rx_valid && byte_cnt == 2'b01) begin
            device_id_reg <= data;
        end
    end
    
    // 寄存器地址寄存器设置
    always @(posedge Clk or negedge Rst_n) begin
        if (!Rst_n) begin
            reg_addr_reg <= 16'h0000;
        end else if ((current_state == CMD_W||current_state == CMD_R) && rx_valid) begin
            case (byte_cnt)
                2'b01: reg_addr_reg[15:8] <= data;
                2'b10: reg_addr_reg[7:0]  <= data;
                default: ;
            endcase
        end
    end
    
    // I2C控制请求生成
    always @(posedge Clk or negedge Rst_n) begin
        if (!Rst_n) begin
            wrreg_req <= 1'b0;
            rdreg_req <= 1'b0;
            addr      <= 16'h0000;
            wrdata    <= 8'h00;
            iic_busy <= 1'b0;
        end else if (current_state == CMD_W && rx_valid && byte_cnt == 2'b11) begin
                wrreg_req <= 1'b1;
              //  addr      <= reg_addr_reg;
                wrdata    <= data;
                iic_busy <=1;
        end else if (current_state == CMD_R && rx_valid && byte_cnt == 2'b11) begin
                rdreg_req <= 1'b1;
                iic_busy <=1;
              //  addr      <= reg_addr_reg;
        end  else if ((iic_busy==1)&&(R_Done==1||W_Done==1)) begin
         wrreg_req <= 1'b0;
         rdreg_req <= 1'b0;   
         iic_busy <= 1'b0;
        end else begin
        wrreg_req <= 1'b0;
        rdreg_req <= 1'b0; 
         end
    end
    
//      always @(posedge Clk or negedge Rst_n) begin
//        if (!Rst_n) begin
//            iic_busy <= 1'b0;
//        end else if ((iic_busy==1)&&(R_Done==1||W_Done==1))
//           iic_busy <= 1'b0;
//        end
        
    // 实例化I2C控制器
    i2c_control i2c_control_inst (
        .Clk        (Clk),
        .Rst_n      (Rst_n),
        .wrreg_req  (wrreg_req),
        .rdreg_req  (rdreg_req),
        .addr       (reg_addr_reg),
        .addr_mode  (0),
        .wrdata     (wrdata),
        .rddata     (rddata),
        .device_id  (device_id_reg),
        .R_Done    (R_Done),
        .W_Done    (W_Done),
        .ack        (),
        .i2c_sclk   (i2c_sclk),
        .i2c_sdat   (i2c_sdat)
    );

endmodule