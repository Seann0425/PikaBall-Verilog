`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/03 11:34:42
// Design Name: 
// Module Name: player
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module player(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    output [11:0]x,
    output [11:0]y
    );
    
// Declare system variables
reg  [31:0] player_clock;
reg  [31:0] player_vclock;

wire [9:0]  pos;
wire [9:0]  posv;

//wire gravity=1;
reg [26:0] speed;
reg [26:0] speed_clk;

wire btn_level, btn_pressed;
reg  prev_btn_level;
// Declare the video buffer size
localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height

// Set parameters for the fish images
localparam player_VPOS   = 199; // Vertical location of the fish_1 in the sea image.

localparam player_W      = 41; // Width of the player.
localparam player_H      = 42; // Height of the player.

parameter gravity = 27'd1;  
parameter init_speed = 27'd4; 
  
debounce btn_db(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn_level)
);

// ------------------------------------------------------------------------
// An animation clock for the motion of the fish, upper bits of the
// fish clock is the x position of the fish on the VGA screen.
// Note that the fish will move one screen pixel every 2^20 clock cycles,
// or 10.49 msec
//速度控制
assign x = player_clock[31:20]; // the x position of the right edge of the fish1 image
                                   // in the 640x480 VGA screen
assign y = {2'b00,player_vclock[31:22]}; // the y position of the up edge of the fish3 image
                                    // in the 640x480 VGA screen
                                    
reg face;
reg facev;

always @(posedge clk) begin

  if (~reset_n ) begin
    player_clock[31:20] <= {VBUF_W - player_W - 1};
    face <= 1;
  end else if(face==1 && ~(player_clock[31:20]+ player_W > VBUF_W) && usr_btn[0]==1)
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
  if (~reset_n ) begin
     player_vclock[31:22] <= VBUF_H - player_H -21;
  end else if (facev == 1 && player_vclock[31:22] > 0) begin
     player_vclock <= player_vclock - speed;
  end else if (facev == 0 && player_vclock[31:22] + player_H < VBUF_H -20) begin
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
  end else if (btn_pressed && player_vclock[31:22] == (VBUF_H - player_H - 20)) begin//player_vclock[31:22] >= (VBUF_H - player_H - 2)
    speed <= 20;
    facev <= 1;
  end else if (facev == 1 && speed_clk > 27'd8388608) begin
    if (speed == 0 ) facev <= 0;
    else     speed <= speed - 4;
    speed_clk <= 0;
  end else if (facev == 0 && player_vclock[31:22] + player_H < VBUF_H -20 && speed_clk > 27'd8388608) begin
    speed <= speed + 2;
    speed_clk <= 0;
  end else
    speed_clk = speed_clk +1;
end

    
    
endmodule
