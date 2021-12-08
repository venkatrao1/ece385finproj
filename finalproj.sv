`include "structs.sv"
module finalproj (
      ///////// Clocks /////////
      input    MAX10_CLK1_50,

      ///////// KEY /////////
      input    [ 1: 0]   KEY,

      ///////// SW /////////
      input    [ 9: 0]   SW,

      ///////// LEDR /////////
      output   [ 9: 0]   LEDR,

      ///////// HEX /////////
      output   [ 7: 0]   HEX0,
      output   [ 7: 0]   HEX1,
      output   [ 7: 0]   HEX2,
      output   [ 7: 0]   HEX3,
      output   [ 7: 0]   HEX4,
      output   [ 7: 0]   HEX5,

      ///////// SDRAM /////////
      output             DRAM_CLK,
      output             DRAM_CKE,
      output   [12: 0]   DRAM_ADDR,
      output   [ 1: 0]   DRAM_BA,
      inout    [15: 0]   DRAM_DQ,
      output             DRAM_LDQM,
      output             DRAM_UDQM,
      output             DRAM_CS_N,
      output             DRAM_WE_N,
      output             DRAM_CAS_N,
      output             DRAM_RAS_N,

      ///////// VGA /////////
      output             VGA_HS,
      output             VGA_VS,
      output   [ 3: 0]   VGA_R,
      output   [ 3: 0]   VGA_G,
      output   [ 3: 0]   VGA_B,

      ///////// ARDUINO /////////
      inout    [15: 0]   ARDUINO_IO,
      inout              ARDUINO_RESET_N 
);

logic Reset; // active high, for now let's keep it at 0
assign Reset = 0;

logic Clk;
assign Clk = MAX10_CLK1_50; // if we want to use a PLL we can change this.

screenXY output_mod_coords;
logic new_frame;
logic [2:0] framebuffer_out;

screenXY render_mod_coords;
logic [2:0] render_color;
logic render_done, render_ack;

framebuffer_module framebuffer_mod(
	.Clk(Clk),
	.Reset(Reset),
	.new_frame(new_frame),
	.output_mod_coords(output_mod_coords),
	.color_out(framebuffer_out),
      .render_mod_coords(render_mod_coords),
      .color_in(render_color),
      .render_done(render_done),
      .render_ack(render_ack)
);

render_module render_mod(
      .Clk(Clk),
      .Reset(Reset),    
      .coords_out(render_mod_coords),
      .color_out(render_color),
      .render_done(render_done),
      .render_ack(render_ack)
);

output_module output_mod(
	.Clk(Clk),
	.Reset(Reset),
	.hs(VGA_HS),
	.vs(VGA_VS),
	.new_frame(new_frame),
	.framebuffer_coords(output_mod_coords),
	.framebuffer_output(framebuffer_out),
	.color_out({VGA_R,VGA_G,VGA_B})
);

endmodule