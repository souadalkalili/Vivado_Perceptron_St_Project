`timescale 1ns / 1ps

module Perceptron_Top #(
    parameter N = 6,                             
    parameter DATASET_SIZE = 64,                
    parameter WIDTH = 32,                         
    parameter SHIFT = 26
)(
    input wire clk,
    input wire rst,
    input wire start,
    output wire error_flag,
    output wire signed [WIDTH-1:0] current_sum,
    output wire [$clog2(DATASET_SIZE)-1:0] current_sample_idx,
    output wire done,
    output wire [15:0] epoch,
    output wire signed [WIDTH-1:0] out_b,
    output wire signed [(WIDTH*N)-1:0] out_w_flattened 
);

    wire [7:0] CV;
    wire [$clog2(N)-1:0] bit_counter;

    // «” œ⁄«¡ ÊÕœ… «· Õﬂ„ (Control Unit)
    Generic_CU #(
        .DATASET_SIZE(DATASET_SIZE),
        .N(N)
    ) cu (
        .start(start),
        .clk(clk),
        .rst(rst),
        .error_flag(error_flag),
        .CV(CV),
        .sample_idx(current_sample_idx),
        .bit_counter(bit_counter),
        .done(done),
        .epoch(epoch)
    );

    // «” œ⁄«¡ „”«— «·»Ì«‰«  (Data Path Unit)
    Generic_DU #(
        .N(N),
        .WIDTH(WIDTH),
        .SHIFT(SHIFT)
    ) du (
        .clk(clk),
        .rst(rst),
        .CV(CV),
        .sample_idx(current_sample_idx),
        .bit_counter(bit_counter),
        .error_flag(error_flag),
        .current_sum(current_sum),
        .out_b(out_b),
        .out_w_flattened(out_w_flattened) // —»ÿ „»«‘— „⁄ «·„Œ—Ã «·Œ«—ÃÌ ··‹ Top
    );

endmodule