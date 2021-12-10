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
	input angle player_angle,
	input flight_mode,
	input [16:0] horizon,
	input fly_highlow
);

localparam horizFOV = 245; // basically, tan of this angle = 320/240 * tan(vert_fov)

logic [6:0] flyHeight; // this can be any value between 63 (highest peaks) and 127
always_comb begin
	if(fly_highlow) flyHeight = 127;
	else flyHeight = 65;
end

maptile mapresult;
posXY maplutpos;
MapLUT maplut(.clk(Clk), .x(maplutpos.x.intpart), .y(maplutpos.y.intpart), .data(mapresult));

logic [7:0] heightdiff;
logic [35:0] mulresult;
heightmultiplier hmul(.dataa({1'b0, heightscale}), .datab(heightdiff), .result(mulresult)); // heightscale is unsigned
assign heightdiff = mapresult.height - curHeight;

logic[26:0] heightscale;
HeightScaleROM hsrom(.clock(Clk), .address(dist_ctr), .q(heightscale));

logic [8:0] dist_ctr; // counts from 0 to 511 and calculates the half tile distance.
logic [8:0] curX; // counts from 0 to 319, current col being rendered to.

logic[6:0] curHeight;
posXY curPosL;
struct {
	logic [53:0] x;
	logic [53:0] y;
} curPerpendVector; // perpendicular vector, scaled up to match dist_ctr (needs to be big)
posXY dir_L; // which direction does player_angle_L point?
posXY dir_perpend; // which direction is from L to R?

logic [17:0] screencolsigned; // position to draw to on screen

posXY nextPosL;
always_comb begin
	nextPosL.x = curPosL.x + {dir_L.x[43], dir_L.x[43:1]} + (dir_L.x[0]& ~dist_ctr[0]); // sub half of dir components from curPoses
	nextPosL.y = curPosL.y + {dir_L.y[43], dir_L.y[43:1]} + (dir_L.y[0]& ~dist_ctr[0]);
end

angle player_angle_L;
angle player_angle_perpend;
TrigLUT triglut_LX(.clk(Clk), .inval(player_angle_L+512), .outval(dir_L.x));
TrigLUT triglut_LY(.clk(Clk), .inval(player_angle_L), .outval(dir_L.y));
RenderStepLUT steplut_perpendX(.clk(Clk), .inval(player_angle_perpend+512), .outval(dir_perpend.x));
RenderStepLUT steplut_perpendY(.clk(Clk), .inval(player_angle_perpend), .outval(dir_perpend.y));

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
	RENDER_2,
	RENDER_3
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
				maplutpos <= player_pos;
				curPosL <= player_pos;
				player_angle_L <= player_angle + horizFOV;
				player_angle_perpend <= player_angle + 1536; // this is 90 degrees clockwise of where we're looking
				if(render_ack) state <= WAIT_LUTS_INIT;
			end
			WAIT_LUTS_INIT: state <= INIT_COUNTERS; // wait for mapresult to load
			INIT_COUNTERS: begin
				if(flight_mode) curHeight <= flyHeight;
				else curHeight <= mapresult.height + 2; // we are 2 units tall, make height moving average so it'
				dist_ctr <= 0;
				curPerpendVector.x <= 0;
				curPerpendVector.y <= 0;
				state <= INIT_ROW;
			end
			INIT_ROW: begin
				curPosL <= nextPosL;
				slidingPos <= nextPosL;
				// curPerpendVector has 18 bits dec, 36 bits frac
				// so curPerPendVector is currently += dir_perpend*1 = actual dir * 2^8
				curPerpendVector.x <= curPerpendVector.x + {{10{dir_perpend.x[43]}}, dir_perpend.x};
				curPerpendVector.y <= curPerpendVector.y + {{10{dir_perpend.y[43]}}, dir_perpend.y};
				curX <= 0;
				state <= RENDER_0;
			end
			RENDER_0: begin
				maplutpos <= slidingPos;
				state <= RENDER_1;
			end
			RENDER_1: begin
				if(dist_ctr == 0) highestDrawn[curX] <= '1;
				state <= RENDER_2; // mapLUT still processing
			end
			RENDER_2: begin
				screencolsigned <= mulresult[35:18] + horizon; // how many columns should we take up?
				state <= RENDER_3;
			end
			RENDER_3: begin // maplut done, now check mul result
				if(!screencolsigned[17] && outY < highestDrawnOut) begin
					framebuffer_we <= 1;
					highestDrawn[curX] <= outY;
					coords_out.x <= curX;
					coords_out.y <= outY;
					color_out <= mapresult.color;
				end
				if(curX == 319) begin
					if(dist_ctr == 511) begin
						state <= WAIT_ACK;
						render_done <= 1;
					end
					else state <= INIT_ROW;
					dist_ctr <= dist_ctr + 1;
				end
				else begin
					slidingPos.x <= slidingPos.x + (curPerpendVector.x>>>8);
					slidingPos.y <= slidingPos.y + (curPerpendVector.y>>>8);
					state <= RENDER_0;
				end
				curX <= curX + 1;
			end
		endcase
	end
end

endmodule