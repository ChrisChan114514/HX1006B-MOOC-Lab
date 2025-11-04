`timescale 1 ns / 1 ps
module CNT10_TB();

reg CLK_50;
reg [2:0] KEY;  // KEY[2]=EN, KEY[1]=LOAD_N, KEY[0]=RST_N
reg [3:0] SW;
// wires   
wire [3:0] DOUT;
wire COUT;

// 访问内部信号用于波形观察
wire clk_internal;           // 分频后的时钟
wire [25:0] div_cnt_internal; // 分频计数器
assign clk_internal = U_CNT10.clk;
assign div_cnt_internal = U_CNT10.div_cnt;

// 为了加快仿真，覆盖主模块的分频参数
// DIV_LEN = 2 表示每 1 个 CLK_50 周期 clk 就跳变（clk = CLK_50/2）
// 这样计数器在每个 clk 上升沿（即每 2 个 CLK_50 周期 = 4ns）变化一次
defparam U_CNT10.DIV_LEN = 2;  // 将 50,000,000 改为 2 以加快仿真

CNT10 U_CNT10(
	.CLK_50	(CLK_50),
	.KEY		(KEY),
	.SW		(SW),
	.DOUT		(DOUT),
	.COUT		(COUT)
);

initial begin 
	CLK_50 <= 1'b0;
	KEY <= 3'b000;  // EN=0, LOAD_N=0, RST_N=0 (all disabled/reset)
	SW <= 4'b0000;
	
	$display("========================================");
	$display("CNT10 Testbench Started");
	$display("Note: DIV_LEN overridden to 2 for fast simulation");
	$display("DIV_LEN/2 = 1, so clk_internal toggles every CLK_50 cycle");
	$display("Counter increments every clk_internal posedge (every 4ns)");
	$display("KEY mapping: KEY[2]=EN, KEY[1]=LOAD_N, KEY[0]=RST_N");
	$display("========================================");
	
	#20 	KEY[0] <= 1'b1;  // Release reset (RST_N=1)
			$display("[%0t ns] Reset released (KEY[0]=1)", $time);
			
	#20	KEY[2] <= 1'b1;  // Enable counter (EN=1)
			SW <= 4'b0011;   // Set load data to 3
			$display("[%0t ns] Counter enabled (KEY[2]=1), SW=3", $time);
			
	#100	KEY[1] <= 1'b0;  // Load data (LOAD_N=0)
			$display("[%0t ns] Load signal asserted (KEY[1]=0)", $time);
			
	#20	KEY[1] <= 1'b1;  // Resume counting (LOAD_N=1)
			$display("[%0t ns] Load released (KEY[1]=1), counting from loaded value", $time);
	
	// 等待足够长的时间观察多次计数
	// 每次计数需要 1 个 clk 周期 = 4ns (2个CLK_50周期)
	// 完整的 0-9 循环需要 10 * 4ns = 40ns
	#2000;  // 等待 2000ns，可以看到约 50 个完整的计数循环
	
	$display("========================================");
	$display("Simulation completed at %0t ns", $time);
	$display("Final DOUT = %0d, COUT = %0b", DOUT, COUT);
	$display("========================================");
	$stop;
end

// 监控输出变化
always @(DOUT or COUT) begin
	$display("[%0t ns] DOUT=%0d (0x%h), COUT=%0b", $time, DOUT, DOUT, COUT);
end

// 监控内部分频时钟的跳变
always @(posedge clk_internal) begin
	$display("[%0t ns] clk_internal posedge, div_cnt=%0d", $time, div_cnt_internal);
end

always @(negedge clk_internal) begin
	$display("[%0t ns] clk_internal negedge, div_cnt=%0d", $time, div_cnt_internal);
end

always #1 begin 
	CLK_50 <= ~CLK_50;
end

endmodule                                         