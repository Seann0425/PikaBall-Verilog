`timescale 1ns / 1ps

module npc(
    input clk,
    input reset_n,
    input  [11:0] ball_pos_x,
    input  [11:0] ball_pos_y,
    output [11:0] npc_pos_x,
    output [11:0] npc_pos_y
);

reg [31:0] npc_clock;
reg [31:0] npc_vclock;

wire [9:0] pos;
wire [9:0] pos_v;

reg [26:0] speed;
reg [26:0] speed_clk;

localparam VBUF_W = 320;
localparam VBUF_H = 240;
localparam NPC_VPOS = 199;
localparam NPC_W = 41;
localparam NPC_H = 42;

parameter gravity = 27'd1;
parameter init_speed = 27'd4;

assign npc_pos_x = npc_clock[31:20];
assign npc_pos_y = {2'b00, npc_vclock[31:22]};

reg face_v;

// npc horizontal movement
always @(posedge clk) begin
    if (~reset_n) npc_clock[31:20] <= {VBUF_W - NPC_W - 1};
    else if (~(npc_clock[31:20] + NPC_W > VBUF_W) && ball_pos_x > npc_pos_x)
        npc_clock <= npc_clock + 1;
    else if (~(npc_clock[31:20] <= 160) && ball_pos_x < npc_pos_x)
        npc_clock <= npc_clock - 1;
end

// npc vertical movement

// acceleration setting

endmodule