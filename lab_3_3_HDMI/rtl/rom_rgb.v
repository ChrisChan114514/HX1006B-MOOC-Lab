module rom_rgb(
	input			clk,
	input			reset_n,
	
	input [10:0]	x,
	input [10:0]	y,

    input [10:0]    position,  // 扩展到11位以支持1280x720
    input [ 2:0]    action,
    input           orientation,
	
	output reg [23:0]	rgb  // 从12位扩展到24位RGB888
);

localparam CLOUD =4'h6,BLUESKY=4'h7,GRASS=4'he,BRICK2=4'hf;

reg [5:0]  pal_addr, bg_pal, fg_pal;
reg [11:0] pal_rom[63:0];  // 调色板保持12位
reg [5:0]  png_rom[256*64-1:0];
wire [10:0] x_shift,y_shift;  // 扩展到11位

reg [3:0] background;

// 缩放因子: 1280x720 vs 640x480 = 2倍
wire [10:0] x_scaled;  // 缩放后的x坐标
wire [10:0] y_scaled;  // 缩放后的y坐标

assign x_scaled = x >> 1;  // 除以2进行缩放
assign y_scaled = y >> 1;  // 除以2进行缩放

initial $readmemh("walk_pal.mem",pal_rom);
initial $readmemh("walk.mem", png_rom);

always @(posedge clk) begin
	bg_pal <= png_rom[{background[3],y_scaled[4:0],background[2:0],x_scaled[4:0]}];
	if(orientation)
		fg_pal <= png_rom[{y_shift[5:0],action[2:0],x_shift[4:0]}];
	else
		fg_pal <= png_rom[{y_shift[5:0],action[2:0],~x_shift[4:0]}];
end

assign x_shift = x_scaled>position ? x_scaled-position : 0;
assign y_shift = y_scaled - 32 ;

always @*
	pal_addr = (fg_pal && x_shift-1 < 32 && y_shift <64)  ? fg_pal : bg_pal;

always @ (posedge clk) begin
	// 将12位RGB444扩展为24位RGB888
	rgb <= {pal_rom[pal_addr][11:8], pal_rom[pal_addr][11:8],   // R: 4位扩展到8位
	        pal_rom[pal_addr][7:4],  pal_rom[pal_addr][7:4],    // G: 4位扩展到8位  
	        pal_rom[pal_addr][3:0],  pal_rom[pal_addr][3:0]};   // B: 4位扩展到8位
end


// Background
always @*
	case({y_scaled[6:5],x_scaled[8:5]})
		6'h2 : background = CLOUD;
		6'h8 : background = CLOUD;
		6'h26 : background = GRASS;
		6'h29 : background = GRASS;
		6'h30 : background = BRICK2;
		6'h31 : background = BRICK2;
		6'h32 : background = BRICK2;
		6'h33 : background = BRICK2;
		6'h34 : background = BRICK2;
		6'h35 : background = BRICK2;
		6'h36 : background = BRICK2;
		6'h37 : background = BRICK2;
		6'h38 : background = BRICK2;
		6'h39 : background = BRICK2;
		6'h3a : background = BRICK2;
		6'h3b : background = BRICK2;
		6'h3c : background = BRICK2;
		6'h3d : background = BRICK2;
		6'h3e : background = BRICK2;
		6'h3f : background = BRICK2;
		default : background = BLUESKY;
	endcase

		

endmodule 
