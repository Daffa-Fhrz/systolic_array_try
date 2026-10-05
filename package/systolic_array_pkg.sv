`timescale 1ns/1ps
package systolic_array_pkg;
    localparam int DATA_WIDTH = 8;
    localparam int ACC_WIDTH  = 32;
    localparam int N          = 4;

    typedef logic [DATA_WIDTH-1:0] data_t;
    typedef logic [DATA_WIDTH-1:0] weight_t;
    typedef logic [ACC_WIDTH-1:0]  out_matrix_t;
endpackage