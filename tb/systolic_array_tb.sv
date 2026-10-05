`timescale 1ns/1ps
import systolic_array_pkg::*;

module systolic_array_tb;
    localparam int K = 6;

    logic clk = 0;
    logic rst_n;
    logic load_w;
    weight_t weight_in [N][N];
    data_t   a_in      [N];
    logic [N*ACC_WIDTH-1:0] psum_out_flat;

    int A [K][N];
    int W [N][N];
    int errors  = 0;
    int checked = 0;

    always #5 clk = ~clk;

    systolic_array dut (
        .clk(clk), .rst_n(rst_n), .load_w(load_w),
        .weight_in(weight_in), .a_in(a_in), .psum_out_flat(psum_out_flat)
    );

    initial begin
        $dumpfile("systolic_array.vcd");
        $dumpvars(0, systolic_array_tb);
    end

    function automatic int golden(int k, int c);
        int s = 0;
        for (int r = 0; r < N; r++) s += A[k][r] * W[r][c];
        return s;
    endfunction

    task automatic run_test(string name);
        int kk;
        logic [ACC_WIDTH-1:0] got;

        @(negedge clk);
        for (int r = 0; r < N; r++)
            for (int c = 0; c < N; c++) weight_in[r][c] = W[r][c];
        load_w = 1;
        @(negedge clk);
        load_w = 0;

        // row r is delayed by r cycles, column c is read c cycles late
        for (int t = 0; t < K + 2*N; t++) begin
            for (int c = 0; c < N; c++) begin
                kk = t - N - c;
                if (kk >= 0 && kk < K) begin
                    got = psum_out_flat[c*ACC_WIDTH +: ACC_WIDTH];
                    checked++;
                    if (got !== ACC_WIDTH'(golden(kk, c))) begin
                        errors++;
                        $error("%s: y[%0d][%0d] = %0d, expected %0d",
                               name, kk, c, got, golden(kk, c));
                    end
                end
            end
            for (int r = 0; r < N; r++) begin
                kk = t - r;
                a_in[r] = (kk >= 0 && kk < K) ? data_t'(A[kk][r]) : '0;
            end
            @(negedge clk);
        end
    endtask

    initial begin
        load_w = 0;
        for (int r = 0; r < N; r++) begin
            a_in[r] = '0;
            for (int c = 0; c < N; c++) weight_in[r][c] = '0;
        end
        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;

        // test 1: identity weights
        for (int k = 0; k < K; k++) for (int r = 0; r < N; r++) A[k][r] = (k + 1) * (r + 1);
        for (int r = 0; r < N; r++) for (int c = 0; c < N; c++) W[r][c] = (r == c) ? 1 : 0;
        run_test("identity");

        // test 2: constant weights and inputs
        for (int r = 0; r < N; r++) for (int c = 0; c < N; c++) W[r][c] = 2;
        for (int k = 0; k < K; k++) for (int r = 0; r < N; r++) A[k][r] = 3;
        run_test("const");

        // test 3: random weights and inputs
        for (int r = 0; r < N; r++) for (int c = 0; c < N; c++) W[r][c] = $urandom_range(0, 255);
        for (int k = 0; k < K; k++) for (int r = 0; r < N; r++) A[k][r] = $urandom_range(0, 255);
        run_test("random");

        if (errors == 0) $display("PASS: %0d outputs checked", checked);
        else             $display("FAIL: %0d errors / %0d outputs", errors, checked);
        $finish;
    end

    initial begin
        #100000;
        $fatal(1, "timeout");
    end
endmodule