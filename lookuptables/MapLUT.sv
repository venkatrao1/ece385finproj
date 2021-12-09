//ROM containing 256x256 tile map to be rendered.

module MapLUT(
	input 	clk,
	input [15:0] addr,
	output [8:0] data);


	MapRom rom(.address(addr), .clock(clk), .q(data));
	
endmodule