module clark(
	input en,
	input rst_n,
	input sys_clk,
	input [31:0] I_Uf,
	input [31:0] I_Vf,
	input [31:0] I_Wf,
	input [31:0] re_add1,
	input [31:0] re_add2,
	input [31:0] re_mult1,
	input [31:0] re_mult2,
	input [31:0] udc,
	inout [31:0] re_div,
	output reg [31:0] onesq2_udc,
	output reg [31:0] sq2_oneudc,
	output reg [31:0] num,
	output reg [31:0] den,
	output reg [31:0] add1a,
	output reg [31:0] add1b,
	output reg [31:0] add2a,
	output reg [31:0] add2b,
	output reg isadd1,
	output reg isadd2,
	output reg [31:0] mult1a,
	output reg [31:0] mult1b,
	output reg [31:0] mult2a,
	output reg [31:0] mult2b,
	output ack,
	output reg [31:0] I_alpha,
	output reg [31:0] I_beta
);
localparam onesq6=32'h3E1F7970;
localparam onesq2=32'h3E8A1BDF;
localparam one=32'h3F800000;
localparam twosq2=32'h3F3504F3;

reg [5:0] wait_cnt;
reg [3:0] state;
reg [3:0] next_state;

assign ack=(state==4'd5);

always @(posedge sys_clk or negedge rst_n)
begin
	if (rst_n==1'b0)
		state<=0;
	else state<=next_state;
end

always @(posedge sys_clk or negedge rst_n)
begin
	if (rst_n==1'b0)
		wait_cnt<=6'd0;
	else
		if (state==next_state && state!=4'd0)
			wait_cnt<=wait_cnt+6'd1;
		else
			wait_cnt<=0;
end

always@(*)
begin
	if (rst_n==1'b0)
		next_state<=4'd0;
	else
		case(state)
		0:
			if (en) next_state<=1;
			else next_state<=0;
		1: if (wait_cnt==12) next_state<=2;
			else next_state<=1;
		2: if (wait_cnt==12) next_state<=3;
			else next_state<=2;
		3: if (wait_cnt==12) next_state<=4;
			else next_state<=3;
		4: next_state<=5;
		5: next_state<=0;
		default: next_state<=0;
		endcase
end

always@(posedge sys_clk or negedge rst_n)
begin
	if (rst_n==1'b0)
	begin
		add1a<=32'd0;
		add2a<=32'd0;
		add1b<=32'd0;
		add2b<=32'd0;
		isadd1<=1'b0;
		isadd2<=1'b0;
	end
	else 
	case (next_state)
	1:
	if (state!=next_state)
	begin
		add1a<=I_Uf; add1b<=I_Uf; isadd1<=1'b1;
		add2a<=I_Vf; add2b<=I_Wf; isadd2<=1'b1;
	end
	else
	begin
		add1a<=add1a; add1b<=add1b; isadd1<=isadd1;
		add2a<=add2a; add2b<=add2b; isadd2<=isadd2;
	end
	2:
	if (state!=next_state)
	begin
		add1a<=re_add1; add1b<=re_add2; isadd1<=1'b0;
		add2a<=I_Vf; add2b<=I_Wf; isadd2<=1'b0;
	end
	else
	begin
		add1a<=add1a; add1b<=add1b; isadd1<=isadd1;
		add2a<=add2a; add2b<=add2b; isadd2<=isadd2;
	end
	default:
	begin
		add1a<=add1a; add1b<=add1b; isadd1<=isadd1;
		add2a<=add2a; add2b<=add2b; isadd2<=isadd2;
	end
	endcase
end

always@(posedge sys_clk or negedge rst_n)
begin
	if (rst_n==1'b0)
	begin
		mult1a<=32'd0; mult1b<=32'd0;
		mult2a<=32'd0; mult2b<=32'd0;
	end
	else
	case (next_state)
	1:
	if (state!=next_state)
	begin
		mult1a<=twosq2; mult1b<=udc;
		mult2a<=mult2a; mult2b<=mult2b;
	end
	else
	begin
		mult1a<=mult1a; mult1b<=mult1b;
		mult2a<=mult2a; mult2b<=mult2b;
	end
	3:
	if (state!=next_state)
	begin
		mult1a<=onesq6; mult1b<=re_add1;
		mult2a<=onesq2; mult2b<=re_add2;
	end
	else
	begin
		mult1a<=mult1a; mult1b<=mult1b;
		mult2a<=mult2a; mult2b<=mult2b;
	end
	default:
	begin
		mult1a<=mult1a; mult1b<=mult1b;
		mult2a<=mult2a; mult2b<=mult2b;
	end
	endcase
end

always@(posedge sys_clk or negedge rst_n)
begin
	if (rst_n==1'b0)
		onesq2_udc<=32'd0;
	else
		if (state==1)
			onesq2_udc<=re_mult1;
		else
			onesq2_udc<=onesq2_udc;
end

always@(posedge sys_clk or negedge rst_n)
begin
	if (rst_n==1'b0)
	begin
		I_alpha<=32'd0;
		I_beta<=32'd0;
	end
	else if (state==4)
	begin
		I_alpha<=re_mult1;
		I_beta<=re_mult2;
	end
	else
	begin
		I_alpha<=I_alpha;
		I_beta<=I_beta;
	end
end

always@(posedge sys_clk or negedge rst_n)
begin
	if (rst_n==1'b0)
	begin
		num<=32'd0; den<=32'h3F800000;
	end
	else
		if (state==2||state==3)
			if (state==2 && wait_cnt==6'd8)
			begin
				num<=one; den<=onesq2_udc;
			end
			else
			begin
				num<=num; den<=den;
			end
		else
		begin
			num<=num; den<=den;
		end
end

always@(posedge sys_clk or negedge rst_n)
begin
	if (rst_n==1'b0)
		sq2_oneudc<=32'd0;
	else
	if (state==4)
		sq2_oneudc<=re_div;
	else
		sq2_oneudc<=sq2_oneudc;
end

endmodule
