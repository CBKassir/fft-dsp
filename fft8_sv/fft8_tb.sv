`timescale 1ns/1ps
module tb_fft8;
    logic clk, rst;
    logic in_valid;
    logic signed [15:0] in_re [0:7], in_im [0:7];
    logic out_valid;
    logic signed [15:0] out_re [0:7], out_im [0:7];

    initial clk = 0;
    always #5 clk = ~clk;

    fft8 fft_inst (
        .clk(clk), .rst(rst),
        .in_valid(in_valid), .in_re(in_re), .in_im(in_im),
        .out_valid(out_valid), .out_re(out_re), .out_im(out_im)
    );

    integer i;
    initial begin
        // Initialize
        rst = 1;
        in_valid = 0;
        for (i = 0; i < 8; i++) begin
            in_re[i] = 0;
            in_im[i] = 0;
        end

        #20;
        rst = 0;
        #10;

        // Test 1: impulse input [1.0, 0,0,...,0]
        in_valid = 1;
        in_re[0] = 16'sd32767; in_im[0] = 0;    // 32767 = (1.0 in Q1.15)
        for (i = 1; i < 8; i++) begin in_re[i] = 0; in_im[i] = 0; end
        #10; in_valid = 0;
        wait (out_valid == 1);
        $display("Test 1: Impulse Input [1,0,0,0,0,0,0,0] FFT Output:");
        for (i = 0; i < 8; i++) begin
            $display("  X[%0d] = %0d + j%0d", i, out_re[i], out_im[i]);
        end
        // Expected: All outputs = 32767 + j0 (since FFT of impulse is constant 1.0)

        // Test 2: [0.5,0,0,...,0]
        #10;
        in_valid = 1;
        in_re[0] = 16'sd16384; in_im[0] = 0;    // 16384 = (0.5 in Q1.15)
        for (i = 1; i < 8; i++) begin in_re[i] = 0; in_im[i] = 0; end
        #10; in_valid = 0;
        wait (out_valid == 1);
        $display("\nTest 2: [0.5,0,0,0,0,0,0,0] FFT Output:");
        for (i = 0; i < 8; i++) begin
            $display("  X[%0d] = %0d + j%0d", i, out_re[i], out_im[i]);
        end
        // Expected: All outputs ≈ 16384 + j0 (FFT of constant 0.5 is constant 0.5)

        // Test 3: [0.5,0.5,0,0,0,0,0,0]
        #10;
        in_valid = 1;
        in_re[0] = 16'sd16384; in_im[0] = 0;
        in_re[1] = 16'sd16384; in_im[1] = 0;
        for (i = 2; i < 8; i++) begin in_re[i] = 0; in_im[i] = 0; end
        #10; in_valid = 0;
        wait (out_valid == 1);
        $display("\nTest 3: [0.5,0.5,0,0,0,0,0,0] FFT Output:");
        for (i = 0; i < 8; i++) begin
            $display("  X[%0d] = %0d + j%0d", i, out_re[i], out_im[i]);
        end
        // Expected:
        // X[0]=32767, X[1]=27955-11552j, X[2]=16384-16384j, X[3]=4788-11552j,
        // X[4]=0,     X[5]=4788+11552j,  X[6]=16384+16384j, X[7]=27955+11552j
        #10 $finish;
    end
endmodule
