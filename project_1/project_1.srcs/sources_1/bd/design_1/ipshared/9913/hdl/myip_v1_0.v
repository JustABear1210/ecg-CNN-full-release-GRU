
`timescale 1 ns / 1 ps

	module myip_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
		//bram0	// control input data 
		input wire [12:0] addr_input,
		input wire clk_input,
		input wire [31:0] din_input,
		output wire [31:0] dout_input,
		input wire en_input,
		input wire we_input,
			
		//bram1	// control output
		input wire [12:0] addr_output,
		input wire clk_output,
		input wire [31:0] din_output,
		output wire [31:0] dout_output,
		input wire en_output,
		input wire we_output,
		
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);
// Instantiation of Axi Bus Interface S00_AXI
/*
	assign op_st = slv_reg0[0];
	assign data_in = slv_reg0[1];
	assign  rst_sw = slv_reg0[2];
	done is slv_reg1
	conv1_bias_ready is slv_reg2
*/
	reg done;
	wire conv1_bias_ready;
	myip_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) myip_v1_0_S00_AXI_inst (
	
		.op_st(op_st),
		.data_in(data_in),
		.done(done),
		.rst_sw(rst_sw),
		.conv1_bias_ready(conv1_bias_ready),
	
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

	// Add user logic here
wire rst_hw;
assign rst_hw = (mode == 3'b011 || mode[2] ) ? 0 :
				(pooling_done && prepare_next_layer_bias_done  ) ? 1 : 0 ;

wire rst;
assign rst = rst_hw | rst_sw;

// layer 1 need to put bias into bramb first ===========================================================
assign conv1_bias_ready = ( cnt_conv1_bias_addr [10] == 1'b1 ) ? 1 : 0 ;
reg conv1_bias_ready_delay;
always @(posedge s00_axi_aclk) conv1_bias_ready_delay <= conv1_bias_ready;

//================================================================= 
reg [2:0] mode;
always @(posedge s00_axi_aclk) begin 
	if ( rst_sw ) begin
		done <= 1'b0;
		mode <= 3'b000;
	end
	else if ( mode[2] == 1'b1 ) begin 
		done <= 1'b1;
		mode[0] <= 1'b1;
	end
	else if ( pooling_done && prepare_next_layer_bias_done ) mode <= mode + 1'b1;
	//else if ( rst_hw && rst_hw_delay ) mode <= mode + 1'b1;
	
end

reg conv_and_relu_done;
reg conv_and_relu_done_delay;
always @(posedge s00_axi_aclk) conv_and_relu_done_delay <= conv_and_relu_done;
always @(posedge s00_axi_aclk) begin 
	if ( rst ) conv_and_relu_done <= 0;
	else if ( cnt_w[weight_check_bit] == 1'b1 )	conv_and_relu_done <= 1;
	else conv_and_relu_done <= conv_and_relu_done;
end

// Add user logic here
wire [2:0] input_channel_check_bit;
wire [5:0] output_channel_check_bit;
wire [3:0] in_vector_size_check_bit;
wire [3:0] weight_check_bit;
wire [11:0]pooling_max_check_bit;

assign input_channel_check_bit = (mode ==3'b000) ? 0 : (mode == 3'b001) ? 2 : (mode == 3'b010) ? 4 : 5 ;
assign output_channel_check_bit = (mode ==3'b000) ? 2 : (mode == 3'b001) ? 4 : (mode == 3'b010) ? 5 : 6 ;
assign in_vector_size_check_bit = (mode ==3'b000) ? 8 : (mode == 3'b001) ? 7 : (mode == 3'b010) ? 6 : 5 ;
assign weight_check_bit = (mode == 3'b000) ? 2 : (mode == 3'b001) ? 6 : (mode == 3'b010) ? 9 : (mode == 3'b011) ? 11: 0;
assign pooling_max_check_bit = (mode == 3'b000) ? 10 : 11;

//assign input_channel_number = (mode ==2'b00) ? 0 : (mode == 2'b01) ? 3 : (mode == 2'b10) ? 15 : (mode == 2'b11) ? 31 : 5'bzzzzz;
//assign output_channel_number = (mode ==2'b00) ? 3 : (mode == 2'b01) ? 15 : (mode == 2'b10) ? 31 : (mode == 2'b11) ? 63 : 6'bzzzzzz;
//assign in_vector_size = (mode ==2'b00) ? 255 : (mode == 2'b01) ? 127 : (mode == 2'b10) ? 63 : (mode == 2'b11) ? 31 : 10'dz;
//assign weight_num = (mode == 2'b00) ? 3 : (mode == 2'b01) ? 63 : (mode == 2'b10) ? 511 : (mode == 2'b11) ? 2047: 11'dz;
//assign pooling_max_address = (mode == 2'b00) ? 1023 : 2047;

wire last_output_channel = ( input_repeat_time[output_channel_check_bit] == 1'b1 ) ? 1 : 0;
wire last_input_channel = ( acc_times[input_channel_check_bit] == 1'b1 ) ? 1 : 0 ;
// input data bram signal==============================================================================================
// input bram port A// when data_in port A write input data // when op_st read port
reg op_st_delay ;
always @(posedge s00_axi_aclk) begin 
	op_st_delay <= op_st;
end
	
wire bram_input_ena, bram_input_wea;
wire [10:0] bram_input_addra;
wire [5:0] bram_input_dina, bram_input_douta;
assign bram_input_douta = ( mode[0] == 1'b0 ) ? brama_douta[5:0] : bramb_douta[5:0] ;
reg [10:0] cnt_a;

assign bram_input_ena = data_in ? en_input : 
					( conv_and_relu_done || one_input_channel_done_delay ) ? 0 : // avoid memory collision
					( op_st_delay ) ? 1 : 0;
assign bram_input_wea = data_in ? we_input : 0;
assign bram_input_addra = data_in ? addr_input >> 2 : op_st_delay ? cal_addra : 0 ;
assign bram_input_dina = data_in ? din_input[5:0] : 0;

wire [10:0] cal_addra;
assign cal_addra = ( done == 0 ) ? cnt_a : 0 ;

// cnt_a is brama address, when calculate
wire one_input_channel_done = ( cnt_a == ( (acc_times << in_vector_size_check_bit) -1 ) ) ? 1 : 0;
reg [6:0] input_repeat_time;	// count output channel
reg [5:0] acc_times;	// count accumulate times, count input channel
reg [2:0] wait_padding_cnt;	// padding, wait 7 clock  
reg [2:0] wait_padding_cnt_delay;
always @(posedge s00_axi_aclk) wait_padding_cnt_delay <= wait_padding_cnt;
always@(posedge s00_axi_aclk) begin
	if(rst) begin 
		input_repeat_time <= 1;
		acc_times <= 1;
		cnt_a <= 0 ;
		wait_padding_cnt <= 0;
	end
	else if ( kernel_end_out ) begin 
		if ( last_input_channel ) begin 
			cnt_a <= 0;
			acc_times <= 1 ;
			if ( last_output_channel == 1'b0 ) input_repeat_time <= input_repeat_time + 1;
		end
		else begin 
			cnt_a <= cnt_a + 1;
			acc_times <= acc_times + 1;
		end
		wait_padding_cnt <= 0;
	end		
	
	else  if ( one_input_channel_done ) begin //max index
		// if ( cnt_a == ( (in_vector_size) * (acc_times) - 1 )  )
		cnt_a <= cnt_a;
	end
	
	else if(kernel_en)  begin 
		if ( wait_padding_cnt == 6 ) cnt_a <= cnt_a + 1;
		else wait_padding_cnt <= wait_padding_cnt + 1;
	end
	else cnt_a <= cnt_a ;
end

// input bram Port B // when op_st write port, write next layer bias 
wire bram_input_enb, bram_input_web;
wire [10:0] bram_input_addrb;
wire [9:0] bram_input_dinb, bram_input_doutb;
assign bram_input_doutb = ( mode[0] == 1'b0 ) ? brama_doutb : bramb_doutb ;

reg [11:0] cnt_input_bram_portb_bias; 
reg [11:0] cnt_input_bram_portb_bias_delay;	//沒用到
always @(posedge s00_axi_aclk) cnt_input_bram_portb_bias_delay <= cnt_input_bram_portb_bias;
always @(posedge s00_axi_aclk) begin 
	if ( rst ) cnt_input_bram_portb_bias <= 0;
	else if ( conv_and_relu_done == 1'b0 ) begin 
		if ( wait_padding_cnt == 0 ) cnt_input_bram_portb_bias <= cnt_input_bram_portb_bias;
		else cnt_input_bram_portb_bias <= bram_input_addra; 
	end
	
	else if ( conv_and_relu_done == 1'b1 ) begin 
		if ( cnt_input_bram_portb_bias[11] == 1'b0 ) cnt_input_bram_portb_bias <= cnt_input_bram_portb_bias + 1;
	end
	
	else cnt_input_bram_portb_bias <= cnt_input_bram_portb_bias;
end

reg prepare_next_layer_bias_done;
always @(posedge s00_axi_aclk)begin 
	if ( rst ) prepare_next_layer_bias_done <= 0;
	else if ( mode == 3'b011 )  prepare_next_layer_bias_done <= 1 ;
	else if (cnt_input_bram_portb_bias[11] == 1'b1) prepare_next_layer_bias_done <= 1; 
	else prepare_next_layer_bias_done <= prepare_next_layer_bias_done;
end 

reg one_input_channel_done_delay;
reg one_input_channel_done_delay_delay;
always @(posedge s00_axi_aclk) one_input_channel_done_delay <= one_input_channel_done;
always @(posedge s00_axi_aclk) one_input_channel_done_delay_delay <= one_input_channel_done_delay;
assign bram_input_enb = (prepare_next_layer_bias_done) ? 0 : // avoid memory collision
						(last_output_channel && one_input_channel_done_delay_delay) ? 0 :	// avoid memory collision
						( last_output_channel && wait_padding_cnt_delay == 6  /*&& wait_padding_cnt == 6*/) ? 1 : 
						( cnt_input_bram_portb_bias[11] ) ? 0 :
						( conv_and_relu_done && !prepare_next_layer_bias_done ) ? 1 : 0 ;
assign bram_input_web = bram_input_enb;
assign bram_input_addrb = ( prepare_next_layer_bias_done ) ? 0 : cnt_input_bram_portb_bias ;
assign bram_input_dinb = bram_bias_douta;


// output bram signal==========================================================================================
// output bram port A // when kernel_start_out read port // when pooling read port // when done read port
wire bram_output_ena, bram_output_wea;
wire [10:0] bram_output_addra;
wire [20:0] bram_output_dina, bram_output_douta;
assign bram_output_douta = (mode[0] == 1'b0) ? bramb_douta : brama_douta ;
assign bram_output_ena = (kernel_start_out) ? 1 : ( pooling_en ) ? 1 : (done) ? 1 : 0;
assign bram_output_wea = 0;
assign bram_output_addra = (kernel_start_out) ? (base_address+kernel_output_num-1) : 
							( pooling_en ) ? pooling_addr_read[10:0] :
							(done) ? addr_output >> 2 : 0  ;
assign bram_output_dina = 0;

wire [10:0] base_address;
assign base_address = (input_repeat_time-1) << (in_vector_size_check_bit);

// output bram port B	// when conv1_bias_ready is 0 , write port // when kernel_start_out write port // when pooling write port

reg [10:0] bram_addrb_outpupt_reg;
always@(posedge s00_axi_aclk)begin 
	if ( rst ) bram_addrb_outpupt_reg <= 0;
	else if (kernel_start_out) bram_addrb_outpupt_reg <= bram_output_addra;
	else bram_addrb_outpupt_reg <= bram_addrb_outpupt_reg;
end

wire bram_output_enb, bram_output_web;
wire [10:0] bram_output_addrb;
wire [20:0] bram_output_dinb, bram_output_doutb;
assign bram_output_doutb = ( mode[0] == 1'b0 ) ? bramb_doutb : brama_doutb ; 

reg [10:0] cnt_conv1_bias_addr;
reg [10:0] cnt_conv1_bias_addr_delay;
always @(posedge s00_axi_aclk) cnt_conv1_bias_addr_delay <= cnt_conv1_bias_addr;
always @(posedge s00_axi_aclk) begin 
	if ( rst_sw ) cnt_conv1_bias_addr <= 0 ; 
	else if ( cnt_conv1_bias_addr[10] == 1'b1 ) cnt_conv1_bias_addr <= cnt_conv1_bias_addr;
	else if (conv1_bias_ready == 1'b0) cnt_conv1_bias_addr <= cnt_conv1_bias_addr + 1; 
	else cnt_conv1_bias_addr <= cnt_conv1_bias_addr;
end
assign bram_output_enb = (~conv1_bias_ready_delay) ? 1 : (kernel_start_out_delay) ? 1 : (pooling_we) ? 1 : 0;
assign bram_output_web = bram_output_enb;
assign bram_output_addrb = (~conv1_bias_ready_delay) ? cnt_conv1_bias_addr_delay : (kernel_start_out_delay) ? bram_addrb_outpupt_reg : (pooling_we) ? pooling_addr_write : 0;
assign bram_output_dinb = 	(~conv1_bias_ready_delay) ? { {11{bram_bias_douta[9]}}, bram_bias_douta} :
							(kernel_start_out_delay == 1 ) ? relu_or_acc : 
							(pooling_we) ? pooling_out : 0;
wire [20:0] relu_or_acc;
assign relu_or_acc = ( last_input_channel ) ? { {15{1'b0}}, relu_out } : acc_result;

wire [20:0] acc_result;
wire [5:0] relu_out;
assign acc_result = bram_output_douta + { {6{kernel_out[14]}}, kernel_out} ;
assign relu_out = (acc_result[20] == 1'b1) ? 6'b000000 : 
				  ( |acc_result[19:9] ) ? 6'b111111 :	//  acc_result[19:9] have 1
				  (acc_result[2] == 1'b1 && (&acc_result[8:3] == 0) ) ? // acc_result[8:3] at least one bit is 0
				  acc_result[8:3] + 1'b1 : acc_result[8:3] ;
			
//	pooling====================================================================
reg pooling_en, pooling_we, pooling_done;
reg [11:0] pooling_addr_read;
wire [9:0] pooling_addr_write;
reg [5:0] pooling_fp_out;
wire [5:0] pooling_out;
assign pooling_out = ( pooling_fp_out >= bram_output_douta ) ? pooling_fp_out : bram_output_douta[5:0];
assign pooling_addr_write = (pooling_addr_read >> 1) - 1;
always @(posedge s00_axi_aclk) pooling_fp_out <= bram_output_douta;
always @(posedge s00_axi_aclk) begin 
	if ( rst ) pooling_done <= 0;
	//else if (pooling_addr_read == pooling_max_address) pooling_done <= 1 ;
	else if ( pooling_addr_read[pooling_max_check_bit] == 1'b1 ) pooling_done <= 1 ;
end

always @(posedge s00_axi_aclk) begin 
	if ( rst ) pooling_addr_read <= 0;
	//else if ( pooling_addr_read == pooling_max_address ) pooling_addr_read <= pooling_addr_read;
	else if ( pooling_addr_read[pooling_max_check_bit] == 1'b1 ) pooling_addr_read <= pooling_addr_read;
	else if ( pooling_en ) pooling_addr_read <= pooling_addr_read + 1'b1;
	else pooling_addr_read <= pooling_addr_read;
end


always @(posedge s00_axi_aclk) begin 
	if (rst) pooling_en <= 0;
	else if ( conv_and_relu_done && pooling_done == 0) pooling_en <= 1;
	//else if ( pooling_addr_read == pooling_max_address ) pooling_en <= 0;
	else if ( pooling_addr_read[pooling_max_check_bit] == 1'b1 ) pooling_en <= 0;
	else pooling_en <= pooling_en;
end

always @(posedge s00_axi_aclk) begin 
	if ( rst ) pooling_we <= 0;
	else if ( pooling_addr_read[0] == 1 ) pooling_we <= 1;
	else pooling_we <= 0;
end

// brama signal==========================================================================================
wire brama_ena, brama_wea;
wire [10:0] brama_addra;
wire [20:0] brama_dina;
wire [20:0] brama_douta;
assign brama_ena = (mode[0] == 1'b0) ? bram_input_ena : bram_output_ena ;
assign brama_wea = (mode[0] == 1'b0) ? bram_input_wea : bram_output_wea;
assign brama_addra = (mode[0] == 1'b0) ? bram_input_addra :  bram_output_addra ;
assign brama_dina = (mode[0] == 1'b0) ? { {15{bram_input_dina[5]}}, bram_input_dina} : bram_output_dina ;// when bram a is input bram // when data_in bram_input_dina is signed 6 bit data, need signed extension
																										 // when bram a is output bram, port A is read port
wire brama_enb, brama_web;
wire [10:0] brama_addrb;
wire [20:0] brama_dinb;
wire [20:0] brama_doutb;
assign brama_enb = (mode[0] == 1'b0) ? bram_input_enb : bram_output_enb ;
assign brama_web = (mode[0] == 1'b0) ? bram_input_web : bram_output_web;
assign brama_addrb = (mode[0] == 1'b0) ? bram_input_addrb : bram_output_addrb ;
assign brama_dinb = (mode[0] == 1'b0) ? { {11{bram_input_dinb[9]}}, bram_input_dinb} : bram_output_dinb ; // when bram a is input bram, need to write bias, bram_input_dinb need signed extension

blk_mem_gen_0 brama(
	.clka(s00_axi_aclk), 
	.addra(brama_addra), 
	.dina(brama_dina), 
	.douta(brama_douta), 
	.wea(brama_wea), 
	.ena(brama_ena),
	
	
	.clkb(s00_axi_aclk),
	.addrb(brama_addrb),
	.dinb(brama_dinb),
	.doutb(brama_doutb),
	.web(brama_web),
	.enb(brama_enb)
) ; 

// bramb signal==========================================================================================
wire bramb_ena, bramb_wea;
wire [10:0] bramb_addra;
wire [20:0] bramb_dina;
wire [20:0] bramb_douta;
assign bramb_ena = (mode[0] == 1'b0) ? bram_output_ena : bram_input_ena ;
assign bramb_wea = (mode[0] == 1'b0) ? bram_output_wea : bram_input_wea;
assign bramb_addra = (mode[0] == 1'b0) ? bram_output_addra : bram_input_addra ;
assign bramb_dina = (mode[0] == 1'b0) ? 0 : 0 ;	// when bram b is output bram, port A is read port
												// when bram b is input bram // no data_in, so bramb_dina is useless

wire bramb_enb, bramb_web;
wire [10:0] bramb_addrb;
wire [20:0] bramb_dinb;
wire [20:0] bramb_doutb;
assign bramb_enb = (mode[0] == 1'b0) ? bram_output_enb : bram_input_enb ;
assign bramb_web = (mode[0] == 1'b0) ? bram_output_web : bram_input_web ;
assign bramb_addrb = (mode[0] == 1'b0) ? bram_output_addrb : bram_input_addrb ;
assign bramb_dinb = (mode[0] == 1'b0) ? bram_output_dinb: { {11{bram_input_dinb[9]}}, bram_input_dinb} ; // when bram b is input bram, need to write bias, bram_input_dinb need signed extension

blk_mem_gen_0 bramb(
	.clka(s00_axi_aclk), 
	.addra(bramb_addra), 
	.dina(bramb_dina), 
	.douta(bramb_douta), 
	.wea(bramb_wea), 
	.ena(bramb_ena),
	
	.clkb(s00_axi_aclk),
	.addrb(bramb_addrb),
	.dinb(bramb_dinb),
	.doutb(bramb_doutb),
	.web(bramb_web),
	.enb(bramb_enb)
) ; 



// bias bram signal==================================================================================================
wire [3:0] next_layer_out_vector_size_check_bit;
assign next_layer_out_vector_size_check_bit = (mode ==3'b000) ? 7 : (mode == 3'b001) ? 6 : 5 ; // mode == 3'b010 is 5

wire bram_bias_ena, bram_bias_wea;
wire [9:0] bram_bias_dina, bram_bias_douta;
wire [6:0] bram_bias_addra;

reg [6:0] cnt_bias_bram;
reg [8:0] cnt_bias_inputnum;	//control cnt_bias_bram
reg [8:0] cnt_bias_inputnum_delay;
always @(posedge s00_axi_aclk) cnt_bias_inputnum_delay <= cnt_bias_inputnum;

always @(posedge s00_axi_aclk) begin 
	if ( rst_sw ) cnt_bias_bram <= 0;
	else if ( cnt_bias_bram == 7'd115 ) cnt_bias_bram <= cnt_bias_bram;	// max index
	else if ( !conv1_bias_ready ) cnt_bias_bram <= (cnt_bias_inputnum[8]) ? cnt_bias_bram + 1 : cnt_bias_bram ;
	else if ( cnt_bias_inputnum[next_layer_out_vector_size_check_bit] ) cnt_bias_bram <= cnt_bias_bram + 1;
	else cnt_bias_bram <= cnt_bias_bram;
end 

always @(posedge s00_axi_aclk) begin 
	if ( rst ) cnt_bias_inputnum <= 1;
	else if ( !conv1_bias_ready ) cnt_bias_inputnum <= ( cnt_bias_inputnum[8] ) ? 1 : cnt_bias_inputnum + 1;
	else if ( last_output_channel && wait_padding_cnt == 6 ) begin 
		if ( kernel_end_out ) cnt_bias_inputnum <= 1;
		else cnt_bias_inputnum <= (cnt_bias_inputnum[next_layer_out_vector_size_check_bit]) ? 1 : cnt_bias_inputnum + 1;
	end
	
	else if (prepare_next_layer_bias_done) cnt_bias_inputnum <= 1;
	
	else if ( conv_and_relu_done ) begin 
		if ( !done ) cnt_bias_inputnum <= ( cnt_bias_inputnum[next_layer_out_vector_size_check_bit] ) ? 1 : cnt_bias_inputnum + 1 ;
		else cnt_bias_inputnum <= cnt_bias_inputnum;
	end
end

assign bram_bias_ena = (!conv1_bias_ready) ? 1 : 
					   (last_output_channel && wait_padding_cnt == 6) ? 1 : // use when convolution begin 
					   //(one_input_channel_done) ? 0 :	//use when one input channel finish 
					   //(cnt_bias_inputnum_delay[next_layer_out_vector_size_check_bit]) ? 1 :	// use during convolution
					   (conv_and_relu_done) ? 1 : 0;
assign bram_bias_wea = 0;
assign bram_bias_dina = 0;
assign bram_bias_addra = cnt_bias_bram ;

blk_mem_gen_bias brambias(
	.clka(s00_axi_aclk), 
	.addra(bram_bias_addra), 
	.dina(bram_bias_dina), 
	.douta(bram_bias_douta), 
	.wea(bram_bias_wea), 
	.ena(bram_bias_ena)
) ; 

// weight bram signal==================================================================================================
wire bram_enw, bram_wew;
wire [11:0] bram_addrw;
wire [63:0] bram_dinw, bram_doutw;
reg [11:0] cnt_w;
assign bram_enw = ( op_st && conv_and_relu_done == 0) ? 1 : 0;
assign bram_wew = 0;
assign bram_addrw = (op_st) ? cnt_w+base_address_weight : 0 ;
assign bram_dinw = 0;

wire [9:0] base_address_weight;
assign base_address_weight = (mode == 3'b000) ? 0 : 
							(mode == 3'b001) ? 4 :
							(mode == 3'b010) ? 68 : 580 ;

always@(posedge s00_axi_aclk) begin
	if( rst ) cnt_w <= 0 ;
	else  if ( cnt_w[weight_check_bit] == 1'b1 ) cnt_w <= cnt_w;
	else if( kernel_end_out == 1 ) begin 
		cnt_w <= cnt_w + 1;
	end
	else cnt_w <= cnt_w ;
end

blk_mem_gen_accw bramw(
	.clka(s00_axi_aclk), 
	.addra(bram_addrw), 
	.dina(bram_dinw), 
	.douta(bram_doutw), 
	.wea(bram_wew), 
	.ena(bram_enw)
	
) ; 

//Kernel signal ====================================================================================================================

wire signed [14:0] kernel_out;
wire kernel_start_out, kernel_end_out, kernel_en;
wire [5:0] kernel_inputdata;
assign kernel_inputdata = bram_input_douta;
wire [8:0] kernel_output_num;

reg kernel_start_out_delay;
always@(posedge s00_axi_aclk) kernel_start_out_delay <= kernel_start_out;
Kernel mykernel(
 	.clk(s00_axi_aclk), 
	.op_st(op_st), 
	.rst(rst),
	.mode(mode),
	
	.in_data(kernel_inputdata), 
	.in_w(bram_doutw),
	
	.conv_and_relu_done(conv_and_relu_done),
	.in_vector_size_check_bit(in_vector_size_check_bit),
	
	.dout(kernel_out),
	.output_num(kernel_output_num),
	.start_out(kernel_start_out),
	.end_out(kernel_end_out),
	.kernel_en(kernel_en)
	
);

assign dout_output = { {11{bram_output_douta[20]}}, bram_output_douta};
	// User logic ends

	endmodule
