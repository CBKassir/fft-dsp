module fft8 #(
    parameter integer WIDTH = 16  // Bit width for fixed-point
)(
    input  logic                   clk,
    input  logic                   rst,
    input  logic                   in_valid,
    input  logic signed [WIDTH-1:0] in_re [0:7], // Input real part
    input  logic signed [WIDTH-1:0] in_im [0:7], // Input imag part
    output logic                   out_valid,
    output logic signed [WIDTH-1:0] out_re [0:7],// Output real part
    output logic signed [WIDTH-1:0] out_im [0:7] // Output imag part
);

    // Twiddle factor constants (Q1.(WIDTH-1) fixed-point, e.g. Q1.15 for WIDTH=16)
    // w8^1 = cos(45°) - j*sin(45°) = 0.7071 - j0.7071
    localparam signed [WIDTH-1:0] W1_re = 16'sd23170; // ~0.7071 * 2^15
    localparam signed [WIDTH-1:0] W1_im = -16'sd23170;
    // w8^2 = cos(90°) - j*sin(90°) = 0 - j1.0
    localparam signed [WIDTH-1:0] W2_re = 16'sd0;
    localparam signed [WIDTH-1:0] W2_im = -16'sd32768; // -1.0 in Q1.15 (min int)
    // w8^3 = cos(135°) - j*sin(135°) = -0.7071 - j0.7071
    localparam signed [WIDTH-1:0] W3_re = -16'sd23170;
    localparam signed [WIDTH-1:0] W3_im = -16'sd23170;

    // Pipeline registers for each stage (complex arrays)
    logic signed [WIDTH-1:0] stage0_re [0:7], stage0_im [0:7]; // Input buffer
    logic signed [WIDTH-1:0] stage1_re [0:7], stage1_im [0:7]; // After stage 1 (Y values)
    logic signed [WIDTH-1:0] stage2_re [0:7], stage2_im [0:7]; // After stage 2 (Z values)

    // Intermediate variables for multiplies
    logic signed [31:0] mul_re, mul_im;
    logic signed [WIDTH-1:0] t2_re, t2_im;

    // State machine for pipeline stages
    typedef enum logic [1:0] {IDLE, STAGE1, STAGE2, STAGE3} state_t;
    state_t state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            out_valid <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    out_valid <= 1'b0;
                    if (in_valid) begin
                        // Latch input samples into stage0 registers
                        for (int i = 0; i < 8; i++) begin
                            stage0_re[i] <= in_re[i];
                            stage0_im[i] <= in_im[i];
                        end
                        state <= STAGE1;
                    end
                end

                STAGE1: begin
                    // === Stage 1: Size-2 butterflies (distance = 4) ===
                    // Pairs: (0,4), (1,5), (2,6), (3,7)
                    // Twiddle Factors
                    //   (0,4), (1,5), (2,6), (3,7): w2^0 = 1

                    stage1_re[0] <= stage0_re[0] + stage0_re[4];
                    stage1_im[0] <= stage0_im[0] + stage0_im[4];
                    stage1_re[4] <= stage0_re[0] - stage0_re[4];
                    stage1_im[4] <= stage0_im[0] - stage0_im[4];

                    stage1_re[1] <= stage0_re[1] + stage0_re[5];
                    stage1_im[1] <= stage0_im[1] + stage0_im[5];
                    stage1_re[5] <= stage0_re[1] - stage0_re[5];
                    stage1_im[5] <= stage0_im[1] - stage0_im[5];

                    stage1_re[2] <= stage0_re[2] + stage0_re[6];
                    stage1_im[2] <= stage0_im[2] + stage0_im[6];
                    stage1_re[6] <= stage0_re[2] - stage0_re[6];
                    stage1_im[6] <= stage0_im[2] - stage0_im[6];

                    stage1_re[3] <= stage0_re[3] + stage0_re[7];
                    stage1_im[3] <= stage0_im[3] + stage0_im[7];
                    stage1_re[7] <= stage0_re[3] - stage0_re[7];
                    stage1_im[7] <= stage0_im[3] - stage0_im[7];

                    state <= STAGE2;
                end

                STAGE2: begin
                    // === Stage 2: Size-4 butterflies (distance = 2) ===
                    // Pairs: (0,2), (1,3), (4,6), (5,7)
                    // Twiddle factors:
                    //   (0,2), (4,6): w4^0 = 1
                    //   (1,3), (5,7): w4^1 = -j

                    stage2_re[0] <= stage1_re[0] + stage1_re[2];
                    stage2_im[0] <= stage1_im[0] + stage1_im[2];
                    stage2_re[2] <= stage1_re[0] - stage1_re[2];
                    stage2_im[2] <= stage1_im[0] - stage1_im[2];
                    
                    stage2_re[1] <= stage1_re[1] + stage1_im[3];
                    stage2_im[1] <= stage1_im[1] - stage1_re[3];
                    stage2_re[3] <= stage1_re[1] - stage1_im[3];
                    stage2_im[3] <= stage1_im[1] + stage1_re[3];
                    
                    stage2_re[4] <= stage1_re[4] + stage1_re[6];
                    stage2_im[4] <= stage1_im[4] + stage1_im[6];
                    stage2_re[6] <= stage1_re[4] - stage1_re[6];
                    stage2_im[6] <= stage1_im[4] - stage1_im[6];
                    
                    stage2_re[5] <= stage1_re[5] + stage1_im[7];
                    stage2_im[5] <= stage1_im[5] - stage1_re[7];
                    stage2_re[7] <= stage1_re[5] - stage1_im[7];
                    stage2_im[7] <= stage1_im[5] + stage1_re[7];

                    state <= STAGE3;
                end

                STAGE3: begin
                    // === Stage 3: Size-8 butterflies (distance = 1) ===
                    // Pairs: (0,4), (1,5), (2,6), (3,7)

                    // (0,4) with W8^0 = 1
                    out_re[0] <= stage2_re[0] + stage2_re[4];
                    out_im[0] <= stage2_im[0] + stage2_im[4];
                    out_re[4] <= stage2_re[0] - stage2_re[4];
                    out_im[4] <= stage2_im[0] - stage2_im[4];

                    // (1,5) with W8^1
                    mul_re = stage2_re[5]*W1_re - stage2_im[5]*W1_im;
                    mul_im = stage2_re[5]*W1_im + stage2_im[5]*W1_re;
                    mul_re = mul_re >>> (WIDTH-1);
                    mul_im = mul_im >>> (WIDTH-1);
                    out_re[1] <= stage2_re[1] + mul_re[WIDTH-1:0];
                    out_im[1] <= stage2_im[1] + mul_im[WIDTH-1:0];
                    out_re[5] <= stage2_re[1] - mul_re[WIDTH-1:0];
                    out_im[5] <= stage2_im[1] - mul_im[WIDTH-1:0];

                    // (2,6) with W8^2
                    mul_re = stage2_re[6]*W2_re - stage2_im[6]*W2_im;
                    mul_im = stage2_re[6]*W2_im + stage2_im[6]*W2_re;
                    mul_re = mul_re >>> (WIDTH-1);
                    mul_im = mul_im >>> (WIDTH-1);
                    out_re[2] <= stage2_re[2] + mul_re[WIDTH-1:0];
                    out_im[2] <= stage2_im[2] + mul_im[WIDTH-1:0];
                    out_re[6] <= stage2_re[2] - mul_re[WIDTH-1:0];
                    out_im[6] <= stage2_im[2] - mul_im[WIDTH-1:0];

                    // (3,7) with W8^3
                    mul_re = stage2_re[7]*W3_re - stage2_im[7]*W3_im;
                    mul_im = stage2_re[7]*W3_im + stage2_im[7]*W3_re;
                    mul_re = mul_re >>> (WIDTH-1);
                    mul_im = mul_im >>> (WIDTH-1);
                    out_re[3] <= stage2_re[3] + mul_re[WIDTH-1:0];
                    out_im[3] <= stage2_im[3] + mul_im[WIDTH-1:0];
                    out_re[7] <= stage2_re[3] - mul_re[WIDTH-1:0];
                    out_im[7] <= stage2_im[3] - mul_im[WIDTH-1:0];

                    out_valid <= 1'b1;
                    state <= IDLE;
                end

            endcase
        end
    end
endmodule
