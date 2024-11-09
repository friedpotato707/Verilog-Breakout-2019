module game
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,   						//	VGA Blue[9:0], 
		HEX0, 
		HEX1, 
		HEX2, 
		HEX3
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;
	
	output reg [6:0] HEX0, HEX1, HEX2, HEX3;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock      
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	reg [2:0] colour;
	reg [7:0] x;
	reg [7:0] y;
   reg plot;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(plot),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		
		
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
	
	
	
	
	wire ballDone, paddleDone;
	wire ballEnable, paddleEnable;
	
	wire ld_c_ball;
	
	wire [7:0] ball_x, ball_y;
	wire [2:0] ball_colour;
	wire ball_plot;
	
	wire bounce;	
	
	wire BOUNCE_LEFT, BOUNCE_RIGHT, BOUNCE_UP, BOUNCE_DOWN;	
	
   wire IsPosX, IsPosY;
   
	
	ball_module ball_mod(
	                     .ball_x(ball_x), 
								.ball_y(ball_y), 
								.ball_colour(ball_colour), 
								.ball_plot(ball_plot), 
								.bounce(bounce), 
								.BOUNCE_LEFT(BOUNCE_LEFT), 
								.BOUNCE_RIGHT(BOUNCE_RIGHT), 
								.BOUNCE_UP(BOUNCE_UP),
								.BOUNCE_DOWN(BOUNCE_DOWN), 
								.CLOCK_50(CLOCK_50), 
								.resetn(resetn),
								.colourButton(~KEY[1]), 
								.IsPosX(IsPosX), 
								.IsPosY(IsPosY), 
								.lost(lost), 
								.restart(~KEY[1]),
								.won(won)
								);
	
	
	wire ld_c_paddle;
	
	wire [7:0] paddle_x, paddle_y;
	wire [2:0] paddle_colour;
	wire paddle_plot;
	
	// indicates whether player has lost the game
	wire lost;
   //assign lost = (bounce == 1'b0 && ball_y == 8'd119) ? 1 : 0 ;	
		
		
		paddle_module paddle_mod(
		                         .paddle_x(paddle_x), 
										 .paddle_y(paddle_y), 
										 .paddle_colour(paddle_colour), 
										 .paddle_plot(paddle_plot), 
										 .CLOCK_50(CLOCK_50), 
										 .resetn(resetn),
										 .colourButton(~KEY[1]), 
		                         .leftKey(~KEY[3]), 
		                         .rightKey(~KEY[2]), 
										 .lost(lost),
										 .restart(~KEY[1])
										 );
		
	   
	wire [1:0] mfsm_out_sig;
	wire [1:0] mfsm_in_sig;
	   
		
    reg [19:0] DELAY_OUT;
	 
	 
	 
	 
