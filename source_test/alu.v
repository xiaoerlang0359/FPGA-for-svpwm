module alu(
input clk,
input rst_n,
input data_ack,
input [15:0] I_U,
input [15:0] I_V,
input [15:0] I_W,
input [31:0] theta,
input [31:0] udc,
input [31:0] period,
input [31:0] Kp,
input [31:0] Ki,
input [31:0] I_q_star,
output [15:0] CP1,
output [15:0] CP2,
output [15:0] CP3,
output dataoutput_ack
);

localparam SIDLE=4'd0;
localparam SINPUT=4'd1;
localparam SCLARK_SIN_COS=4'd2;
localparam SPARK=4'd3;
localparam SPID=4'd4;
localparam SINVPARK=4'd5;
localparam SSVPWM=4'd6;
localparam SOUTPUT=4'd7;
localparam SACK=4'd8;

reg [3:0] state;
reg [3:0] next_state;
wire [31:0] I_Uf,I_Vf,I_Wf;
wire [31:0] thetaf;
wire [31:0] sin,cos;
wire [31:0] sq2_oneudc,onesq2_udc;
wire [31:0] I_alpha,I_beta;
wire [31:0] I_q,I_d;
wire [31:0] U_alpha,U_beta;
wire [31:0] CP1f,CP2f,CP3f;
wire [31:0] U_d,U_q;


wire isadd1_clark,isadd2_clark,isadd1_park,isadd2_park;
wire isadd1_pid,isadd2_pid,isadd1_invpark,isadd2_invpark;
wire isadd1_svpwm,isadd2_svpwm;
wire [31:0] comp1a_pid,comp1b_pid;
wire [31:0] comp2a_pid,comp2b_pid;
wire [31:0] comp1a_svpwm,comp1b_svpwm;
wire [31:0] pre_abs1_pid,pre_abs2_pid;
wire [31:0] pre_abs1_svpwm,pre_abs2_svpwm;
wire [31:0] mult1a_clark,mult1b_clark;
wire [31:0] mult2a_clark,mult2b_clark;
wire [31:0] mult1a_park,mult1b_park;
wire [31:0] mult2a_park,mult2b_park;
wire [31:0] mult3a_park,mult3b_park;
wire [31:0] mult4a_park,mult4b_park;
wire [31:0] mult1a_invpark,mult1b_invpark;
wire [31:0] mult2a_invpark,mult2b_invpark;
wire [31:0] mult3a_invpark,mult3b_invpark;
wire [31:0] mult4a_invpark,mult4b_invpark;  
wire [31:0] mult1a_pid,mult1b_pid;
wire [31:0] mult2a_pid,mult2b_pid;
wire [31:0] mult1a_svpwm,mult1b_svpwm;
wire [31:0] mult2a_svpwm,mult2b_svpwm;
wire [31:0] mult3a_svpwm,mult3b_svpwm;
wire [31:0] num_sincos,den_sincos;
wire [31:0] num_clark,den_clark;
wire [31:0] add1a_clark,add1b_clark;
wire [31:0] add2a_clark,add2b_clark;
wire [31:0] add1a_park,add1b_park;
wire [31:0] add2a_park,add2b_park;
wire [31:0] add1a_pid,add1b_pid;
wire [31:0] add2a_pid,add2b_pid;
wire [31:0] add1a_invpark,add1b_invpark;
wire [31:0] add2a_invpark,add2b_invpark;
wire [31:0] add1a_svpwm,add1b_svpwm;
wire [31:0] add2a_svpwm,add2b_svpwm;
reg [31:0] add1a,add1b;
reg [31:0] add2a,add2b;
reg [31:0] comp1a,comp1b;
reg [31:0] comp2a,comp2b;
reg [31:0] mult1a,mult1b;
reg [31:0] mult2a,mult2b;
reg [31:0] mult3a,mult3b;
reg [31:0] mult4a,mult4b;
wire [31:0] num,den;
reg [31:0] pre_abs1,pre_abs2;
wire [31:0] re_add1,re_add2,re_add3;
wire [31:0] re_mult1,re_mult2,re_mult3,re_mult4;
wire [31:0] re_abs1,re_abs2;
wire [31:0] re_div;
reg isadd1,isadd2;
wire re_comp1,re_comp2;
wire datainput_en,datainput_ack;
wire clark_en,clark_ack;
wire sincos_en,sincos_ack;
wire park_en,park_ack;
wire pid_en,pid_ack;
wire invpark_en,invpark_ack;
wire svpwm_en,svpwm_ack;
wire dataoutput_en;
wire active_div;
reg [1:0] clark_sincos_ack;
wire sys_clk;
wire pll_rst;

