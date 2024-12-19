`timescale 1ns / 1ps

module main(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    input [3:0] usr_sw,
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    );
localparam [3:0] S_MAIN_INIT = 0 , S_MAIN_IDLE = 1,
                 S_MAIN_START = 2 ,  S_MAIN_WAIT1 =3, S_MAIN_PLAY = 4,
                 S_MAIN_CAL = 5 ,  S_MAIN_WAIT2 =6,
                 S_MAIN_END =7;
localparam VBUF_W = 320;
localparam VBUF_H = 240;
localparam BALL_W = 30;
localparam BALL_H = 30;

wire [11:0] player_x;
wire [11:0] player_y;
wire [11:0] computer_x;
wire [11:0] computer_y;
wire [11:0] ball_x;
wire [11:0] ball_y;
reg [2:0] player_score;
reg [2:0] computer_score;
reg [1:0] state;
wire touched; // determine if ball touch the floor
reg  [2:0] P, P_next;
reg [31:0] cnt1; //counting for start
reg [31:0] cnt2; //counting for wait1
reg win; // who win
reg [9:0] sm_clk; // random smash for npc
wire sm; // for npc
assign sm = usr_sw[1]== 1'b1 ? sm_clk[3] : 1'b1;


assign touched = (ball_y + BALL_H >= VBUF_H - 20)? 1:0;

Ball ball(
    .clk(clk),
    .reset_n(reset_n),
    .Player_X(player_x),
    .Player_Y(player_y),
    .NPC_X(computer_x),
    .NPC_Y(computer_y),
    .game_state(state), // 0: start, 1: ball wait for drop, 2: in game, 3: game end, 4: default
    .who_win(win), // 0: player win, 1: npc win
    .smash(usr_btn[3]), // smash control
    .smash1(sm),
    .Ball_X(ball_x),
    .Ball_Y(ball_y)
);

player players(
    .clk(clk),
    .reset_n(reset_n),
    .usr_btn(usr_btn),
    .game_state(state),
    .x(player_x),
    .y(player_y)
);
    
npc npcs(
    .clk(clk),
    .reset_n(reset_n),
    .ball_pos_x(ball_x),
    .ball_pos_y(ball_y),
    .game_mode(usr_sw[1]),
    .game_state(state),
    .npc_pos_x(computer_x),
    .npc_pos_y(computer_y)
);
     
display show(
    .clk(clk),
    .reset_n(reset_n),
    .player_x_position(player_x),
    .player_y_position(player_y),
    .computer_x_position(computer_x),
    .computer_y_position(computer_y),
    .ball_x_position(ball_x),
    .ball_y_position(ball_y),
    .player_score(player_score),
    .computer_score(computer_score),
    .game_state(state),
    .usr_sw(usr_sw),
    .mode(usr_sw[1]),
    .special(usr_sw[2]),
    .VGA_HSYNC(VGA_HSYNC),
    .VGA_VSYNC(VGA_VSYNC),
    .VGA_RED(VGA_RED),
    .VGA_GREEN(VGA_GREEN),
    .VGA_BLUE(VGA_BLUE)
);

always @(posedge clk) begin
  if (~reset_n || P==S_MAIN_INIT) begin
    state <= 0;
  end else  if(P == S_MAIN_START)begin
    state <= 0;
  end else  if(P == S_MAIN_WAIT1)begin
    state <= 1;
  end else  if(P == S_MAIN_PLAY)begin
    state <= 2;
  end else  if(P == S_MAIN_END)begin
    state <= 3;
  end
end

// FSM of the SD card reader that reads the super block (512 bytes)
always @(posedge clk) begin
  if (~reset_n) begin
    P <= S_MAIN_INIT;
  end else begin
    P <= P_next;
  end
end

always @(posedge clk) begin
  if (~reset_n || P==S_MAIN_INIT) begin
    sm_clk <= 0;
  end else if(sm_clk > 1000) begin
    sm_clk <= 0;
  end else begin
    sm_clk <= sm_clk+1;
  end
end

always @(posedge clk) begin
  if (~reset_n || P==S_MAIN_INIT) begin
    cnt1 <= 0;
    cnt2 <= 0;
  end else if(P == S_MAIN_START) begin
    cnt1 <= cnt1 + 1;
  end else if(P == S_MAIN_WAIT1) begin
    cnt2 <= cnt2 + 1;
  end else begin
    cnt1 <= 0;
    cnt2 <= 0;
  end
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT: 
      P_next = S_MAIN_IDLE;
    S_MAIN_IDLE: // wait for sw pull
      if (usr_sw[0] == 0) P_next = S_MAIN_START;
      else P_next = S_MAIN_IDLE;
    S_MAIN_START: // wait for a short time
        if(cnt1>100000000) P_next = S_MAIN_WAIT1;
        else P_next = S_MAIN_START;
    S_MAIN_WAIT1:
        if(cnt2>50000000) P_next = S_MAIN_PLAY;
        else P_next = S_MAIN_WAIT1;
    S_MAIN_PLAY: // in game
      if (touched) P_next = S_MAIN_WAIT2;
      else P_next = S_MAIN_PLAY;
    S_MAIN_WAIT2:
        P_next = S_MAIN_CAL ;
    S_MAIN_CAL: // score calculating
      if(player_score >= 7) P_next = S_MAIN_END;
      else if (computer_score >= 7) P_next = S_MAIN_END;
      else P_next = S_MAIN_WAIT1;
    S_MAIN_END: // game end
        if (usr_sw[0] == 1) P_next = S_MAIN_INIT;
        else P_next = S_MAIN_END;
    default:
      P_next = S_MAIN_INIT;
  endcase
end

// compute score and who win
always @(posedge clk) begin
    if(~reset_n || P==S_MAIN_INIT) begin
        player_score <= 0;
        computer_score <= 0;
        win <= 0;
    end else if(P_next == S_MAIN_WAIT2) begin
        if(ball_x >=160)begin
            computer_score <= computer_score + 1;
            win <= 1;
        end else if(ball_x <160) begin
            player_score <= player_score + 1;
            win <= 0;
        end
    end  
end

endmodule
