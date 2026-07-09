module game_controller (clk, reset, tick, ev_left, ev_right, ev_drop,board, cursor_col, current_player,
                        game_won, game_draw, winner, falling_active, falling_row, falling_col, falling_player);
    input  logic clk, reset, tick;
    input  logic ev_left, ev_right, ev_drop;
    output logic [5:0][6:0][1:0] board;         
    output logic [2:0] cursor_col;               
    output logic current_player;                 
    output logic game_won, game_draw;
    output logic winner;                         
    output logic falling_active;
    output logic [2:0] falling_row, falling_col;
    output logic falling_player;
    enum {S_TURN, S_DROP, S_CHECK, S_WIN, S_DRAW} state;

    logic win_p1, win_p2;
    win_detector detector (.board, .win_p1, .win_p2);

    //lowest empty row of the cursor column
    logic [2:0] landing_row;
    logic col_not_full, empty_cell_found;
    integer i;
    always_comb begin
        landing_row = 3'd0;
        empty_cell_found = 1'b0;
        for (i = 0; i < 6; i = i + 1) begin
            if (~empty_cell_found && board[i][cursor_col] == 2'b00) begin
                landing_row = i;
                empty_cell_found = 1'b1;
            end
        end
        col_not_full = empty_cell_found;
    end

    //check board full
    logic board_full;
    integer full_check_row, full_check_col;
    always_comb begin
        board_full = 1'b1;
        for (full_check_row = 0; full_check_row < 6; full_check_row = full_check_row + 1)
            for (full_check_col = 0; full_check_col < 7; full_check_col = full_check_col + 1)
                if (board[full_check_row][full_check_col] == 2'b00) board_full = 1'b0;
    end

    assign game_won  = (state == S_WIN);
    assign game_draw = (state == S_DRAW);
    integer reset_row, reset_col;
    always_ff @(posedge clk) begin
        if (reset) begin
            state <= S_TURN;
            cursor_col <= 3'd3;       
            current_player <= 1'b0;      
            winner <= 1'b0;
            falling_active <= 1'b0;
            falling_row <= 3'd0;
            falling_col <= 3'd0;
            falling_player <= 1'b0;
            for (reset_row = 0; reset_row < 6; reset_row = reset_row + 1)
                for (reset_col = 0; reset_col < 7; reset_col = reset_col + 1)
                    board[reset_row][reset_col] <= 2'b00;
        end
        else begin
            case (state)
                S_TURN: begin
                    falling_active <= 1'b0;
                    if (ev_left && cursor_col != 3'd0)
                        cursor_col <= cursor_col - 3'd1;
                    else if (ev_right && cursor_col != 3'd6)
                        cursor_col <= cursor_col + 3'd1;
                    if (ev_drop && col_not_full) begin
                        falling_active <= 1'b1;
                        falling_row    <= 3'd5;  
                        falling_col    <= cursor_col;
                        falling_player <= current_player;
                        state          <= S_DROP;
                    end
                end

                S_DROP: begin
                    if (tick) begin
                        if (falling_row > landing_row)
                            falling_row <= falling_row - 3'd1;
                        else begin
                            if (current_player == 1'b0) 
										board[landing_row][falling_col] <= 2'b01;
                            else 
										board[landing_row][falling_col] <= 2'b10;
										falling_active <= 1'b0;
										state <= S_CHECK;
                        end
                    end
                end

                S_CHECK: begin
                    if (win_p1) begin
                        winner <= 1'b0;
                        state  <= S_WIN;
                    end
                    else if (win_p2) begin
                        winner <= 1'b1;
                        state  <= S_WIN;
                    end
                    else if (board_full) state <= S_DRAW;
                    else begin
                        current_player <= ~current_player;
                        state          <= S_TURN;
                    end
                end
            endcase
        end
    end
endmodule

module game_controller_testbench;
    logic clk, reset, tick;
    logic ev_left, ev_right, ev_drop;
    logic [5:0][6:0][1:0] board;
    logic [2:0] cursor_col;
    logic current_player, game_won, game_draw, winner;
    logic falling_active;
    logic [2:0] falling_row, falling_col;
    logic falling_player;

    game_controller dut (.clk, .reset, .tick, .ev_left, .ev_right, .ev_drop,
                         .board, .cursor_col, .current_player,
                         .game_won, .game_draw, .winner,
                         .falling_active, .falling_row, .falling_col, .falling_player);

    parameter PERIOD = 10;
    initial begin
        clk = 0;
        forever #(PERIOD/2) clk = ~clk;
    end

    integer i, j;
    initial begin
        ev_left = 0; ev_right = 0; ev_drop = 0; tick = 0;
        reset = 1; @(posedge clk); @(posedge clk);
        reset = 0; @(posedge clk);

        for (i = 0; i < 4; i = i + 1) begin
            ev_right = 1; tick = 1; @(posedge clk);
            ev_right = 0; tick = 0; @(posedge clk);
        end
        ev_right = 1; tick = 1; @(posedge clk);
        ev_right = 0; tick = 0; @(posedge clk);

        for (i = 0; i < 8; i = i + 1) begin
            ev_left = 1; tick = 1; @(posedge clk);
            ev_left = 0; tick = 0; @(posedge clk);
        end

        ev_drop = 1; tick = 1; @(posedge clk);
        ev_drop = 0; tick = 0; @(posedge clk);
        for (i = 0; i < 15; i = i + 1) begin
            tick = 1; @(posedge clk);
            tick = 0; @(posedge clk);
        end

        for (j = 0; j < 5; j = j + 1) begin
            ev_drop = 1; tick = 1; @(posedge clk);
            ev_drop = 0; tick = 0; @(posedge clk);
            for (i = 0; i < 15; i = i + 1) begin
                tick = 1; @(posedge clk);
                tick = 0; @(posedge clk);
            end
        end

        ev_drop = 1; tick = 1; @(posedge clk);
        ev_drop = 0; tick = 0; @(posedge clk);
        for (i = 0; i < 5; i = i + 1) begin
            tick = 1; @(posedge clk);
            tick = 0; @(posedge clk);
        end

        reset = 1; @(posedge clk); @(posedge clk);
        reset = 0; @(posedge clk);

        for (j = 0; j < 4; j = j + 1) begin
            for (i = 0; i < 7; i = i + 1) begin
                if (cursor_col < j) begin
                    ev_right = 1; tick = 1; @(posedge clk);
                    ev_right = 0; tick = 0; @(posedge clk);
                end else if (cursor_col > j) begin
                    ev_left = 1; tick = 1; @(posedge clk);
                    ev_left = 0; tick = 0; @(posedge clk);
                end else @(posedge clk);
            end

            ev_drop = 1; tick = 1; @(posedge clk);
            ev_drop = 0; tick = 0; @(posedge clk);
            for (i = 0; i < 15; i = i + 1) begin
                tick = 1; @(posedge clk);
                tick = 0; @(posedge clk);
            end
				
            if (j < 3) begin
                for (i = 0; i < 7; i = i + 1) begin
                    if (cursor_col < 6) begin
                        ev_right = 1; tick = 1; @(posedge clk);
                        ev_right = 0; tick = 0; @(posedge clk);
                    end else @(posedge clk);
                end
                ev_drop = 1; tick = 1; @(posedge clk);
                ev_drop = 0; tick = 0; @(posedge clk);
                for (i = 0; i < 15; i = i + 1) begin
                    tick = 1; @(posedge clk);
                    tick = 0; @(posedge clk);
                end
            end
        end
        $stop;
    end
endmodule
