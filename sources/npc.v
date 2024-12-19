`timescale 1ns / 1ps

module npc(
    input clk,
    input reset_n,
    input  [11:0] ball_pos_x,
    input  [11:0] ball_pos_y,
    input game_mode, // 0: hard, 1: easy
    input [1:0] game_state,
    output [11:0] npc_pos_x,
    output [11:0] npc_pos_y
);

reg [31:0] npc_clock;
reg [31:0] npc_vclock;
reg [20:0] doziness_clock; // for easy mode

wire [9:0] pos;
wire [9:0] pos_v;

reg [26:0] speed;
reg [26:0] speed_clk;

localparam VBUF_W = 320;
localparam VBUF_H = 240;
localparam NPC_VPOS = 199;
localparam NPC_W = 41;
localparam NPC_H = 42;
localparam BALL_DIST = 18;

parameter gravity = 27'd1;
parameter init_speed = 27'd4;

assign npc_pos_x = npc_clock[31:20];
assign npc_pos_y = {2'b00, npc_vclock[31:22]};

reg face_v;

// npc horizontal movement
always @(posedge clk) begin
    if (~reset_n || game_state == 1) npc_clock[31:20] <= 1;
    else if (~(npc_clock[31:20] + NPC_W > 160) && ball_pos_x > npc_pos_x + BALL_DIST + npc_clock[1:0]
            && (game_mode == 0 || doziness_clock < 21'd500_000))
        npc_clock <= npc_clock + 1;
    else if (~(npc_clock[31:20] <= 0) && ball_pos_x < npc_pos_x + BALL_DIST + npc_clock[1:0]
            && (game_mode == 0 || doziness_clock < 21'd500_000))
        npc_clock <= npc_clock - 1;
end

// npc vertical movement
always @(posedge clk) begin
    if (~reset_n || game_state == 1 ) npc_vclock[31:22] <= VBUF_H - NPC_H - 21;
    else if (face_v && npc_vclock[31:22] > 0)
        npc_vclock <= npc_vclock - speed;
    else if (~face_v && npc_vclock[31:22] + NPC_H < VBUF_H - 20)
        npc_vclock <= npc_vclock + speed;
end

// acceleration setting
always @(posedge clk) begin
    if (~reset_n) begin
        speed <= 0;
        face_v <= 1;
        speed_clk <= 0;
    end else if (ball_pos_y <= 80 && npc_vclock[31:22] == (VBUF_H - NPC_H - 20)) begin
        speed <= 20;
        face_v <= 1;
    end else if (face_v && speed_clk > 27'd8388608) begin
        if (speed == 0) face_v <= 0;
        else speed <= speed - 4;
        speed_clk <= 0;
    end else if (~face_v && npc_vclock[31:22] + NPC_H < VBUF_H - 20 && speed_clk > 27'd8388608) begin
        speed <= speed + 2;
        speed_clk <= 0;
    end else speed_clk <= speed_clk + 1;
end

// doziness clock control
always @(posedge clk) begin
    if (~reset_n) doziness_clock <= 0;
    else if (game_mode == 1 && doziness_clock < 21'd1_000_000) doziness_clock <= doziness_clock + 1;
    else doziness_clock <= 0;
end

endmodule
