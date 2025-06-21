
`timescale 1 ns / 1 ps

	module pi_leibnitz_v1_0 #
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
	pi_leibnitz_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) pi_leibnitz_v1_0_S00_AXI_inst (
	
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
    
    pi_leibniz pi_leibniz_inst (
        .clk(s00_axi_aclk),
        .reset(s00_axi_areset), // Reset jest aktywny niski w AXI, wysoki w module pipeline
        .start_count(s00_user_reg_0[0]),
        .iterations_in(s00_user_reg_1[29:0]),
        .done(s00_user_reg_2[0]),
        .pi_out(s00_user_reg_3[31:0])
    );
	// User logic ends

	endmodule

module pi_leibniz (
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
    wire [31:0] term_outputs [0:PARALLEL_UNITS-1];
    reg [29:0] which_words [0:PARALLEL_UNITS-1];

    reg all_ready;
    integer i;

    generate
        genvar k;
        for (k = 0; k < PARALLEL_UNITS; k = k + 1) begin : one_word_gen
            one_word one_word_inst (
                .clk(clk),
                .reset(reset),
                .which_word(which_words[k]),
                .start(start[k]),
                .ready(ready[k]),
                .calc_word(term_outputs[k])
            );
        end
    endgenerate

    always @(*) begin
        all_ready = 1'b1;
        for (i = 0; i < PARALLEL_UNITS; i = i + 1) begin
            if (!ready[i]) begin
                all_ready = 1'b0;
            end
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pi_out <= 0;
            done <= 0;
            state <= STATE_IDLE;
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
                        for (i = 0; i < PARALLEL_UNITS; i = i + 1) begin
                           which_words[i] <= 0;
                           start[i] <= 0;
                        end
                        state <= STATE_START_UNITS;
                    end
                end

                STATE_START_UNITS: begin
                    if (n < iterations_in) begin
                        for (i = 0; i < PARALLEL_UNITS; i = i + 1) begin
                            if ((n + i) < iterations_in) begin 
                                which_words[i] <= n + i;
                                start[i] <= 1;
                            end else begin
                                start[i] <= 0; 
                            end
                        end
                        state <= STATE_WAIT_READY;
                    end else begin
                        pi_out <= sum <<< 2;
                        done <= 1; 
                        state <= STATE_DONE;
                    end
                end

                STATE_WAIT_READY: begin
                    for (i = 0; i < PARALLEL_UNITS; i = i + 1) begin
                        start[i] <= 0;
                    end
                    if (all_ready) begin
                        i_sum <= 0; 
                        state <= STATE_ACCUMULATE;
                    end
                end

                STATE_ACCUMULATE: begin
                    if ((n + i_sum) < iterations_in) begin
                        if ((n + i_sum) % 2 == 0)
                            sum <= sum + term_outputs[i_sum];
                        else
                            sum <= sum - term_outputs[i_sum];
                    end
                    
                    if (i_sum == PARALLEL_UNITS - 1) begin
                        n <= n + PARALLEL_UNITS;
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

module one_word(
    input wire clk,
    input wire reset,
    input wire [29:0] which_word,
    input wire start,
    output reg ready,
    output reg [31:0] calc_word 
);

    wire [31:0] dividend = 1<<30;
    wire [31:0] divisor = (which_word << 1) + 1;

    reg start_div;
    wire [31:0] quotient;
    wire div_ready;

    reg busy = 0;
    reg div_ready_d = 0;

    one_word_divider_32bit divider (
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


module one_word_divider_32bit(
    input wire clk,
    input wire reset,
    input wire start,
    input wire [31:0] dividend,    
    input wire [31:0] divisor,    
    output reg [31:0] quotient,
    output reg ready
);

    reg [63:0] dividend_reg;         
    reg [31:0] divisor_reg;
    reg [5:0] bit_counter;           
    reg busy;

    wire [63:0] shifted_dividend = dividend_reg << 1;
    wire [31:0] remainder_part = shifted_dividend[63:32];
    wire can_subtract = (remainder_part >= divisor_reg);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient <= 0;
            ready <= 0;
            busy <= 0;
            bit_counter <= 0;
            dividend_reg <= 0;
            divisor_reg <= 0;
        end else if (start && !busy) begin
            dividend_reg <= {32'b0, dividend}; 
            divisor_reg <= divisor;
            quotient <= 0;
            bit_counter <= 32;            
            ready <= 0;
            busy <= 1;
        end else if (busy) begin
            ready <= 0; 

            if (can_subtract) begin
                dividend_reg <= {remainder_part - divisor_reg, shifted_dividend[31:0]};
                quotient <= (quotient << 1) | 1;
            end else begin
                dividend_reg <= shifted_dividend;
                quotient <= quotient << 1;
            end
            
            bit_counter <= bit_counter - 1;

            if (bit_counter == 1) begin
                ready <= 1;
                busy <= 0;
            end
        end else begin
            ready <= 0;
        end
    end
endmodule