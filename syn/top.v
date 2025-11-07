module fpga_top_usb_serial (
    input  wire        clk50mhz,     // connect to a 50MHz oscillator
    input  wire        clk60mhz, 
    output wire        led,          // 1: USB connected , 0: USB disconnected
    // USB signals
    output wire        usb_dp_pull,  // connect to USB D+ by an 1.5k resistor
    inout              usb_dp,       // connect to USB D+
    inout              usb_dn,       // connect to USB D-
    // debug output info, only for USB developers, can be ignored for normally use
    output wire        uart_tx  ,     // If you want to see the debug info of USB device core, please connect this UART signal to host-PC (UART format: 115200,8,n,1), otherwise you can ignore this signal.
    input button,   //复位按键
    input [1:0]  cmd, 
    input rxd,
    output txd,
    output mosi,
    input miso,
    output sclk,
    output cs,
    output i2c_sclk,
    inout i2c_sdat
);
//wire[1:0]  cmd;
//assign cmd=2'b01; 
//------------------------时钟生成-------------------------------------------------------------------------------
//wire       clk60mhz;
//wire       clk_locked;
//clk_wiz_0 u_altpll (
//    .clk_in1       ( clk50mhz    ),
//    .clk_out1       (  clk60mhz ),
//    .locked      ( clk_locked  ),
//    .resetn(1'b1));
//defparam u_altpll.bandwidth_type = "AUTO",    u_altpll.clk0_divide_by = 5,    u_altpll.clk0_duty_cycle = 50,    u_altpll.clk0_multiply_by = 6,    u_altpll.clk0_phase_shift = "0",    u_altpll.compensate_clock = "CLK0",    u_altpll.inclk0_input_frequency = 20000,    u_altpll.intended_device_family = "Cyclone IV E",    u_altpll.lpm_hint = "CBX_MODULE_PREFIX=pll",    u_altpll.lpm_type = "altpll",    u_altpll.operation_mode = "NORMAL",    u_altpll.pll_type = "AUTO",    u_altpll.port_activeclock = "PORT_UNUSED",    u_altpll.port_areset = "PORT_UNUSED",    u_altpll.port_clkbad0 = "PORT_UNUSED",    u_altpll.port_clkbad1 = "PORT_UNUSED",    u_altpll.port_clkloss = "PORT_UNUSED",    u_altpll.port_clkswitch = "PORT_UNUSED",    u_altpll.port_configupdate = "PORT_UNUSED",    u_altpll.port_fbin = "PORT_UNUSED",    u_altpll.port_inclk0 = "PORT_USED",    u_altpll.port_inclk1 = "PORT_UNUSED",    u_altpll.port_locked = "PORT_USED",    u_altpll.port_pfdena = "PORT_UNUSED",    u_altpll.port_phasecounterselect = "PORT_UNUSED",    u_altpll.port_phasedone = "PORT_UNUSED",    u_altpll.port_phasestep = "PORT_UNUSED",    u_altpll.port_phaseupdown = "PORT_UNUSED",    u_altpll.port_pllena = "PORT_UNUSED",    u_altpll.port_scanaclr = "PORT_UNUSED",    u_altpll.port_scanclk = "PORT_UNUSED",    u_altpll.port_scanclkena = "PORT_UNUSED",    u_altpll.port_scandata = "PORT_UNUSED",    u_altpll.port_scandataout = "PORT_UNUSED",    u_altpll.port_scandone = "PORT_UNUSED",    u_altpll.port_scanread = "PORT_UNUSED",    u_altpll.port_scanwrite = "PORT_UNUSED",    u_altpll.port_clk0 = "PORT_USED",    u_altpll.port_clk1 = "PORT_UNUSED",    u_altpll.port_clk2 = "PORT_UNUSED",    u_altpll.port_clk3 = "PORT_UNUSED",    u_altpll.port_clk4 = "PORT_UNUSED",    u_altpll.port_clk5 = "PORT_UNUSED",    u_altpll.port_clkena0 = "PORT_UNUSED",    u_altpll.port_clkena1 = "PORT_UNUSED",    u_altpll.port_clkena2 = "PORT_UNUSED",    u_altpll.port_clkena3 = "PORT_UNUSED",    u_altpll.port_clkena4 = "PORT_UNUSED",    u_altpll.port_clkena5 = "PORT_UNUSED",    u_altpll.port_extclk0 = "PORT_UNUSED",    u_altpll.port_extclk1 = "PORT_UNUSED",    u_altpll.port_extclk2 = "PORT_UNUSED",    u_altpll.port_extclk3 = "PORT_UNUSED",    u_altpll.self_reset_on_loss_lock = "OFF",    u_altpll.width_clock = 5;
//-------------------------------------------------------------------------------------------------------


