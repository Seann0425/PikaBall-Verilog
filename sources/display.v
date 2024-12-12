`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/02 22:37:37
// Design Name: 
// Module Name: display
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


module display(
    input  clk,
    input  reset_n,
    input [11:0] player_x_position,
    input [11:0] player_y_position,
    input [11:0] computer_x_position,
    input [11:0] computer_y_position,
    input [11:0] ball_x_position,
    input [11:0] ball_y_position, 
    input  [3:0] user_btn,
    input [2:0] player_score,
    input [2:0] computer_score,
    input [1:0] Game_state,
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    );
    
// Declare system variables
wire player_region,computer_region,ball_region,player_score_region,computer_score_region,game_start_region,game_over_region;

// declare SRAM control signals
wire [16:0] sram_addr_background,sram_addr_background2,sram_addr_player,sram_addr_computer,sram_addr_ball,sram_addr_player_score,sram_addr_computer_score,sram_addr_game_start,sram_addr_game_over;
wire [11:0] data_in;
wire [11:0] data_out_background,data_out_background2,data_out_player,data_out_computer,data_out_ball,data_out_fire_ball,data_out_player_score,data_out_computer_score,data_out_game_start,data_out_game_over;
wire sram_we, sram_en;

// General VGA control signals
wire vga_clk;         // 50MHz clock for VGA control
wire video_on;        // when video_on is 0, the VGA controller is sending
                      // synchronization signals to the display device.
  
wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                      // based for the new coordinate (pixel_x, pixel_y)
  
wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)
  
reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixel
  
// Application-specific VGA signals
reg  [17:0] pixel_addr_background,pixel_addr_background2,pixel_addr_player,pixel_addr_computer,pixel_addr_ball,pixel_addr_player_score,pixel_addr_computer_score,pixel_addr_game_start,pixel_addr_game_over;

// Declare the video buffer size
localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height
localparam PIKAJU_W = 41; // pikahu width
localparam PIKAJU_H = 42; // pikahu height
localparam BALL_W = 30; // ball width
localparam BALL_H = 30; // ball height
localparam SCORE_H = 30;
localparam SCORE_W = 24;
localparam gameover_W = 141;
localparam gameover_H = 15;
localparam p_start_W = 189;
localparam p_start_H = 15;

localparam gameover_VPOS = 225;
localparam gameover_L = 179;
localparam p_start_VPOS = 225;
localparam p_start_L = 131;

reg [17:0] addr_player[0:7]; 
reg [17:0] addr_computer[0:7];
reg [17:0] addr_ball[0:7];
reg [17:0] addr_fire_ball[0:7];
reg [17:0] addr_score[0:7];

initial begin
  addr_player[0] = 0;               /* Addr for pika image #1 */
  addr_player[1] = PIKAJU_W*PIKAJU_H;   /* Addr for pika image #2 */
  addr_player[2] = PIKAJU_W*PIKAJU_H*2;
  addr_player[3] = PIKAJU_W*PIKAJU_H*3;
  addr_player[4] = PIKAJU_W*PIKAJU_H*4;
  addr_player[5] = 0;
  addr_player[6] = PIKAJU_W*PIKAJU_H;
  addr_player[7] = PIKAJU_W*PIKAJU_H*2;
 
  addr_computer[0] = 0;
  addr_computer[1] = PIKAJU_W*PIKAJU_H;
  addr_computer[2] = PIKAJU_W*PIKAJU_H*2;
  addr_computer[3] = PIKAJU_W*PIKAJU_H*3;
  addr_computer[4] = PIKAJU_W*PIKAJU_H*4;
  addr_computer[5] = 0;
  addr_computer[6] = PIKAJU_W*PIKAJU_H;
  addr_computer[7] = PIKAJU_W*PIKAJU_H*2;

  addr_ball[0] = 0;
  addr_ball[1] = BALL_W*BALL_H;
  addr_ball[2] = BALL_W*BALL_H*2;
  addr_ball[3] = BALL_W*BALL_H*3;
  addr_ball[4] = BALL_W*BALL_H*4;
  addr_ball[5] = 0;
  addr_ball[6] = BALL_W*BALL_H;
  addr_ball[7] = BALL_W*BALL_H*2;
  
  addr_score[0] = 0;
  addr_score[1] = SCORE_H*SCORE_W;
  addr_score[2] = SCORE_H*SCORE_W*2;
  addr_score[3] = SCORE_H*SCORE_W*3;
  addr_score[4] = SCORE_H*SCORE_W*4;
  addr_score[5] = SCORE_H*SCORE_W*5;
  addr_score[6] = SCORE_H*SCORE_W*6;
  addr_score[7] = SCORE_H*SCORE_W*7;
  
  addr_fire_ball[0] = 0;
  addr_fire_ball[1] = BALL_W*BALL_H;
  addr_fire_ball[2] = BALL_W*BALL_H*2;
  addr_fire_ball[3] = BALL_W*BALL_H*3;
  addr_fire_ball[4] = BALL_W*BALL_H*4;
  addr_fire_ball[5] = BALL_W*BALL_H*5;
  addr_fire_ball[6] = BALL_W*BALL_H*6;
  addr_fire_ball[7] = BALL_W*BALL_H*7;
end

// Instiantiate the VGA sync signal generator
vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);

clk_divider#(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(VBUF_W*VBUF_H), .FILE("background2.mem"))
  ram_background (.clk(clk), .we(sram_we), .en(sram_en),  .addr(sram_addr_background), .data_i(data_in), .data_o(data_out_background));

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(VBUF_W*VBUF_H), .FILE("background.mem"))
  ram_background2 (.clk(clk), .we(sram_we), .en(sram_en),  .addr(sram_addr_background2), .data_i(data_in), .data_o(data_out_background2));
  
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(PIKAJU_W*PIKAJU_H*5), .FILE("pika.mem"))
  ram_player (.clk(clk), .we(sram_we), .en(sram_en),  .addr(sram_addr_player), .data_i(data_in), .data_o(data_out_player));
  
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(PIKAJU_W*PIKAJU_H*5), .FILE("pika.mem"))
  ram_computer (.clk(clk), .we(sram_we), .en(sram_en),  .addr(sram_addr_computer), .data_i(data_in), .data_o(data_out_computer));
 
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(BALL_W*BALL_H*5), .FILE("ball.mem"))
  ram_ball (.clk(clk), .we(sram_we), .en(sram_en),  .addr(sram_addr_ball), .data_i(data_in), .data_o(data_out_ball));  

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(BALL_W*BALL_H*8), .FILE("fire_ball.mem"))
  ram_fire_ball (.clk(clk), .we(sram_we), .en(sram_en),  .addr(sram_addr_ball), .data_i(data_in), .data_o(data_out_fire_ball)); 
    
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(SCORE_W*SCORE_H*8), .FILE("nums.mem"))
  ram_player_score (.clk(clk), .we(sram_we), .en(sram_en),  .addr(sram_addr_player_score), .data_i(data_in), .data_o(data_out_player_score));  
 
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(SCORE_W*SCORE_H*8), .FILE("nums.mem"))
  ram_computer_score (.clk(clk), .we(sram_we), .en(sram_en),  .addr(sram_addr_computer_score), .data_i(data_in), .data_o(data_out_computer_score)); 

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(p_start_W*p_start_H), .FILE("p_start.mem"))
  ram_game_start (.clk(clk), .we(sram_we), .en(sram_en),  .addr(sram_addr_game_start), .data_i(data_in), .data_o(data_out_game_start)); 

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(gameover_W*gameover_H), .FILE("game_over.mem"))
  ram_game_over (.clk(clk), .we(sram_we), .en(sram_en),  .addr(sram_addr_game_over), .data_i(data_in), .data_o(data_out_game_over)); 
     
assign sram_we = ~user_btn[3]; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = 1;          // Here, we always enable the SRAM block.
assign sram_addr_background = pixel_addr_background;
assign sram_addr_player = pixel_addr_player;
assign sram_addr_computer = pixel_addr_computer;
assign sram_addr_ball = pixel_addr_ball;
assign sram_addr_player_score = pixel_addr_player_score;
assign sram_addr_computer_score = pixel_addr_computer_score;
assign sram_addr_game_start = pixel_addr_game_start;
assign sram_addr_game_over = pixel_addr_game_over;
assign data_in = 12'h000; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// VGA color pixel generator
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;


assign player_region =
           (pixel_y) >= (player_y_position<<1) && pixel_y < (player_y_position<<1) + (PIKAJU_H*2)  &&
           pixel_x <= (player_x_position<<1) + (PIKAJU_W*2) && pixel_x > (player_x_position<<1) - 1;

assign computer_region =
           (pixel_y) >= (computer_y_position<<1) && pixel_y < (computer_y_position<<1) + (PIKAJU_H*2) &&
           pixel_x <= (computer_x_position<<1) + (PIKAJU_W*2) && pixel_x >= (computer_x_position<<1);
 
assign ball_region =
           (pixel_y) >= (ball_y_position<<1) && pixel_y < (ball_y_position<<1) + (BALL_H*2) &&
           pixel_x <= (ball_x_position<<1) + (BALL_W*2) && pixel_x >= (ball_x_position<<1);

assign player_score_region =
           pixel_y  >= 0 && pixel_y <  (SCORE_H*2) &&
           pixel_x <=  (VBUF_W*2) && pixel_x + (SCORE_W*2) > (VBUF_W*2);
           
assign computer_score_region =
           pixel_y  >= 0 && pixel_y <  (SCORE_H*2) &&
           pixel_x <= (SCORE_W*2) && pixel_x >= 0;

assign game_start_region= 
           pixel_y  >= p_start_VPOS && pixel_y <  p_start_VPOS+(p_start_H*2) &&
           pixel_x <= p_start_L+(p_start_W*2) && pixel_x > p_start_L;   

assign game_over_region= 
           pixel_y  >= gameover_VPOS && pixel_y <  gameover_VPOS+(gameover_H*2) &&
           pixel_x <= gameover_L+(gameover_W*2) && pixel_x > gameover_L; 
                                       
always @ (posedge clk) begin
  if (~reset_n) begin
    pixel_addr_background <=0;
    pixel_addr_player<=0;
    pixel_addr_computer<=0;
    pixel_addr_ball<=0;
    pixel_addr_player_score<=0;
    pixel_addr_computer_score<=0;
    pixel_addr_game_start<=0;
    pixel_addr_game_over<=0;
  end
  else begin
    pixel_addr_background <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1) ;
    if(Game_state==0 && game_start_region)begin
        pixel_addr_game_start<=  ((pixel_y -p_start_VPOS)>>1)*p_start_W +((pixel_x- p_start_L)>>1);            
    end
    else pixel_addr_game_start<=10;
    if(Game_state==3 && game_over_region)begin
        pixel_addr_game_over<=  ((pixel_y -gameover_VPOS)>>1)*gameover_W +((pixel_x- gameover_L)>>1);     
    end
    else pixel_addr_game_over<=0;
    if(player_region) begin
    //check the position
        pixel_addr_player<=addr_player[player_x_position[3:1]] +((pixel_y  -(player_y_position<<1))>>1)*PIKAJU_W +(((player_x_position<<1)+(PIKAJU_W*2-1)-pixel_x)>>1);
    end
    else pixel_addr_player<=0;
    
    if(computer_region) begin 
        pixel_addr_computer<=addr_computer[computer_x_position[3:1]] +((pixel_y -(computer_y_position<<1))>>1)*PIKAJU_W +((pixel_x-(computer_x_position<<1))>>1);
    end
    else pixel_addr_computer<=0;
    
    if(ball_region) begin
        pixel_addr_ball<=addr_fire_ball[ball_x_position[5:3]] +((pixel_y -(ball_y_position<<1))>>1)*BALL_W +((pixel_x-(ball_x_position<<1))>>1);                        
    end
    else pixel_addr_ball<=0; 
    
    if(player_score_region) begin
        pixel_addr_player_score<= addr_score[player_score] +((pixel_y)>>1)*SCORE_W +((pixel_x-((VBUF_W*2-1)-(SCORE_W*2-1)))>>1);                        
    end
    else pixel_addr_player_score<=0;  
    
    if(computer_score_region) begin
        pixel_addr_computer_score<= addr_score[computer_score] +((pixel_y)>>1)*SCORE_W +((pixel_x)>>1);                        
    end
    else pixel_addr_computer_score<=0;           
  end
end          
  
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end

always @(*) begin
  if (~video_on)
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
  else begin
      if(data_out_game_over!=12'h0f0)begin
        rgb_next = data_out_game_over;   
      end
      else if(data_out_game_start!=12'h0f0)begin
        rgb_next = data_out_game_start;   
      end
      else if(data_out_computer_score!=12'h0f0)begin
        rgb_next = data_out_computer_score;   
      end   
      else if(data_out_player_score!=12'h0f0)begin
        rgb_next = data_out_player_score;   
      end    
      else if(data_out_fire_ball!=12'h0f0)begin
        rgb_next = data_out_fire_ball;   
      end
      else if(data_out_player!=12'h0f0)begin
        rgb_next = data_out_player;   
      end
      else if(data_out_computer!=12'h0f0) begin
        rgb_next = data_out_computer;
      end
      else rgb_next = data_out_background;
      
  end
end
         
endmodule
