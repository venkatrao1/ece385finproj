//ROM containing 256x256 tile map to be rendered.
`include "../structs.sv"
module MapLUT(
	input 	clk,
	input [7:0] x,
	input [7:0] y,
	output maptile data
);

	MapRom rom(.address({y,x}), .clock(clk), .q(data));
	
endmodule