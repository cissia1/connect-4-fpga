module board_renderer (board, cursor_col, current_player, show_cursor, falling_active,
							 falling_row, falling_col, falling_player, RedPixels, GrnPixels);
    input logic [5:0][6:0][1:0] board;
    input logic [2:0] cursor_col;
    input logic current_player, show_cursor;
    input logic falling_active;
    input logic [2:0]falling_row, falling_col;
    input logic falling_player;
    output logic [15:0][15:0] RedPixels, GrnPixels;
    parameter COL_OFF = 4;  
    parameter ROW_OFF = 5; 
    logic [1:0] color;
    integer board_row, board_col, display_row, display_col;

    always_comb begin
        RedPixels = '0;
        GrnPixels = '0;

        for (board_row = 0; board_row < 6; board_row = board_row + 1) begin
            for (board_col = 0; board_col < 7; board_col = board_col + 1) begin
                color = board[board_row][board_col];
                if (falling_active && falling_row == board_row && falling_col == board_col) begin
                    if (falling_player == 1'b0) 
							color = 2'b01;
                    else 
							color = 2'b10;
                end

                display_row = ROW_OFF + (5 - board_row);
                display_col = COL_OFF + board_col;
                if (color == 2'b01) 
						RedPixels[display_row][display_col] = 1'b1;
                else if (color == 2'b10) 
						GrnPixels[display_row][display_col] = 1'b1;
            end
        end

        if (show_cursor) begin
            display_col = COL_OFF + cursor_col;
            if (current_player == 1'b0) 
					RedPixels[3][display_col] = 1'b1;
            else 
					GrnPixels[3][display_col] = 1'b1;
        end
    end
endmodule

module board_renderer_testbench;
    logic [5:0][6:0][1:0] board;
    logic [2:0] cursor_col;
    logic current_player, show_cursor;
    logic falling_active;
    logic [2:0] falling_row, falling_col;
    logic falling_player;
    logic [15:0][15:0] RedPixels, GrnPixels;

    board_renderer dut (.board, .cursor_col, .current_player, .show_cursor,
                        .falling_active, .falling_row, .falling_col, .falling_player,
                        .RedPixels, .GrnPixels);

    initial begin
        board = '0;
        cursor_col = 3'd0; current_player = 1'b0; show_cursor = 1'b0;
        falling_active = 1'b0; falling_row = 3'd0; falling_col = 3'd0; falling_player = 1'b0;
        #10;

        show_cursor = 1'b1; cursor_col = 3'd0;
        #10;

        cursor_col = 3'd3;
        #10;

        cursor_col = 3'd6; current_player = 1'b1;
        #10;

        show_cursor = 1'b0;
        board[0][0] = 2'b01;
        #10;

        board[5][6] = 2'b10;
        #10;

        board = '0;
        board[0][0] = 2'b01; board[0][1] = 2'b10; board[0][2] = 2'b01;
        board[0][3] = 2'b10; board[0][4] = 2'b01; board[0][5] = 2'b10; board[0][6] = 2'b01;
        #10;

        board = '0;
        falling_active = 1'b1; falling_row = 3'd3; falling_col = 3'd4; falling_player = 1'b0;
        #10;

        board[3][4] = 2'b10;
        #10;

        falling_active = 1'b0; show_cursor = 1'b1; cursor_col = 3'd2; current_player = 1'b0;
        board = '0;
        board[0][2] = 2'b01; board[1][2] = 2'b10; board[0][4] = 2'b10;
        #10;
        $stop;
    end
endmodule