assign pll_rst=1'b0;
assign datainput_en=data_ack;
assign clark_en=datainput_ack;
assign sincos_en=datainput_ack;
assign park_en=(clark_sincos_ack==2'b11);
assign pid_en=park_ack;
assign invpark_en=pid_ack;
assign svpwm_en=invpark_ack;
assign dataoutput_en=svpwm_ack;

assign num=(active_div)? num_clark:num_sincos;
assign den=(active_div)? den_clark:den_sincos;

always@(negedge sys_clk or negedge rst_n)
begin
	if (rst_n==1'b0)
	begin
		add1a<=32'd0; add1b<=32'd0; isadd1<=1'b0;
		add2a<=32'd0; add2b<=32'd0; isadd2<=1'b0;
		mult1a<=32'd0; mult1b<=32'd0;
		mult2a<=32'd0; mult2b<=32'd0;
		mult3a<=32'd0; mult3b<=32'd0;
		mult4a<=32'd0; mult4b<=32'd0;
		pre_abs1<=32'd0; pre_abs2<=32'd0;
		comp1a<=32'd0; comp1b<=32'd0;
		comp2a<=32'd0; comp2b<=32'd0;
	end
	else
	begin
	case(next_state)
		SCLARK_SIN_COS:
		begin
			add1a<=add1a_clark; add1b<=add1b_clark; isadd1<=isadd1_clark;
			add2a<=add2a_clark; add2b<=add2b_clark; isadd2<=isadd2_clark;
			mult1a<=mult1a_clark; mult1b<=mult1b_clark;
			mult2a<=mult2a_clark; mult2b<=mult2b_clark;
			mult3a<=mult3a; mult3b<=mult3b;
			mult4a<=mult4a; mult4b<=mult4b;
			pre_abs1<=pre_abs1; pre_abs2<=pre_abs2;
			comp1a<=comp1a; comp1b<=comp1b;
			comp2a<=comp2a; comp2b<=comp2b;
		end
		SPARK:
		begin
			add1a<=add1a_park; add1b<=add1b_park; isadd1<=isadd1_park;
			add2a<=add2a_park; add2b<=add2b_park; isadd2<=isadd2_park;
			mult1a<=mult1a_park; mult1b<=mult1b_park;
			mult2a<=mult2a_park; mult2b<=mult2b_park;
			mult3a<=mult3a_park; mult3b<=mult3b_park;
			mult4a<=mult4a_park; mult4b<=mult4b_park;
			pre_abs1<=pre_abs1; pre_abs2<=pre_abs2;
			comp1a<=comp1a; comp1b<=comp1b;
			comp2a<=comp2a; comp2b<=comp2b;
		end
		SPID:
		begin
			add1a<=add1a_pid; add1b<=add1b_pid; isadd1<=isadd1_pid;
			add2a<=add2a_pid; add2b<=add2b_pid; isadd2<=isadd2_pid;
			mult1a<=mult1a_pid; mult1b<=mult1b_pid;
			mult2a<=mult2a_pid; mult2b<=mult2b_pid;
			mult3a<=mult3a; mult3b<=mult3b;
			mult4a<=mult4a; mult4b<=mult4b;
			pre_abs1<=pre_abs1_pid; pre_abs2<=pre_abs2_pid;
			comp1a<=comp1a_pid; comp1b<=comp1b_pid;
			comp2a<=comp2a_pid; comp2b<=comp2b_pid;
		end
		SINVPARK:
		begin
			add1a<=add1a_invpark; add1b<=add1b_invpark; isadd1<=isadd1_invpark;
			add2a<=add2a_invpark; add2b<=add2b_invpark; isadd2<=isadd2_invpark;
			mult1a<=mult1a_invpark; mult1b<=mult1b_invpark;
			mult2a<=mult2a_invpark; mult2b<=mult2b_invpark;
			mult3a<=mult3a_invpark; mult3b<=mult3b_invpark;
			mult4a<=mult4a_invpark; mult4b<=mult4b_invpark;
			pre_abs1<=pre_abs1; pre_abs2<=pre_abs2;
			comp1a<=comp1a; comp1b<=comp1b;
			comp2a<=comp2a; comp2b<=comp2b;
		end
		SSVPWM:
		begin
			add1a<=add1a_svpwm; add1b<=add1b_svpwm; isadd1<=isadd1_svpwm;
			add2a<=add2a_svpwm; add2b<=add2b_svpwm; isadd2<=isadd2_svpwm;
			mult1a<=mult1a_svpwm; mult1b<=mult1b_svpwm;
			mult2a<=mult2a_svpwm; mult2b<=mult2b_svpwm;
			mult3a<=mult3a_svpwm; mult3b<=mult3b_svpwm;
			mult4a<=mult4a; mult4b<=mult4b;
			pre_abs1<=pre_abs1_svpwm; pre_abs2<=pre_abs2_svpwm;
			comp1a<=comp1a_svpwm; comp1b<=comp1b_svpwm;
			comp2a<=comp2a; comp2b<=comp2b;
		end
		default:
		begin
			add1a<=add1a; add1b<=add1b; isadd1<=isadd1;
			add2a<=add2a; add2b<=add2b; isadd2<=isadd2;
			mult1a<=mult1a; mult1b<=mult1b;
			mult2a<=mult2a; mult2b<=mult2b;
			mult3a<=mult3a; mult3b<=mult3b;
			mult4a<=mult4a; mult4b<=mult4b;
			pre_abs1<=pre_abs1; pre_abs2<=pre_abs2;
			comp1a<=comp1a; comp1b<=comp1b;
			comp2a<=comp2a; comp2b<=comp2b;
		end
	endcase
	end	
end	

always@(posedge sys_clk or negedge rst_n)
begin
	if (rst_n==1'b0)
		clark_sincos_ack<=2'b00;
	else
	if (state==SCLARK_SIN_COS)
		if (clark_ack)
			clark_sincos_ack<=clark_sincos_ack|2'b10;
		else
		if (sincos_ack)
			clark_sincos_ack<=clark_sincos_ack|2'b01;
		else clark_sincos_ack<=clark_sincos_ack;
	else
		clark_sincos_ack<=2'b00;
end
	

always@(posedge sys_clk or negedge rst_n)
begin
	if (rst_n==1'b0)
		state<=SIDLE;
	else
		state<=next_state;
end
		
always@(*)
begin
	if (rst_n==1'b0)
		next_state<=SIDLE;
	else 
	case (state)
	SIDLE:
		if (data_ack) next_state<=SINPUT;
		else next_state<=SIDLE;
	SINPUT:
		if (datainput_ack) next_state<=SCLARK_SIN_COS;
		else next_state<=SINPUT;
	SCLARK_SIN_COS:
		if (clark_sincos_ack==2'b11) next_state<=SPARK;
		else next_state<=SCLARK_SIN_COS;
	SPARK:
		if (park_ack) next_state<=SPID;
		else next_state<=SPARK;
	SPID:
		if (pid_ack) next_state<=SINVPARK;
		else next_state<=SPID;
	SINVPARK:
		if (invpark_ack) next_state<=SSVPWM;
		else next_state<=SINVPARK;
	SSVPWM:
		if (svpwm_ack) next_state<=svpwm_ack;
		else next_state<=SSVPWM;
	SACK: next_state<=SIDLE;
	default: next_state<=SIDLE;
	endcase
end

datainput datainput0(
	.en(datainput_en),
	.rst_n(rst_n),
	.sys_clk(sys_clk),
	.I_UP(I_U),
	.I_VP(I_V),
	.I_WP(I_W),
	.theta(theta),
	.I_Uf(I_Uf),
	.I_Vf(I_Vf),
	.I_Wf(I_Wf),
	.thetaf(thetaf),
	.ack(datainput_ack)
);

mysin_cos mysin_cos0(
	.en(sincos_en),
	.rst_n(rst_n),
	.sys_clk(sys_clk),
	.thetaf(thetaf),
	.re_div(re_div),
	.num(num_sincos),
	.den(den_sincos),
	.sin(sin),
	.cos(cos),
	.active_div(active_div),
	.ack(sincos_ack)
);

clark clark0(
	.en(clark_en),
	.rst_n(rst_n),
	.sys_clk(sys_clk),
	.I_Uf(I_Uf),
	.I_Vf(I_Vf),
	.I_Wf(I_Wf),
	.re_add1(re_add1),
	.re_add2(re_add2),
	.re_mult1(re_mult1),
	.re_mult2(re_mult2),
	.udc(udc),
	.re_div(re_div),
	.sq2_oneudc(sq2_oneudc),
	.onesq2_udc(onesq2_udc),
	.num(num_clark),
	.den(den_clark),
	.add1a(add1a_clark),
	.add1b(add1b_clark),
	.add2a(add2a_clark),
	.add2b(add2b_clark),
	.isadd1(isadd1_clark),
	.isadd2(isadd2_clark),
	.mult1a(mult1a_clark),
	.mult1b(mult1b_clark),
	.mult2a(mult2a_clark),
	.mult2b(mult2b_clark),
	.ack(clark_ack),
	.I_alpha(I_alpha),
	.I_beta(I_beta)
);

park park0(
	.en(park_en),
	.rst_n(rst_n),
	.sys_clk(sys_clk),
	.re_mult1(re_mult1),
	.re_mult2(re_mult2),
	.re_mult3(re_mult3),
	.re_mult4(re_mult4),
	.re_add1(re_add1),
	.re_add2(re_add2),
	.sin(sin),
	.cos(cos),
	.I_alpha(I_alpha),
	.I_beta(I_beta),
	.mult1a(mult1a_park),
	.mult1b(mult1b_park),
	.mult2a(mult2a_park),
	.mult2b(mult2b_park),
	.mult3a(mult3a_park),
	.mult3b(mult3b_park),
	.mult4a(mult4a_park),
	.mult4b(mult4b_park),
	.add1a(add1a_park),
	.add1b(add1b_park),
	.add2a(add2a_park),
	.add2b(add2b_park),
	.I_d(I_d),
	.I_q(I_q),
	.isadd1(isadd1_park),
	.isadd2(isadd2_park),
	.ack(park_ack)
);

pid pid0(
	.en(pid_en),
	.rst_n(rst_n),
	.sys_clk(sys_clk),
	.Kp(Kp),
	.Ki(Ki),
	.onesq2_udc(onesq2_udc),
	.I_q_star(I_q_star),
	.I_q(I_q),
	.I_d(I_d),
	.re_add1(re_add1),
	.re_add2(re_add2),
	.re_mult1(re_mult1),
	.re_mult2(re_mult2),
	.re_abs1(re_abs1),
	.re_abs2(re_abs2),
	.re_comp1(re_comp1),
	.re_comp2(re_comp2),
	.isadd1(isadd1_pid),
	.isadd2(isadd2_pid),
	.add1a(add1a_pid),
	.add1b(add1b_pid),
	.add2a(add2a_pid),
	.add2b(add2b_pid),
	.mult1a(mult1a_pid),
	.mult1b(mult1b_pid),
	.mult2a(mult2a_pid),
	.mult2b(mult2b_pid),
	.comp1a(comp1a_pid),
	.comp1b(comp1b_pid),
	.comp2a(comp2a_pid),
	.comp2b(comp2b_pid),
	.pre_abs1(pre_abs1_pid),
	.pre_abs2(pre_abs2_pid),
	.U_d(U_d),
	.U_q(U_q),
	.ack(pid_ack)
);

inv_park inv_park0(
	.en(invpark_en),
	.rst_n(rst_n),
	.sys_clk(sys_clk),
	.re_mult1(re_mult1),
	.re_mult2(re_mult2),
	.re_mult3(re_mult3),
	.re_mult4(re_mult4),
	.re_add1(re_add1),
	.re_add2(re_add2),
	.sin(sin),
	.cos(cos),
	.U_d(U_d),
	.U_q(U_q),
	.mult1a(mult1a_invpark),
	.mult1b(mult1b_invpark),
	.mult2a(mult2a_invpark),
	.mult2b(mult2b_invpark),
	.mult3a(mult3a_invpark),
	.mult3b(mult3b_invpark),
	.mult4a(mult4a_invpark),
	.mult4b(mult4b_invpark),
	.add1a(add1a_invpark),
	.add1b(add1b_invpark),
	.add2a(add2a_invpark),
	.add2b(add2b_invpark),
	.U_alpha(U_alpha),
	.U_beta(U_beta),
	.isadd1(isadd1_invpark),
	.isadd2(isadd2_invpark),
	.ack(invpark_ack)
);

svpwm svpwm0(
	.en(svpwm_en),
	.rst_n(rst_n),
	.sys_clk(sys_clk),
	.re_mult1(re_mult1),
	.re_mult2(re_mult2),
	.re_mult3(re_mult3),
	.re_add1(re_add1),
	.re_add2(re_add2),
	.U_alpha(U_alpha),
	.U_beta(U_beta),
	.sq2_oneudcf(sq2_oneudc),
	.period(period),
	.re_abs1(re_abs1),
	.re_abs2(re_abs2),
	.re_comp(re_comp1),
	.comp1a(comp1a_svpwm),
	.comp1b(comp1b_svpwm),
	.pre_abs1(pre_abs1_svpwm),
	.pre_abs2(pre_abs2_svpwm),
	.mult1a(mult1a_svpwm),
	.mult1b(mult1b_svpwm),
	.mult2a(mult2a_svpwm),
	.mult2b(mult2b_svpwm),
	.mult3a(mult3a_svpwm),
	.mult3b(mult3b_svpwm),
	.add1a(add1a_svpwm),
	.add1b(add1b_svpwm),
	.add2a(add2a_svpwm),
	.add2b(add2b_svpwm),
	.CP1f(CP1f),
	.CP2f(CP2f),
	.CP3f(CP3f),
	.isadd1(isadd1_svpwm),
	.isadd2(isadd2_svpwm),
	.ack(svpwm_ack)
);

dataoutput dataoutput0(
	.en(dataoutput_en),
	.rst_n(rst_n),
	.sys_clk(sys_clk),
	.CP1f(CP1f),
	.CP2f(CP2f),
	.CP3f(CP3f),
	.CP1(CP1),
	.CP2(CP2),
	.CP3(CP3),
	.ack(dataoutput_ack)
);

mypll pll0(
	.areset(pll_rst),
	.inclk0(clk),
	.c0(sys_clk));
	
isbigger bigger1(
	.dataa(comp1a),
	.datab(comp1b),
	.clock(sys_clk),
	.ageb(re_comp1)
);

isbigger bigger2(
	.dataa(comp2a),
	.datab(comp2b),
	.clock(sys_clk),
	.ageb(re_comp2)
);

add add1(
	.dataa(add1a),
	.datab(add1b),
	.add_sub(isadd1),
	.clock(sys_clk),
	.result(re_add1)
);

add add2(
	.dataa(add2a),
	.datab(add2b),
	.add_sub(isadd2),
	.clock(sys_clk),
	.result(re_add2)
);


fpmult mult1(
	.dataa(mult1a),
	.datab(mult1b),
	.clock(sys_clk),
	.result(re_mult1)
);

fpmult mult_ab(
	.dataa(mult2a),
	.datab(mult2b),
	.clock(sys_clk),
	.result(re_mult2)
);

fpmult mult_ac(
	.dataa(mult3a),
	.datab(mult3b),
	.clock(sys_clk),
	.result(re_mult3)
);

fpmult mult_bc(
	.dataa(mult4a),
	.datab(mult4b),
	.clock(sys_clk),
	.result(re_mult4)
);

mydiv div_pi(
	.dataa(num),
	.datab(den),
	.clock(sys_clk),
	.result(re_div)
);

myabs abs1(
	.data(pre_abs1),
	.result(re_abs1)
);

myabs abs2(
	.data(pre_abs2),
	.result(re_abs2)
);

endmodule
