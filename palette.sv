`include "structs.sv"

module palette (
	input [2:0] palette_index,
	output RGBcolor color
);

/*
always_comb begin // dummy palette which has the nice property of color 0 being black
	color.r = {palette_index[2], 3'b0};
	color.g = {palette_index[1], 3'b0};
	color.b = {palette_index[0], 3'b0};
end
*/

always_comb begin
	case(palette_index)
		0: color = 12'h8CF;
		1: color = 12'hB86;
		2: color = 12'hB74;
		3: color = 12'hA75;
		4: color = 12'h974;
		5: color = 12'h964;
		6: color = 12'h655;
		7: color = 12'h432;
	endcase
end

endmodule