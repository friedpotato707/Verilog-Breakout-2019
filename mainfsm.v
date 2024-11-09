module mainfsm(
    output reg [1:0] OUT_SIG,    // Signals which object module should be active

    input CLK,                  // CLOCK_50
    input RESET_N,              // Async Low Reset
    input [1:0] IN_SIG );       // Feedback Signals

    // Output Signals
	// OUT_SIG = 0 IDLE
    /* OUT_SIG = 1  PADDLE -> The paddle is active
     * OUT_SIG = 2  BALL -> The ball is active
     */

    // Feedback Signals
	// IDLE = 0
    /*  IN_SIG[0] = 1 -> The Paddle is done processing
     *  IN_SIG[1] = 2 -> The Ball is done processing
     */

    // Main FSM states
    localparam IDLE0    = 3'd0,
               IDLE1    = 3'd1,
               PADDLE   = 3'd2,
               BALL     = 3'd3; 

    // State holders
    reg [1:0] cur_state, next_state;
    always @(*)
    begin
        case(cur_state)
            IDLE0: next_state = (update_active == 1'b0) ? IDLE1 : IDLE0;
            IDLE1: next_state = (update_active == 1'b1) ? PADDLE : IDLE1;
            PADDLE: next_state = (update_active == 1'b1 && IN_SIG == 2'd1) ? BALL : PADDLE;
            BALL: next_state = (update_active == 1'b1 && IN_SIG[1] == 2'd2) ? IDLE0 : BALL;
        endcase
    end

    //                          CONTROL SIGNALS
    //////////////////////////////////////////////////////////////////////////////    
    always @(*)
    begin
        if (RESET_N == 1'b0)
            OUT_SIG = 2'd0;
        else if (cur_state == IDLE0)
            OUT_SIG = 2'd0;
        else if (cur_state == IDLE1)
            OUT_SIG = 2'd0;
        else if (cur_state == PADDLE)
            OUT_SIG = 2'b01;
        else if (cur_state == BALL)
            OUT_SIG = 2'b10;
    end

    //                          ASSIGNING NEXT STATE
    //////////////////////////////////////////////////////////////////////////////
    always @(posedge CLK, negedge RESET_N)
    begin
        if (RESET_N == 1'b0)
            cur_state <= IDLE0;
        else
            cur_state <= next_state;
    end

    //               CYCLING ONE FRAME ACTIVE ONE FRAME OFF
    //////////////////////////////////////////////////////////////////////////////
    reg update_active;

    always @(posedge frame_pulse, negedge RESET_N)
    begin
        if (RESET_N == 1'b0)
            update_active <= 1'b0;
        else
            update_active <= !update_active;
    end

    //                          FRAME COUNTING
    //////////////////////////////////////////////////////////////////////////////
    // Pulse once for each frame
    wire frame_pulse;
    mainfsm_frame_divider div(
        .FRAME_CLK(frame_pulse), 
        .CLK(CLK),
        .RESET_N(RESET_N));
endmodule

module mainfsm_frame_divider(
    output FRAME_CLK,       // Goes High to signal the start of every frame, then goes low

    input CLK,              // The input 50MHz clock
    input RESET_N );          // Async Low Reset

    reg [19:0] counter; // 20-bits to count 83,333 times
    always @(posedge CLK, negedge RESET_N)
    begin
        if (RESET_N == 1'b0)
            counter <= 20'd0;
        else begin
            if (counter == 20'd0)
                counter <= 20'd833332;
            else 
                counter <= counter - 20'd1;
        end
    end

    assign FRAME_CLK = (counter == 20'd0) ? 1 : 0;
endmodule