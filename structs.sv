`ifndef ECE385_STRUCT_HEADER
`define ECE385_STRUCT_HEADER

typedef struct packed {
	logic [7:0] intpart;
	logic [35:0] fracpart;
} fp44;

typedef struct {
	fp44 x;
	fp44 y;
} posXY;

typedef struct packed {
	logic [3:0] r;
	logic [3:0] g;
	logic [3:0] b;
} RGBcolor;

typedef struct {
	logic [8:0] x;
	logic [7:0] y;
} screenXY;

typedef logic[10:0] angle;

typedef logic[4:0] mapheight;
typedef logic[3:0] palcolor;

typedef struct packed {
	mapheight height;
	palcolor color;
} maptile;

`endif