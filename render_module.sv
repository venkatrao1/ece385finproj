`include "structs.sv"
module render_module (
	input Clk,
	input Reset,
	output screenXY coords_out,
	output [2:0] color_out,
	output render_done,
	input render_ack
);

enum {WAIT_ACK, RENDERING} state;
logic [2:0] pattern; // current pattern for testing
logic [7:0] patternctr;
assign pattern = patternctr[7:5];

always_ff @(posedge Clk) begin
	if(Reset) begin
		state <= WAIT_ACK;
		render_done <= 0;
	end
	else begin
		case(state)
			WAIT_ACK: begin
				render_done <= 0;
				if(render_ack) begin
					patternctr <= patternctr + 1;
					state <= RENDERING;
					coords_out <= '0;
				end
			end
			RENDERING: begin
				if(coords_out.x == 319) begin
					if(coords_out.y == 239) begin
						render_done <= 1;
						state <= WAIT_ACK;
					end
					coords_out.x <= '0;
					coords_out.y <= coords_out.y + 1;
				end
				else coords_out.x <= coords_out.x + 1;
			end
		endcase
	end
end

always_comb begin
	color_out = 0;
	case(pattern)
		1: if(coords_out.x == coords_out.y) color_out = pattern; // BL triangle
		2: if(coords_out.y == 0) color_out = pattern; // full screen
		3: if(coords_out.x>>1 == coords_out.y) color_out = pattern; // flatter slant
		4: if(coords_out.y == 120) color_out = pattern; // bottom half
		5: if(coords_out.x == coords_out.y>>1) color_out = pattern; // steeper slant
		6: if(coords_out.x[3]) color_out = pattern; // vertical stripes
		7: begin
			if(coords_out.y[3]) color_out = pattern; // horiz stripes
			else color_out = 6;
		end
	endcase
end

endmodule