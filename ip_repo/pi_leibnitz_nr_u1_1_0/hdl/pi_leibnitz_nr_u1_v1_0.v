
`timescale 1 ns / 1 ps

	module pi_leibnitz_nr_u1_v1_0 #
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
	
	wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_user_reg_0;
	wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_user_reg_1;
	wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_user_reg_2;
	wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_user_reg_3;
// Instantiation of Axi Bus Interface S00_AXI
	pi_leibnitz_nr_u1_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) pi_leibnitz_nr_u1_v1_0_S00_AXI_inst (
	
        .USER_REG_0(s00_user_reg_0), //read-only, self-clear
        .USER_REG_1(s00_user_reg_1), //read-only
        .USER_REG_2(s00_user_reg_2), //write-only
        .USER_REG_3(s00_user_reg_3), //write-only

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
	
	wire s00_axi_areset;
    assign s00_axi_areset = ~s00_axi_aresetn;
    
    
     //Assign zeros to unused bits
    assign s00_user_reg_2[31:1] = 31'b0;
    
    pi_leibniz_nr pi_leibniz_inst (
        .clk(s00_axi_aclk),
        .reset(s00_axi_areset), // Reset jest aktywny niski w AXI, wysoki w module pipeline
        .start_count(s00_user_reg_0[0]),
        .iterations_in(s00_user_reg_1[29:0]),
        .done(s00_user_reg_2[0]),
        .pi_out(s00_user_reg_3[31:0])
    );
	// User logic ends

	endmodule



module pi_leibniz_nr (
    input wire clk,
    input wire reset,
    input wire start_count,
    input wire [29:0] iterations_in,
    output reg done,
    output reg signed [31:0] pi_out
);
    parameter PARALLEL_UNITS = 1;

    localparam STATE_IDLE          = 0;
    localparam STATE_START_UNITS   = 1;
    localparam STATE_WAIT_READY    = 2;
    localparam STATE_ACCUMULATE    = 3;
    localparam STATE_DONE          = 4;

    reg [3:0] state = STATE_IDLE;
    reg [29:0] n = 0;
    reg signed [31:0] sum = 0;

    reg [$clog2(PARALLEL_UNITS)-1:0] i_sum;

    reg start [0:PARALLEL_UNITS-1];
    wire ready [0:PARALLEL_UNITS-1];
    wire signed [31:0] term_outputs [0:PARALLEL_UNITS-1];
    reg [29:0] which_words [0:PARALLEL_UNITS-1];

    reg [PARALLEL_UNITS-1:0] ready_flags;
    reg [$clog2(PARALLEL_UNITS+1)-1:0] units_in_batch;
    wire [PARALLEL_UNITS-1:0] completion_mask = (1 << units_in_batch) - 1;
    integer i;

    generate
        genvar k;
        for (k = 0; k < PARALLEL_UNITS; k = k + 1) begin : one_word_gen
            one_word_NR one_word_inst (
                .clk(clk),
                .reset(reset),
                .which_word(which_words[k]),
                .start(start[k]),
                .ready(ready[k]),
                .calc_word(term_outputs[k])
            );
        end
    endgenerate

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pi_out <= 0;
            done <= 0;
            state <= STATE_IDLE;
            ready_flags <= 0;
            for (i = 0; i < PARALLEL_UNITS; i = i + 1) begin
                start[i] <= 0;
            end
        end else begin
            case (state)
                STATE_IDLE: begin
                    if (start_count) begin
                        done <= 0;
                        n <= 0;
                        sum <= 0;
                        pi_out <= 0;
                        i_sum <= 0;
                        state <= STATE_START_UNITS;
                    end
                end

                STATE_START_UNITS: begin
                    if (n < iterations_in) begin
                        units_in_batch <= 0;
                        ready_flags <= 0;

                        for (i = 0; i < PARALLEL_UNITS; i = i + 1) begin
                            if ((n + i) < iterations_in) begin
                                which_words[i] <= n + i;
                                start[i] <= 1;
                                units_in_batch <= i + 1;
                            end else begin
                                start[i] <= 0;
                            end
                        end
                        state <= STATE_WAIT_READY;
                    end else begin
                        pi_out <= sum << 2;
                        done <= 1'b1;
                        state <= STATE_DONE;
                    end
                end

                STATE_WAIT_READY: begin
                    for (i = 0; i < PARALLEL_UNITS; i = i + 1) begin
                        start[i] <= 1'b0;
                    end

                    for (i = 0; i < PARALLEL_UNITS; i = i + 1) begin
                        if (ready[i]) begin
                            ready_flags[i] <= 1'b1;
                        end
                    end
                    
                    if (ready_flags == completion_mask) begin
                        i_sum <= 1'b0;
                        state <= STATE_ACCUMULATE;
                    end
                end

                STATE_ACCUMULATE: begin
                    if (i_sum < units_in_batch) begin
                        if (((n + i_sum) % 2) == 0)
                            sum <= sum + term_outputs[i_sum];
                        else
                            sum <= sum - term_outputs[i_sum];
                    end
                    if (i_sum == units_in_batch - 1) begin
                        n <= n + units_in_batch;
                        state <= STATE_START_UNITS;
                    end else begin
                        i_sum <= i_sum + 1;
                    end
                end

                STATE_DONE: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end
 endmodule
 
 module one_word_NR(
    input wire clk,
    input wire reset,
    input wire [29:0] which_word,
    input wire start,
    output reg ready,
    output reg signed [31:0] calc_word 
);
    wire [31:0] dividend = 1<<29;
    wire [31:0] divisor = (which_word << 1) + 1;
    reg start_div;
    wire [31:0] quotient; 
    wire div_ready;
    reg busy = 0;
    reg div_ready_d = 0;

    NR_divider_32bit divider (
        .clk(clk),
        .reset(reset), 
        .start(start_div),
        .dividend(dividend), 
        .divisor(divisor),
        .quotient(quotient), 
        .ready(div_ready)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            calc_word <= 0;
            ready <= 0;
            busy <= 0;
            start_div <= 0;
            div_ready_d <= 0;
        end else begin
            start_div <= 0;
            ready <= 0;
            div_ready_d <= div_ready;

            if (div_ready && !div_ready_d) begin
                calc_word <= quotient;
                ready <= 1;
                busy <= 0;
            end else if (start && !busy) begin
                busy <= 1;
                start_div <= 1;
            end
        end
    end
endmodule

module NR_divider_32bit(
    input clk,
    input reset,
    input start,
    input [31:0] dividend,
    input [31:0] divisor,
    output reg [31:0] quotient,
    output reg ready
);
    localparam IDLE = 0, RECIP_CALC = 1, FINAL_MUL = 2, DONE = 3;
    reg [1:0] state;
    reg recip_start;
    wire recip_ready;
    wire [31:0] reciprocal_val;
    reg [63:0] final_product;
    
    reciprocal_32bit_nr recip_inst (
        .clk(clk), 
        .reset(reset), 
        .start(recip_start), 
        .ready(recip_ready),
        .input0(divisor), 
        .output0(reciprocal_val)
    );

    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            ready <= 0;
            recip_start <= 0;
        end else begin
            case (state)
                IDLE: begin
                    recip_start <= 0;
                    ready <= 0;
                    if (start) begin
                        recip_start <= 1;
                        state <= RECIP_CALC;
                    end
                end
                RECIP_CALC: begin
                    recip_start <= 0;
                    if (recip_ready) begin
                        state <= FINAL_MUL;
                    end
                end
                FINAL_MUL: begin
                    final_product <= dividend * reciprocal_val;
                    state <= DONE;
                end
                DONE: begin
                    quotient <= final_product[60:29];
                    ready <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule

module reciprocal_32bit_nr(
    input             clk,
    input             reset,
    input             start,
    output reg        ready,
    input      [31:0] input0,
    output reg [31:0] output0
);
    localparam [31:0] A = 32'h3C3C3415; 
    localparam [31:0] B = 32'h59595800;
    localparam [31:0] HALF = 32'h10000000; // 0.5
    localparam [31:0] TWO = 32'h40000000;  // 2.0

    localparam S_IDLE = 0, S_NORMALIZE_START = 1, S_NORMALIZE_WAIT = 2,
    S_INIT_MUL_START = 3, S_INIT_MUL_WAIT = 4, S_INIT_CALC = 5,
    S_ITER_MUL1_START = 6, S_ITER_MUL1_WAIT = 7, S_ITER_SUB = 8,
    S_ITER_MUL2_START = 9, S_ITER_MUL2_WAIT = 10, S_CHECK_CONV = 11,
    S_ASSIGN_NEW = 12, S_FINAL_SCALE_START = 13, S_FINAL_SCALE_SHIFT = 14,
    S_DONE = 15;

    reg [4:0]  state;
    reg [5:0]  scaling;
    reg [31:0] scaledVal;
    reg [31:0] approxVal;
    reg [31:0] newVal;
    reg [31:0] temp_shift;

    localparam M_IDLE = 0, M_RUN = 1, M_DONE = 2;
    reg [1:0]  mult_state;
    reg        mult_start;
    wire       mult_ready;

    reg [31:0] mult_op_A;
    reg [31:0] mult_op_B;
    reg [1:0]  mult_i; 
    reg [1:0]  mult_j;
    reg [63:0] mult_accumulator;

    wire [11:0] chunk_a = (mult_i == 0) ? mult_op_A[11:0]  : (mult_i == 1) ? mult_op_A[23:12] : {4'd0, mult_op_A[31:24]};
    wire [11:0] chunk_b = (mult_j == 0) ? mult_op_B[11:0]  : (mult_j == 1) ? mult_op_B[23:12] : {4'd0, mult_op_B[31:24]};
    wire [23:0] partial_product;
    
    
    mult_12x12 multiplier_inst (
    .a(chunk_a), 
    .b(chunk_b), 
    .p(partial_product)
    );
    
    always @(posedge clk) begin
        if (reset) begin
            mult_state <= M_IDLE;
            mult_i <= 0;
            mult_j <= 0;
            mult_accumulator <= 0;
        end else begin
            case(mult_state)
                M_IDLE:
                    if (mult_start) begin
                        mult_accumulator <= 0;
                        mult_i <= 0;
                        mult_j <= 0;
                        mult_state <= M_RUN;
                    end
                M_RUN: begin
                    mult_accumulator <= mult_accumulator + ({40'b0, partial_product} << ((mult_i + mult_j) * 12));
                    if (mult_j == 2) begin
                        mult_j <= 0;
                        mult_i <= mult_i + 1;
                    end else begin
                        mult_j <= mult_j + 1;
                    end
                    if (mult_i == 2 && mult_j == 2) begin
                        mult_state <= M_DONE;
                    end
                end
                M_DONE:
                    if (!mult_start) begin
                        mult_state <= M_IDLE;
                    end
            endcase
        end
    end
    assign mult_ready = (mult_state == M_DONE);
   
    wire [63:0] mulResult = mult_accumulator;
    wire [31:0] mul_res_shifted = mulResult[60:29];

    always @(posedge clk) begin
        if (reset) begin
            state <= S_IDLE;
            ready <= 0;
            mult_start <= 0;
        end else begin
            mult_start <= 0; 
            case(state)
                S_IDLE: begin
                    ready <= 0;
                    if (start) begin
                        scaledVal <= input0;
                        scaling <= 6'd0;
                        state <= S_NORMALIZE_START;
                    end
                end
                S_NORMALIZE_START: state <= (scaledVal == 0) ? S_DONE : S_NORMALIZE_WAIT;
                S_NORMALIZE_WAIT:
                    if (scaledVal < HALF) begin
                        scaledVal <= scaledVal << 1;
                        scaling <= scaling + 1;
                    end else begin
                        state <= S_INIT_MUL_START;
                    end
                
                S_INIT_MUL_START: begin
                    mult_start <= 1;
                    mult_op_A <= A;
                    mult_op_B <= scaledVal;
                    state <= S_INIT_MUL_WAIT;
                end
                S_INIT_MUL_WAIT:
                    if (mult_ready) begin
                        state <= S_INIT_CALC;
                    end

                S_INIT_CALC: begin
                    approxVal <= B - mul_res_shifted;
                    state <= S_ITER_MUL1_START;
                end

                S_ITER_MUL1_START: begin
                    mult_start <= 1;
                    mult_op_A <= scaledVal;
                    mult_op_B <= approxVal;
                    state <= S_ITER_MUL1_WAIT;
                end
                S_ITER_MUL1_WAIT:
                    if (mult_ready) begin
                        state <= S_ITER_SUB;
                    end
                
                S_ITER_SUB: begin
                    newVal <= TWO - mul_res_shifted;
                    state <= S_ITER_MUL2_START;
                end

                S_ITER_MUL2_START: begin
                    mult_start <= 1;
                    mult_op_A <= newVal;
                    mult_op_B <= approxVal;
                    state <= S_ITER_MUL2_WAIT;
                end
                S_ITER_MUL2_WAIT:
                    if (mult_ready) begin
                        state <= S_CHECK_CONV;
                    end

                S_CHECK_CONV: begin
                    newVal <= mul_res_shifted;
                    if (approxVal == mul_res_shifted) begin
                        state <= S_FINAL_SCALE_START;
                    end else begin
                        state <= S_ASSIGN_NEW;
                    end
                end
                S_ASSIGN_NEW: begin
                    approxVal <= newVal;
                    state <= S_ITER_MUL1_START;
                end

                  S_FINAL_SCALE_START: begin
                    temp_shift <= approxVal;
                    scaling <= 29 - scaling; 
                    state <= S_FINAL_SCALE_SHIFT;
                end

                S_FINAL_SCALE_SHIFT:
                    if (scaling > 0) begin
                        temp_shift <= temp_shift >> 1; 
                        scaling <= scaling - 1;
                    end else begin
                        state <= S_DONE;
                    end
                S_DONE: begin
                    output0 <= (input0 == 0) ? 32'hFFFFFFFF : temp_shift;
                    ready <= 1;
                    state <= S_IDLE;
                end
            endcase
        end
    end
endmodule

module mult_12x12(
    input      [11:0] a,
    input      [11:0] b,
    output     [23:0] p
);
    assign p = a * b;
endmodule
