`timescale 1ns / 1ps
module Generic_DU #(
    parameter N = 6,
    parameter DATASET_SIZE = 64,
    parameter WIDTH = 32,
    parameter SHIFT = 26
)(
    input wire clk,
    input wire rst,
    input wire [7:0] CV,
    input wire [$clog2(DATASET_SIZE)-1:0] sample_idx, 
    input wire [$clog2(N)-1:0] bit_counter,
    output wire error_flag, 
    output wire signed [WIDTH-1:0] current_sum,
    output reg signed [WIDTH-1:0] out_b,
    output reg signed [(WIDTH*N)-1:0] out_w_flattened
);

    // ≈‘«—«  «· Õﬂ„
    wire enabl_lut        = CV[7];
    wire enable_sample    = CV[6];
    wire enabl_shift      = CV[5];
    wire enable_sum       = CV[4];
    wire select_x         = CV[3];
    wire select_bw        = CV[2];
    wire load_bias_to_sum = CV[1];
    wire sum_reg_reset    = CV[0];

    localparam signed [WIDTH-1:0] LR = 1 << (SHIFT - 3);

    reg [N-1:0] shift_reg, x_hold;
    reg target_reg;
    reg signed [WIDTH-1:0] sum_reg;
    reg signed [WIDTH-1:0] weight_reg [0:N-1];
    reg signed [WIDTH-1:0] bias_reg;

    // LUT Instance
    wire [N-1:0] v_x; wire t_w;
   Generic_LUT #(
        .N(N),
        .DATASET_SIZE(DATASET_SIZE)
    ) lut (
        .clk(clk), 
        .rst(rst), 
        .enabl_lut(enabl_lut), 
        .sample_index(sample_idx), 
        .vector_x(v_x), 
        .target(t_w)
    );
    // «” ﬁ—«— «·„œŒ·« 
   always @(posedge clk or posedge rst) begin
          if (rst) begin
              shift_reg  <= 0;
              x_hold     <= 0;
              target_reg <= 0;
          end else if (enable_sample) begin
              shift_reg  <= v_x; 
              x_hold     <= v_x; 
              target_reg <= t_w;
          end else if (enabl_shift) begin
              shift_reg  <= shift_reg >> 1;
          end
      end
    // «·Õ”«»« 
    assign error_flag = ((sum_reg >= 0) != target_reg);
    assign current_sum = sum_reg;

    //  ÕœÌÀ «·√Ê“«‰ -  „  ⁄œÌ·Â ·ÌﬂÊ‰ „ Ê«›ﬁ« „⁄ ‰»÷… «·‹ UPDATE
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i=0; i<N; i=i+1) weight_reg[i] <= 0;
            bias_reg <= 0;
        end else if (select_bw) begin
            if (target_reg) begin
                bias_reg <= bias_reg + LR;
                for (i=0; i<N; i=i+1) if (x_hold[i]) weight_reg[i] <= weight_reg[i] + LR;
            end else begin
                bias_reg <= bias_reg - LR;
                for (i=0; i<N; i=i+1) if (x_hold[i]) weight_reg[i] <= weight_reg[i] - LR;
            end
        end
    end

    //  Ã„Ì⁄ «·„Œ—Ã
    integer k;
    always @(*) begin
        for (k=0; k<N; k=k+1) out_w_flattened[k* WIDTH+: WIDTH] = weight_reg[k];
        out_b = bias_reg;
    end

    // «·‹ Accumulator
    wire [$clog2(N)-1:0] c_bit = (bit_counter >= N) ? (N-1) : bit_counter;
    wire signed [WIDTH-1:0] mux_w = (select_x && shift_reg[0]) ? weight_reg[c_bit] : 0;

   always @(posedge clk or posedge rst) begin
          if (rst) begin
              sum_reg <= 0;
          end else if (sum_reg_reset) begin
              sum_reg <= 0;
          end else if (load_bias_to_sum) begin
              sum_reg <= bias_reg;
          end else if (enable_sum) begin
              sum_reg <= sum_reg + mux_w;
          end
      end
endmodule