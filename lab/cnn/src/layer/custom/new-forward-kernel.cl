#define TILE_WIDTH 16

__kernel void do_not_remove_this_kernel() {
    int tx = get_local_id(0);
    tx = tx + 1;
}

__kernel void prefn_marker_kernel() {
    int tx = get_local_id(0);
    tx = tx + 1;
}

__kernel void conv_forward_kernel(__global float *y, __constant float *x, __constant float *k, const int B, const int M, const int C, const int H, const int W, const int K)
{
    /*
    Modify this function to implement the forward pass described in Chapter 16.
    We have added an additional dimension to the tensors to support an entire mini-batch
    The goal here is to be correct AND fast.
    We have some nice #defs for you below to simplify indexing. Feel free to use them, or create your own.
    */

    const int H_out = H - K + 1;
    const int W_out = W - K + 1;

// An example use of these macros:
// float a = y4d(0,0,0,0)
// y4d(0,0,0,0) = a
#define y4d(i3, i2, i1, i0) y[(i3) * (M * H_out * W_out) + (i2) * (H_out * W_out) + (i1) * (W_out) + i0]
#define x4d(i3, i2, i1, i0) x[(i3) * (C * H * W) + (i2) * (H * W) + (i1) * (W) + i0]
#define k4d(i3, i2, i1, i0) k[(i3) * (C * K * K) + (i2) * (K * K) + (i1) * (K) + i0]

    int W_grid = (W_out + TILE_WIDTH - 1) / TILE_WIDTH;
    int H_grid = (H_out + TILE_WIDTH - 1) / TILE_WIDTH;

    int b = get_global_id(2);
    int m = get_group_id(0);
    int h = (get_group_id(1) / H_grid) * TILE_WIDTH + get_local_id(1);
    int w = (get_group_id(1) % W_grid) * TILE_WIDTH + get_local_id(0);

    if (h < H_out && w < W_out) {
        y4d(b, m, h, w) = 0.0f;
        for (int c = 0; c < C; ++c) {
            for (int p = 0; p < K; ++p) {
                for (int q = 0; q < K; ++q) {
                    y4d(b, m, h, w) += x4d(b, c, h+p, w+q) * k4d(m, c, p, q);
                }
            }
        }
    }


#undef y4d
#undef x4d
#undef k4d
}

