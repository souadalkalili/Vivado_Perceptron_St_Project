`timescale 1ns / 1ps

module Perceptron_Top_tb;

    parameter N_TB = 6;                         // ⁄œœ „œŒ·«  «·‰„Ê–Ã
    parameter DATASET_SIZE_TB = 64;            // ÕÃ„ ⁄Ì‰«  «·œ« « ”Ì  ·‹ 10 „œŒ·« 
    parameter WIDTH_TB = 32;                     // «·ÕÃ„ «·≈Ã„«·Ì ··ﬂ·„… (32 » )
    parameter SHIFT_TB = 26;                     // ⁄œœ » «  «·ﬂ”—
    
    reg start;
    reg clk;
    reg rst;

    wire error_flag;
    wire signed [WIDTH_TB-1:0] current_sum;       
    wire [$clog2(DATASET_SIZE_TB)-1:0] current_sample_idx;
    wire done;
    wire [15:0] epoch;
    wire signed [WIDTH_TB-1:0] out_b;            
    wire signed [(WIDTH_TB*N_TB)-1:0] out_w_flattened; // «” ﬁ»«· «·”·ﬂ «·Œ«—ÃÌ Â‰«

    // „’›Ê›… «·√”·«ﬂ ·€—÷  ›ﬂÌ n Ê“«‰ »‘ﬂ· „‰›’· ›Ì «·‹ Waveform
    wire signed [WIDTH_TB-1:0] w [0:N_TB-1];

    genvar idx;
    generate
        for (idx = 0; idx < N_TB; idx = idx + 1) begin : weight_split
            assign w[idx] = out_w_flattened[idx * WIDTH_TB +: WIDTH_TB];
        end
    endgenerate

    Perceptron_Top #(
        .N(N_TB),
        .DATASET_SIZE(DATASET_SIZE_TB),          
        .WIDTH(WIDTH_TB),                        
        .SHIFT(SHIFT_TB)
    ) uut (
        .start(start),
        .clk(clk),
        .rst(rst),
        .error_flag(error_flag),
        .current_sum(current_sum),
        .current_sample_idx(current_sample_idx),
        .done(done),
        .epoch(epoch),
        .out_b(out_b),
        .out_w_flattened(out_w_flattened)
    );

    always begin
        #5 clk = ~clk;
    end

    initial begin
        clk = 0;
        rst = 1; //  ›⁄Ì· «·—Ì”  ·· ’›Ì— «·ﬂ«„· ›Ì «·»œ«Ì…
        start = 0;
        #100;
        rst = 0; // ≈·€«¡ «·—Ì” 
        #100;
        start = 1; // ‰»÷… «·»œ¡ · ‘€Ì· «·‹ CU
        #40;
        start = 0;
        $display("[SIMULATION START] Running Inputs Structural Perceptron Trainer...");

        fork : sim_monitor
            begin
                @(posedge done);
                $display("==========================================================");
                $display("[SUCCESS] Training Completed for n Inputs!");
                $display("Time of Convergence = %0t ns", $time);
                $display("Total Epochs taken  = %0d", epoch);
                $display("Final Bias (out_b)  = %0d", out_b);
                $display("==========================================================");
                #100;
                $finish;
            end
            begin
                #50000000; 
                $display("[TIMEOUT] Simulation stopped by safety guard.");
                $finish;
            end
        join
    end

    // ‘«‘… «·„—«ﬁ»… «··ÕŸÌ… œ«Œ· «·‹ Tcl Console ·‹ Vivado
    always @(current_sample_idx) begin
        if (!rst) begin
            $display("Time = %0t ns | Sample = %0d | Sum = %0d | Error = %b | Epoch = %0d", 
                     $time, current_sample_idx, current_sum, error_flag, epoch);
        end
    end

endmodule