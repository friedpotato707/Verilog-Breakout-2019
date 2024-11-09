/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


module paddle_module(paddle_x, paddle_y, paddle_colour, paddle_plot, CLOCK_50, resetn, colourButton, leftKey, rightKey, lost, restart);
      
		input leftKey, rightKey;

      input colourButton;
		
		input lost, restart;
	
      input CLOCK_50, resetn;   
		
	   output [7:0] paddle_x, paddle_y;
	   output [2:0] paddle_colour;
	   output paddle_plot;
		
		wire ld_c_paddle;
		
		wire paddleDone;
		
	   paddle_datapath d0(
		    .leftKey(leftKey), 
		    .rightKey(rightKey), 
		    .enable(paddleEnable),
		    .CLOCK_50(CLOCK_50),
		    .ld_c(ld_c_paddle),
		    .COLOUR_IN(3'b111),
		    .reset_n(resetn),
		    .X_OUT(paddle_x),
		    .Y_OUT(paddle_y),
		    .COLOUR_OUT(paddle_colour),
		    .DONE(paddleDone), 
			 .lost(lost),
			 .restart(restart)
		 );
	
	    paddle_control c0(
	       .CLOCK_50(CLOCK_50),
	       .reset_n(resetn),
	       .colourButton(colourButton),
	       .enable(paddleEnable),
	       .ld_c(ld_c_paddle),
	       .canDraw(paddle_plot)
	    );





endmodule




// PADDLE CIRCUIT
module paddle_control(canDraw, colourButton, reset_n, CLOCK_50, enable, ld_c);
	input CLOCK_50, reset_n, colourButton;
	
	output reg enable, ld_c, canDraw;	
	
	reg [3:0] current_state, next_state;
	
	// States
	localparam  S_LOAD_C = 4'd0,
                S_LOAD_C_WAIT = 4'd1,
			    Exec = 4'd2;
	
	// Next state logic
	always@(*)
        begin: state_table
            case (current_state)
                Exec: next_state = Exec;
                default: next_state = Exec;
            endcase
        end 
   
    // Output logic
	always@(*)
      begin: enable_signals
          ld_c = 1'b0;
		  enable = 1'b0;
		  canDraw = 1'b0;
		  
		  case(current_state)
			    S_LOAD_C_WAIT:
			        begin
                        ld_c = 1'b1;
			        end		
				Exec:
				    begin
				        ld_c = 1'b1;
					    enable = 1'b1;
					    canDraw = 1'b1;
					end
				default:
				    begin
                        // do nothing here
				    end
		  endcase
    end
	 
	 // Current state registers
	 always@(posedge CLOCK_50)
      begin: state_FFs
        if(!reset_n)
            current_state <= Exec;
        else
            current_state <= next_state;
      end 
endmodule





// Datapath

module paddle_datapath(COLOUR_OUT, X_OUT, Y_OUT, COLOUR_IN, leftKey, rightKey, enable, CLOCK_50, ld_c, reset_n, DONE, lost, restart);

	input ld_c, CLOCK_50, reset_n, enable;
	
	output DONE;
	
	input lost, restart;

    // input colour
	input [2:0] COLOUR_IN;

    // when leftKey is pressed, paddle is moving left, when rightKey is pressed, paddle is 
    // moving right, if none of them are pressed, paddle stays on the same place.

	input leftKey, rightKey;	

    // output Colour
	output[2:0] COLOUR_OUT;

    // output X and Y positions
	output[7:0] X_OUT, Y_OUT;
	
	wire[19:0] current_delay;

	wire[3:0] frames_passed;
	
	// Count the delay

	paddle_delay_counter dc(
	                 .CLOCK_50(CLOCK_50),
	                 .reset_n(reset_n),
	                 .delay_passed(enable),
	                 .DELAY_OUT(current_delay)
	                 ); // value of delay counter
						  

	assign delay_passed = (current_delay ==  20'd0) ? 1 : 0;  // indicates whether delay passed


	// it takes 4 steps to draw the hole paddle, i.e. output each one of four horizontal 
	// pixels one after one

    // check whether all pixels in the array have been output

	paddle_frame_counter fc(
	                 .CLOCK_50(CLOCK_50),
	                 .reset_n(reset_n),
	                 .enable(delay_passed), 
	                 .FRAME_OUT(frames_passed)
	                 );  // count frames here
	
	assign canOutputPixels = (frames_passed == 4'b1111) ? 1 : 0; // when enough frames have passed

	/////////////////////////////////////////////////////////////

	
	wire[2:0] colour_new;

	wire[7:0] X_SCREEN_POS;

	assign colour_new = (frames_passed == 4'b1111) ? 3'b000 : COLOUR_IN;
	assign DONE = (frames_passed == 4'b1111) ? 1'b1 : 1'b0;


	// y always stays 119

	paddle_pixel_array_generator pag(
	                          .leftKey(leftKey), 
	                          .rightKey(rightKey), 
	                          .X_IN(X_SCREEN_POS), 
	                          .Y_IN(8'd110), 
	                          .COLOUR_IN(colour_new), 
	                          .ld_c(ld_c), 
	                          .CLOCK_50(CLOCK_50), 
	                          .reset_n(reset_n), 
	                          .enable(enable), 
	                          .X_OUT(X_OUT), 
	                          .Y_OUT(Y_OUT), 
	                          .COLOUR_OUT(COLOUR_OUT)
	                          );



	// Modify position of x in the screen space and output those new positions

	paddle_x_counter xc(
	             .leftKey(leftKey), 
	             .rightKey(rightKey), 
	             .slow_clock(canOutputPixels), 
	             .reset_n(reset_n), 
	             .X_OUT(X_SCREEN_POS), 
					 .lost(lost),
					 .restart(restart)
	             );

	////////////////////////////////////////////////

endmodule






// Counter that counts from 0 to 3

module paddle_counter(OUT, reset_n, enable, CLOCK_50);

	input CLOCK_50, reset_n, enable;
	output reg [3:0] OUT;
	
	always @(posedge CLOCK_50)
	begin
		if(reset_n == 1'b0)
			OUT <= 4'b1111;
		else if(enable == 1'b1)
		begin
		  if(OUT == 4'b1111)
			  OUT <= 4'b0000;
		  else
			  OUT <= OUT + 1'b1;
		end
   end
endmodule






// This counter counts from 847457 to 0

module paddle_delay_counter(DELAY_OUT, reset_n, delay_passed, CLOCK_50);
		
		input CLOCK_50, delay_passed, reset_n;
		
		output reg [19:0] DELAY_OUT;
		
		always @(posedge CLOCK_50)
		begin
			if(reset_n == 1'b0)
				DELAY_OUT <= 20'b10000000000000000000;
			else if(delay_passed == 1'b1)
			begin
			   if(DELAY_OUT == 20'd0 )
					DELAY_OUT <= 20'b10000000000000000000;
				else
					DELAY_OUT <= DELAY_OUT - 1'b1;
			end
		end
endmodule






// counts from 0 to 3

module paddle_frame_counter(FRAME_OUT, reset_n, enable, CLOCK_50);

	input CLOCK_50, reset_n, enable;

	output reg [3:0] FRAME_OUT;
	
	always @(posedge CLOCK_50)
	begin
		if(reset_n == 1'b0)
			FRAME_OUT <= 4'b0000;
		else if(enable == 1'b1)
		begin
		  if(FRAME_OUT == 4'b1111)
			  FRAME_OUT <= 4'b0000;
		  else
			  FRAME_OUT <= FRAME_OUT + 1'b1;
		end
   end
endmodule






// counts the position of x in the screen space

module paddle_x_counter(X_OUT, slow_clock, reset_n, leftKey, rightKey, lost, restart);

	input leftKey, rightKey, slow_clock, reset_n, restart;

	output reg[7:0] X_OUT;
	
	input lost;
	
	 reg first;
	 always @(negedge slow_clock)
	 begin
		if (reset_n == 1'b0 || restart)
			first <= 1'b0;
		else if (first != 1'b1)
			first <= 1'b1;
	 end		
	
	always@(negedge slow_clock)
	   begin
	   if (reset_n == 1'b0 || !first)
		    X_OUT <= 8'd0;
	   else
			begin
			if(!lost)
			    begin
			    if(rightKey == 1'b1 && X_OUT + 1'b1 < 8'b10011011)
				    X_OUT <= X_OUT + 4'b0100;
			    else if(leftKey == 1'b1 && X_OUT > 4'b0001)
				    X_OUT <= X_OUT - 4'b0100;
		       end
	      end
	   end		
endmodule





// Circuit that outputs pixels in the pixel array, starting from initial position

module paddle_pixel_array_generator(COLOUR_OUT, X_OUT, Y_OUT, X_IN, Y_IN, COLOUR_IN, leftKey, rightKey, ld_c, enable, reset_n, CLOCK_50);

	input [2:0] COLOUR_IN;

	input [7:0] Y_IN, X_IN;

	output [2:0] COLOUR_OUT;

	output[7:0] X_OUT, Y_OUT;

    input leftKey, rightKey, CLOCK_50, enable, ld_c, reset_n;

    // current x value of a pixel in a 2d array
	wire [3:0] xPixel;

    // initial x value of a pixel
	reg [7:0] initialX;

    // temporary colour used by this circuit
    reg [2:0] tempColour;

    // set COLOUR_OUT to temporary colour
    assign COLOUR_OUT = tempColour;

    assign Y_OUT = Y_IN; // assign output position for y
    assign X_OUT = initialX + xPixel; // assign output position for x
	
	always @ (posedge CLOCK_50) 
	    begin
            if(!reset_n) 
            begin
                initialX <= 7; 
			    tempColour <= 3'b000;
            end
            else 
                begin
                    initialX <= X_IN;
				    if(ld_c == 1)
					    tempColour <= COLOUR_IN;
                end
        end

	paddle_counter xPixelCounter(
	                      .CLOCK_50(CLOCK_50), 
	                      .reset_n(reset_n), 
	                      .enable(enable), 
	                      .OUT(xPixel)
	                      ); // counts from 0 to 3
    
endmodule