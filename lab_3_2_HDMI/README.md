# lab_3_2 - HDMI 图像显示控制器

## 项目概述

本实验设计了一个基于 HDMI/DVI 协议的图像显示控制器，实现了 800×600@60Hz 的显示输出，采用 TMDS 差分信号传输，能够从 ROM 中读取位图数据并在 HDMI 显示器上居中显示 256×128 像素的图像。

## Verilog程序设计

### 系统架构

HDMI 显示系统由以下核心模块组成：

1. **hdmi_colorbar_top**：顶层模块，集成时钟管理和各子模块，实例化 ROM IP 核
2. **pll_clk**：PLL 时钟生成模块，产生 40MHz 像素时钟和 200MHz 串行时钟
3. **video_driver**：视频时序驱动模块，生成 800×600@60Hz 时序信号
4. **video_display**：视频显示模块，从 ROM 读取图像数据并生成像素输出（**本次实验重点修改的文件**）
5. **rom_bmp**：ROM IP 核，存储 256×128 像素的位图数据（6 位颜色深度）
6. **dvi_transmitter_top**：DVI/HDMI 传输顶层模块
7. **dvi_encoder**：DVI 编码器，执行 TMDS 8b/10b 编码
8. **serializer_10_to_1**：10:1 并串转换器，使用 DDR 输出技术
9. **asyn_rst_syn**：异步复位同步化模块

### video_display 模块功能

`video_display` 模块是应用层显示逻辑模块，负责从 ROM 读取图像数据并生成显示内容，具有以下特性：

- **分辨率支持**：800×600 像素（SVGA）
- **图像尺寸**：256×128 像素（存储在 ROM 中）
- **颜色深度**：24 位 RGB888 全彩色输出（从 6 位 ROM 数据扩展而来）
- **显示位置**：图像居中显示，背景为黑色
- **ROM 接口**：输出 15 位地址，接收 6 位 RGB 数据
- **颜色扩展**：将 ROM 的 6 位颜色（2:2:2）扩展为 24 位 RGB888（8:8:8）
- **地址生成**：根据像素坐标计算 ROM 读取地址（addr = y×256 + x）

### 功能实现机制

#### 时钟生成

- **系统输入时钟**：50MHz
- **PLL 输出**：
  - 像素时钟：40MHz（用于 800×600@60Hz 时序）
  - 串行时钟：200MHz（5 倍像素时钟，用于 TMDS 串行化）

#### 800×600 视频时序

- **像素时钟**：40MHz
- **水平时序**：总计 1056 个时钟周期
  - 显示区：800 像素
  - 前肩：40 像素
  - 同步脉冲：128 像素
  - 后肩：88 像素
- **垂直时序**：总计 628 行
  - 显示区：600 行
  - 前肩：1 行
  - 同步脉冲：4 行
  - 后肩：23 行
- **帧率**：60Hz（40MHz ÷ 1056 ÷ 628 ≈ 60Hz）

#### ROM 图像显示算法

`video_display` 模块通过以下方式从 ROM 读取并显示图像：

**显示区域计算**：

```verilog
IMG_X_START = (800 - 256) / 2 = 272   // 图像起始横坐标
IMG_Y_START = (600 - 128) / 2 = 236   // 图像起始纵坐标
```

**地址生成逻辑**：

```verilog
// 相对坐标计算
x = pixel_xpos - IMG_X_START;
y = pixel_ypos - IMG_Y_START;

// 显示使能条件
dis_en = (pixel_xpos >= IMG_X_START && pixel_xpos < IMG_X_START + 256) &&
         (pixel_ypos >= IMG_Y_START && pixel_ypos < IMG_Y_START + 128);

// ROM 地址生成（15 位，覆盖 256×128=32768 字）
rom_addr = {y[6:0], x[7:0]};  // 地址 = y×256 + x
```

**颜色扩展逻辑**：

```verilog
// 将 6 位 ROM 数据（R[1:0], G[1:0], B[1:0]）扩展为 24 位 RGB888
R[7:0] = {rom_data[1], rom_data[1], rom_data[1], rom_data[1],
          rom_data[0], rom_data[0], rom_data[0], rom_data[0]};
G[7:0] = {rom_data[3], rom_data[3], rom_data[3], rom_data[3],
          rom_data[2], rom_data[2], rom_data[2], rom_data[2]};
B[7:0] = {rom_data[5], rom_data[5], rom_data[5], rom_data[5],
          rom_data[4], rom_data[4], rom_data[4], rom_data[4]};
```

- **图像尺寸**：256×128 像素（存储在 ROM 中）
- **显示位置**：居中显示（起始坐标：272, 236）
- **ROM 容量**：32768 字（256×128）
- **数据宽度**：6 位（每通道 2 位）
- **初始化文件**：logo.mif（包含位图图像数据）
- **颜色扩展**：位复制方式，保持颜色比例

#### TMDS 编码与传输

