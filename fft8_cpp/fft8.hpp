#ifndef FFT8_H
#define FFT8_H

#include <ap_int.h>

#define WIDTH 16
#define N 8

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
);

#endif