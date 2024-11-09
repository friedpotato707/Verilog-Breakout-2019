module brick_module(CLOCK_50, XOUT, YOUT, COLOUR, RESETN, COLLISION_X_IN, COLLISION_Y_IN, BOUNCE_LEFT, BOUNCE_RIGHT, BOUNCE_DOWN, BOUNCE_UP, update_br, X_IN, Y_IN);
    output [7:0] XOUT, YOUT;
    output [2:0] COLOUR;

    input RESETN;
    input CLOCK_50, update_br;
	 
	 input BOUNCE_LEFT, BOUNCE_RIGHT, BOUNCE_UP, BOUNCE_DOWN;
	 
	 
	 input [7:0] X_IN, Y_IN;
	 
	 
	 // input from collision detection circuit
	 input [7:0] COLLISION_X_IN, COLLISION_Y_IN;
	 

    // Brick data
    reg [2:0] bricks[31:0];
	 
	 reg first;
	 always @(posedge CLOCK_50)
	 begin
		if (RESETN == 1'b0)
			first <= 1'b0;
		else if (first != 1'b1)
			first <= 1'b1;
	 end

    always @(posedge CLOCK_50)
    begin
        if (first == 1'b0)
        begin
            // Bricks
            // Row 0
            bricks[0] <= 3'b100;
            bricks[1] <= 3'b100;
            bricks[2] <= 3'b100;
            bricks[3] <= 3'b100;
            bricks[4] <= 3'b100;
            bricks[5] <= 3'b100;
            bricks[6] <= 3'b100;
            bricks[7] <= 3'b100;

            // Row 1
            bricks[8] <= 3'b011;
            bricks[9] <= 3'b011;
            bricks[10] <= 3'b011;
            bricks[11] <= 3'b011;
            bricks[12] <= 3'b011;
            bricks[13] <= 3'b011;
            bricks[14] <= 3'b011;
            bricks[15] <= 3'b011;

            // Row 2
            bricks[16] <= 3'b010;
            bricks[17] <= 3'b010;
            bricks[18] <= 3'b010;
            bricks[19] <= 3'b010;
            bricks[20] <= 3'b010;
            bricks[21] <= 3'b010;
            bricks[22] <= 3'b010;
            bricks[23] <= 3'b010;

            // Row 3
            bricks[24] <= 3'b001;
            bricks[25] <= 3'b001;
            bricks[26] <= 3'b001;
            bricks[27] <= 3'b001;
            bricks[28] <= 3'b001;
            bricks[29] <= 3'b001;
            bricks[30] <= 3'b001;
            bricks[31] <= 3'b001;
        end
    end

    localparam ANCHOR_LEFT = 8'd2,
               ANCHOR_TOP  = 8'd4;

    wire signal_brick;
    assign signal_brick = (pixel_counter == 7'd127) ? 1 : 0;

    // Brick Counter
    reg [4:0] brick_counter;
    always @(posedge signal_brick, negedge RESETN)
    begin  
        if (RESETN == 1'b0)
            brick_counter <= 5'd0;
        else
            brick_counter <= brick_counter + 1'b1;
    end

    reg [6:0] pixel_counter; // First four for counting to 16 and next to count to 8
    always @(posedge CLOCK_50)
    begin
        if (RESETN == 1'b0)
            pixel_counter <= 7'd0;
        else
            pixel_counter <= pixel_counter + 1'b1;
    end

    // Assign the X, Y Pixel Positions
    assign XOUT = ANCHOR_LEFT + (5'd20 * brick_counter[2:0]) + pixel_counter[3:0];
    assign YOUT = ANCHOR_TOP  + (4'd12 * brick_counter[4:3]) + pixel_counter[6:4];

    //assign XOUT = X_IN + pixel_counter[3:0];
    //assign YOUT = Y_IN + pixel_counter[6:4];


    wire [2:0] health;
    assign health = bricks[brick_counter];

    // Set the colour
    reg [2:0] colour;
    always @(*)
    begin
        if (health == 3'd0)
            colour = 3'b111;
        else if (health == 3'd4)
            colour = 3'b100;
        else if (health == 3'd3)
            colour = 3'b001;
        else if (health == 3'd2)
            colour = 3'b010;
        else if (health == 3'd1)
            colour = 3'b110;
    end

    // Output the colour
    assign COLOUR = colour;
endmodule