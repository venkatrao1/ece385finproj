`include "structs.sv"
module render_module (
	input Clk,
	input Reset,
	output screenXY coords_out,
	output [2:0] color_out,
	output render_done,
	input render_ack
);

fp44 sinresult;
TrigLUT triglut(.clk(Clk), .inval(coords_out.x*16), .outval(sinresult));
logic[44:0] xsinscaled;
assign xsinscaled = {sinresult.intpart+1, sinresult.fracpart}*128;

maptile mapresult;
MapLUT maplut(.clk(Clk), .x(coords_out.x), .y(coords_out.y), .data(mapresult));

enum {WAIT_ACK, RENDERING} state;
logic [2:0] pattern; // current pattern for testing
//assign pattern = 7;
logic [9:0] patternctr;
assign pattern = patternctr[9:7];

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
					coords_out.x <= 0;
					coords_out.y <= 0;
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
		5: color_out = mapresult.color;
		6: begin
			if(mapresult.height[5:3] == 0) color_out = 1;
			else color_out = mapresult.height[5:3];
		end
		7: begin
			if(coords_out.y==xsinscaled[44:37]) color_out = pattern;
		end
	endcase
end

endmodule