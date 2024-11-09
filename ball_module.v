/////////////////////////////////////////////////////////////////////////////////////////////////////////////


module ball_module(ball_x, ball_y, ball_colour, ball_plot, bounce, BOUNCE_LEFT, BOUNCE_RIGHT, BOUNCE_UP, BOUNCE_DOWN, CLOCK_50, resetn, colourButton, IsPosX, IsPosY, lost, restart, won);

      input colourButton;
      input CLOCK_50, resetn;

    	wire ballDone;
	   wire ballEnable;
		
		input lost, won;
		
		input restart;
	
	   wire ld_c_ball;
	 
	   output [7:0] ball_x, ball_y;
	   output [2:0] ball_colour;
	   
		output ball_plot;
	
	   input bounce;	
	
	   input BOUNCE_LEFT, BOUNCE_RIGHT, BOUNCE_UP, BOUNCE_DOWN;	
		
		output IsPosX, IsPosY;


    	datapath ball_data_path(
		.enable(ballEnable),
		.CLOCK_50(CLOCK_50),
		.ld_c(ld_c_ball),
		.COLOUR_IN(3'b111),
		.reset_n(resetn),
		.X_OUT(ball_x),
		.Y_OUT(ball_y),
		.COLOUR_OUT(ball_colour),
		.bounce(bounce),
		.BOUNCE_UP(BOUNCE_UP), 
		.BOUNCE_DOWN(BOUNCE_DOWN), 
		.BOUNCE_LEFT(BOUNCE_LEFT), 
		.BOUNCE_RIGHT(BOUNCE_RIGHT),
		.IsPosX(IsPosX), 
		.IsPosY(IsPosY), 
		.lost(lost), 
		.restart(restart),
		.won(won)
		 );
	
	
	   control ball_control_path(CLOCK_50,resetn,colourButton,ballEnable,ld_c_ball, ball_plot);




endmodule

// BALL CIRCUIT


// Datapath

module datapath(enable,CLOCK_50,ld_c,COLOUR_IN,reset_n,X_OUT,Y_OUT,COLOUR_OUT, bounce, BOUNCE_LEFT, BOUNCE_RIGHT, BOUNCE_DOWN, BOUNCE_UP, IsPosX, IsPosY, lost, restart, won);

   input bounce, BOUNCE_LEFT, BOUNCE_RIGHT, BOUNCE_UP, BOUNCE_DOWN;

	input enable,CLOCK_50,reset_n,ld_c;

	input [2:0] COLOUR_IN;

	output[7:0] X_OUT, Y_OUT;

	output[2:0] COLOUR_OUT;
	
	input lost, won;
	
	input restart;

	

	wire[19:0] current_delay;

	wire[3:0] frames_passed;

	wire[7:0] X_ScreenPos, Y_ScreenPos;

	wire[2:0] colour_new;


	
	// Count the delay

	delay_counter dc(CLOCK_50,reset_n,enable,current_delay);

	assign delay_passed = (current_delay ==  20'd0) ? 1 : 0;




    // check whether all pixels in the array have been output

	frame_counter fc(CLOCK_50,reset_n,delay_passed,frames_passed);

	assign canOutputPixels = (frames_passed == 4'b0100) ? 1 : 0;


	output IsPosX, IsPosY;

	// Modify positions of x and y in the screen space and output those new positions

	x_counter xc(CLOCK_50,canOutputPixels,reset_n,canOutputPixels, X_ScreenPos, BOUNCE_LEFT, BOUNCE_RIGHT, IsPosX, lost, restart, won);

	y_counter yc(CLOCK_50,canOutputPixels,reset_n,canOutputPixels, Y_ScreenPos, bounce, BOUNCE_DOWN, BOUNCE_UP, IsPosY, lost, restart, won);

	


	assign colour_new = (frames_passed == 4'b0100) ? 3'b000 : COLOUR_IN;

	pixel_array_generator pag(X_ScreenPos, Y_ScreenPos, colour_new, ld_c, CLOCK_50, reset_n, enable, X_OUT, Y_OUT, COLOUR_OUT);

endmodule	






// Control module

module control(CLOCK_50, reset_n, colourButton, enable, ld_c, canDraw);

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







// Counter

module counter(CLOCK_50,reset_n,enable, OUT);

	input CLOCK_50, reset_n, enable;

	output reg [1:0] OUT;

	always @(posedge CLOCK_50)
	begin
		if(reset_n == 1'b0)
			OUT <= 2'b00;
		else if(enable == 1'b1)
		begin
		  if(OUT == 2'b11)
			  OUT <= 2'b00;
		  else
			  OUT <= OUT + 1'b1;
		end
   end
endmodule







// Delay counter

module delay_counter(CLOCK_50,reset_n,enable, DELAY_OUT);

		input CLOCK_50;

		input reset_n;

		input enable;

		output reg [19:0] DELAY_OUT;

		always @(posedge CLOCK_50)
		begin
			if(reset_n == 1'b0)
				DELAY_OUT <= 20'b11001110111001100001;
			else if(enable ==1'b1)
			begin
			   if(DELAY_OUT == 20'd0)
					DELAY_OUT <= 20'b11001110111001100001;
				else
					DELAY_OUT <= DELAY_OUT - 1'b1;
			end
		end
endmodule






// Frame counter

module frame_counter(CLOCK_50, reset_n,enable, FRAME_OUT);

	input CLOCK_50,reset_n,enable;

	output reg [3:0] FRAME_OUT;

	always @(posedge CLOCK_50)
	begin
		if(reset_n == 1'b0)
			FRAME_OUT <= 4'b0000;
		else if(enable == 1'b1)
		begin
		  if(FRAME_OUT == 4'b0100)
			  FRAME_OUT <= 4'b0000;
		  else
			  FRAME_OUT <= FRAME_OUT + 1'b1;
		end
   end
endmodule







// Counts the on-screen x position of the ball

module x_counter(CLOCK_50, slow_clock, reset_n, enable, OUT, BOUNCE_LEFT, BOUNCE_RIGHT, IsPosX, lost, restart, won);

   input BOUNCE_LEFT, BOUNCE_RIGHT;

	input CLOCK_50,enable,reset_n, slow_clock;
	
	input restart;
	
	input lost, won;

	output reg[7:0] OUT;

	output reg IsPosX;

    always@(posedge slow_clock)
	    begin
		    if(reset_n == 1'b0)
			    IsPosX <= 1'b1;
		    else
		        begin
					   if(BOUNCE_LEFT)
							IsPosX <= 1'b0;	
						else if(BOUNCE_RIGHT)
						    IsPosX <= 1'b1;					  
			        if(IsPosX == 1'b1)
			            begin									 
				            if(OUT == 8'd159)
					            IsPosX <= 1'b0;
				            else if(BOUNCE_LEFT == 1'b0 && BOUNCE_RIGHT == 1'b0)
					            IsPosX <= 1'b1;							
			            end
			        else if(IsPosX == 1'b0)
			            begin
				            if(OUT == 8'b00000000)
					            IsPosX <= 1'b1;
								else if(BOUNCE_LEFT == 1'b0 && BOUNCE_RIGHT == 1'b0) 
								   IsPosX <= 1'b0;
								
			            end
		        end
	    end



	always@(negedge slow_clock)
	    begin
	        if(reset_n == 1'b0 || restart)
			    OUT <= 8'b00000000;
	        else
			    begin
				     if(!lost && !won)
					  begin
			            if(IsPosX == 1'b1)
				            OUT <= OUT + 1'b1;
			            else
				            OUT <= OUT - 1'b1;
					  end
		        end
		end        
endmodule








// Counts the on-screen y position of the ball

module y_counter(CLOCK_50, slow_clock, reset_n, enable, OUT, bounce, BOUNCE_DOWN, BOUNCE_UP, IsPosY, lost, restart, won);

   input BOUNCE_DOWN, BOUNCE_UP;

   input bounce;

	input CLOCK_50, enable, reset_n, slow_clock;

	output reg[7:0] OUT;
	
	input lost, won;
	
	input restart;

   output reg IsPosY;
	
	 
	 reg first;
	 always @(posedge CLOCK_50)
	 begin
		if (reset_n == 1'b0)
			first <= 1'b0;
		else if (first != 1'b1)
			first <= 1'b1;
	 end	 
	 

	always@(posedge CLOCK_50)
	    begin
		    if(reset_n == 1'b0)
			    IsPosY <= 1'b1;
		    else
		        begin
					  if(BOUNCE_DOWN == 1'b1)
					      IsPosY <= 1'b1;
						else if(BOUNCE_UP == 1'b1)
						   IsPosY <= 1'b0;					  
			        if(IsPosY == 1'b1)
			            begin								 
							   if(bounce == 1'b1 || OUT == 8'd119)
								    IsPosY <= 1'b0;
			 	            else if(BOUNCE_DOWN == 1'b0 && BOUNCE_UP == 1'b0)
					            IsPosY <= 1'b1;
			            end
			        else
			            begin
				            if(OUT <= 8'b00000010)
					            IsPosY <= 1'b1;
				            else if(BOUNCE_DOWN == 1'b0 && BOUNCE_UP == 1'b0)
					            IsPosY <= 1'b0;
			            end
		        end
		end



	always@(negedge slow_clock)
	    begin
	        if(reset_n == 1'b0 || restart)
			    OUT <= 8'b00111100;
	        else
			    begin
				     if(!lost && !won)
					  begin
			            if(IsPosY == 1'b1)
				            OUT <= OUT + 1'b1;
			            else
				            OUT <= OUT - 1'b1;
					 end			
		        end  
        end		
endmodule








// Stores and outputs pixels of 2d-array

module pixel_array_generator(X_IN, Y_IN, COLOUR_IN, ld_c, CLOCK_50, reset_n, enable, X_OUT, Y_OUT, COLOUR_OUT);

	input reset_n, enable, CLOCK_50, ld_c;

	input [7:0] X_IN, Y_IN;

	input [2:0] COLOUR_IN;

	output[7:0] X_OUT;

	output [7:0] Y_OUT;

	output [2:0] COLOUR_OUT;


	reg [7:0] tempX, tempY;
	reg [2:0] tempC;

	
	always @(posedge CLOCK_50) 
	    begin
            if (!reset_n) 
                begin
                    tempX <= 7'b0; 
                    tempY <= 7'b0;
			        tempC <= 3'b0;
                end
            else 
                begin
                    tempX <= X_IN;
                    tempY <= Y_IN;
				    if(ld_c == 1'b1)
					    tempC <= COLOUR_IN;
                end
        end



    wire [1:0] xPixel, yPixel;

    combinedCounter combCount(xPixel, yPixel, CLOCK_50, reset_n, enable);


    assign COLOUR_OUT = tempC;

    assign Y_OUT = tempY + yPixel;

	assign X_OUT = tempX + xPixel;



endmodule



module combinedCounter(X_OUT, Y_OUT, CLOCK_50, reset_n, enable);
    
	output reg [7:0] X_OUT, Y_OUT;
	input CLOCK_50, reset_n, enable;
	 
	always @(posedge CLOCK_50)
	begin
		if(reset_n == 1'b0)
		begin
			X_OUT <= 2'b00;
			Y_OUT <= 2'b00;
		end
		else if(enable == 1'b1)
		    begin
		        if(X_OUT == 2'b01)
		            begin
			            X_OUT <= 2'b00;
                        if(Y_OUT == 2'b01)
 			                Y_OUT <= 2'b00;
 			            else
                            Y_OUT <= Y_OUT + 1'b1;
			        end
		        else
			        X_OUT <= X_OUT + 1'b1;
		    end
    end
    
endmodule