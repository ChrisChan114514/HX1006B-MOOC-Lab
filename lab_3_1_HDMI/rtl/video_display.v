
module  video_display(
    input                pixel_clk,
    input                sys_rst_n,
    
    input        [10:0]  pixel_xpos,  //像素点横坐标
    input        [10:0]  pixel_ypos,  //像素点纵坐标
    output  reg  [23:0]  pixel_data   //像素点数据
);

//parameter define 800*600
parameter  H_DISP = 11'd800;                       //分辨率——行
parameter  V_DISP = 11'd600;                       //分辨率——列

localparam WHITE   = 24'b11111111_11111111_11111111;  //RGB888 白色
localparam YELLOW  = 24'b11111111_11111111_00000000;  //RGB888 黄色
localparam CYAN    = 24'b00000000_11111111_11111111;  //RGB888 青色
localparam GREEN   = 24'b00000000_11111111_00000000;  //RGB888 绿色
localparam MAGENTA = 24'b11111111_00000000_11111111;  //RGB888 品红色
localparam RED     = 24'b11111111_00000000_00000000;  //RGB888 红色
localparam BLUE    = 24'b00000000_00000000_11111111;  //RGB888 蓝色
localparam BLACK   = 24'b00000000_00000000_00000000;  //RGB888 黑色

//均匀分布参数：1920/8 = 240像素/区域
localparam BAND_WIDTH = H_DISP / 8;
    
//*****************************************************
//**                    main code
//*****************************************************

//根据当前像素点坐标指定当前像素点颜色数据,在屏幕上显示8条彩色条纹
//使用除法实现均匀分布，每个区域宽度为240像素
always @(posedge pixel_clk ) begin
    if (!sys_rst_n)
        pixel_data <= 24'd0;
    else begin
        if (pixel_xpos < BAND_WIDTH * 1)
            pixel_data <= WHITE;        // 白色
        else if (pixel_xpos < BAND_WIDTH * 2)
            pixel_data <= YELLOW;       // 黄色
        else if (pixel_xpos < BAND_WIDTH * 3)
            pixel_data <= CYAN;         // 青色
        else if (pixel_xpos < BAND_WIDTH * 4)
            pixel_data <= GREEN;        // 绿色
        else if (pixel_xpos < BAND_WIDTH * 5)
            pixel_data <= MAGENTA;      // 品红色
        else if (pixel_xpos < BAND_WIDTH * 6)
            pixel_data <= RED;          // 红色
        else if (pixel_xpos < BAND_WIDTH * 7)
				pixel_data <= BLACK;        // 黑色
        else
            pixel_data <= BLUE;         // 蓝色
    end
end

endmodule