wire [ 7:0] recv_data;//usb端收到的数据
wire [7:0] tousb_data;//给usb发送的数据
wire        recv_valid;//usb接收一字节数据后置1   //8.01记得给每个模块加单独的信号

reg [ 7:0] rcv_data;//被选择端收到的数据
reg      recv_done;//被选择端接收一字节数据后置1



    
//-------------------------uart模块-------------------------------------------------------------------------------

wire [ 7:0] rcv_data_uart;//uart端收到的数据
reg [7:0] send_data_uart;//需要uart发送的数据
wire      recv_done_uart;
reg        recv_valid_uart;
uart_with_fifo   uart_with_fifo(
.clk50mhz(clk50mhz),
.clk60mhz(clk60mhz),
.button(button),
.rxd(rxd),
.txd(txd),
.rcv_data(rcv_data_uart),//uart端收到的数据
.send_data(send_data_uart),//需要uart发送的数据
.recv_done(recv_done_uart),
.uart_idle(    ),
.recv_valid(recv_valid_uart)
    );
    
 //-------------------------iic模块-------------------------------------------------------------------------------
 wire [ 7:0] rcv_data_iic;//iic端收到的数据
reg [7:0] send_data_iic;//需要iic发送的数据
wire      recv_done_iic;
reg        recv_valid_iic;
iic_with_fifo   iic_uut(
.clk50mhz(clk50mhz),
.clk60mhz(clk60mhz),
.button(button),
.i2c_sclk(i2c_sclk),
.i2c_sdat(i2c_sdat),
.rcv_data(rcv_data_iic),//iic端读出的数据
.send_data(send_data_iic),//写入FIFO的数据
.recv_done(recv_done_iic),
.recv_valid(recv_valid_iic)
//.rd_en(rd_en),
//.rd_en_f(rd_en_f),
//.wrdata(wrdata),
//.txd_data(txd_data)


    ); 
    
     //-------------------------spi模块-------------------------------------------------------------------------------
wire [ 7:0] rcv_data_spi;//iic端收到的数据
reg [7:0] send_data_spi;//需要iic发送的数据
wire      recv_done_spi;
reg        recv_valid_spi;
spi_with_fifo   spi_uut(
.clk50mhz(clk50mhz),
.clk60mhz(clk60mhz),
.button(button),
.mosi(mosi),
.miso(miso),
.cs(cs),
.sclk(sclk),
.rcv_data(rcv_data_spi),//iic端读出的数据
.send_data(send_data_spi),//写入FIFO的数据
.recv_done(recv_done_spi),
.recv_valid(recv_valid_spi)
//.rd_en(rd_en),
//.rd_en_f(rd_en_f),
//.wrdata(wrdata),
//.txd_data(txd_data)


    ); 
 
 //-------------------------端口选择-------------------------------------------------------------------------------
