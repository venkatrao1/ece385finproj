`include "structs.sv"
module framebuffer_module(
	input Clk,
	input Reset,
	input new_frame, // should be pulsed high when new frame happens (when vsync low...)
	input screenXY output_mod_coords,
	output [2:0] color_out,
	input screenXY render_mod_coords,
	input [2:0] color_in,
	input render_done, // input from rendering module when current frame is done
	output render_ack // pulses high for one cycle when the framebuffers switch and the rendering module can do stuff again
);

logic whichDisplaying; // which buffer is the output module reading from? (which buffer isn't being written to)
logic [2:0] buffer0 [86399:0]; // framebuffers with 360*240 pixels of 3 bits each
logic [2:0] buffer0out;
logic [2:0] buffer1 [86399:0]; // this could prob be 1 2d array but I'm not sure that quartus will infer ram then
logic [2:0] buffer1out;
logic [16:0] output_addr;
logic [16:0] renderer_addr;
logic [16:0] clearctr;
enum {CLEAR, WAIT_RENDER, WAIT_VSYNC} state;

assign output_addr = output_mod_coords.y*320 + output_mod_coords.x;
assign renderer_addr = render_mod_coords.y*320 + render_mod_coords.x;

always_ff @(posedge Clk) begin
	if(Reset) begin
		state <= CLEAR;
		clearctr <= '0;
		render_ack <= 0;
	end
	else begin

	buffer1out <= buffer1[output_addr];
	buffer0out <= buffer0[output_addr];
	case(state)
		CLEAR: begin
			if(whichDisplaying == 1) buffer0[clearctr] <= '0;
			else buffer1[clearctr] <= '0;
			clearctr <= clearctr+1;
			if(clearctr == 86399) begin
				state <= WAIT_RENDER;
				render_ack <= 1;
			end
		end
		WAIT_RENDER: begin
			render_ack <= 0;
			if(whichDisplaying == 1) buffer0[renderer_addr] <= color_in;
			else buffer1[renderer_addr] <= color_in;
			if(render_done) state <= WAIT_VSYNC;
		end
		WAIT_VSYNC: begin
			if(new_frame) begin
				state <= CLEAR;
				clearctr <= '0;
				whichDisplaying <= !whichDisplaying;
			end
		end
	endcase

	end
end

always_comb begin
	if(whichDisplaying == 1) color_out = buffer1out;
	else color_out = buffer0out;
end

endmodule