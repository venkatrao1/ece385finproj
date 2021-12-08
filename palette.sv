`include "structs.sv"

module palette (
	input [2:0] palette_index,
	output RGBcolor color
);

always_comb begin // dummy palette which has the nice property of color 0 being black
	color.r = {palette_index[2], 3'b0};
	color.g = {palette_index[1], 3'b0};
	color.b = {palette_index[0], 3'b0};
end

endmodule