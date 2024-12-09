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
                  START_POS_PLAYER_X = 180,
                  START_POS_PLAYER_Y = 30,
                  START_POS_NPC_X = 100,
                  START_POS_NPC_Y = 30,
                  START_V_X = 0,
                  START_V_Y = 2,
                  g = 2, 
                  range = 23,
                  smash_speed = 23,
                  ground_y = 220;
                 
localparam [31:0] smash_cnt_max = 5000;

localparam [31:0] max_number_0 = 1,
                  max_number_1 = 3,
                  max_number_2 = 5;

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
wire player_left_side , player_right_side , player_top;
wire player_left_e , player_right_e , player_top_e , player_center_e;
wire NPC_left_side , NPC_right_side , NPC_top;
wire NPC_left_e , NPC_right_e , NPC_top_e , NPC_center_e;
wire NPC_collison;
wire player_on_ground , NPC_on_ground;
wire net_collison;
wire net_collison_top;
wire net_collison_side;

reg start;  // check smash is start
reg [31:0] clk_cnt_max;

// direction control
reg x_dir , y_dir;

initial begin
    clk_cnt_max = max_number_0;
    //clk_cnt_max = max_number_1;
end

//assign
assign player_left_side = (pos_x[31:20] + Ball_W >= Player_X  );
assign player_right_side = ( pos_x[31:20] <= Player_X + Pika_W - 2);
assign player_top = (pos_y[31:20] + Ball_H >= Player_Y);
assign player_left_e = (pos_x[31:20] + Ball_W >= Player_X) && (pos_x[31:20] + Ball_W <= Player_X + range);
assign player_right_e = (pos_x[31:20] >= Player_X + Pika_W - range) && (pos_x[31:20] <= Player_X + Pika_W );
assign player_center_e = (pos_x[31:20] + Ball_W >= Player_X + range) && (pos_x[31:20] <= Player_X + Pika_W - range);
assign player_top_e = (pos_y[31:20] + Ball_H >= Player_Y) && ( pos_y[31:20] + Ball_H <= Player_Y + 21);
assign player_collison = (player_right_side && player_left_side &&player_top 
                         && ( pos_y[31:20] <= Player_Y + Pika_H));
                                                
assign NPC_left_side = (pos_x[31:20] + Ball_W >= NPC_X +5);
assign NPC_right_side = ( pos_x[31:20] <= NPC_X + Pika_W -7);
assign NPC_top_side = (pos_y[31:20] + Ball_H  >= NPC_Y);
assign NPC_left_e = (pos_x[31:20] + Ball_W >= NPC_X ) && (pos_x[31:20] + Ball_W <= NPC_X + range);
assign NPC_right_e = (pos_x[31:20] >= NPC_X + Pika_W - range) && (pos_x[31:20] <= NPC_X + Pika_W );
assign NPC_center_e = (pos_x[31:20] + Ball_W >= NPC_X + range) && (pos_x[31:20] <= NPC_X + Pika_W - range);
assign NPC_top_e = (pos_y[31:20] + Ball_H  >= NPC_Y) && ( pos_y[31:20] + Ball_H <= NPC_Y + 21);
assign NPC_collison = (NPC_left_side && (NPC_right_side) && (NPC_top_side) && 
                      ( pos_y[31:20] <= NPC_Y + Pika_H));


assign net_collison = (pos_y[31:20] + Ball_H >= NET_POS_Y) && (pos_x[31:20] + Ball_W >= NET_POS_X) && ( pos_x[31:20] <= NET_POS_X + NET_W);
assign net_collison_top  =(pos_y[31:20] + Ball_H == NET_POS_Y) && (pos_x[31:20] + Ball_W >= NET_POS_X) && (pos_x[31:20] <= NET_POS_X + NET_W);
 
assign player_on_ground =  Player_Y + Pika_H < ground_y;
assign NPC_on_ground = NPC_Y + Pika_H < ground_y;
 
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
        smash_times <= 6;
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
        v_x <= START_V_X;
    end else begin
        if(check_cnt_max) pos_x <= (x_dir) ? (pos_x + v_x):(pos_x - v_x);
        
        if(pos_x[31:20] == 12'b0) x_dir <= 1;
        else if(pos_x[31:20] + Ball_W == VBUF_W) x_dir <= 0;
        else if(net_collison && pos_x[31:20] + Ball_W == NET_POS_X) x_dir <= 0;
        else if(net_collison && pos_x[31:20] == NET_POS_X + NET_W ) x_dir <= 1;
        else if(player_collison && smash)begin
            x_dir <= 0;
            v_x <= smash_speed;
        end else if(NPC_collison && smash)begin
            x_dir <= 1;
            v_x <= smash_speed;
        end else if(player_collison && player_left_e && ~check_smash_cnt_max)begin 
            x_dir <= 0;
            v_x <= 2; 
        end else if(player_collison && player_right_e)begin 
            x_dir <= 1;
            v_x <= 2; 
        end else if(NPC_collison && NPC_left_e )begin 
            x_dir <= 0;
            v_x <= 2;
        end else if(NPC_collison && NPC_right_e && ~check_smash_cnt_max)begin 
            x_dir <= 1;
            v_x <= 2;
        end else if(NPC_collison && NPC_center_e)begin
            v_x <= 0;
        end else if(player_collison && player_center_e)begin    
            v_x <= 0;
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
        if(check_cnt_max) pos_y <= (y_dir) ? (pos_y + v_y[31:24]) : ( (pos_y < v_y[31:24])?0:(pos_y - v_y[31:24]));
        
        if(pos_y[31:20] == 0 || v_y[31:24] == 0)y_dir <= 1;
        else if(( (player_collison && player_on_ground) || (NPC_collison && NPC_on_ground) ) && smash) y_dir <= 1;
        else if(pos_y[31:20] + Ball_H == VBUF_H - 20) y_dir <= 0;
        else if( (player_collison && player_top_e) || (NPC_collison && NPC_top_e    ) || net_collison_top) y_dir <= 0;
        else y_dir <= y_dir; 
    end
end


//ball y verctor control
always @(posedge clk)begin
    if(~reset_n)begin
        v_y[31:23] <= START_V_Y;
    end else begin
        v_y <= ( y_dir )? (v_y + g) : ( (v_y < g)?0: (v_y - g) );
    end
end

endmodule