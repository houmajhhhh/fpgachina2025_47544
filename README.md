# USB Serial Device FPGA Implementation

基于Xilinx Zynq BX71开发板的USB CDC串行设备FPGA实现，支持UART/SPI/I2C多种通信协议。

## 项目特性

- **USB CDC设备**：模拟USB虚拟串口，主机即插即用
- **多协议支持**：UART、SPI、I2C三种外设通信接口可选
- **异步FIFO**：跨时钟域安全数据传输（50MHz/60MHz）
- **调试支持**：独立UART输出USB核心调试信息
- **紧凑设计**：仅使用FPGA逻辑部分，资源占用低

## 硬件需求

| 项目 | 规格 |
|------|------|
| 开发板 | Xilinx Zynq BX71 |
| SoC | Zynq-7010 |
| FPGA资源 | LUT 17600, FF 35200, BRAM 60×M36K |
| 时钟 | 50MHz(主时钟)、60MHz(USB PHY) |
| 接口 | USB OTG(MicroUSB)、PMOD扩展 |

## 项目结构
```
├── fpga_top_usb_serial.v      # 顶层模块
├── usb_serial_top.v            # USB CDC核心
├── uart_with_fifo.v            # UART通信模块
├── spi_with_fifo.v             # SPI通信模块
├── iic_with_fifo.v             # I2C通信模块
├── async_fifo.v                # 异步FIFO模块
└── constraints/
    └── pinout.xdc              # IO约束文件
```

## 关键模块介绍

### 顶层模块（fpga_top_usb_serial.v）

主要功能：
- 时钟生成与管理
- USB PHY接口
- 多协议端口选择器
- 异步FIFO数据路由
```verilog
module fpga_top_usb_serial (
    input wire clk50mhz,        // 50MHz主时钟
    input wire clk60mhz,        // 60MHz USB时钟
    output wire led,            // USB连接状态指示
    // USB信号
    output wire usb_dp_pull,    // USB D+上拉（1.5kΩ）
    inout usb_dp, usb_dn,       // USB差分信号
    // 外设接口
    input [1:0] cmd,            // 端口选择：00=UART, 01=I2C, 10=SPI
    input button,               // 复位按键
    // UART接口
    input rxd, output txd,
    // SPI接口
    output mosi, input miso, output sclk, output cs,
    // I2C接口
    output i2c_sclk, inout i2c_sdat
);
```

### 端口选择逻辑
```verilog
localparam uart=2'b00, iic=2'b01, spi=2'b10;

always@(*) begin
    if(cmd==uart) begin
        rcv_data = rcv_data_uart;
        recv_done = recv_done_uart;
        send_data_uart = recv_data;
        recv_valid_uart = recv_valid;
    end
    else if(cmd==iic) begin
        // I2C路由...
    end
    else if(cmd==spi) begin
        // SPI路由...
    end
end
```

### 异步FIFO跨域通信
```verilog
async_fifo #(
    .DATA_WIDTH(8),    // 8位数据
    .ADDR_WIDTH(4)     // 16深度
) sender_tousb (
    .wr_clk(clk50mhz), .wr_rst_n(button),
    .wr_en(recv_done && (!full2)),
    .wr_data(rcv_data),
    .rd_clk(clk60mhz), .rd_rst_n(button),
    .rd_en(rd_en2),
    .rd_data(tousb_data),
    .full(full2), .empty(empty2)
);
```

## 引脚分配

| 功能 | PMOD引脚 | 说明 |
|------|---------|------|
| UART_TXD | PMOD1_0 | 传输 |
| UART_RXD | PMOD1_1 | 接收 |
| SPI_SCK | PMOD1_2 | 时钟 |
| SPI_MOSI | PMOD1_3 | 主输出 |
| SPI_MISO | PMOD1_4 | 主输入 |
| SPI_CS | PMOD1_5 | 片选 |
| I2C_SCL | PMOD1_6 | I2C时钟 |
| I2C_SDA | PMOD1_7 | I2C数据(需4.7kΩ上拉) |

## 使用说明

### 编译与烧录

1. 在Vivado中创建工程，添加所有.v文件
2. 添加约束文件(XDC)，指定引脚位置
3. 生成比特流文件
4. 使用Vivado/Vitis烧录至FPGA

### 测试

1. 连接USB数据线至开发板USB OTG接口
2. 主机识别为虚拟COM口
3. 使用串口工具(波特率115200)通信
4. 可选：连接外设(UART/SPI/I2C)至PMOD扩展口

### 调试

如需查看USB核心调试信息，将`uart_tx`信号连接到主机串口(115200,8,n,1)

## 技术细节

- **USB协议**：全速USB 2.0(480Mbps逻辑速率，12Mbps实际速率)
- **时钟域**：60MHz(USB) → 50MHz(主逻辑)，通过async_fifo隔离
- **FIFO深度**：16字节(异步双口RAM)
- **IO标准**：LVCMOS33, 驱动强度12mA



## 联系方式

13602019812
