`include "structs.sv"
module output_module (
	input Clk,
	input Reset, // this module 80% ignores this, anything not reset will resolve after 1-2 frames so
	output logic hs,
	output logic vs,
	output logic new_frame, // literally just vsync inverted, pulses high for each frame
	output screenXY framebuffer_coords,
	input logic [2:0] framebuffer_output,
	output RGBcolor color_out
);
assign new_frame = !vs;

// read pixel from framebuffer (put x and y into framebuffer input)
logic [9:0] DrawX, DrawY;
logic shouldDisplay;
logic cont_hs;
logic cont_vs;
vga_controller vga_cont(.Clk(Clk), .Reset(Reset), .hs(cont_hs), .vs(cont_vs), .pixel_clk(), .blank(shouldDisplay), .sync(), .DrawX(DrawX), .DrawY(DrawY));
assign framebuffer_coords.x = DrawX[9:1];
assign framebuffer_coords.y = DrawY[8:1];

// calculate palette color (1 cycle later)
logic shouldDisplay_delayed;
logic cont_vs_delayed;
logic cont_hs_delayed;
screenXY framebuffer_coords_delayed;
logic [2:0] lastSeen [319:0]; // last seen colors
logic [2:0] lastPaletteColor;
RGBcolor lastSeenRGB;
RGBcolor framebufferRGB;
palette lastSeenPalette(.palette_index(lastPaletteColor), .output(lastSeenRGB));
palette framebufferPalette(.palette_index(framebuffer_output), .output(framebufferRGB));


// actually generate hs and vs, rgb signals based on this (2 cycles later)
always_ff @(posedge Clk) begin
	// this part handles the (1 cycle later) part of my pseudocode
	shouldDisplay_delayed <= shouldDisplay;
	cont_hs_delayed <= cont_hs;
	cont_vs_delayed <= cont_vs;
	framebuffer_coords_delayed <= framebuffer_coords;
	lastPaletteColor <= lastSeen[framebuffer_coords.x];
	

	// now for actual output generation
	hs <= cont_hs_delayed;
	vs <= cont_vs_delayed;
	if(!shouldDisplay_delayed) begin
		if (!cont_vs) lastSeen[framebuffer_coords_delayed.x] <= '0; // clear lastSeen if new frame
		color_out <= '0; // display black while blanking
	end
	else begin
		if(|framebuffer_output) begin // if the framebufffer generated a nonzero color, use it and update lastSeen
			color_out <= framebufferRGB;
			lastSeen[framebuffer_coords_delayed.x] <= framebuffer_output;
		end
		else color_out <= lastSeenRGB;
	end

end

endmodule