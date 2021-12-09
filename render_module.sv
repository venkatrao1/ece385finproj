`include "structs.sv"
module render_module (
	input Clk,
	input Reset,
	output screenXY coords_out,
	output [2:0] color_out,
	output framebuffer_we,
	output render_done,
	input render_ack,
	input posXY player_pos,
	input angle player_angle
);

localparam horizFOV = 245; // basically, tan of this angle = 320/240 * tan(vert_fov)
localparam horizonY = 120; // the horizon is midway down by default

maptile mapresult;
posXY maplutpos;
MapLUT maplut(.clk(Clk), .x(maplutpos.x.intpart), .y(maplutpos.y.intpart), .data(mapresult));

logic [26:0] mul_a;
logic [7:0] mul_b;
logic [35:0] mulresult;
logic [17:0] screencolsigned;
heightmultiplier hmul(.dataa({1'b0, mul_a}), .datab(mul_b), .result(mulresult)); // a is unsigned
assign mul_b = mapresult.height - curHeight;

HeightScaleROM hsrom(.clock(Clk), .address(dist_ctr), .q(mul_a));

logic [8:0] dist_ctr; // counts from 0 to 511 and calculates the half tile distance.
logic [8:0] curX; // counts from 0 to 319, current col being rendered to.

posXY curPos;
logic[6:0] curHeight;
posXY curPosL;
posXY54 curPerpendVector; // perpendicular vector, scaled up to match dist_ctr
posXY dir_L; // which direction does player_angle_L point?
posXY dir_perpend; // which direction is from L to R?
posXY dir_perpend_scaled; // this is a hacky solution, TODO replace with better lookup table when patrick wakes up
assign	dir_perpend_scaled.x = dir_perpend.x;// + {dir_perpend.x[43], dir_perpend.x[43:1]}; // 3/2 happens to miraculously be a number that matches within like 2-3% of the scaling factor I need, otherwise I would have gone to sleep 
assign	dir_perpend_scaled.y = dir_perpend.y;// + {dir_perpend.y[43], dir_perpend.y[43:1]};

angle player_angle_L;
angle player_angle_perpend;
TrigLUT triglut_LX(.clk(Clk), .inval(player_angle_L+512), .outval(dir_L.x));
TrigLUT triglut_LY(.clk(Clk), .inval(player_angle_L), .outval(dir_L.y));
TrigLUT triglut_perpendX(.clk(Clk), .inval(player_angle_perpend+512), .outval(dir_perpend.x));
TrigLUT triglut_perpendY(.clk(Clk), .inval(player_angle_perpend), .outval(dir_perpend.y));

posXY slidingPos; // slides from left to right as our row counter increases

logic[7:0] highestDrawnOut;
logic[7:0] highestDrawn[320];// for each X val, what's the highest Y we've drawn on?
always_ff @(posedge Clk) highestDrawnOut <= highestDrawn[curX];

logic[7:0] outY;
always_comb begin
	if(screencolsigned > 239) outY = 0;
	else outY = 239 - screencolsigned;
end

enum {
	WAIT_ACK, // wait for acknowledgement signal
	WAIT_LUTS_INIT, // wait_ack sets up lut addresses, but we must wait 1 cycle to read from them
	INIT_COUNTERS, // initialize everything based on LUTS?
	INIT_ROW, // do beginning of row things like add to curPosL and curPosR
	RENDER_0,
	RENDER_1,
	RENDER_1_5,
	RENDER_2
} state;

always_ff @(posedge Clk) begin
	if(Reset) begin
		state <= WAIT_ACK;
		render_done <= 0;
	end
	else begin
		case(state)
			WAIT_ACK: begin
				framebuffer_we <= 0;
				render_done <= 0;
				curPos <= player_pos;
				maplutpos <= player_pos;
				curPosL <= player_pos;
				player_angle_L <= player_angle + horizFOV;
				player_angle_perpend <= player_angle - 512;
				if(render_ack) begin
					state <= WAIT_LUTS_INIT;
				end
			end
			WAIT_LUTS_INIT: begin
				state <= INIT_COUNTERS;
			end
			INIT_COUNTERS: begin
				curHeight <= mapresult.height + 2; // we are 2 tall
				dist_ctr <= 0;
				curPosL.x <= curPos.x;
				curPosL.y <= curPos.y;
				curPerpendVector.x <= 0;
				curPerpendVector.y <= 0;
				state <= INIT_ROW;
			end
			INIT_ROW: begin
				curPosL.x <= curPosL.x + {dir_L.x[43], dir_L.x[43:1]} + (dir_L.x[0]& ~dist_ctr[0]); // sub half of dir components from curPoses
				slidingPos.x <= curPosL.x + {dir_L.x[43], dir_L.x[43:1]} + (dir_L.x[0]& ~dist_ctr[0]);
				curPerpendVector.x <= curPerpendVector.x + {{11{dir_perpend_scaled.x[43]}}, dir_perpend_scaled.x[43:1]} + (dir_perpend.x[0]& ~dist_ctr[0]);
				curPerpendVector.y <= curPerpendVector.y + {{11{dir_perpend_scaled.y[43]}}, dir_perpend_scaled.y[43:1]} + (dir_perpend.y[0]& ~dist_ctr[0]);
				curPosL.y <= curPosL.y + {dir_L.y[43], dir_L.y[43:1]} + (dir_L.y[0]& ~dist_ctr[0]);
				slidingPos.y <= curPosL.y + {dir_L.y[43], dir_L.y[43:1]} + (dir_L.y[0]& ~dist_ctr[0]);
				curX <= 0;
				state <= RENDER_0;
			end
			RENDER_0: begin
				maplutpos <= slidingPos;
				state <= RENDER_1;
			end
			RENDER_1: begin // maplut still processing
				if(dist_ctr == 0) highestDrawn[curX] <= 255;
				state <= RENDER_1_5;
			end
			RENDER_1_5: begin
				screencolsigned <= mulresult[35:18] + horizonY; // how many columns should we take up?
				state <= RENDER_2;
			end
			RENDER_2: begin // maplut done, now check mul result
				//framebuffer_we <= 1;
				//coords_out.x <= maplutpos.x.intpart;
				//coords_out.y <= maplutpos.y.intpart;
				//color_out <= mapresult.color;
				if(!screencolsigned[17]) begin
					if(outY < highestDrawnOut) begin
						framebuffer_we <= 1;
						highestDrawn[curX] <= outY;
						coords_out.x <= curX;
						coords_out.y <= outY;
						color_out <= mapresult.color;
					end
				end
				if(curX == 319) begin
					if(dist_ctr == 200) begin
						state <= WAIT_ACK;
						render_done <= 1;
					end
					else begin
						dist_ctr <= dist_ctr + 1;
						state <= INIT_ROW;
					end
				end
				else begin
					curX <= curX + 1;
					slidingPos.x <= slidingPos.x + (curPerpendVector.x>>>7); // why does this work
					slidingPos.y <= slidingPos.y + (curPerpendVector.y>>>7);
					state <= RENDER_0;
				end
			end
		endcase
	end
end

endmodule