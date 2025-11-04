
module  video_display(
    input                pixel_clk,
    input                sys_rst_n,
    
    input        [1:0]   key,           // 添加按键输入
    input                vs_flag,       // 添加场同步标志
    
    input        [10:0]  pixel_xpos,  //像素点横坐标
    input        [10:0]  pixel_ypos,  //像素点纵坐标
    output       [23:0]  pixel_data   //像素点数据
);

//parameter define 1280*720
parameter  H_DISP = 11'd1280;                      //分辨率——行
parameter  V_DISP = 11'd720;                       //分辨率——列

// 卡通动画控制信号
wire              orientation;
wire [10:0]       position;
wire [2:0]        action;

//*****************************************************
//**                    main code
//*****************************************************

// 实例化卡通控制器
cartoon_ctr u_cartoon_ctr(
    .clk        (pixel_clk),
    .reset_n    (sys_rst_n),
    .key        (key),
    .vs_flag    (vs_flag),
    .orientation(orientation),
    .position   (position),
    .action     (action)
);

// 实例化ROM RGB模块
rom_rgb u_rom_rgb(
    .clk        (pixel_clk),
    .reset_n    (sys_rst_n),
    .x          (pixel_xpos),
    .y          (pixel_ypos),
    .position   (position),
    .action     (action),
    .orientation(orientation),
    .rgb        (pixel_data)
);

endmodule