//	     always @(posedge CLOCK_50)
//		begin
//			if(resetn == 1'b0)
//				DELAY_OUT <= 20'b10000000000000111000;
//			else
//			begin
//			   if(DELAY_OUT == 20'd0 )
//					DELAY_OUT <= 20'b10000000000000111000;
//				else
//					DELAY_OUT <= DELAY_OUT - 1'b1;
//			end
//		end
		
	 
	 
		
    always @(posedge CLOCK_50)
		begin
			if(resetn == 1'b0)
				DELAY_OUT <= 20'b11000001000000011000;
			else
			begin
			   if(DELAY_OUT == 20'd0 )
					DELAY_OUT <= 20'b11000001000000011000;
				else
					DELAY_OUT <= DELAY_OUT - 1'b1;
			end
		end
		
		
			// States
	localparam  drawPaddle = 4'd0,
               drawBall = 4'd1, 
					drawBricks = 4'd2, 
					lose_state = 4'd3,
					win_state = 4'd4;
				
					
	reg [4:0] current_state, next_state;
	
	
	
	
//	                drawPaddle: next_state = (DELAY_OUT == 20'b00000000000000101000) ? drawBall : drawPaddle;
//					 //waitS: next_state = 
//					 drawBall: next_state = (DELAY_OUT == 20'b00000000000000100000) ? drawBricks : drawBall;
//					 
//					 drawBricks: next_state = (DELAY_OUT == 20'b00000000000000000000) ? drawPaddle : drawBricks;




///////////////////////////////// BRICKS BEFORE BALL


//	                drawPaddle: next_state = (DELAY_OUT == 20'b00000001000000001000) ? drawBall : drawPaddle;
//					 //waitS: next_state = 
//					 drawBall: next_state = (DELAY_OUT == 20'b00000001000000000000) ? drawBricks : drawBall;
//					 
//					 drawBricks: next_state = (DELAY_OUT == 20'b00000000000000000000) ? drawPaddle : drawBricks;
		
	
	
		  
	// Next state logic
	always@(*)
        begin: state_table
            case (current_state)
	                drawPaddle: next_state = (DELAY_OUT == 20'b01000001000000001000) ? drawBricks : drawPaddle;
					 
					 drawBricks: next_state = (DELAY_OUT == 20'b00000000000000001000) ? drawBall : drawBricks;
					 
					 drawBall: next_state = (DELAY_OUT == 20'b00000000000000000000) ? lose_state : drawBall;
					 
					 lose_state: next_state = (lost == 1'b1) ? lose_state : win_state;
					 
					 win_state: next_state = (won == 1'b1) ? win_state : drawPaddle;
										 
                default: next_state = drawPaddle;
            endcase
		  end
		 
  
		  
 wire [7:0] BR_X, BR_Y;	 


   wire delay_passed; 
	
	
	wire [7:0] brick_x, brick_y;
	wire [2:0] brick_colour;
	
	
	
	wire [7:0] COLLISION_X, COLLISION_Y;
	
	
	assign update_br = (DELAY_OUT == 20'b00000000000000001000) ? 1 : 0;
	
	
	brick_module brick_mod(
	                              .CLOCK_50(CLOCK_50), 
											.XOUT(brick_x), 
											.YOUT(brick_y), 
											.COLOUR(brick_colour), 
											.RESETN(resetn), 
											.COLLISION_X_IN(COLLISION_X), 
											.COLLISION_Y_IN(COLLISION_Y), 
											.BOUNCE_LEFT(BOUNCE_LEFT), 
											.BOUNCE_RIGHT(BOUNCE_RIGHT), 
											.BOUNCE_UP(BOUNCE_UP), 
											.BOUNCE_DOWN(BOUNCE_DOWN),
											.update_br(update_br),
											.X_IN(BR_X), 
											.Y_IN(BR_Y)
											);
											
		
    wire [2:0] CUR_COLOUR;			
											
	 reg [6:0] pixel_counter; // First four for counting to 16 and next to count to 8
    always @(posedge CLOCK_50)
    begin
        if (resetn == 1'b0)
            pixel_counter <= 7'd0;
        else
            pixel_counter <= pixel_counter + 1'b1;
    end									
		  
		  
    // Output logic
	always@(*)
	   begin
		  case(current_state)
			    drawBall:
				 begin
				 plot = ball_plot;
				 	x = ball_x;
					y = ball_y;
					colour = ball_colour;
				 end
				 
				 drawPaddle:
				 begin
				 plot = paddle_plot;
					x = paddle_x;
					y = paddle_y;
					colour = paddle_colour;
				end
				 drawBricks:
				 begin
				   plot = 1'b1;
					x = BR_X + pixel_counter[3:0];                              //////////////////////BR_X;
					y = BR_Y + pixel_counter[6:4];                             ////////////// BR_Y;
					colour = CUR_COLOUR;                    //////3'b111;				
				 end
		  endcase
    end		  
		  
		  
		  
   // Current state registers
	 always@(posedge CLOCK_50)
      begin: state_FFs
        if(!resetn)
            current_state <= drawPaddle;
        else
            current_state <= next_state;
      end 		

		    
		  
    collision_detector cdet(
	                         .CLOCK_50(CLOCK_50), 
									 .reset_n(resetn), 
									 .ball_x_in(ball_x), 
									 .ball_y_in(ball_y), 
									 .paddle_x_in(paddle_x), 
									 .BOUNCE(bounce),
									 .lost(lost),
									 .restart(~KEY[1])
									 );
									 
	
	
	reg [7:0] score;
	wire [29:0] fake_score;
	wire bfirst;			 
			
	always @(posedge CLOCK_50)
		begin
			if (!resetn || ~KEY[1])
				score <= 8'd0;
			if(bfirst == 1'b1)
			begin
			if (fake_score % 30'd10000 == 0)
				begin
					score <= score + 1'b1;
				end
			end
		end
		
	wire [11:0] bcd_digits;
		
	bin_to_bcd bcd(
		.binary(score - 8'd167), 
		.binary_coded_decimal(bcd_digits)
	);
		
	hex_decoder h0(
		.HEX(bcdhex0),
		.C(bcd_digits[3:0])
	);
	
	hex_decoder h1(
		.HEX(bcdhex1),
		.C(bcd_digits[7:4])
	);
	
	hex_decoder h2(
		.HEX(bcdhex2),
		.C(bcd_digits[11:8])
	);
	
	assign bcdhex3 = 7'b1000000;
	
	wire won;
	
	wire [6:0] bcdhex0;
	wire [6:0] bcdhex1;
	wire [6:0] bcdhex2;
	wire [6:0] bcdhex3;

	wire [6:0] texthex0;
	wire [6:0] texthex1;
	wire [6:0] texthex2;
	wire [6:0] texthex3;
		
	wire [2:0] tin0;
	wire [2:0] tin1;
	wire [2:0] tin2;
	wire [2:0] tin3;
		
	assign tin0 = (lost == 1'b1) ? 3'd3 : 3'd7;
	assign tin1 = (lost == 1'b1) ? 3'd2 : 3'd6;
	assign tin2 = (lost == 1'b1) ? 3'd1 : 3'd5;
	assign tin3 = (lost == 1'b1) ? 3'd0 : 3'd4;
		
	decoder d0(
		.SEGMENT(texthex0),
		.data_in(tin0)
	);
	
	decoder d1(
		.SEGMENT(texthex1),
		.data_in(tin1)
	);
	
	decoder d2(
		.SEGMENT(texthex2),
		.data_in(tin2)
	);
	
	decoder d3(
		.SEGMENT(texthex3),
		.data_in(tin3)
	);
	
	wire ended;
	assign ended = (lost == 1'b1 || won == 1'b1) ? 1 : 0;
	
	always @(*)
	begin
		case(ended)
			1'b1: begin
				HEX0 = texthex0;
				HEX1 = texthex1;
				HEX2 = texthex2;
				HEX3 = texthex3;
			end
			1'b0: begin
				HEX0 = bcdhex0;
				HEX1 = bcdhex1;
				HEX2 = bcdhex2;
				HEX3 = bcdhex3;
			end
		endcase
	end
	
    brick_collision_detector bld(
	                          .CLOCK_50(CLOCK_50), 
									  .BALL_X_IN(ball_x), 
									  .BALL_Y_IN(ball_y), 
									  .reset_n(resetn), 
									  .X_IN(BR_X), 
									  .Y_IN(BR_Y), 
									  .BOUNCE_LEFT(BOUNCE_LEFT), 
									  .BOUNCE_RIGHT(BOUNCE_RIGHT), 
									  .BOUNCE_DOWN(BOUNCE_DOWN), 
									  .BOUNCE_UP(BOUNCE_UP),
									  .COLLISION_X(COLLISION_X), 
									  .COLLISION_Y(COLLISION_Y),
									  .ALLOW_DECR(update_br), 
									  .CURRENT_COLOUR(CUR_COLOUR), 
									  .IsPosX(IsPosX), 
									  .IsPosY(IsPosY),
									  .fake_score(fake_score),
									  .bounce_first(bfirst),
									  .won(won),
									  .restart(~KEY[1])
								     );		
			
		
	 wire [7:0] COUNT;
			
	 brick_delay_counter bdc(
	                         .CLOCK_50(CLOCK_50), 
									 .reset_n(resetn), 
									 .COUNT(COUNT)
									 );
								
	 assign brick_clock = (COUNT == 8'd127) ? 1 : 0;		

    brick_collision_counter(
	                         .CLOCK_50(brick_clock), 
									 .reset_n(resetn), 
									 .X_OUT(BR_X), 
									 .Y_OUT(BR_Y)
									 );			


endmodule


// TODO
// make player loose
// increment score
// make restart on loss
// 



module collision_detector(CLOCK_50, reset_n, ball_x_in, ball_y_in, paddle_x_in, BOUNCE, lost, restart);
	 
	 input restart;
	 
	 reg first;
	 always @(posedge CLOCK_50)
	 begin
		if (reset_n == 1'b0 || restart)
			first <= 1'b0;
		else if (first != 1'b1)
			first <= 1'b1;
	 end	 

    input [7:0] ball_x_in, ball_y_in, paddle_x_in;
	 input CLOCK_50, reset_n;
	 
	 output reg lost;
	 
	 output reg BOUNCE;
	 
	 always @ (posedge CLOCK_50)
	 begin
	     if(!reset_n || !first)
		      begin
				BOUNCE <= 1'b0;
				lost <= 1'b0;
				end
		  else
		      begin
                if(ball_y_in >= 8'd110)
					     begin
								if (ball_y_in >= 8'd115)
								   lost <= 1'b1;
					         else if(ball_x_in - paddle_x_in <= 8'd3 ||  paddle_x_in - ball_x_in <= 8'd3)
								begin
					             BOUNCE <= 1'b1;
									 lost <= 1'b0;
								end
						  end			 
					 else
					     begin
						      BOUNCE <= 1'b0;
					     end
		       end
				
	 end	 
	 
//	 always @ (posedge CLOCK_50)
//	 begin
//	     if(!reset_n || first == 1'b0)
//		      begin
//		      lost <= 1'b0;
//				BOUNCE <= 1'b0;
//				end
//		  else
//		      begin
//                if(ball_y_in >= 8'd110 && ball_y_in <= 8'd112)
//					     begin
//								if (paddle_x_in <= ball_x_in && ball_x_in <= paddle_x_in + 8'd7)
//								//if(ball_x_in - paddle_x_in <= 8'd3 ||  paddle_x_in - ball_x_in <= 8'd3)
//									begin
//										BOUNCE <= 1'b1;
//										lost <= 1'b0;
//									end
//						  end		
//					 else if (ball_y_in > 8'd117)
//					 begin
//					   BOUNCE <= 1'b0;
//						lost <= 1'b1;
//						end
//					 else
//					     begin
//						      BOUNCE <= 1'b0;
//						      data_0 <= 3'b000;
//					         data_1 <= 3'b001;
//					         data_2 <= 3'b010;
//					         data_3 <= 3'b011;
//					     end                
//		       end
//				
//	 end
	 
//	 always @ (posedge CLOCK_50)
//	 begin
//	     if(!reset_n)
//		      begin
//		      LOST_OUT <= 1'b0;
//				BOUNCE <= 1'b0;
//				end
//		  else
//		      begin
//                if(ball_y_in >= 8'd117)
//					     begin
//					         if(ball_x_in - paddle_x_in <= 8'd3 ||  paddle_x_in - ball_x_in <= 8'd3)
//					             BOUNCE <= 1'b1;
//						  end			 
//					 else
//					     begin
//						      BOUNCE <= 1'b0;
//						      data_0 <= 3'b000;
//					         data_1 <= 3'b001;
//					         data_2 <= 3'b010;
//					         data_3 <= 3'b011;
//						      LOST_OUT <= 1'b1;
//					     end
//		       end
//				
//	 end	 
	 
	 reg [2:0] data_0;	
	 reg [2:0] data_1;
    reg [2:0] data_2;
    reg [2:0] data_3;	
	 
	 wire w0, w1, w2, w3;
	 
	 assign w0 = data_0;
	 assign w1 = data_1;
	 assign w2 = data_2;
	 assign w3 = data_3;

	 

endmodule




module decoder(SEGMENT, data_in);

    output reg [6:0] SEGMENT;
	 
	 input [2:0] data_in;
	 
	 always @ (*)
	 begin
	     case(data_in)
		      3'b000:
				// lETTER l
				SEGMENT = 7'b1000111;
				
			   3'b001:
				// lETTER o
				SEGMENT = 7'b1000000;
				
				3'b010:
				// lETTER s
				SEGMENT = 7'b0010010;
				
				3'b011:
				// lETTER e
				SEGMENT = 7'b0000110;
				
				3'b100:
				// W left side
				SEGMENT = 7'b1000011;
				
				3'b101:
				// W right side
				SEGMENT = 7'b1100001;
				
				3'b110:
				// i
				SEGMENT = 7'b1101111;
				
				3'b111:
				// n
				SEGMENT = 7'b0101011;
				
				default:
				SEGMENT = 7'b1111111;
		  endcase
	 end

endmodule

module brick_collision_detector(restart, won, bounce_first, fake_score, ALLOW_DECR, CLOCK_50, BALL_X_IN, BALL_Y_IN, reset_n, X_IN, Y_IN, BOUNCE_LEFT, BOUNCE_RIGHT, BOUNCE_DOWN, BOUNCE_UP, COLLISION_X, COLLISION_Y, CURRENT_COLOUR, IsPosX, IsPosY);

output reg BOUNCE_LEFT, BOUNCE_RIGHT, BOUNCE_UP, BOUNCE_DOWN;
input [8:0] X_IN, Y_IN, BALL_X_IN, BALL_Y_IN;
input CLOCK_50, reset_n;

output reg [7:0] COLLISION_X, COLLISION_Y;

input ALLOW_DECR, restart;

reg canDecr;

output reg [29:0] fake_score;

input IsPosX, IsPosY;

output reg [2:0] CURRENT_COLOUR;

output won;

assign choice1 = BALL_Y_IN <= Y_IN && (Y_IN - BALL_Y_IN == 8'd0 || Y_IN - BALL_Y_IN == 8'd8);
assign choice2 = BALL_X_IN <= X_IN && (X_IN - BALL_X_IN == 8'd0 || X_IN - BALL_X_IN == 8'd16);

// Brick data
    reg [2:0] bricks[39:0];
	 
	 reg first;
	 always @(posedge CLOCK_50)
	 begin
		if (reset_n == 1'b0 || restart)
			first <= 1'b0;
		else if (first != 1'b1)
			first <= 1'b1;
	 end

	 
	 	reg [19:0] DELAY_OUT;
	 
	 reg enable_del;
		
    always @(posedge CLOCK_50)
		begin
			if(reset_n == 1'b0 || enable_del == 1'b0)
				DELAY_OUT <= 20'b0000001000000001000;
			else if(enable_del == 1'b1)
			begin
			   if(DELAY_OUT == 20'd0 )
					DELAY_OUT <= 20'b00000001000000001000;
				else
					DELAY_OUT <= DELAY_OUT - 1'b1;
			end
		end																			
				
	 
	 
always @(posedge CLOCK_50)
begin 
    if(first == 1'b1)
									     begin
										      if(Y_IN == 8'd4)
												     begin
													      if(X_IN == 8'd2)
															    CURRENT_COLOUR <= bricks[0];
													      if(X_IN == 8'd22)
															    CURRENT_COLOUR <= bricks[1];
													      if(X_IN == 8'd42)
															    CURRENT_COLOUR <= bricks[2];
													      if(X_IN == 8'd62)
															    CURRENT_COLOUR <= bricks[3];
													      if(X_IN == 8'd82)
															    CURRENT_COLOUR <= bricks[4];
													      if(X_IN == 8'd102)
															    CURRENT_COLOUR <= bricks[5];
													      if(X_IN == 8'd122)
															    CURRENT_COLOUR <= bricks[6];
													      if(X_IN == 8'd142)
															    CURRENT_COLOUR <= bricks[7];																 
													  end
										      else if(Y_IN == 8'd16)
												     begin
													      if(X_IN == 8'd2)
															    CURRENT_COLOUR <= bricks[8];
													      if(X_IN == 8'd22)
															    CURRENT_COLOUR <= bricks[9];
													      if(X_IN == 8'd42)
															    CURRENT_COLOUR <= bricks[10];
													      if(X_IN == 8'd62)
															    CURRENT_COLOUR <= bricks[11];
													      if(X_IN == 8'd82)
															    CURRENT_COLOUR <= bricks[12];
													      if(X_IN == 8'd102)
															    CURRENT_COLOUR <= bricks[13];
													      if(X_IN == 8'd122)
															    CURRENT_COLOUR <= bricks[14];
													      if(X_IN == 8'd142)
															    CURRENT_COLOUR <= bricks[15];																 
													  end
										      else if(Y_IN == 8'd28)
												     begin
													      if(X_IN == 8'd2)
															    CURRENT_COLOUR <= bricks[16];
													      if(X_IN == 8'd22)
															   CURRENT_COLOUR <= bricks[17];
													      if(X_IN == 8'd42)
															    CURRENT_COLOUR <= bricks[18];
													      if(X_IN == 8'd62)
															    CURRENT_COLOUR <= bricks[19];
													      if(X_IN == 8'd82)
															    CURRENT_COLOUR <= bricks[20];
													      if(X_IN == 8'd102)
															    CURRENT_COLOUR <= bricks[21];
													      if(X_IN == 8'd122)
															    CURRENT_COLOUR <= bricks[22];
													      if(X_IN == 8'd142)
															    CURRENT_COLOUR <= bricks[23];																 
													  end		
										      else if(Y_IN == 8'd40)
												     begin
													      if(X_IN == 8'd2)
															    CURRENT_COLOUR <= bricks[24];
													      if(X_IN == 8'd22)
															    CURRENT_COLOUR <= bricks[25];
													      if(X_IN == 8'd42)
															    CURRENT_COLOUR <= bricks[26];
													      if(X_IN == 8'd62)
															    CURRENT_COLOUR <= bricks[27];
													      if(X_IN == 8'd82)
															    CURRENT_COLOUR <= bricks[28];
													      if(X_IN == 8'd102)
															    CURRENT_COLOUR <= bricks[29];
													      if(X_IN == 8'd122)
															    CURRENT_COLOUR <= bricks[30];
													      if(X_IN == 8'd142)
															    CURRENT_COLOUR <= bricks[31];																 
													  end
										      else if(Y_IN == 8'd52)
												     begin
													      if(X_IN == 8'd2)
															    CURRENT_COLOUR <= bricks[32];
													      if(X_IN == 8'd22)
															    CURRENT_COLOUR <= bricks[33];
													      if(X_IN == 8'd42)
															    CURRENT_COLOUR <= bricks[34];
													      if(X_IN == 8'd62)
															    CURRENT_COLOUR <= bricks[35];
													      if(X_IN == 8'd82)
															    CURRENT_COLOUR <= bricks[36];
													      if(X_IN == 8'd102)
															    CURRENT_COLOUR <= bricks[37];
													      if(X_IN == 8'd122)
															    CURRENT_COLOUR <= bricks[38];
													      if(X_IN == 8'd142)
															    CURRENT_COLOUR <= bricks[39];																 
													  end														  
										  end
end

localparam red = 3'b100,
			  green = 3'b010,
			  blue = 3'b001,
			  black = 3'b000,
			  white = 3'b111,
			  yellow = 3'b110,
			  pink = 3'b101,
			  cyan = 3'b011;
			  

reg drawn;
reg won;

reg [2:0] level;

 reg second;
 always @(posedge CLOCK_50)
 begin
	if (reset_n == 1'b0)
		second <= 1'b0;
	else if (first != 1'b1)
		second <= 1'b1;
 end

always @(posedge CLOCK_50)
begin
	if (!second)
		level <= 3'd0;
	else if (restart)
		begin
			if (level == 3'd7)
				level <= 3'd0;
			else
				level <= level + 1'd1;
		end
end
 
output reg bounce_first;

always @(posedge CLOCK_50)
begin
        if(ALLOW_DECR == 1'b1)
		      canDecr <= 1'b1;
        if (first == 1'b0)
        begin
            // Bricks
				bounce_first <= 1'b0;
				enable_del <= 1'b0;
				canDecr <= 1'b1;
				drawn <= 1'b0;
				won <= 1'b0;
				fake_score <= 30'd0;
				
				// LEVEL 0
				if (level == 3'd0)
				begin
					bricks[0] <= 3'b000;
					bricks[1] <= 3'b111;
					bricks[2] <= 3'b111;
					bricks[3] <= 3'b111;
					bricks[4] <= 3'b111;
					bricks[5] <= 3'b111;
					bricks[6] <= 3'b111;
					bricks[7] <= 3'b000;

					bricks[8] <= 3'b000;
					bricks[9] <= 3'b011;
					bricks[10] <= 3'b011;
					bricks[11] <= 3'b011;
					bricks[12] <= 3'b011;
					bricks[13] <= 3'b011;
					bricks[14] <= 3'b011;
					bricks[15] <= 3'b000;

					
					bricks[16] <= 3'b000;
					bricks[17] <= 3'b010;	
					bricks[18] <= 3'b010;
					bricks[19] <= 3'b010;
					bricks[20] <= 3'b010;
					bricks[21] <= 3'b010;
					bricks[22] <= 3'b010;
					bricks[23] <= 3'b000;


					bricks[24] <= 3'b000;
					bricks[25] <= 3'b001;
					bricks[26] <= 3'b001;
					bricks[27] <= 3'b001;
					bricks[28] <= 3'b001;
					bricks[29] <= 3'b001;
					bricks[30] <= 3'b001;
					bricks[31] <= 3'b000;
					
					bricks[32] <= 3'b000;
					bricks[33] <= 3'b101;
					bricks[34] <= 3'b101;
					bricks[35] <= 3'b101;
					bricks[36] <= 3'b101;
					bricks[37] <= 3'b101;
					bricks[38] <= 3'b101;
					bricks[39] <= 3'b000;
				end
				
				// LEVEL 1 BOX
				else if (level == 3'd1)
				begin
					bricks[0] <= 3'b000;
					bricks[1] <= blue;
					bricks[2] <= blue;
					bricks[3] <= blue;
					bricks[4] <= blue;
					bricks[5] <= blue;
					bricks[6] <= blue;
					bricks[7] <= 3'b000;

					bricks[8] <= 3'b000;
					bricks[9] <= blue;
					bricks[10] <= black;
					bricks[11] <= black;
					bricks[12] <= black;
					bricks[13] <= black;
					bricks[14] <= blue;
					bricks[15] <= 3'b000;

					
					bricks[16] <= 3'b000;
					bricks[17] <= blue;	
					bricks[18] <= black;
					bricks[19] <= red;
					bricks[20] <= red;
					bricks[21] <= black;
					bricks[22] <= blue;
					bricks[23] <= 3'b000;


					bricks[24] <= 3'b000;
					bricks[25] <= blue;
					bricks[26] <= black;
					bricks[27] <= black;
					bricks[28] <= black;
					bricks[29] <= black;
					bricks[30] <= blue;
					bricks[31] <= 3'b000;
					
					bricks[32] <= 3'b000;
					bricks[33] <= blue;
					bricks[34] <= blue;
					bricks[35] <= blue;
					bricks[36] <= blue;
					bricks[37] <= blue;
					bricks[38] <= blue;
					bricks[39] <= 3'b000;
				end
				
				// LEVEL 2 Google
				else if (level == 3'd2)
				begin
					bricks[0] <= 3'b000;
					bricks[1] <= red;
					bricks[2] <= red;
					bricks[3] <= red;
					bricks[4] <= red;
					bricks[5] <= red;
					bricks[6] <= red;
					bricks[7] <= 3'b000;

					bricks[8] <= 3'b000;
					bricks[9] <= green;
					bricks[10] <= black;
					bricks[11] <= black;
					bricks[12] <= black;
					bricks[13] <= black;
					bricks[14] <= black;
					bricks[15] <= 3'b000;

					
					bricks[16] <= 3'b000;
					bricks[17] <= green;	
					bricks[18] <= black;
					bricks[19] <= yellow;
					bricks[20] <= yellow;
					bricks[21] <= yellow;
					bricks[22] <= cyan;
					bricks[23] <= 3'b000;


					bricks[24] <= 3'b000;
					bricks[25] <= green;
					bricks[26] <= black;
					bricks[27] <= black;
					bricks[28] <= black;
					bricks[29] <= black;
					bricks[30] <= cyan;
					bricks[31] <= 3'b000;
					
					bricks[32] <= 3'b000;
					bricks[33] <= green;
					bricks[34] <= blue;
					bricks[35] <= blue;
					bricks[36] <= blue;
					bricks[37] <= blue;
					bricks[38] <= blue;
					bricks[39] <= 3'b000;
				end
				
				// LEVEL 3 X
				else if (level == 3'd3)
				begin
					bricks[0] <= 3'b000;
					bricks[1] <= cyan;
					bricks[2] <= black;
					bricks[3] <= black;
					bricks[4] <= black;
					bricks[5] <= black;
					bricks[6] <= cyan;
					bricks[7] <= 3'b000;

					bricks[8] <= 3'b000;
					bricks[9] <= black;
					bricks[10] <= cyan;
					bricks[11] <= black;
					bricks[12] <= black;
					bricks[13] <= cyan;
					bricks[14] <= black;
					bricks[15] <= 3'b000;

					
					bricks[16] <= 3'b000;
					bricks[17] <= black;	
					bricks[18] <= black;
					bricks[19] <= cyan;
					bricks[20] <= cyan;
					bricks[21] <= black;
					bricks[22] <= black;
					bricks[23] <= 3'b000;


					bricks[24] <= 3'b000;
					bricks[25] <= black;
					bricks[26] <= cyan;
					bricks[27] <= black;
					bricks[28] <= black;
					bricks[29] <= cyan;
					bricks[30] <= black;
					bricks[31] <= 3'b000;
					
					bricks[32] <= 3'b000;
					bricks[33] <= cyan;
					bricks[34] <= black;
					bricks[35] <= black;
					bricks[36] <= black;
					bricks[37] <= black;
					bricks[38] <= cyan;
					bricks[39] <= 3'b000;
				end
				
				// LEVEL 4 SMILE
				else if (level == 3'd4)
				begin
					bricks[0] <= 3'b000;
					bricks[1] <= yellow;
					bricks[2] <= black;
					bricks[3] <= yellow;
					bricks[4] <= yellow;
					bricks[5] <= black;
					bricks[6] <= yellow;
					bricks[7] <= 3'b000;

					bricks[8] <= 3'b000;
					bricks[9] <= black;
					bricks[10] <= yellow;
					bricks[11] <= black;
					bricks[12] <= black;
					bricks[13] <= yellow;
					bricks[14] <= black;
					bricks[15] <= 3'b000;

					
					bricks[16] <= 3'b000;
					bricks[17] <= black;	
					bricks[18] <= black;
					bricks[19] <= black;
					bricks[20] <= black;
					bricks[21] <= black;
					bricks[22] <= black;
					bricks[23] <= 3'b000;


					bricks[24] <= 3'b000;
					bricks[25] <= black;
					bricks[26] <= yellow;
					bricks[27] <= black;
					bricks[28] <= black;
					bricks[29] <= yellow;
					bricks[30] <= black;
					bricks[31] <= 3'b000;
					
					bricks[32] <= 3'b000;
					bricks[33] <= yellow;
					bricks[34] <= black;
					bricks[35] <= yellow;
					bricks[36] <= yellow;
					bricks[37] <= black;
					bricks[38] <= yellow;
					bricks[39] <= 3'b000;
				end
				
				// LEVEL 5 Explosion
				else if (level == 3'd5)
				begin
					bricks[0] <= 3'b000;
					bricks[1] <= yellow;
					bricks[2] <= black;
					bricks[3] <= red;
					bricks[4] <= red;
					bricks[5] <= black;
					bricks[6] <= yellow;
					bricks[7] <= 3'b000;

					bricks[8] <= 3'b000;
					bricks[9] <= black;
					bricks[10] <= red;
					bricks[11] <= black;
					bricks[12] <= black;
					bricks[13] <= red;
					bricks[14] <= black;
					bricks[15] <= 3'b000;

					
					bricks[16] <= 3'b000;
					bricks[17] <= red;	
					bricks[18] <= black;
					bricks[19] <= black;
					bricks[20] <= black;
					bricks[21] <= black;
					bricks[22] <= red;
					bricks[23] <= 3'b000;


					bricks[24] <= 3'b000;
					bricks[25] <= black;
					bricks[26] <= red;
					bricks[27] <= black;
					bricks[28] <= black;
					bricks[29] <= red;
					bricks[30] <= black;
					bricks[31] <= 3'b000;
					
					bricks[32] <= 3'b000;
					bricks[33] <= yellow;
					bricks[34] <= black;
					bricks[35] <= red;
					bricks[36] <= red;
					bricks[37] <= black;
					bricks[38] <= yellow;
					bricks[39] <= 3'b000;
				end
				
				// LEVEL 6 258
				else if (level == 3'd6)
				begin
					bricks[0] <= 3'b000;
					bricks[1] <= red;
					bricks[2] <= red;
					bricks[3] <= green;
					bricks[4] <= green;
					bricks[5] <= red;
					bricks[6] <= red;
					bricks[7] <= red;

					bricks[8] <= 3'b000;
					bricks[9] <= black;
					bricks[10] <= red;
					bricks[11] <= green;
					bricks[12] <= black;
					bricks[13] <= red;
					bricks[14] <= black;
					bricks[15] <= red;

					
					bricks[16] <= 3'b000;
					bricks[17] <= red;	
					bricks[18] <= red;
					bricks[19] <= green;
					bricks[20] <= green;
					bricks[21] <= red;
					bricks[22] <= red;
					bricks[23] <= red;


					bricks[24] <= 3'b000;
					bricks[25] <= red;
					bricks[26] <= black;
					bricks[27] <= black;
					bricks[28] <= green;
					bricks[29] <= red;
					bricks[30] <= black;
					bricks[31] <= red;
					
					bricks[32] <= 3'b000;
					bricks[33] <= red;
					bricks[34] <= red;
					bricks[35] <= green;
					bricks[36] <= green;
					bricks[37] <= red;
					bricks[38] <= red;
					bricks[39] <= red;
				end
		
				// LEVEL 7 DE1
				else if (level == 3'd7)
				begin
					bricks[0] <= 3'b000;
					bricks[1] <= red;
					bricks[2] <= red;
					bricks[3] <= black;
					bricks[4] <= green;
					bricks[5] <= green;
					bricks[6] <= blue;
					bricks[7] <= 3'b000;

					bricks[8] <= 3'b000;
					bricks[9] <= red;
					bricks[10] <= black;
					bricks[11] <= red;
					bricks[12] <= green;
					bricks[13] <= black;
					bricks[14] <= blue;
					bricks[15] <= 3'b000;

					
					bricks[16] <= 3'b000;
					bricks[17] <= red;	
					bricks[18] <= black;
					bricks[19] <= red;
					bricks[20] <= green;
					bricks[21] <= green;
					bricks[22] <= blue;
					bricks[23] <= 3'b000;


					bricks[24] <= 3'b000;
					bricks[25] <= red;
					bricks[26] <= black;
					bricks[27] <= red;
					bricks[28] <= green;
					bricks[29] <= black;
					bricks[30] <= blue;
					bricks[31] <= 3'b000;
					
					bricks[32] <= 3'b000;
					bricks[33] <= red;
					bricks[34] <= red;
					bricks[35] <= black;
					bricks[36] <= green;
					bricks[37] <= green;
					bricks[38] <= blue;
					bricks[39] <= 3'b000;
				end
				
        end
		  
    if(!reset_n)
	     begin
	         BOUNCE_LEFT = 1'b0; 
				BOUNCE_RIGHT = 1'b0;
				BOUNCE_UP = 1'b0;
				BOUNCE_DOWN = 1'b0;
				bounce_first <= 1'b0;
				COLLISION_X <= 8'b00000000;
				COLLISION_Y <= 8'b00000000;
		  end
	 else if(first != 1'b0) 
	     begin
		  
if (BALL_Y_IN == Y_IN && X_IN <= BALL_X_IN && BALL_X_IN < X_IN + 8'd16)
	begin
		// BOUNCE up
		BOUNCE_UP <= 1'b1;
		COLLISION_X <= X_IN;
		COLLISION_Y <= Y_IN;
		enable_del <= 1'b1;
		bounce_first <= 1'b1;
	end
else if (BALL_Y_IN == Y_IN + 8'd7 && X_IN <= BALL_X_IN && BALL_X_IN < X_IN + 8'd16)
	begin
		// Bounce down
		BOUNCE_DOWN <= 1'b1;
		COLLISION_X <= X_IN;
		COLLISION_Y <= Y_IN;
		enable_del <= 1'b1;
		bounce_first <= 1'b1;
	end
else if (BALL_X_IN == X_IN && Y_IN + 8'd1 <= BALL_Y_IN && BALL_Y_IN < Y_IN + 8'd7)
	begin
		// Bounce on left side
		BOUNCE_LEFT <= 1'b1;
		COLLISION_X <= X_IN;
		COLLISION_Y <= Y_IN;
		enable_del <= 1'b1;
		bounce_first <= 1'b1;
	end
else if (BALL_X_IN == X_IN + 8'd15 && Y_IN + 8'd1 <= BALL_Y_IN && BALL_Y_IN < Y_IN + 8'd7)
	begin
		// Bounce right
		BOUNCE_RIGHT <= 1'b1;
		COLLISION_X <= X_IN;
		COLLISION_Y <= Y_IN;
		enable_del <= 1'b1;
		bounce_first <= 1'b1;
	end
	
	// Check win condition
	if (bricks[0] == 1'b0 && bricks[1] == 1'b0 && bricks[2] == 1'b0 && bricks[3] == 1'b0 && bricks[4] == 1'b0 && bricks[5] == 1'b0 && bricks[6] == 1'b0 && bricks[7] == 1'b0 && bricks[8] == 1'b0 && bricks[9] == 1'b0 && bricks[10] == 1'b0 && bricks[11] == 1'b0 && bricks[12] == 1'b0 && bricks[13] == 1'b0 && bricks[14] == 1'b0 && bricks[15] == 1'b0 && bricks[16] == 1'b0 && bricks[17] == 1'b0 && bricks[18] == 1'b0 && bricks[19] == 1'b0 && bricks[20] == 1'b0 && bricks[21] == 1'b0 && bricks[22] == 1'b0 && bricks[23] == 1'b0 &&  bricks[24] == 1'b0 && bricks[25] == 1'b0 && bricks[26] == 1'b0 && bricks[27] == 1'b0 && bricks[28] == 1'b0 && bricks[29] == 1'b0 && bricks[30] == 1'b0 && bricks[31] == 1'b0 && bricks[32] == 1'b0 && bricks[33] == 1'b0 && bricks[34] == 1'b0 && bricks[35] == 1'b0 && bricks[36] == 1'b0 && bricks[37] == 1'b0 && bricks[38] == 1'b0 && bricks[39] == 1'b0) begin
			won <= 1'b1;
		 end
	
                                      if(COLLISION_Y == 8'd4)
												     begin
													      drawn <= 1'b0;
															if (DELAY_OUT == 20'b00000000000000000000)
															    enable_del <= 1'b0;
													      if(COLLISION_X == 8'd2 && bricks[0] > 1'b0)
															    begin
																 bricks[0] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[0] - 1'b1 : bricks[0];
																 //drawn <= 1'b1;
															    end
													      if(COLLISION_X == 8'd22 && bricks[1] > 1'b0)
															    begin
																 bricks[1] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[1] - 1'b1 : bricks[1];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd42 && bricks[2] > 1'b0)
															    begin
																 bricks[2] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[2] - 1'b1 : bricks[2];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd62 && bricks[3] > 1'b0)
															    begin
																 bricks[3] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[3] - 1'b1 : bricks[3];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd82 && bricks[4] > 1'b0)
															    begin
																 bricks[4] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[4] - 1'b1 : bricks[4];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd102 && bricks[5] > 1'b0)
															    begin
																 bricks[5] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[5] - 1'b1 : bricks[5];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd122 && bricks[6] > 1'b0)
															    begin
																 bricks[6] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[6] - 1'b1 : bricks[6];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd142 && bricks[7] > 1'b0)
															    begin
																 bricks[7] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[7] - 1'b1 : bricks[7];
																 //drawn <= 1'b1; 
																 end 
													  end
										      else if(COLLISION_Y == 8'd16)
												     begin
													      drawn <= 1'b0;
													      if(COLLISION_X == 8'd2 && bricks[8] > 1'b0)
															    begin
																 bricks[8] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[8] - 1'b1 : bricks[8];
																 //drawn <= 1'b1;
																 end
													      if(COLLISION_X == 8'd22 && bricks[9] > 1'b0)
															    begin
																 bricks[9] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[9] - 1'b1 : bricks[9];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd42 && bricks[10] > 1'b0)
															    begin
																 bricks[10] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[10] - 1'b1 : bricks[10];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd62 && bricks[11] > 1'b0)
															    begin
																 bricks[11] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[11] - 1'b1 : bricks[11];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd82 && bricks[12] > 1'b0)
															    begin
																 bricks[12] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[12] - 1'b1 : bricks[12];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd102 && bricks[13] > 1'b0)
															    begin
																 bricks[13] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[13] - 1'b1 : bricks[13];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd122 && bricks[14] > 1'b0)
															    begin
																 bricks[14] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[14] - 1'b1 : bricks[14];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd142 && bricks[15] > 1'b0)
															    begin
																 bricks[15] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[15] - 1'b1 : bricks[15];	
																 //drawn <= 1'b1;
																 end
													  end
										      else if(COLLISION_Y == 8'd28)
												     begin
													      drawn <= 1'b0;
													      if(COLLISION_X == 8'd2 && bricks[16] > 1'b0)
															    begin
																 bricks[16] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[16] - 1'b1 : bricks[16];
																 //drawn <= 1'b1;
																 end
													      if(COLLISION_X == 8'd22 && bricks[17] > 1'b0)
															   begin
																bricks[17] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[17] - 1'b1 : bricks[17];
																drawn <= 1'b1;
																fake_score <= fake_score + 1'b1;
																end
													      if(COLLISION_X == 8'd42 && bricks[18] > 1'b0)
															    begin
																 bricks[18] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[18] - 1'b1 : bricks[18];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd62 && bricks[19] > 1'b0)
															    begin
																 bricks[19] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[19] - 1'b1 : bricks[19];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd82 && bricks[20] > 1'b0)
															    begin
																 bricks[20] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[20] - 1'b1 : bricks[20];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd102 && bricks[21] > 1'b0)
															    begin
																 bricks[21] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[21] - 1'b1 : bricks[21];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd122 && bricks[22] > 1'b0)
															    begin
																 bricks[22] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[22] - 1'b1 : bricks[22];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd142 && bricks[23] > 1'b0)
															    begin
																 bricks[23] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[23] - 1'b1 : bricks[23];
																 //drawn <= 1'b1;
																 end
													  end		
										      else if(COLLISION_Y == 8'd40)
												     begin
													      drawn <= 1'b0;
													      if(COLLISION_X == 8'd2 && bricks[24] > 1'b0)
															    begin
																 bricks[24] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[24] - 1'b1 : bricks[24];
																 //drawn <= 1'b1;
																 end
													      if(COLLISION_X == 8'd22 && bricks[25] > 1'b0)
															    begin
																 bricks[25] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[25] - 1'b1 : bricks[25];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd42 && bricks[26] > 1'b0)
															    begin
																 bricks[26] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[26] - 1'b1 : bricks[26];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd62 && bricks[27] > 1'b0)
															    begin
																 bricks[27] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[27] - 1'b1 : bricks[27];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd82 && bricks[28] > 1'b0)
															    begin
																 bricks[28] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[28] - 1'b1 : bricks[28];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd102 && bricks[29] > 1'b0)
															    begin
																 bricks[29] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[29] - 1'b1 : bricks[29];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd122 && bricks[30] > 1'b0)
															    begin
																 bricks[30] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[30] - 1'b1 : bricks[30];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd142 && bricks[31] > 1'b0)
															    begin
																 bricks[31] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[31] - 1'b1 : bricks[31];	
																 //drawn <= 1'b1;
																 end
													  end
										      else if(COLLISION_Y == 8'd52)
												     begin
													      drawn <= 1'b0;
													      if(COLLISION_X == 8'd2 && bricks[32] > 1'b0)
															    begin
																 bricks[32] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[2] - 1'b1 : bricks[32];
																 //drawn <= 1'b1;
																 end
													      if(COLLISION_X == 8'd22 && bricks[33] > 1'b0)
															    begin
																 bricks[33] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[33] - 1'b1 : bricks[33];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd42 && bricks[34] > 1'b0)
															    begin
																 bricks[34] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[34] - 1'b1 : bricks[34];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd62 && bricks[35] > 1'b0)
															    begin
																 bricks[35] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[35] - 1'b1 : bricks[35];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd82 && bricks[36] > 1'b0)
															    begin
																 bricks[36] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[36] - 1'b1 : bricks[36];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd102 && bricks[37] > 1'b0)
															    begin
																 bricks[37] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[37] - 1'b1 : bricks[37];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd122 && bricks[38] > 1'b0)
															    begin
																 bricks[38] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[38] - 1'b1 : bricks[38];
																 drawn <= 1'b1;
																 fake_score <= fake_score + 1'b1;
																 end
													      if(COLLISION_X == 8'd142 && bricks[39] > 1'b0)
															    begin
																 bricks[39] <= (DELAY_OUT == 20'b00000000000000000000) ? bricks[39] - 1'b1 : bricks[39];	
																 //drawn <= 1'b1;
																 end
													  end		
											
							   if(drawn == 1'b0)
				                begin
						              BOUNCE_LEFT <= 1'b0; 
				                    BOUNCE_RIGHT <= 1'b0;
				                    BOUNCE_UP <= 1'b0;
				                    BOUNCE_DOWN <= 1'b0;
		
                            end		
//end					

					 end 
			   else
				    begin
					     BOUNCE_LEFT <= 1'b0; 
				        BOUNCE_RIGHT <= 1'b0;
				        BOUNCE_UP <= 1'b0;
				        BOUNCE_DOWN <= 1'b0;
						  COLLISION_X <= 8'b0;
						  COLLISION_Y <= 8'b0;
					 end

	end	  

endmodule



module brick_delay_counter(CLOCK_50, reset_n, COUNT);

     input CLOCK_50, reset_n;
	  output reg [7:0] COUNT;
	  
	  always @(posedge CLOCK_50)
	  begin
	      if(!reset_n)
			    COUNT <= 8'd0;
		   else 
			    begin
				 if(COUNT == 8'd128)
				     COUNT <= 8'd0;
				 else
				     COUNT <= COUNT + 1'b1;
				 
				 
				 end
	  
	  end



endmodule


module brick_collision_counter(CLOCK_50, reset_n, X_OUT, Y_OUT);

input CLOCK_50, reset_n;
output reg [7:0] X_OUT, Y_OUT;

reg [2:0] count;

always @(negedge CLOCK_50)
    begin
        if(!reset_n || count == 3'b101)
		      begin
		          X_OUT <= 8'b00000010;
				    Y_OUT <= 8'b00000100;
					 count <= 3'b000;
		      end			 
		   else if(count != 3'b101)
	          begin
				     if(count == 3'b000)
					      Y_OUT <= 8'b00000100;
					  if(X_OUT == 8'b00000000)
					      X_OUT <= 8'b00000010;
					  X_OUT <= X_OUT + 8'b00010100;
					  if(X_OUT == 8'b10001110)
					      begin
							    count <= count + 1'b1;
								 if(count != 3'b101)
								     begin
					                  X_OUT <= 8'b00000010;
											if(count != 3'b100)
							                Y_OUT <= Y_OUT + 8'b00001100;
					              end
							end
             end
			


    end

endmodule

module bin_to_bcd(binary, binary_coded_decimal);
    input [7:0] binary;

    output [11:0] binary_coded_decimal;

    reg [11:0] binary_coded_decimal; 
    reg [3:0] i;   

     always @(binary)
        begin
            binary_coded_decimal = 0;
            for (i = 0; i < 8; i = i+1)
            begin
                binary_coded_decimal = {binary_coded_decimal[10:0],binary[7-i]};

                if(i < 7 && binary_coded_decimal[3:0] > 4) 
                    binary_coded_decimal[3:0] = binary_coded_decimal[3:0] + 3;
                if(i < 7 && binary_coded_decimal[7:4] > 4)
                    binary_coded_decimal[7:4] = binary_coded_decimal[7:4] + 3;
                if(i < 7 && binary_coded_decimal[11:8] > 4)
                    binary_coded_decimal[11:8] = binary_coded_decimal[11:8] + 3;  
            end
        end         
endmodule

module hex_decoder(HEX, C);
	input [3:0] C;
	output [6:0] HEX;
	
	assign HEX[0] = (~C[3] & C[2] & ~C[1] & ~C[0]) | (~C[3] & ~C[2] & ~C[1] & C[0]) | (C[3] & C[2] & ~C[1] & C[0]) | (C[3] & ~C[2] & C[1] & C[0]);
	assign HEX[1] = (C[3] & C[2] & ~C[1] & ~C[0]) | (~C[3] & C[2] & ~C[1] & C[0]) | (C[3] & C[1] & C[0]) | (C[2] & C[1] & ~C[0]);
	assign HEX[2] = (C[3] & C[2] & ~C[1] & ~C[0]) | (C[3] & C[2] & C[1]) | (~C[3] & ~C[2] & C[1] & ~C[0]);
	assign HEX[3] = (~C[3] & C[2] & ~C[1] & ~C[0]) | (~C[3] & ~C[2] & ~C[1] & C[0]) | (C[2] & C[1] & C[0]) | (C[3] & ~C[2] & C[1] & ~C[0]);
	assign HEX[4] = (~C[3] & C[0]) | (~C[3] & C[2] & ~C[1]) | (~C[2] & ~C[1] & C[0]);
	assign HEX[5] = (~C[3] & ~C[2] & C[0]) | (~C[3] & ~C[2] & C[1]) | (~C[3] & C[1] & C[0]) | (C[3] & C[2] & ~C[1] & C[0]);
	assign HEX[6] = (~C[3] & ~C[2] & ~C[1]) | (C[3] & C[2] & ~C[1] & ~C[0]) | (~C[3] & C[2] & C[1] & C[0]);
endmodule