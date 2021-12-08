`include "structs.sv"
module framebuffer_module(
	input Clk,
	input Reset,
	input new_frame, // should be pulsed high when new frame happens (when vsync low...)
	input screenXY output_module_coords,
	output [2:0] color_out
);

logic framectr; // alternate between 2 pictures to simulate double buffer?
always_ff @(posedge Clk) begin
	if(Reset) framectr <= 0;
	if(output_module_coords.x-output_module_coords.y == 0) color_out <= 3'b001;
	else color_out <= '0;
end
endmodule