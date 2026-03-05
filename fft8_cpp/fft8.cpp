#include "fft8.hpp"

void fft8(
    ap_int<WIDTH> in_re[N],
    ap_int<WIDTH> in_im[N],
    ap_int<WIDTH> &out_re0, ap_int<WIDTH> &out_im0,
    ap_int<WIDTH> &out_re1, ap_int<WIDTH> &out_im1,
    ap_int<WIDTH> &out_re2, ap_int<WIDTH> &out_im2,
    ap_int<WIDTH> &out_re3, ap_int<WIDTH> &out_im3,
    ap_int<WIDTH> &out_re4, ap_int<WIDTH> &out_im4,
    ap_int<WIDTH> &out_re5, ap_int<WIDTH> &out_im5,
    ap_int<WIDTH> &out_re6, ap_int<WIDTH> &out_im6,
    ap_int<WIDTH> &out_re7, ap_int<WIDTH> &out_im7
) {
    #pragma HLS PIPELINE II=1

    // --- Stage 0: copy inputs ---
    ap_int<WIDTH> stage0_re[N], stage0_im[N];
    for(int i=0; i<N; i++) {
        #pragma HLS UNROLL
        stage0_re[i] = in_re[i];
        stage0_im[i] = in_im[i];
    }

    // --- Stage 1: size-2 butterflies ---
    ap_int<WIDTH> stage1_re[N], stage1_im[N];
    for(int i=0; i<4; i++) {
        #pragma HLS UNROLL
        stage1_re[i]   = stage0_re[i] + stage0_re[i+4];
        stage1_im[i]   = stage0_im[i] + stage0_im[i+4];
        stage1_re[i+4] = stage0_re[i] - stage0_re[i+4];
        stage1_im[i+4] = stage0_im[i] - stage0_im[i+4];
    }

    // --- Stage 2: size-4 butterflies ---
    ap_int<WIDTH> stage2_re[N], stage2_im[N];

    const ap_int<WIDTH> W1_re = 23170;  // 0.7071*2^15
    const ap_int<WIDTH> W1_im = -23170;
    const ap_int<WIDTH> W2_re = 0;
    const ap_int<WIDTH> W2_im = -32768;
    const ap_int<WIDTH> W3_re = -23170;
    const ap_int<WIDTH> W3_im = -23170;

    // (0,2), (4,6) w^0 = 1
    stage2_re[0] = stage1_re[0] + stage1_re[2];
    stage2_im[0] = stage1_im[0] + stage1_im[2];
    stage2_re[2] = stage1_re[0] - stage1_re[2];
    stage2_im[2] = stage1_im[0] - stage1_im[2];

    stage2_re[4] = stage1_re[4] + stage1_re[6];
    stage2_im[4] = stage1_im[4] + stage1_im[6];
    stage2_re[6] = stage1_re[4] - stage1_re[6];
    stage2_im[6] = stage1_im[4] - stage1_im[6];

    // (1,3) and (5,7) with twiddle multiplication
    ap_int<31> tmp_re, tmp_im;

    // (1,3) w^1 = -j
    tmp_re = -stage1_im[3];
    tmp_im =  stage1_re[3];
    stage2_re[1] = stage1_re[1] + tmp_re;
    stage2_im[1] = stage1_im[1] + tmp_im;
    stage2_re[3] = stage1_re[1] - tmp_re;
    stage2_im[3] = stage1_im[1] - tmp_im;

    // (5,7) w^3 = -0.7071 - j0.7071
    tmp_re = (stage1_re[7]*W3_re - stage1_im[7]*W3_im) >> (WIDTH-1);
    tmp_im = (stage1_re[7]*W3_im + stage1_im[7]*W3_re) >> (WIDTH-1);
    stage2_re[5] = stage1_re[5] + tmp_re;
    stage2_im[5] = stage1_im[5] + tmp_im;
    stage2_re[7] = stage1_re[5] - tmp_re;
    stage2_im[7] = stage1_im[5] - tmp_im;

    // --- Stage 3: size-8 butterflies ---
    ap_int<31> mul_re, mul_im;

    out_re0 = stage2_re[0] + stage2_re[4];
    out_im0 = stage2_im[0] + stage2_im[4];
    out_re4 = stage2_re[0] - stage2_re[4];
    out_im4 = stage2_im[0] - stage2_im[4];

    // (1,5) w^1
    mul_re = (stage2_re[5]*W1_re - stage2_im[5]*W1_im) >> (WIDTH-1);
    mul_im = (stage2_re[5]*W1_im + stage2_im[5]*W1_re) >> (WIDTH-1);
    out_re1 = stage2_re[1] + mul_re;
    out_im1 = stage2_im[1] + mul_im;
    out_re5 = stage2_re[1] - mul_re;
    out_im5 = stage2_im[1] - mul_im;

    // (2,6) w^2
    mul_re = (stage2_re[6]*W2_re - stage2_im[6]*W2_im) >> (WIDTH-1);
    mul_im = (stage2_re[6]*W2_im + stage2_im[6]*W2_re) >> (WIDTH-1);
    out_re2 = stage2_re[2] + mul_re;
    out_im2 = stage2_im[2] + mul_im;
    out_re6 = stage2_re[2] - mul_re;
    out_im6 = stage2_im[2] - mul_im;

    // (3,7) w^3
    mul_re = (stage2_re[7]*W3_re - stage2_im[7]*W3_im) >> (WIDTH-1);
    mul_im = (stage2_re[7]*W3_im + stage2_im[7]*W3_re) >> (WIDTH-1);
    out_re3 = stage2_re[3] + mul_re;
    out_im3 = stage2_im[3] + mul_im;
    out_re7 = stage2_re[3] - mul_re;
    out_im7 = stage2_im[3] - mul_im;
}