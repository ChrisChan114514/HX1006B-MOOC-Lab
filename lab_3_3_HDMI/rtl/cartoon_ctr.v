module cartoon_ctr(
	input 	clk,
	input	reset_n,
	
	input [1:0] key,
	input 		vs_flag,
	
	output reg orientation,  //控制方向 0:左，1:右
	output reg [10:0] position,  //坐标方向，以图片左边为标准线，扩展到11位
	output reg [2:0] action  //动作
);

reg [19:0] pos_cnt;		//移动计数，20ms移动1像素
reg [3:0] act_cnt;  //动作切换计数，320ms换一个动作
reg [10:0] position_reg;  // 扩展到11位
reg [2:0] action_reg;  

/*--------------左右方向控制---------------*/
always @ (posedge clk or negedge reset_n) begin
	if(!reset_n)
		orientation <= 1'b0;
	else if(key[0]^key[1])
		if(key[1])
			orientation = 1'b1;
		else if(key[0])
			orientation = 1'b0;
	else 
		orientation <= orientation;
end

/*--------------按下计数---------------*/
always @ (posedge clk or negedge reset_n) begin
	if (!reset_n)
		pos_cnt <= 20'd0;
	else if (key[1]^key[0] && pos_cnt <= 500_000)
		pos_cnt <= pos_cnt + 1'b1;
	else 
		pos_cnt <= 20'd0;
end

/*--------------位置移动---------------*/
always @ (posedge clk or negedge reset_n) begin
	if (!reset_n)
		position_reg <= 11'd576;  // 1280/2 - 64 = 640 - 64 = 576，居中位置
	else if (pos_cnt == 500_000) begin
		if (orientation == 1'b0 && position_reg > 0)	
			position_reg <= position_reg - 1'b1;
		else if (orientation == 1'b1 && position_reg < 11'd1216)  // 1280 - 64 = 1216
			position_reg <= position_reg + 1'b1;
	end
	else
		position_reg <= position_reg;
end

/*--------------动作改变---------------*/
always @ (posedge clk or negedge reset_n) begin
	if (!reset_n)
		act_cnt <= 4'd0;
	else if (act_cnt == 4'd15)
		act_cnt <= 4'd0;
	else if (pos_cnt == 500_000)
		act_cnt <= act_cnt + 1'b1;
end

always @ (posedge clk or negedge reset_n) begin
	if (!reset_n)
		action_reg <= 3'd0;
   else if (act_cnt == 4'd15) begin
		if (action_reg < 3'd5) begin
            action_reg <= action_reg + 1'b1;
		end
		else begin
            action_reg <= 3'd0;  
		end
	end
	else 
		action_reg <= action_reg;
end

/*--------------脉冲寄存---------------*/	
always @ (posedge vs_flag or negedge reset_n) begin
	if (!reset_n) begin
		position <= 11'd576;  // 初始化到居中位置
		action <= 3'd0;
	end
	else begin
		position <= position_reg;
		action <= action_reg;
	end	
end
	
endmodule 
