`timescale 1ns/1ps
import systolic_array_pkg::*;

module systolic_array (
    input  logic                     clk,
    input  logic                     rst_n,
    input  logic                     load_w,
    input  weight_t                  weight_in [N][N],
    input  data_t                    a_in      [N],
    output logic [N*ACC_WIDTH-1:0]   psum_out_flat
);
    data_t       a_wire    [N][N+1];
    out_matrix_t psum_wire [N+1][N];

    genvar r, c;

    generate
        for (r = 0; r < N; r++) begin : row_edge
            assign a_wire[r][0] = a_in[r];
        end
        for (c = 0; c < N; c++) begin : col_edge
            assign psum_wire[0][c] = '0;
        end

        for (r = 0; r < N; r++) begin : rows
            for (c = 0; c < N; c++) begin : cols
                PE pe_inst (
                    .clk      (clk),
                    .rst_n    (rst_n),
                    .load_w   (load_w),
                    .w_in     (weight_in[r][c]),
                    .a_in     (a_wire[r][c]),
                    .psum_in  (psum_wire[r][c]),
                    .a_out    (a_wire[r][c+1]),
                    .psum_out (psum_wire[r+1][c])
                );
            end
        end

        for (c = 0; c < N; c++) begin : out_edge
            assign psum_out_flat[c*ACC_WIDTH +: ACC_WIDTH] = psum_wire[N][c];
        end
    endgenerate
endmodule