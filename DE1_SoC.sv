module DE1_SoC (HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, KEY, SW, LEDR, GPIO_1, CLOCK_50);
    output logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    output logic [9:0]  LEDR;
    input  logic [3:0]  KEY;
    input  logic [9:0]  SW;
    output logic [35:0] GPIO_1;
    input  logic CLOCK_50;

    logic RST, btn_left, btn_right, btn_drop;
    assign RST       = ~KEY[0];
    assign btn_right = ~KEY[2];
    assign btn_left  = ~KEY[1];
    assign btn_drop  = ~KEY[3];

    logic [31:0] clk;
    logic SYSTEM_CLOCK;

    clock_divider divider (.clock(CLOCK_50), .divided_clocks(clk));
    assign SYSTEM_CLOCK = clk[14]; 

    logic [7:0] tick_count;
    logic tick;
    always_ff @(posedge SYSTEM_CLOCK) begin
        if (RST | tick_count == 8'd127) tick_count <= 8'd0;
        else tick_count <= tick_count + 8'd1;
    end
    assign tick = (tick_count == 8'd0);

    logic prev_left, prev_right, prev_drop;
    logic ev_left, ev_right, ev_drop;
    always_ff @(posedge SYSTEM_CLOCK) begin
        if (RST) begin
            prev_left  <= 1'b0;
            prev_right <= 1'b0;
            prev_drop  <= 1'b0;
        end
        else if (tick) begin
            prev_left  <= btn_left;
            prev_right <= btn_right;
            prev_drop  <= btn_drop;
        end
    end
    assign ev_left  = tick & btn_left  & ~prev_left;
    assign ev_right = tick & btn_right & ~prev_right;
    assign ev_drop  = tick & btn_drop  & ~prev_drop;

    logic [5:0][6:0][1:0] board;
    logic [2:0] cursor_col, falling_row, falling_col;
    logic current_player, game_won, game_draw, winner;
    logic falling_active, falling_player;

    game_controller game (.clk(SYSTEM_CLOCK), .reset(RST), .tick,
                          .ev_left, .ev_right, .ev_drop,
                          .board, .cursor_col, .current_player,
                          .game_won, .game_draw, .winner,
                          .falling_active, .falling_row, .falling_col, .falling_player);


    logic [15:0][15:0] RedPixels;
    logic [15:0][15:0] GrnPixels; 

    LEDDriver Driver (.CLK(SYSTEM_CLOCK), .RST, .EnableCount(1'b1), .RedPixels, .GrnPixels, .GPIO_1);

    board_renderer render (.board, .cursor_col, .current_player,
                           .show_cursor(~game_won & ~game_draw),
                           .falling_active, .falling_row, .falling_col, .falling_player,
                           .RedPixels, .GrnPixels);
    logic [3:0] hex5_val;
    always_comb begin
        if (game_won) begin
            if (winner) hex5_val = 4'd2;
            else hex5_val = 4'd1;
        end
        else if (game_draw) hex5_val = 4'd15; 
        else begin
            if (current_player) hex5_val = 4'd2;
            else hex5_val = 4'd1;
        end
    end
    hex_decoder h5 (.d(hex5_val), .seg(HEX5));
    logic [3:0] hex0_val;
    always_comb begin
        if (game_won | game_draw) hex0_val = 4'd15; 
        else hex0_val = {1'b0, cursor_col} + 4'd1;
    end
    hex_decoder h0 (.d(hex0_val), .seg(HEX0));

    assign HEX1 = '1;
    assign HEX2 = '1;
    assign HEX3 = '1;
    assign HEX4 = '1;
endmodule
