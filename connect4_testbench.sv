module connect4_testbench;
    logic clk, reset, tick;
    logic ev_left, ev_right, ev_drop;
    logic [5:0][6:0][1:0] board;
    logic [2:0] cursor_col;
    logic current_player;
    logic game_won, game_draw, winner;
    logic falling_active;
    logic [2:0] falling_row, falling_col;
    logic falling_player;

    game_controller dut (.clk, .reset, .tick, .ev_left, .ev_right, .ev_drop, .board, .cursor_col, .current_player,
								.game_won, .game_draw, .winner, .falling_active, .falling_row, .falling_col, .falling_player);
    logic [15:0][15:0] RedPixels, GrnPixels;
    board_renderer render (.board, .cursor_col, .current_player, .show_cursor(~game_won & ~game_draw),
									.falling_active, .falling_row, .falling_col, .falling_player, .RedPixels, .GrnPixels);

    parameter PERIOD = 10;
    initial begin
        clk = 0;
        forever #(PERIOD/2) clk = ~clk;
    end

    logic [6:0][2:0] play_col;
    integer move_index, step;

    initial begin
        play_col[0] = 3'd3;
        play_col[1] = 3'd4;
        play_col[2] = 3'd3;
        play_col[3] = 3'd4;
        play_col[4] = 3'd3;
        play_col[5] = 3'd4;
        play_col[6] = 3'd3;
        ev_left = 1'b0; ev_right = 1'b0; ev_drop = 1'b0; tick = 1'b0;
        reset = 1'b1; @(posedge clk); @(posedge clk);
        reset = 1'b0; @(posedge clk);

        for (move_index = 0; move_index < 7; move_index = move_index + 1) begin
            for (step = 0; step < 6; step = step + 1) begin
                if (cursor_col < play_col[move_index]) begin
                    ev_right = 1'b1; tick = 1'b1; @(posedge clk);
                    ev_right = 1'b0; tick = 1'b0; @(posedge clk);
                end else if (cursor_col > play_col[move_index]) begin
                    ev_left = 1'b1; tick = 1'b1; @(posedge clk);
                    ev_left = 1'b0; tick = 1'b0; @(posedge clk);
                end else begin
                    @(posedge clk);
                end
            end
				
            ev_drop = 1'b1; tick = 1'b1; @(posedge clk);
            ev_drop = 1'b0; tick = 1'b0; @(posedge clk);

            for (step = 0; step < 20; step = step + 1) begin
                tick = 1'b1; @(posedge clk);
                tick = 1'b0; @(posedge clk);
            end
        end

        reset = 1'b1; @(posedge clk); @(posedge clk);
        reset = 1'b0; @(posedge clk);
        dut.board[0] = {2'b10, 2'b01, 2'b01, 2'b10, 2'b10, 2'b01, 2'b01};
        dut.board[1] = {2'b01, 2'b10, 2'b10, 2'b01, 2'b01, 2'b10, 2'b10};
        dut.board[2] = {2'b10, 2'b01, 2'b01, 2'b10, 2'b10, 2'b01, 2'b01};
        dut.board[3] = {2'b01, 2'b10, 2'b10, 2'b01, 2'b01, 2'b10, 2'b10};
        dut.board[4] = {2'b10, 2'b01, 2'b01, 2'b10, 2'b10, 2'b01, 2'b01};
        dut.board[5] = {2'b01, 2'b00, 2'b10, 2'b01, 2'b01, 2'b10, 2'b10};
        @(posedge clk);
        ev_right = 1'b1; tick = 1'b1; @(posedge clk);
        ev_right = 1'b0; tick = 1'b0; @(posedge clk);
        ev_right = 1'b1; tick = 1'b1; @(posedge clk);
        ev_right = 1'b0; tick = 1'b0; @(posedge clk);
        ev_drop = 1'b1; tick = 1'b1; @(posedge clk);
        ev_drop = 1'b0; tick = 1'b0; @(posedge clk);
        for (step = 0; step < 5; step = step + 1) begin
            tick = 1'b1; @(posedge clk);
            tick = 1'b0; @(posedge clk);
        end

        reset = 1'b1; @(posedge clk); @(posedge clk);
        reset = 1'b0; @(posedge clk); @(posedge clk);
        $stop;
    end
endmodule
