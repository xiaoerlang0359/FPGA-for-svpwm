module dataoutput(
	input en,
	input rst_n,
	input sys_clk,
	input [31:0] CP1f,
	input [31:0] CP2f,
	input [31:0] CP3f,
	output [15:0] CP1,
	output [15:0] CP2,
	output [15:0] CP3,
	output ack
);

reg [5:0] wait_cnt;

assign ack=(wait_cnt==6'd7);

always @(posedge sys_clk or negedge rst_n)
begin
	if (rst_n==1'b0)
		wait_cnt<=6'd0;
	else
	begin
		case (wait_cnt)
			0: 
			if (en==1'b1)
				wait_cnt<=1;
			else
				wait_cnt<=0;
			7: wait_cnt<=0;
			default: wait_cnt<=wait_cnt+6'd1;
		endcase
	end
end

float2int float2int1(
	.dataa(CP1f),
	.result(CP1),
	.clock(sys_clk)
);

float2int float2int2(
	.dataa(CP2f),
	.result(CP2),
	.clock(sys_clk)
);

float2int float2int3(
	.dataa(CP3f),
	.result(CP3),
	.clock(sys_clk)
);

endmodule