- **编码方式**：8b/10b TMDS 编码（直流平衡编码）
- **通道数量**：3 个数据通道（R、G、B）+ 1 个时钟通道
- **差分信号**：每个通道使用差分对传输（P/N）
- **串行化**：使用 DDR 技术实现 10:1 并串转换

### 端口说明

#### hdmi_colorbar_top 顶层模块

| 端口           | 方向   | 位宽 | 说明                              |
| -------------- | ------ | ---- | --------------------------------- |
| sys_clk        | input  | 1    | 50MHz 系统时钟                    |
| sys_rst_n      | input  | 1    | 系统复位信号（低电平有效）        |
| tmds_clk_p     | output | 1    | TMDS 时钟差分信号正端             |
| tmds_clk_n     | output | 1    | TMDS 时钟差分信号负端             |
| tmds_data_p[2] | output | 1    | TMDS 数据通道 2 差分信号正端（R） |
| tmds_data_n[2] | output | 1    | TMDS 数据通道 2 差分信号负端（R） |
| tmds_data_p[1] | output | 1    | TMDS 数据通道 1 差分信号正端（G） |
| tmds_data_n[1] | output | 1    | TMDS 数据通道 1 差分信号负端（G） |
| tmds_data_p[0] | output | 1    | TMDS 数据通道 0 差分信号正端（B） |
| tmds_data_n[0] | output | 1    | TMDS 数据通道 0 差分信号负端（B） |

#### video_display 应用层模块

| 端口           | 方向   | 位宽 | 说明                       |
| -------------- | ------ | ---- | -------------------------- |
| pixel_clk      | input  | 1    | 40MHz 像素时钟             |
| sys_rst_n      | input  | 1    | 系统复位信号（低电平有效） |
| pixel_xpos     | input  | 11   | 当前像素横坐标（0~799）    |
| pixel_ypos     | input  | 11   | 当前像素纵坐标（0~599）    |
| rom_data[5:0]  | input  | 6    | ROM 输出的 6 位 RGB 数据   |
| rom_addr[14:0] | output | 15   | ROM 读取地址（0~32767）    |
| pixel_data[23] | output | 24   | 像素颜色数据 RGB888 格式   |

#### rom_bmp ROM 模块

| 端口          | 方向   | 位宽 | 说明                           |
| ------------- | ------ | ---- | ------------------------------ |
| address[14:0] | input  | 15   | ROM 读取地址（0~32767）        |
| clock         | input  | 1    | 读取时钟（40MHz 像素时钟）     |
| q[5:0]        | output | 6    | 6 位 RGB 数据（R:G:B = 2:2:2） |

## ModelSim 仿真验证

本工程包含完整的仿真测试平台 `tb_hdmi_colorbar_top.v`，用于验证 HDMI 显示系统的功能。

### 仿真环境配置

- **时间单位**：`timescale 1ns/1ps`
- **系统时钟**：50MHz（周期 20ns）
- **像素时钟**：40MHz（由 PLL 生成）
- **串行时钟**：200MHz（由 PLL 生成）
- **仿真时长**：建议至少 20ms，覆盖 1 帧完整的显示周期

### 测试激励

1. **时钟生成**：产生 50MHz 连续系统时钟
2. **复位序列**：
   - 初始时刻 sys_rst_n=0，复位系统
   - 200ns 后释放复位（sys_rst_n=1）
3. **运行测试**：观察 TMDS 差分信号输出和时序

### 主要观察信号

- **video_hs/video_vs**：内部视频同步信号（800×600 时序）
- **video_de**：数据使能信号（有效显示区域标识）
- **pixel_data**：24 位 RGB 像素数据，在图像区域应显示 ROM 中的图像
- **rom_addr**：ROM 地址信号，在图像显示区域从 0 循环到 32767
- **rom_data**：ROM 输出的 6 位颜色数据
- **tmds_data_p/n**：TMDS 差分数据信号
- **tmds_clk_p/n**：TMDS 差分时钟信号

### 时序参数验证

- **行周期**：约 26.4μs（1056 × 25ns）
- **场周期**：约 16.6ms（628 行 × 26.4μs）
- **帧率**：60Hz

## FPGA 硬件实验

在 Quartus 中综合并生成 `.sof` 配置文件，下载到 FPGA 开发板进行硬件验证。

### 引脚绑定

#### 输入信号

| 信号      | FPGA引脚 | 电气标准 | 说明                       |
| --------- | -------- | -------- | -------------------------- |
| sys_clk   | P11      | 3.3V     | 50MHz 系统时钟（板载晶振） |
| sys_rst_n | M1       | 3.3V     | 系统复位（KEY1 按键）      |

#### 输出信号（HDMI 接口）

