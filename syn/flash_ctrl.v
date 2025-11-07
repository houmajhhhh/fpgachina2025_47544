module flash_control
	(
		input		wire	CLK,
		input		wire	RSTn,
		output	reg	clock25M,
		output	reg[3:0]	cmd_type,
		input		wire	Done_Sig,
		output	reg[7:0]	flash_cmd,
	//	input	[23:0]	flash_addr,
		input		[7:0]	mydata_o,
		input			myvalid_o,
		input   [3:0]     cmd,
		output reg[3:0] state
	);
 
//reg[3:0] i;
//wire [3:0]     cmd=4'b1000;
reg[3:0] next_state;
reg[7:0] time_delay;
localparam idle=4'd0,rid=4'd1,write=4'd3,read=4'd4,sweep=4'd5,writeen1=4'd6,sector=4'd7,wait1=4'd8,readreg1=4'd9,writedis=4'd10,readreg2=4'd11,write_flash=4'd12,read_flash=4'd13,writeen2=4'd14,wait2=4'd15;
//FLASH ²Á³ý,Page Program,¶ÁÈ¡³ÌÐò	

//always @(posedge clock25M or negedge RSTn)
//begin
//    if(!RSTn)    state<=idle;
//    else         state<=next_state;
//end

always @(posedge clock25M or negedge RSTn)
begin
   if(!RSTn)begin
		state <= idle;
		//flash_addr <= 24'd0;
		flash_cmd <= 8'd0;
		cmd_type <= 4'b0000;
		time_delay <= 8'd0;
	end
	else begin
	   case(state)
	        idle:begin
	        if (cmd[0]==1) state<=rid;
	        else  if (cmd[1]==1) state<=write;
	        else  if (cmd[2]==1) state<=read;
	        else  if (cmd[3]==1) state<=sweep;
	        else state<=idle;
	        end
	        
			rid:begin	//¶ÁDevice ID
				if( Done_Sig )begin
					flash_cmd <= 8'h00;
					state<=idle;
					cmd_type <= 4'b0000;
				end
				else begin
					flash_cmd <= 8'h90;
				//	flash_addr <= 24'd0;
					cmd_type <= 4'b1000;
				end	
			end
			
			//sweep:  next_state<=writeen1;
			
	       sweep:begin	//Ð´Write Enable instruction
				if(Done_Sig)begin
					flash_cmd <= 8'h00;
					state<=sector;
					cmd_type <= 4'b0000;
				end
				else begin
					flash_cmd <= 8'h06;
					cmd_type <= 4'b1001;
				end
			end
			
			sector:begin	//Sector²Á³ý
				if(Done_Sig)begin
					flash_cmd <= 8'h00;
					state<=wait1;
					cmd_type<=4'b0000;
				end
				else begin
					flash_cmd <= 8'h20;
				//	flash_addr <= 24'd0;
					cmd_type <= 4'b1010;
				end
			end
			
	      wait1:begin	//waitting 100 clock
				if(time_delay < 8'd100)begin
					flash_cmd <= 8'h00;
					time_delay <= time_delay + 8'd1;
					cmd_type <= 4'b0000;
				end
				else begin
					state<=readreg1;
					time_delay <= 8'd0;
				end	
			end
			
			readreg1:begin	//¶Á×´Ì¬¼Ä´æÆ÷1, µÈ´ýidle
				if(Done_Sig)begin 
					if(mydata_o[0] == 1'b0)begin
						flash_cmd <= 8'h00;
						state<=writedis;
						cmd_type <= 4'b0000;
					end
					else begin
						flash_cmd <= 8'h05;
						cmd_type <= 4'b1011;
					end
				end
				else begin
					flash_cmd <= 8'h05;
					cmd_type <= 4'b1011;
				end
			end
			
	      writedis :begin	//Ð´Write disable instruction
				if(Done_Sig)begin
					flash_cmd <= 8'h00;
					state<=readreg2;
					cmd_type <= 4'b0000;
				end
				else begin
					flash_cmd <= 8'h04;
					cmd_type <= 4'b1100;
				end
			end
			
			readreg2:begin	//¶Á×´Ì¬¼Ä´æÆ÷1, µÈ´ýidle
				if(Done_Sig)begin
					if(mydata_o[0] == 1'b0)begin
						flash_cmd <= 8'h00;
						state<=idle;
						cmd_type <= 4'b0000;
					end
					else begin
						flash_cmd <= 8'h05;
						cmd_type <= 4'b1011;
					end
				end
				else begin
					flash_cmd <= 8'h05;
					cmd_type <= 4'b1011;
				end
			end
			
			//write :  next_state<=writeen2;
			
	       write:begin	//Ð´Write Enable instruction
				if(Done_Sig)begin
					flash_cmd <= 8'h00;
					state<=wait2;
					cmd_type <= 4'b0000;
				end
				else begin
					flash_cmd <= 8'h06;
					cmd_type <= 4'b1001;
				end 
			end
			
	      wait2:begin	//waitting 100 clock
				if(time_delay < 8'd100)begin
					flash_cmd <= 8'h00;
					time_delay <= time_delay + 8'd1;
					cmd_type <= 4'b0000;
				end
				else begin
					state<=write_flash;
					time_delay <= 8'd0;
				end	
			end
			
	     write_flash:begin	//page program: write 0~255 to flash
				if(Done_Sig)begin
					flash_cmd <= 8'h00;
					state<=wait1;
					cmd_type <= 4'b0000;
				end
				else begin
					flash_cmd <= 8'h02;
				//	flash_addr <= 24'h00ff56;
					cmd_type <= 4'b1101;
				end
			end
			

		//	read :  next_state<=read_flash;
			read:begin	//read 256byte
				if(Done_Sig)begin
					flash_cmd <= 8'h00;
					state<=idle;
					cmd_type <= 4'b0000;
				end
				else begin
					flash_cmd <= 8'h03;
				//	flash_addr <= 24'd0;
					cmd_type <= 4'b1110;
				end
			end
			
			default:state<=idle;
			
		endcase
	end
end


//²úÉú25MhzµÄSPI Clock		  
always @(posedge CLK)
begin
   if(!RSTn)begin
		clock25M <= 1'b0;
	end
	else begin
		clock25M <= ~clock25M;
	end
end

endmodule