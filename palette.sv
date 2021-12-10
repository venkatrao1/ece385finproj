`include "structs.sv"

module palette (
	input [2:0] palette_index,
	output RGBcolor color
);

always_comb begin
	case(palette_index)
		0: color = 12'h8CF;
		1: color = 12'hB86;
		2: color = 12'hA75;
		3: color = 12'h975;
		4: color = 12'h975;
		5: color = 12'h964;
		6: color = 12'h656;
		7: color = 12'h433;
	endcase
end

endmodule