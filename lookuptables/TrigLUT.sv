//Trig look up table
`include "../structs.sv"
module TrigLUT (
	input 		 clk,
	input angle inval,
	output fp44 outval); //first 8 bits are integer, last 36 are decimal
	
	logic [8:0] addr;
	logic [35:0] lutout;
	
	TrigRom rom (.address(addr), .clock(clk), .q(lutout));

	enum {ONE, NEG_ONE, POSITIVE, NEGATIVE} prevangle;
	always_ff @ (posedge clk)
	begin
		if(inval == 11'h200) prevangle <= ONE;
		else if(inval == 11'h600) prevangle <= NEG_ONE;
		else if(inval[10]) prevangle <= NEGATIVE;
		else prevangle <= POSITIVE;
	end
	
	always_comb
	begin
		//set correct addr line depending on where in sine wave
		if (inval[9])
			addr = ~inval[8:0]; //second and fourth quadrant
		else
			addr = inval[8:0]; //first and third quadrant
			
		//special cases (change to case statement??)
		case(prevangle)
			ONE: begin
				outval.intpart = 1;
				outval.fracpart = 0;
			end
			NEG_ONE: begin
				outval.intpart = -1;
				outval.fracpart = 0;
			end
			NEGATIVE: outval = -lutout;
			POSITIVE: outval = lutout;
		endcase
		
	end
	
	
endmodule
