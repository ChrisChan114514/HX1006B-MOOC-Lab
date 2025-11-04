//Writer: ChrisChan Date: 2025-10-23
`timescale 1 ns / 1 ps
module CNT10_TB();

reg CLK;
reg EN;
reg LOAD;
reg RST;
reg [3:0] DATA;
// wires   
wire [3:0] DOUT;
wire COUT;

CNT10 U_CNT10(
	.CLK		(CLK),
	.EN		(EN),
	.RST		(RST),
	.LOAD		(LOAD),
	.DATA		(DATA),
	.DOUT		(DOUT),
	.COUT		(COUT)
);

initial begin 
	CLK <= 1'b0;
	EN <= 1'b0;
	LOAD <= 1'b1;
	RST <= 1'b0;
	DATA <= 4'b0000;
	
	// 测试1: 复位测试
	#20 	RST <= 1'b1;
	
	// 测试2: LOAD=1时从0到9正常计数模式
	#20	EN <= 1'b1;
	#240	; // 计数12个时钟周期 (0->9, 然后回到0, 再到1)
	
	// 测试3: EN为0，LOAD=0时无法加载数据
	EN <= 1'b0;
	#20	DATA <= 4'b0101; // 加载数值5
		LOAD <= 1'b0;
	#20	LOAD <= 1'b1;
		EN <= 1'b1;
	
	// 测试4: 从加载值(5)计数到9并观察进位
	#120	; // 从5计数到9 (6个时钟周期)
	
	// 测试5: EN为1,LOAD=0可以加载数据
	#40	LOAD <= 1'b0;
		DATA <= 4'b1000; // 加载数值8
	#20	LOAD <= 1'b1;
	
	// 测试6: 从8计数到9, 观察COUT进位和回到0
	#60	; // 计数 8->9->0
	
	// 测试7: EN=0禁止计数
	EN <= 1'b0;
	#80	; // 计数器应保持当前值
	
	// 测试8: 重新使能并继续计数
	EN <= 1'b1;
	#100	; // 继续计数
	
	// 测试9: 运行中复位
	#40	RST <= 1'b0;
	#20	RST <= 1'b1;
	
	// 测试10: LOAD=1时从0再次开始计数
	#200	; // 最终计数阶段
end

always #10 begin 
	CLK <= ~CLK;
end

endmodule                                         