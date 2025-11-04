//****************************************Copyright (c)***********************************//
// HDMI音乐播放器顶层模块
// 功能：整合HDMI图片显示和乐曲播放器功能
// 改造自：hdmi_colorbar_top.v 和 music_player.v
//****************************************************************************************//

module hdmi_music_player_top(
    input        sys_clk,       // 系统时钟输入
    input        sys_rst_n,     // 系统复位信号（低电平有效）
    
    // HDMI输出接口
    output       tmds_clk_p,    // TMDS 时钟通道正
    output       tmds_clk_n,    // TMDS 时钟通道负
    output [2:0] tmds_data_p,   // TMDS 数据通道正
    output [2:0] tmds_data_n,   // TMDS 数据通道负
    
    // 音乐播放器接口
    output       speak,         // 扬声器输出
    output       high,          // 高音标志
    output [3:0] led            // LED显示（显示音符）
);

//===============================================
// 时钟和复位信号
//===============================================
wire          pixel_clk;       // 像素时钟
wire          pixel_clk_5x;    // 5倍像素时钟
wire          clk_locked;      // PLL锁定信号

wire          clk_1M;          // 1MHz时钟（音乐播放）
wire          clk_2K;          // 2KHz时钟（音乐播放）

//===============================================
// HDMI显示相关信号
//===============================================
wire  [10:0]  pixel_xpos_w;
wire  [10:0]  pixel_ypos_w;
wire  [23:0]  pixel_data_w;

wire          video_hs;
wire          video_vs;
wire          video_de;
wire  [23:0]  video_rgb;

// ROM相关信号（图片数据）
wire  [16:0]  rom_bmp_addr;    // 17位地址支持512x256=131072
wire          rom_bmp_data;    // 1位黑白数据（从VGAlab）

//===============================================
// 音乐播放器相关信号
//===============================================
wire          clk4hz;          // 4Hz节拍时钟
wire  [7:0]   cnt8;            // 音符计数器
wire  [3:0]   music_note;      // 当前音符
wire  [10:0]  tone_code;       // 音调代码
wire          spk_pwm;         // 扬声器PWM信号
wire          spk_toggle;      // 扬声器翻转信号

//*****************************************************
//**                    HDMI显示部分
//*****************************************************

// 例化PLL IP核（用于HDMI像素时钟）
pll_clk u_pll_clk(
    .areset    (~sys_rst_n),
    .inclk0    (sys_clk),
    .c0        (pixel_clk),      // 像素时钟
    .c1        (pixel_clk_5x),   // 5倍像素时钟
    .locked    (clk_locked)
);

// 例化ROM IP核（存储BMP图片数据）
rom_bmp u_rom_bmp(
    .address   (rom_bmp_addr),
    .clock     (pixel_clk),
    .q         (rom_bmp_data)
);

// 例化视频显示驱动模块
video_driver u_video_driver(
    .pixel_clk      (pixel_clk),
    .sys_rst_n      (sys_rst_n & clk_locked),

    .video_hs       (video_hs),
    .video_vs       (video_vs),
    .video_de       (video_de),
    .video_rgb      (video_rgb),
    .data_req       (),
    
    .pixel_xpos     (pixel_xpos_w),
    .pixel_ypos     (pixel_ypos_w),
    .pixel_data     (pixel_data_w)
);

// 例化视频显示模块
video_display u_video_display(
    .pixel_clk      (pixel_clk),
    .sys_rst_n      (sys_rst_n & clk_locked),

    .pixel_xpos     (pixel_xpos_w),
    .pixel_ypos     (pixel_ypos_w),
    .cnt138         (cnt8),              // 连接音符计数器，实现动态方框显示
    .rom_data       (rom_bmp_data),
    .rom_addr       (rom_bmp_addr),
    .pixel_data     (pixel_data_w)
);

// 例化HDMI驱动模块
dvi_transmitter_top u_rgb2dvi_0(
    .pclk           (pixel_clk),
    .pclk_x5        (pixel_clk_5x),
    .reset_n        (sys_rst_n & clk_locked),
                
    .video_din      (video_rgb),
    .video_hsync    (video_hs), 
    .video_vsync    (video_vs),
    .video_de       (video_de),
                
    .tmds_clk_p     (tmds_clk_p),
    .tmds_clk_n     (tmds_clk_n),
    .tmds_data_p    (tmds_data_p),
    .tmds_data_n    (tmds_data_n)
);

//*****************************************************
//**                  音乐播放器部分
//*****************************************************

// 例化PLL IP核（用于音乐播放时钟）
pll_music u_pll_music(
    .inclk0    (sys_clk),
    .c0        (clk_1M),         // 1MHz时钟
    .c1        (clk_2K)          // 2KHz时钟
);

// 例化分频器（产生4Hz节拍时钟）
fdiv u_fdiv(
    .clk       (clk_2K),
    .pm        (clk4hz)
);

// 例化138计数器（音符序列计数）
cnt138t u_cnt138(
    .clk       (clk4hz),
    .rst_n     (sys_rst_n),
    .cnt8      (cnt8)
);

// 例化音乐ROM（存储乐曲数据）
music u_music(
    .address   (cnt8),
    .clock     (clk4hz),
    .q         (music_note)
);

// 例化音符译码器
f_code u_f_code(
    .INX       (music_note),
    .CODE      (led),            // LED显示当前音符
    .TO        (tone_code),      // 音调代码
    .H         (high)            // 高音标志
);

// 例化扬声器驱动模块
speak u_speaker(
    .clk       (clk_1M),
    .TN        (tone_code),
    .SPKS      (spk_pwm)
);

// 例化D触发器（产生方波）
DFF u_dff(
    .clk       (spk_pwm),
    .D         (~spk_toggle),
    .Q         (spk_toggle)
);

// 输出扬声器信号
assign speak = spk_toggle;

endmodule
