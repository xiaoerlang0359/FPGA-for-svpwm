module inv_park(
	input en,
	input rst_n,
	input sys_clk,
	input [31:0] re_mult1,
	input [31:0] re_mult2,
	input [31:0] re_mult3,
	input [31:0] re_mult4,
	input [31:0] re_add1,
	input [31:0] re_add2,
	input [31:0] sin,
	input [31:0] cos,
	input [31:0] U_d,
	input [31:0] U_q,
	output reg [31:0] mult1a,
	output reg [31:0] mult1b,
	output reg [31:0] mult2a,
	output reg [31:0] mult2b,
	output reg [31:0] mult3a,
	output reg [31:0] mult3b,
	output reg [31:0] mult4a,
	output reg [31:0] mult4b,
	output reg [31:0] add1a,
	output reg [31:0] add1b,
	output reg [31:0] add2a,
	output reg [31:0] add2b,
	output reg [31:0] U_alpha,
	output reg [31:0] U_beta,
	output reg isadd1,
	output reg isadd2,
	output ack
);

reg [5:0] wait_cnt;
reg [3:0] state;
reg [3:0] next_state;

assign ack=(state==4);

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
		3: next_state<=4;
		4: next_state<=0;
		default: next_state<=0;
		endcase
end

always@(posedge sys_clk or negedge rst_n)
begin
	if (rst_n==1'b0)
	begin
		mult1a<=32'd0; mult1b<=32'd0;
		mult2a<=32'd0; mult2b<=32'd0;
		mult3a<=32'd0; mult3b<=32'd0;
		mult4a<=32'd0; mult4b<=32'd0;
	end
	else
		if (next_state==4'd1)
			if (state!=next_state)
			begin
				mult1a<=cos; mult1b<=U_d;
				mult2a<=sin; mult2b<=U_q;
				mult3a<=sin; mult3b<=U_d;
				mult4a<=cos; mult4b<=U_q;
			end
			else
			begin
				mult1a<=mult1a; mult1b<=mult1b;
				mult2a<=mult2a; mult2b<=mult2b;
				mult3a<=mult3a; mult3b<=mult3b;
				mult4a<=mult4a; mult4b<=mult4b;
			end
		else
		begin
			mult1a<=mult1a; mult1b<=mult1b;
			mult2a<=mult2a; mult2b<=mult2b;
			mult3a<=mult3a; mult3b<=mult3b;
			mult4a<=mult4a; mult4b<=mult4b;
		end
end

always@(posedge sys_clk or negedge rst_n)
begin
	if (rst_n==1'b0)
	begin
		add1a<=32'd0; add1b<=32'd0; isadd1<=1'b0;
		add2a<=32'd0; add2b<=32'd0; isadd2<=1'b0;
	end
	else if (next_state==4'd2)
		if (state!=next_state)
		begin
			add1a<=re_mult1; add1b<=re_mult2; isadd1<=1'b0;
			add2a<=re_mult4; add2b<=re_mult3; isadd2<=1'b1;
		end
		else
		begin
			add1a<=re_mult1; add1b<=re_mult2; isadd1<=1'b0;
			add2a<=re_mult4; add2b<=re_mult3; isadd2<=1'b1;
		end
	else
	begin
		add1a<=add1a; add1b<=add1b; isadd1<=isadd1;
		add2a<=add2a; add2b<=add2b; isadd2<=isadd2;
	end
end

always@(posedge sys_clk or negedge rst_n)
begin
	if (rst_n==1'b0)
	begin
		U_alpha<=32'd0; U_beta<=32'd0;
	end
	else if (state==4'd3)
	begin
		U_alpha<=re_add1; U_beta<=re_add2;
	end
	else 
	begin
		U_alpha<=U_alpha; U_beta<=U_beta;
	end
end

endmodule