| 信号           | FPGA引脚 | 电气标准  | 说明                     |
| -------------- | -------- | --------- | ------------------------ |
| tmds_clk_p     | D6       | LVDS 3.3V | HDMI 时钟差分信号正端    |
| tmds_clk_n     | C6       | LVDS 3.3V | HDMI 时钟差分信号负端    |
| tmds_data_p[2] | H5       | LVDS 3.3V | HDMI 数据通道2正端（红） |
| tmds_data_n[2] | G5       | LVDS 3.3V | HDMI 数据通道2负端（红） |
| tmds_data_p[1] | E8       | LVDS 3.3V | HDMI 数据通道1正端（绿） |
| tmds_data_n[1] | D8       | LVDS 3.3V | HDMI 数据通道1负端（绿） |
| tmds_data_p[0] | B7       | LVDS 3.3V | HDMI 数据通道0正端（蓝） |
| tmds_data_n[0] | A7       | LVDS 3.3V | HDMI 数据通道0负端（蓝） |

**注意**：以上引脚分配需根据实际开发板原理图进行调整。

### 硬件测试步骤

**连接 HDMI 显示器**

- 使用标准 HDMI 线缆连接 FPGA 开发板的 HDMI 接口和显示器
- 确保显示器支持 800×600@60Hz（SVGA）分辨率

## 技术要点总结

### 与 VGA 实验的对比

| 特性         | VGA 实验（640×480）           | HDMI 实验（800×600）          |
| ------------ | ------------------------------ | ------------------------------ |
| 接口类型     | VGA 模拟接口                   | HDMI/DVI 数字接口              |
| 信号类型     | 并行 RGB + 同步信号            | TMDS 差分串行信号              |
| 时钟频率     | 25MHz（像素时钟）              | 40MHz（像素时钟）              |
| 颜色深度     | 12 位（4:4:4）                 | 24 位（8:8:8）                 |
| 分辨率       | 640×480                       | 800×600                       |
| 图像尺寸     | 256×128（居中显示）           | 256×128（居中显示）           |
| 时钟管理     | 简单二分频                     | PLL 倍频与分频                 |
| 编码方式     | 无编码（直接输出）             | TMDS 8b/10b 编码               |
| 传输技术     | 单端并行                       | 差分串行 + DDR                 |
| ROM 数据格式 | 6 位 RGB（2:2:2）              | 6 位 RGB（2:2:2）              |
| 颜色扩展     | 扩展到 12 位（位复制）         | 扩展到 24 位（位复制）         |
| 显示逻辑     | ROM 读取 + 居中显示 + 红色边框 | ROM 读取 + 居中显示 + 黑色背景 |
| 边框效果     | 2 像素红色边框                 | 无边框，纯黑色背景             |

### 关键技术点

1. **PLL 时钟生成**：生成 40MHz 像素时钟和 200MHz 串行时钟
2. **ROM IP 核应用**：使用 Altera ROM IP 核存储 32KB 位图数据
3. **图像居中显示**：计算显示起始坐标实现图像居中
4. **地址生成逻辑**：根据相对坐标生成 ROM 读取地址
5. **颜色位扩展**：将 6 位 ROM 数据扩展为 24 位 RGB888
6. **TMDS 编码**：实现直流平衡和转换最小化的 8b/10b 编码
7. **高速串行化**：使用 DDR 和 DDIO 原语实现 10:1 并串转换
8. **差分信号驱动**：配置 LVDS 输出标准驱动 HDMI 物理层
9. **时序约束**：正确设置多时钟域约束和输出延迟约束
10. **复位同步**：跨时钟域的异步复位同步化处理

### 项目文件说明

| 文件/目录                    | 类型        | 说明                              |
| ---------------------------- | ----------- | --------------------------------- |
| rtl/hdmi_colorbar_top.v      | Verilog HDL | 顶层模块，实例化 ROM 和各子模块   |
| rtl/video_display.v          | Verilog HDL | 视频显示模块，ROM 读取和颜色扩展  |
| rtl/video_driver.v           | Verilog HDL | 视频时序驱动模块                  |
| rtl/dvi_transmitter_top.v    | Verilog HDL | DVI/HDMI 传输顶层                 |
| rtl/dvi_encoder.v            | Verilog HDL | TMDS 编码器                       |
| rtl/serializer_10_to_1.v     | Verilog HDL | 10:1 串行化模块                   |
| rtl/asyn_rst_syn.v           | Verilog HDL | 异步复位同步化                    |
| prj_1006B/ipcore/rom_bmp.v   | Verilog HDL | ROM IP 核文件                     |
| prj_1006B/ipcore/rom_bmp.qip | QIP 文件    | ROM IP 核配置文件                 |
| prj_1006B/ipcore/logo.mif    | MIF 文件    | 位图数据初始化文件（32768×6bit） |
| prj_1006B/ipcore/pll_clk/    | IP 核目录   | PLL 时钟生成 IP 核                |
| prj_1006B/ipcore/ddio_out/   | IP 核目录   | DDR 输出 IP 核                    |

ChrisChan
更新日期：2025/10/28
