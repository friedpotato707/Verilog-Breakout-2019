module player(enable, reset_n, CLOCK_50, leftKey, rightkey, COLOUR_IN, COLOUR_OUT, X_OUT, Y_OUT, DONE);

    output wire [7:0] X_OUT, Y_OUT;
	input enable, enable1, reset_n, CLOCK_50, leftKey, rightKey;
	output wire [2:0] COLOUR_OUT;
	input [2:0] COLOUR_IN;
    output wire DONE;
	
	ball_datapath bd0(enable,CLOCK_50,ld_c,3'b111,KEY[0],x,y,colour, DONE);
	ball_control bc0(CLOCK_50,KEY[0],~KEY[1],enable,ld_c,writeEn);
	
	
	
	paddle_datapath d0(
                .leftKey(~KEY[3]), 
                .rightKey(~KEY[2]), 
                .enable(enable1),
                .CLOCK_50(CLOCK_50),
                .ld_c(ld_c),
                .COLOUR_IN(3'b111),
                .reset_n(KEY[0]),
                .X_OUT(x),
                .Y_OUT(y),
                .COLOUR_OUT(colour)
				.DONE(DONE)
                );
	
	paddle_control c0(
	           .CLOCK_50(CLOCK_50),
	           .reset_n(KEY[0]),
	           .colourButton(~KEY[1]),
	           .enable(enable1),
	           .ld_c(ld_c),
	           .canDraw(writeEn)
	           );


endmodule;