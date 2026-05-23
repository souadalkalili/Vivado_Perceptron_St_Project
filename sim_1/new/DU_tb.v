`timescale 1ns / 1ps

module Generic_DU #(
    parameter N = 4,
    parameter DATASET_SIZE = 16,
    parameter WIDTH = 32
)(
    input wire clk,
    input wire rst,
    input wire [7:0] CV,              // ‰«ﬁ· «· Õﬂ„ «·„ÊÕœ «·ﬁ«œ„ „‰ «·‹ CU
    input wire [3:0] sample_idx,      // „ƒ‘— «·”ÿ—
    input wire [2:0] bit_counter,     // ⁄œ«œ «·» «  œ«Œ· «·”ÿ—
    
    input wire signed [WIDTH-1:0] weight_in,
    input wire signed [WIDTH-1:0] bias_in,
    input wire signed [WIDTH-1:0] lr_in,
    input wire signed [WIDTH-1:0] target_in,
    
    output wire error_flag,
    output wire signed [WIDTH-1:0] current_sum
);

    // ---  ›ﬂÌﬂ «·‹ Control Vector (CV) »‰«¡ ⁄·Ï  — Ì» „’›Ê›… «· Õﬂ„ ---
    wire enabl_lut        = CV[7];
    wire enable_sample    = CV[6];
    wire enabl_shift      = CV[5];
    wire enable_sum       = CV[4];
    wire select_x         = CV[3];
    wire select_bw        = CV[2];
    wire load_bias_to_sum = CV[1];
    wire sum_reg_reset    = CV[0];

    // √”·«ﬂ Ê„”Ã·«  œ«Œ·Ì…
    wire [N-1:0] vector_x_wire;
    reg [N-1:0] shift_reg;
    reg signed [WIDTH-1:0] sum_reg;
    wire state_x;

    // 1. «” œ⁄«¡ «·‹ LUT („Œ“‰ «·»Ì«‰« )
    Generic_LUT #(
        .DATASET_SIZE(DATASET_SIZE),
        .N(N)
    ) data_source (
        .enabl_lut(enabl_lut),
        .sample_idx(sample_idx),
        .vector_x(vector_x_wire)
    );

    // 2. „ÊœÌÊ· «·‹ Shift Register („”Ã· «·≈“«Õ…)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 0;
        end else if (enable_sample) begin
            shift_reg <= vector_x_wire; // ‘Õ‰ «·”ÿ— »«·ﬂ«„·
        end else if (enabl_shift) begin
            shift_reg <= shift_reg >> 1; // ≈“«Õ… ··Ì„Ì‰ ·”Õ» «·»  «· «·Ì
        end
    end

    // ”Õ» «·»  «·Õ«·Ì («·»  «·√ﬁ· √Â„Ì… √À‰«¡ «·≈“«Õ…)
    assign state_x = shift_reg[0];

    // 3. «·„Ã„⁄ Ê«·„ı⁄«·Ã (Accumulator Support Q6.26)
    wire signed [WIDTH-1:0] mux_wb;
    // ·Ê «·»  «·Õ«·Ì 1 ‰Œ «— «·Ê“‰° ·Ê 0 ‰Œ «— ’›— (·√‰ «·√Ê“«‰ „÷—Ê»… ›Ì «·„œŒ· «·»«Ì‰—Ì)
    assign mux_wb = (select_x && state_x) ? weight_in : 32'h00000000;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sum_reg <= 32'h00000000;
        end else if (sum_reg_reset) begin
            sum_reg <= 32'h00000000;
        end else if (load_bias_to_sum) begin
            sum_reg <= bias_in; //  Õ„Ì· «·‹ Bias ﬂﬁÌ„… «» œ«∆Ì… ··Ã„⁄
        end else if (enable_sum) begin
            sum_reg <= sum_reg + mux_wb; // «·Ã„⁄ «· —«ﬂ„Ì ··‹ Fixed Point
        end
    end

    assign current_sum = sum_reg;

    // 4. œ«·… «· ›⁄Ì· ÊÕ”«» «·Œÿ√ (Activation Function & Error Flags)
    // œ«·… «· ›⁄Ì·  ⁄ „œ ⁄·Ï »  «·≈‘«—… (Bit 31) ›Ì «·‹ Fixed-Point
    wire current_prediction = (sum_reg[WIDTH-1] == 1'b0) ? 1'b1 : 1'b0;
    
    // „ﬁ«—‰… «· Êﬁ⁄ »«·ﬁÌ„… «·„” Âœ›…
    assign error_flag = (current_prediction != target_in[0]) ? 1'b1 : 1'b0;

endmodule

