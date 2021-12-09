//movement code
`include "structs.sv"
module playermovement(
	input 	clk,
	input 	reset,
	input 	new_frame,
	input [9:0] SW,
	output angle angleout,
	output posXY position,
	output [7:0] HEX0,
	output [7:0] HEX1,
	output [7:0] HEX2,
	output [7:0] HEX3,
	output [7:0] HEX4,
	output [7:0] HEX5,
	output [9:0] LEDR
	);
	
	fp44 xcoordvar;
	fp44 ycoordvar;
	angle anglevar; //not sure if we need these	
	angle anglein;
	logic movefor;
	logic moveback;
	logic turnleft;
	logic turnright;
		
	assign angleout = anglevar;
	assign position.x = xcoordvar;
	assign position.y = ycoordvar;
	
	
	//zero angle points east
	//origin coord in the bottom left
	
	TrigLUT lut(.clk(clk), .inval(anglein), .outval(sinresult));
	fp44 sinresult;

	logic [4:0] channel;
	initial channel = 1;
	
	enum logic [2:0] {HALT, YMOVE, XMOVE, ANGLEWAIT, ANGLEMOVE} state, nextstate;
	
	always_ff @ (posedge sys_clk)
	begin
		if(reset) begin
			state <= HALT;
			ycoordvar <= 0;
			xcoordvar <= 0;
			anglevar <= 512;
		end
		else state <= nextstate;
		
		unique case(state) //
			HALT: begin
				anglein <= anglevar;
				channel <= 1;
			end
			YMOVE: begin
				if(movefor && cur_adc_ch == 1) ycoordvar <= ycoordvar + (sinresult);
				if(moveback && cur_adc_ch == 1) ycoordvar <= ycoordvar - (sinresult);
				if(anglevar <= 512) anglein <= 512 - anglevar; //pi/2 - angle to get cosine
				else anglein <= 2560 - anglevar; //5pi/2 - angle to get cosine
				channel <= 1;
			end
			XMOVE: begin
				if(movefor && cur_adc_ch == 1)xcoordvar <= xcoordvar + (sinresult);
				if(moveback && cur_adc_ch == 1)xcoordvar <= xcoordvar - (sinresult);
				channel <= 2;
			end
			ANGLEWAIT: channel<= 2;
			ANGLEMOVE: begin
				if(turnleft && cur_adc_ch == 2) anglevar <= anglevar + 10;
				if(turnright && cur_adc_ch == 2) anglevar <= anglevar - 10;
				channel <= 1;
			end
			
		endcase
	end
	
	always_comb
	begin
		//nextstate = state; //default if no new_frame
		unique case(state)
			HALT: begin
				if(new_frame) nextstate = YMOVE;
				else nextstate = HALT;
			end
			YMOVE: nextstate = XMOVE;
			XMOVE: nextstate = ANGLEWAIT;
			ANGLEWAIT: begin
				if(new_frame) nextstate = ANGLEMOVE;
				else nextstate = ANGLEWAIT;
			end
			ANGLEMOVE: nextstate = HALT;
		endcase
		
		//Code to tell which direction to move in
			if(adc_sample_data > 2000) begin
				movefor = 1;
				moveback = 0;
				turnleft = 1;
				turnright = 0;
			end
			else if(adc_sample_data < 700) begin
				movefor = 0;
				moveback = 1;
				turnleft = 0;
				turnright = 1;
			end
			else begin
				movefor = 0;
				moveback = 0;
				turnleft = 0;
				turnright = 0;
			end
	
		
	end
	
	
	
	/****** Joystick code *********/
//This code was taken from the ADC_RTL modle from the class archives 


wire reset_n;
wire sys_clk;
assign reset_n = ~reset;

adc_qsys u0 (
        .clk_clk                              (clk),                              //                    clk.clk
        .reset_reset_n                        (reset_n),                        //                  reset.reset_n
        .modular_adc_0_command_valid          (command_valid),          //  modular_adc_0_command.valid
        .modular_adc_0_command_channel        (command_channel),        //                       .channel
        .modular_adc_0_command_startofpacket  (command_startofpacket),  //                       .startofpacket
        .modular_adc_0_command_endofpacket    (command_endofpacket),    //                       .endofpacket
        .modular_adc_0_command_ready          (command_ready),          //                       .ready
        .modular_adc_0_response_valid         (response_valid),         // modular_adc_0_response.valid
		  .modular_adc_0_response_channel       (response_channel),       //                       .channel
        .modular_adc_0_response_data          (response_data),          //                       .data
        .modular_adc_0_response_startofpacket (response_startofpacket), //                       .startofpacket
        .modular_adc_0_response_endofpacket   (response_endofpacket),    //                       .endofpacket
        .clock_bridge_sys_out_clk_clk         (sys_clk)          // clock_bridge_sys_out_clk.clk
    );
	 
	// command
wire  command_valid;
wire  [4:0] command_channel;
wire  command_startofpacket;
wire  command_endofpacket;
wire command_ready;

// continused send command
assign command_startofpacket = 1'b1; // // ignore in altera_adc_control core
assign command_endofpacket = 1'b1; // ignore in altera_adc_control core
assign command_valid = 1'b1; // 
//assign command_channel = SW[2:0]+1; // SW2/SW1/SW0 down: map to arduino ADC_IN0
assign command_channel = channel; //change to switch between 1 and 2

////////////////////////////////////////////
// response
wire response_valid/* synthesis keep */;
wire [4:0] response_channel;
wire [11:0] response_data;
wire response_startofpacket;
wire response_endofpacket;
reg [4:0]  cur_adc_ch /* synthesis noprune */;
reg [11:0] adc_sample_data /* synthesis noprune */;
reg [12:0] vol /* synthesis noprune */;

always @ (posedge sys_clk)
begin
	if (response_valid)
	begin
		adc_sample_data <= response_data;
		cur_adc_ch <= response_channel;
	end
end	

assign HEX5[7] = 1'b1; // low active
assign HEX4[7] = 1'b1; // low active
assign HEX3[7] = 1'b1; // low active
assign HEX2[7] = 1'b1; // low active
assign HEX1[7] = 1'b1; // low active
assign HEX0[7] = 1'b1; // low active

assign LEDR = {{6{1'b0}},movefor,moveback,turnleft,turnright};

SEG7_LUT	SEG7_LUT_5 (
	.oSEG(HEX5),
	.iDIG(anglevar[10:7])
);

SEG7_LUT	SEG7_LUT_4 (
	.oSEG(HEX4),
	.iDIG(anglevar[6:3])
);

SEG7_LUT	SEG7_LUT_3 (
	.oSEG(HEX3),
	.iDIG(xcoordvar[43:40])
);

SEG7_LUT	SEG7_LUT_2 (
	.oSEG(HEX2),
	.iDIG(xcoordvar[39:36])
);

SEG7_LUT	SEG7_LUT_1 (
	.oSEG(HEX1),
	.iDIG(ycoordvar[43:40])
);

SEG7_LUT	SEG7_LUT_0 (
	.oSEG(HEX0),
	.iDIG(ycoordvar[39:36])
);
/******** END Joystick Code ***********/


endmodule