localparam uart=2'b00, iic=2'b01, spi=2'b10 ; //,can=2'b11;
always@(*)
    if(cmd==uart) 
    begin
           rcv_data=rcv_data_uart;
           recv_done=recv_done_uart;
           send_data_uart=recv_data;  
           recv_valid_uart =recv_valid;
    end 
    else  if(cmd==iic) 
    begin
             rcv_data=rcv_data_iic;
             recv_done=recv_done_iic;
             send_data_iic=recv_data;
             recv_valid_iic =recv_valid; 
    end 
    else  if(cmd==spi)
    begin
             rcv_data=rcv_data_spi;
             recv_done=recv_done_spi;
             send_data_spi=recv_data; 
             recv_valid_spi =recv_valid;
    end
 //--------------------------------usb的fifo和usb串口------------------------------------------------------------------------


    wire full2;
    wire empty2;
    reg  cnt;
    wire rd_en2;
    reg rd_en_f2;
    assign rd_en2 = (cnt) && (!empty2);
    
always @(posedge clk60mhz or negedge button) begin
    if (!button) begin
        cnt <= 1'b0;  // 复位时计数器清零
    end else begin
        cnt <= ~cnt;  
    end 
end


    //reg rd_en2_pre;
//always @(posedge clk60mhz or negedge button) begin
//    if (!button) begin
 //       rd_en2_pre <= 1'b0;  // 复位时计数器清零
  //  end else if(cnt==10000) begin
 //       rd_en2_pre <= 1;  
 //   end else  rd_en2_pre <= 0;
//end

always @(posedge clk60mhz or negedge button) begin
      if (!button) begin
       rd_en_f2 <= 0;
      end else begin
      rd_en_f2<=rd_en2;
      end  
end
      
    async_fifo #(
        .DATA_WIDTH(8),       // 数据位宽为8
        .ADDR_WIDTH(4)        // 地址位宽为4（深度16）
    ) sender_tousb (
        // 写端口（clk_wr时钟域）
        .wr_clk(clk50mhz),
        .wr_rst_n(button),
        .wr_en(recv_done && (!full2)), // 仅当FIFO未满时写入
        .wr_data(rcv_data),
        
        // 读端口（clk_rd时钟域）
        .rd_clk(clk60mhz),
        .rd_rst_n(button),
        .rd_en(rd_en2),
        .rd_data(tousb_data),
        
        // 状态标志
        .full(full2),
        .empty(empty2)
    );
    
//-------------------------------------------------------------------------------------------------------------------------------------
// USB-CDC Serial port device
//-------------------------------------------------------------------------------------------------------------------------------------

// here we simply make a loopback connection for testing, but convert lowercase letters to uppercase.
// When using minicom/hyperterminal/serial-assistant to send data from the host to the device, the send data will be returned.

usb_serial_top #(
    .DEBUG           ( "FALSE"             )    // If you want to see the debug info of USB device core, set this parameter to "TRUE"
) u_usb_serial (
    .rstn            (  button ),
    .clk             ( clk60mhz            ),
    // USB signals
    .usb_dp_pull     ( usb_dp_pull         ),
    .usb_dp          ( usb_dp              ),
    .usb_dn          ( usb_dn              ),
    // USB reset output
    .usb_rstn        ( led                 ),   // 1: connected , 0: disconnected (when USB cable unplug, or when system reset (rstn=0))
    // CDC receive data (host-to-device)
    .recv_data       ( recv_data           ),   // received data byte
    .recv_valid      ( recv_valid          ),   // when recv_valid=1 pulses, a data byte is received on recv_data
    // CDC send data (device-to-host)
    .send_data       ( tousb_data           ),   // send_data
    .send_valid      ( rd_en_f2          ),   // loopback connect recv_valid to send_valid
    .send_ready      (                     ),   // ignore send_ready, ignore the situation that the send buffer is full (send_ready=0). So here it will lose data when you send a large amount of data
    // debug output info, only for USB developers, can be ignored for normally use
    .debug_en        (                     ),
    .debug_data      (                     ),
    .debug_uart_tx   ( uart_tx             )
);



endmodule