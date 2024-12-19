`timescale 1ns / 1ps

module player(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    input  [1:0] game_state,
    output [11:0] x,
    output [11:0] y
);
    
// declare system variables
reg  [31:0] player_clock;
reg  [31:0] player_vclock;

wire [9:0]  pos;
wire [9:0]  posv;

reg [26:0] speed;
reg [26:0] speed_clk;

wire btn_level, btn_pressed;
reg  prev_btn_level;

localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height
localparam PLAYER_W      = 41; // width of the player.
localparam PLAYER_H      = 42; // height of the player.

parameter gravity = 27'd1;  
parameter init_speed = 27'd4; 
  
debounce btn_db(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn_level)
);

// speed control
assign x = player_clock[31:20]; // the x position of the right edge of the player image
                                   // in the 640x480 VGA screen
assign y = {2'b00,player_vclock[31:22]}; // the y position of the up edge of the player image
                                    // in the 640x480 VGA screen
                                    
reg face;
reg facev;

always @(posedge clk) begin
  if (~reset_n || game_state == 1) begin
    player_clock[31:20] <= {VBUF_W - PLAYER_W - 1};
    face <= 1;
  end else if(face==1 && ~(player_clock[31:20]+ PLAYER_W > VBUF_W) && usr_btn[0]==1)
    player_clock <= player_clock + 1;
  else if(face==0 && ~(player_clock[31:20] <= 160) && usr_btn[2]==1)
    player_clock <= player_clock - 1;
  if (usr_btn[0]==1) begin
     face<=1 ;
  end else if(usr_btn[2]==1) begin
     face<=0;
  end
end


always @(posedge clk) begin
  if (~reset_n || game_state == 1) begin
     player_vclock[31:22] <= VBUF_H - PLAYER_H -21;
  end else if (facev == 1 && player_vclock[31:22] > 0) begin
     player_vclock <= player_vclock - speed;
  end else if (facev == 0 && player_vclock[31:22] + PLAYER_H < VBUF_H -20) begin
     player_vclock <= player_vclock + speed;
  end
end
    
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 0;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1 : 0;

always @(posedge clk) begin
  if (~reset_n) begin
    speed <= 0;
    facev <= 1;
    speed_clk <=0;
  end else if (btn_pressed && player_vclock[31:22] == (VBUF_H - PLAYER_H - 20)) begin
    // initialize the vertical speed and change the direction
    speed <= 20;
    facev <= 1;
  end else if (facev == 1 && speed_clk > 27'd8388608) begin
    // slow down the speed until it become 0 and change the direction
    if (speed == 0 ) facev <= 0;
    else     speed <= speed - 4;
    speed_clk <= 0;
  end else if (facev == 0 && player_vclock[31:22] + PLAYER_H < VBUF_H -20 && speed_clk > 27'd8388608) begin
    // control the fall down speed
    speed <= speed + 2;
    speed_clk <= 0;
  end else
    speed_clk = speed_clk +1;
end

    
    
endmodule
