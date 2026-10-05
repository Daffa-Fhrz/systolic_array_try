`timescale 1ns/1ps
import systolic_array_pkg::*;

module PE (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  load_w,
    input  logic [DATA_WIDTH-1:0] a_in,
    input  logic [DATA_WIDTH-1:0] w_in,
    input  logic [ACC_WIDTH-1:0]  psum_in,
    output logic [ACC_WIDTH-1:0]  psum_out,
    output logic [DATA_WIDTH-1:0] a_out
);
    logic [DATA_WIDTH-1:0] weight_reg;
    logic [ACC_WIDTH-1:0]  product;

    assign product = ACC_WIDTH'(a_in) * ACC_WIDTH'(weight_reg);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)       weight_reg <= '0;
        else if (load_w)  weight_reg <= w_in;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            psum_out <= '0;
            a_out    <= '0;
        end else begin
            psum_out <= psum_in + product;
            a_out    <= a_in;
        end
    end
endmodule