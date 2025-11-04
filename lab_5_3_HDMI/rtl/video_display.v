
module  video_display(
    input                pixel_clk,
    input                sys_rst_n,
    
    input        [10:0]  pixel_xpos,  //像素点横坐标
    input        [10:0]  pixel_ypos,  //像素点纵坐标
    input        [7:0]   cnt138,      //音符计数器（用于动态方框显示）
    input                rom_data,    //ROM读取的1位黑白数据（从VGAlab）
    output  reg  [16:0]  rom_addr,    //ROM地址输出（17位支持512x256=131072）
    output  reg  [23:0]  pixel_data   //像素点数据
);

//parameter define 800*600
parameter  H_DISP = 11'd800;                       //分辨率——行
parameter  V_DISP = 11'd600;                       //分辨率——列
parameter  IMG_WIDTH = 11'd512;                    //图像宽度（改为512）
parameter  IMG_HEIGHT = 11'd256;                   //图像高度

//图像显示起始坐标（居中显示）
localparam IMG_X_START = (H_DISP - IMG_WIDTH) / 2;
localparam IMG_Y_START = (V_DISP - IMG_HEIGHT) / 2;

localparam RED   = 24'b11111111_00000000_00000000;  //RGB888 红色（边框和动态方框）
localparam BLACK = 24'b00000000_00000000_00000000;  //RGB888 黑色（背景）

//相对坐标
wire [10:0] x;
wire [10:0] y;
wire        dis_en;
wire        border_en;  //边框使能信号
wire        dynamic_box_en; //动态方框使能信号

//计算动态方框位置（根据cnt138计算，完全匹配VGA工程逻辑）
// 图片：512x256, 一行16个音符，共8行，每个音符32x32像素
// VGA中图片起始：(64, 112)，方框起始偏移：(-1, 1)
// 保持相同的相对位置关系映射到HDMI
wire [10:0] pic_x_abs;     // 方框在屏幕上的绝对X坐标
wire [10:0] pic_y_abs;     // 方框在屏幕上的绝对Y坐标
wire [7:0]  cnt138_adjusted; // 调整后的计数器（往后延迟2个位置）

// 调整方框位置：延迟2个音符位置以匹配实际播放
assign cnt138_adjusted = (cnt138 >= 8'd2) ? (cnt138 - 8'd2) : 8'd0;

// VGA中方框绝对位置：
// X: 63 + cnt138[3:0]*32 (图片@64，方框从63开始，即图片左边界-1)
// Y: 113 + cnt138[6:4]*32 (图片@112，方框从113开始，即图片上边界+1)
//
// HDMI中图片起始：IMG_X_START=(800-512)/2=144, IMG_Y_START=(600-256)/2=172
// 保持相同相对偏移：
// X相对图片：-1像素
// Y相对图片：+1像素
assign pic_x_abs = (IMG_X_START - 11'd1) + cnt138_adjusted[3:0] * 11'd32;
assign pic_y_abs = (IMG_Y_START + 11'd1) + cnt138_adjusted[6:4] * 11'd32;

assign x = pixel_xpos - IMG_X_START;
assign y = pixel_ypos - IMG_Y_START;
assign dis_en = (pixel_xpos >= IMG_X_START && pixel_xpos < IMG_X_START + IMG_WIDTH) &&
                (pixel_ypos >= IMG_Y_START && pixel_ypos < IMG_Y_START + IMG_HEIGHT);

//边框判断：图像区域内的前2行、后2行、左2列、右2列
assign border_en = dis_en && ((x < 2) || (x >= IMG_WIDTH - 2) || (y < 2) || (y >= IMG_HEIGHT - 2));

//动态方框判断：使用绝对坐标，完全匹配VGA逻辑
//绘制32x32方框的四条边（当cnt138[7]=0时显示，且计数器>=2时才显示）
assign dynamic_box_en = (cnt138[7] != 1'b1) && (cnt138 >= 8'd2) &&
                        (((pixel_xpos == pic_x_abs || pixel_xpos == pic_x_abs + 11'd31) && 
                          pixel_ypos >= pic_y_abs && pixel_ypos <= pic_y_abs + 11'd31) ||
                         ((pixel_ypos == pic_y_abs || pixel_ypos == pic_y_abs + 11'd31) && 
                          pixel_xpos >= pic_x_abs && pixel_xpos <= pic_x_abs + 11'd31));
    
//*****************************************************
//**                    main code
//*****************************************************

//生成ROM地址
always @(posedge pixel_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        rom_addr <= 17'd0;
    else begin
        if (dis_en)
            rom_addr <= {y[7:0], x[8:0]};  //地址 = y*512 + x (17位：8位y + 9位x)
        else
            rom_addr <= 17'd0;
    end
end

//根据当前像素点坐标指定当前像素点颜色数据，显示ROM图像
always @(posedge pixel_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        pixel_data <= 24'd0;
    else begin
        if (dynamic_box_en) begin
            //红色动态方框（优先级最高，与VGA工程一致）
            pixel_data <= RED;
        end
        else if (border_en) begin
            //红色边框（2像素宽）
            pixel_data <= RED;
        end
        else if (dis_en) begin
            //显示ROM图像数据，1位黑白数据转换为24位RGB888
            //rom_data=1显示彩色，rom_data=0显示黑色
            if (rom_data) begin
                //彩色显示
                pixel_data[23:16] <= {rom_data,rom_data,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0};  //R
                pixel_data[15:8]  <= {1'b0,1'b0,rom_data,rom_data,1'b0,1'b0,1'b0,1'b0};  //G
                pixel_data[7:0]   <= {rom_data,1'b0,rom_data,1'b0,1'b0,1'b0,1'b0,1'b0};  //B
            end
            else begin
                pixel_data <= BLACK;
            end
        end
        else begin
            //黑色背景
            pixel_data <= BLACK;
        end
    end
end

endmodule