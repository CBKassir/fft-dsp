#include "fft8.hpp"
#include <iostream>

int main() {
    ap_int<WIDTH> in_re[N] = {1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000};
    ap_int<WIDTH> in_im[N] = {0,0,0,0,0,0,0,0};

    ap_int<WIDTH> out_re[N];
    ap_int<WIDTH> out_im[N];

    fft8(
        in_re, in_im,
        out_re[0], out_im[0],
        out_re[1], out_im[1],
        out_re[2], out_im[2],
        out_re[3], out_im[3],
        out_re[4], out_im[4],
        out_re[5], out_im[5],
        out_re[6], out_im[6],
        out_re[7], out_im[7]
    );

    std::cout << "FFT Output:\n";
    for(int i = 0; i < N; i++) {
        std::cout << "Y[" << i << "] = " << (int)out_re[i] << " + j" << (int)out_im[i] << "\n";
    }
    return 0;
}