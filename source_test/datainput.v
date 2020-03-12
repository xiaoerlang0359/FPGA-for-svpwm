module datainput(
 input en,
 input rst_n,
 input sys_clk,
 input signed [15:0] I_UP,
 input signed [15:0] I_VP,
 input signed [15:0] I_WP,
 input [31:0] theta,
 output [31:0] I_Uf,
 output [31:0] I_Vf,
 output [31:0] I_Wf,
 output [31:0] thetaf,
 output ack
);

reg [5:0] wait_cnt;
wire signed [31:0] I_U;
wire signed [31:0] I_V;
wire signed [31:0] I_W;
wire signed [31:0] I_UPP;
wire signed [31:0] I_VPP;
wire signed [31:0] I_WPP;
assign I_UPP={{16{1'b0}},I_UP};
assign I_VPP={{16{1'b0}},I_VP};
assign I_WPP={{16{1'b0}},I_WP};
assign I_U=I_UPP-32'd32768;
assign I_V=I_VPP-32'd32768;
assign I_W=I_WPP-32'd32768;
assign ack=(wait_cnt==6'd8);

always @(posedge sys_clk)
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
			8: wait_cnt<=0;
			default: wait_cnt<=wait_cnt+6'd1;
		endcase
	end
end

int2float int2float1(
	.dataa(I_U),
	.result(I_Uf),
	.clock(sys_clk)
);

int2float int2float2(
	.dataa(I_V),
	.result(I_Vf),
	.clock(sys_clk)
);

int2float int2float3(
	.dataa(I_W),
	.result(I_Wf),
	.clock(sys_clk)
);

int2float int2float4(
	.dataa(theta),
	.result(thetaf),
	.clock(sys_clk)
);

endmodule
