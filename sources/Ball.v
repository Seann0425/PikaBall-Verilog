module Ball(
    input clk,
    input reset_n,
    input [11:0] Player_X,
    input [11:0] Player_Y,
    input [11:0] NPC_X,
    input [11:0] NPC_Y,
    input [1:0] Game_state, //0:start 1:ball wait for drop 2:in game 3:game end
    input who_win, //0:player win 1:npc win
    input smash, //smash control
    output [11:0] Ball_X,
    output [11:0] Ball_Y
);

//paramater
localparam [11:0] Ball_W = 30,
                  Ball_H = 30,
                  Pika_W = 41,
                  Pika_H = 42,
                  VBUF_H = 240,
                  VBUF_W = 320,
                  NET_W = 6,
                  NET_H = 90,
                  NET_POS_X = 160,
                  NET_POS_Y = 150,
                  START_POS_PLAYER_X = 160,
                  START_POS_PLAYER_Y = 60,
                  START_POS_NPC_X = 100,
                  START_POS_NPC_Y = 60,
                  START_V_X = 1,
                  START_V_Y = 0,
                  g = 2;  
                 
localparam [31:0] clk_cnt_max = 25,
                  smash_cnt_max = 50_000_000;

//variable
reg [31:0] pos_x , pos_y;
reg [31:0] v_x , v_y;
reg check_x_dir , check_y_dir;
reg [2:0] smash_times;
reg [31:0] clk_cnt;
reg [31:0] smash_cnt;
wire check_cnt_max;
wire check_smash_cnt_max;
wire palyer_collison;
wire NPC_collison;
wire net_collison;
wire net_collison_top;
wire net_collison_side;

reg start;  // check smash is start

// direction control
reg x_dir , y_dir;


//assign
assign player_collison = ((pos_x[31:20] + Ball_W >= Player_X + 5 ) && ( pos_x[31:20] <= Player_X + Pika_W - 7)&&
                         (pos_y[31:20] + Ball_H >= Player_Y) && ( pos_y[31:20] <= Player_Y + Pika_H));

assign NPC_collison = ((pos_x[31:20] + Ball_W >= NPC_X +5) && ( pos_x[31:20] <= NPC_X + Pika_W -7)&&
                      ( pos_y[31:20] + Ball_H  >= NPC_Y) && ( pos_y[31:20] <= NPC_Y + Pika_H));

assign net_collison = (pos_y[31:20] + Ball_H >= NET_POS_Y) && (pos_x[31:20] + Ball_W >= NET_POS_X) && ( pos_x[31:20] <= NET_POS_X + NET_W);
assign net_collison_top  =(pos_y[31:20] + Ball_H == NET_POS_Y) && (pos_x[31:20] + Ball_W >= NET_POS_X) && (pos_x[31:20] <= NET_POS_X + NET_W);
 
assign Ball_X = pos_x[31:20];
assign Ball_Y = pos_y[31:20];
assign check_cnt_max = (clk_cnt == clk_cnt_max);
assign check_smash_cnt_max = (smash_cnt == smash_cnt_max);

//clk_cnt control
always @(posedge clk)begin
    if(~reset_n) clk_cnt <= 0;
    else clk_cnt <= (clk_cnt == clk_cnt_max)?0:(clk_cnt + 1);
end 

//smash cnt contrl
always @(posedge clk)begin
    if(~reset_n) begin 
        smash_cnt <= 0;
        start <= 0;
        smash_times <= 1;
    end else if(start)begin
        smash_cnt <= (smash_cnt == smash_cnt_max)?smash_cnt_max:(smash_cnt+1);
        start <= (check_smash_cnt_max)?0:1;
        smash_times <= 2;
    end else begin
        smash_times <= 1;
        start <= (smash && (player_collison || NPC_collison))?1:0;
        smash_cnt <= 0;
    end
end

//ball pos_x control
always @(posedge clk)begin
    if(~reset_n || Game_state != 2'b10)begin
        pos_x[31:20] <= (who_win)?START_POS_NPC_X:START_POS_PLAYER_X;
        x_dir <= 1;
    end else begin
        pos_x <= (x_dir) ? (pos_x + v_x * smash_times):(pos_x - v_x * smash_times);
        if(pos_x[31:20] == 12'b0) x_dir <= 1;
        else if(pos_x[31:20] + Ball_W == VBUF_W) x_dir <= 0;
        else if(net_collison && pos_x[31:20] + Ball_W == NET_POS_X) x_dir <= 0;
        else if(net_collison && pos_x[31:20] == NET_POS_X + NET_W ) x_dir <= 1;
        else if(player_collison && pos_x[31:20] + Ball_W == Player_X)begin 
            x_dir <= 0;
            v_x <= 2; 
        end else if(player_collison && pos_x[31:20] == Player_X + Pika_W)begin 
            x_dir <= 1;
            v_x <= 2; 
        end else if(NPC_collison && pos_x[31:20] + Ball_W == NPC_X)begin 
            x_dir <= 0;
            v_x <= 2;
        end else if(NPC_collison && pos_x[31:20] == NPC_X + Pika_W)begin 
            x_dir <= 1;
            v_x <= 2;
        end else x_dir <= x_dir;
    end
end

//ball pos_y control
always @(posedge clk)begin
    if(~reset_n || Game_state != 2'b10)begin
        if(who_win) pos_y[31:20] <= START_POS_NPC_Y;
        else pos_y[31:20] <= START_POS_PLAYER_Y;
        y_dir <= 1;
    end else begin
        pos_y <= (y_dir) ? (pos_y + v_y[31:23] * smash_times) : (pos_y - v_y[31:23] * smash_times);
        if(pos_y[31:20] == 0 || v_y[31:23] == 0)y_dir <= 1;
        else if(pos_y[31:20] + Ball_H == VBUF_H - 20) y_dir <= 0;
        else if( (player_collison && pos_x + Ball_H <= Player_Y + 21) || (NPC_collison && pos_x + Ball_H <= NPC_Y + 21) || net_collison_top) y_dir <= 0;
        else y_dir <= y_dir; 
    end
end


//ball verctor control
always @(posedge clk)begin
    if(~reset_n)begin
        v_x <= START_V_X;
        v_y[31:23] <= START_V_Y;
    end else begin
        if(player_collison)begin
            v_y <= 5;
        end else begin
            v_y <= ( y_dir )? (v_y + g) : ( (v_y < g)?0:(v_y - g) );
        end
    end
end

endmodule