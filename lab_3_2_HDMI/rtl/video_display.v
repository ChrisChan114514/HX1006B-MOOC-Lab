
module  video_display(
    input                pixel_clk,
    input                sys_rst_n,
    
    input        [10:0]  pixel_xpos,  //像素点横坐标
    input        [10:0]  pixel_ypos,  //像素点纵坐标
    input        [5:0]   rom_data,    //ROM读取的6位RGB数据
    output  reg  [14:0]  rom_addr,    //ROM地址输出
    output  reg  [23:0]  pixel_data   //像素点数据
);

//parameter define 800*600
parameter  H_DISP = 11'd800;                       //分辨率——行
parameter  V_DISP = 11'd600;                       //分辨率——列
parameter  IMG_WIDTH = 11'd256;                    //图像宽度
parameter  IMG_HEIGHT = 11'd128;                   //图像高度

//图像显示起始坐标（居中显示）
localparam IMG_X_START = (H_DISP - IMG_WIDTH) / 2;
localparam IMG_Y_START = (V_DISP - IMG_HEIGHT) / 2;

localparam RED   = 24'b11111111_00000000_00000000;  //RGB888 红色（边框）
localparam BLACK = 24'b00000000_00000000_00000000;  //RGB888 黑色（背景）

//相对坐标
wire [10:0] x;
wire [10:0] y;
wire        dis_en;
wire        border_en;  //边框使能信号

assign x = pixel_xpos - IMG_X_START;
assign y = pixel_ypos - IMG_Y_START;
assign dis_en = (pixel_xpos >= IMG_X_START && pixel_xpos < IMG_X_START + IMG_WIDTH) &&
                (pixel_ypos >= IMG_Y_START && pixel_ypos < IMG_Y_START + IMG_HEIGHT);

//边框判断：图像区域内的前2行、后2行、左2列、右2列
assign border_en = dis_en && ((x < 2) || (x >= IMG_WIDTH - 2) || (y < 2) || (y >= IMG_HEIGHT - 2));
    
//*****************************************************
//**                    main code
//*****************************************************

//生成ROM地址
always @(posedge pixel_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        rom_addr <= 15'd0;
    else begin
        if (dis_en)
            rom_addr <= {y[6:0], x[7:0]};  //地址 = y*256 + x
        else
            rom_addr <= 15'd0;
    end
end

//根据当前像素点坐标指定当前像素点颜色数据，显示ROM图像
always @(posedge pixel_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        pixel_data <= 24'd0;
    else begin
        if (border_en) begin
            //红色边框（2像素宽）
            pixel_data <= RED;
        end
        else if (dis_en) begin
            //显示ROM图像数据，将6位RGB扩展为24位RGB888
            //每个2位通道扩展为8位：{bit[1],bit[1],bit[1],bit[1],bit[0],bit[0],bit[0],bit[0]}
            pixel_data[23:16] <= {rom_data[1],rom_data[1],rom_data[1],rom_data[1],
                                  rom_data[0],rom_data[0],rom_data[0],rom_data[0]};  //R
            pixel_data[15:8]  <= {rom_data[3],rom_data[3],rom_data[3],rom_data[3],
                                  rom_data[2],rom_data[2],rom_data[2],rom_data[2]};  //G
            pixel_data[7:0]   <= {rom_data[5],rom_data[5],rom_data[5],rom_data[5],
                                  rom_data[4],rom_data[4],rom_data[4],rom_data[4]};  //B
        end
        else begin
            //黑色背景
            pixel_data <= BLACK;
        end
    end
end

endmodule