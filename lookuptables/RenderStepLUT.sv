`include "../structs.sv"
module RenderStepLUT (
	input clk,    // Clock
	input angle inval,
	output fp44 outval
);

logic[35:0] romout;
RenderStepROM rom(.clock(clk), .address(inval[9:0]), .q(romout));
always_comb begin
	if(inval[10]) outval = -romout;
	else outval = romout;
end

endmodule : RenderStepLUT