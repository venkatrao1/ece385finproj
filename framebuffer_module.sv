`include "structs.sv"
module framebuffer_module(
	input Clk,
	input Reset,
	input new_frame, // should be pulsed high when new frame happens (when vsync low...)
	input screenXY output_module_coords,
	output [2:0] color_out
);

logic [5:0] framectr; // alternate between 2 pictures to simulate double buffer?
always_ff @(posedge Clk) begin
	if(Reset) framectr <= 0;
	else if(new_frame) framectr <= framectr+1;
	if(framectr[5]) begin
		if(output_module_coords.x-output_module_coords.y == 0) color_out <= output_module_coords[2:0];
		else color_out <= '0;
	end
	else begin
		if(output_module_coords.y == 120) color_out <= '1;
		else color_out <= '0;
	end
end
endmodule