module fft4_streaming (
    input clk,
    input rst,
    input valid_in,
    input signed [7:0] xr, xi,  // 8-bit real and imaginary inputs
    output reg valid_out,
    output reg signed [15:0] yr0,
    output reg signed [15:0] yr1,
    output reg signed [15:0] yr2,
    output reg signed [15:0] yr3,
    output reg signed [15:0] yi0,
    output reg signed [15:0] yi1,
    output reg signed [15:0] yi2,
    output reg signed [15:0] yi3
      // 16-bit FFT output
);

    // Input storage
    reg signed [7:0] xr_buf [0:3], xi_buf [0:3];
    reg [1:0] sample_cnt;
    reg input_ready;
    reg stage2_init;

    // Internal signals for butterfly outputs
    reg signed [15:0] stage1_r [0:3], stage1_i [0:3];
    reg signed [15:0] stage2_r [0:3], stage2_i [0:3];


    // Input collection
    initial begin
        sample_cnt = 0;
        stage2_init = 0;
        yr0=16'd0;
        yr1=16'd0;
        yr2=16'd0;
        yr3=16'd0;
        input_ready=0;
        yi0=16'd0;
        yi1=16'd0;
        yi2=16'd0;
        yi3=16'd0;
        for (integer i =0 ;i<4 ;i++ ) begin
            stage1_r[i]=16'd0;
            stage1_i[i]=16'd0;
            stage2_r[i]=16'd0;
            stage2_i[i]=16'd0;
            xr_buf[i]=8'd0;
            xi_buf[i]=8'd0;
        end


    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sample_cnt <= 0;
            input_ready <= 0;
        end 

        else if (valid_in) begin
            xr_buf[sample_cnt] <= xr;
            xi_buf[sample_cnt] <= xi;
            sample_cnt <= sample_cnt + 1;
            if (sample_cnt == 2'd3)
                input_ready <= 1;
        end
    end

    // Stage 1: Butterfly (No twiddle)
    // y0 = x0 + x2, y1 = x1 + x3
    // y2 = x0 - x2, y3 = x1 - x3
    always @(posedge clk) begin
        if (input_ready) begin
            stage1_r[0] <= xr_buf[0] + xr_buf[2];
            stage1_i[0] <= xi_buf[0] + xi_buf[2];
            stage1_r[1] <= xr_buf[1] + xr_buf[3];
            stage1_i[1] <= xi_buf[1] + xi_buf[3];
            stage1_r[2] <= xr_buf[0] - xr_buf[2];
            stage1_i[2] <= xi_buf[0] - xi_buf[2];
            stage1_r[3] <= xr_buf[1] - xr_buf[3];
            stage1_i[3] <= xi_buf[1] - xi_buf[3];
            //$display("Stagereal1 %d %d %d %d",stage1_r[0],stage1_r[1],stage1_r[2],stage1_r[3]);

            stage2_r[0] = stage1_r[0] + stage1_r[1];
            stage2_i[0] = stage1_i[0] + stage1_i[1];
            stage2_r[2] = stage1_r[0] - stage1_r[1];
            stage2_i[2] = stage1_i[0] - stage1_i[1];

            // Y[1] = (a + jb), W1 = -j => multiply by -j = (b, -a)
            stage2_r[1] = stage1_i[3] + stage1_r[2];
            stage2_i[1] = stage1_i[2] - stage1_r[3];

            // Y[3] = (a - jb), W3 = j => multiply by j = (-b, a)
            stage2_r[3] = -stage1_i[3] + stage1_r[2];
            stage2_i[3] = stage1_i[2] + stage1_r[3];

            // Set output
            yr0 = stage2_r[0]; yi0 = stage2_i[0];
            yr1 = stage2_r[1]; yi1 = stage2_i[1];
            yr2 = stage2_r[2]; yi2 = stage2_i[2];
            yr3 = stage2_r[3]; yi3 = stage2_i[3];

            //stage2_init <= 1;
        end
    end


 

endmodule

`timescale 1ns/100ps

module tb_;

reg signed [7:0] inputreal;
reg signed [7:0] inputimag;
reg clk;
reg rst;
reg rst_n;
reg validinput;
wire validout;
wire [15:0] yreal [3:0];
wire [15:0] yimag [3:0];
wire signed [15:0] yreal0, yreal1, yreal2, yreal3;
wire signed [15:0] yimag0, yimag1, yimag2, yimag3;

 fft4_streaming uut(
    .rst(rst),
    .clk(clk),
    .valid_in(validinput),
    .valid_out(validout),
    .xr(inputreal),
    .xi(inputimag),
    .yr0(yreal0),
    .yr1(yreal1),
    .yr2(yreal2),
    .yr3(yreal3),

    .yi0(yimag0),
    .yi1(yimag1),
    .yi2(yimag2),
    .yi3(yimag3)
    
    
);


localparam CLK_PERIOD = 20;
always #(CLK_PERIOD/2) clk=~clk;

initial begin
    $dumpfile("outputwf.vcd");
    $dumpvars(0, tb_);
    $dumpvars(0, uut.stage1_r[0]);
    $dumpvars(0, uut.stage1_r[1]);
    $dumpvars(0, uut.stage1_r[2]);
    $dumpvars(0, uut.stage1_r[3]);
    $dumpvars(0, uut.stage2_r[0]);
    $dumpvars(0, uut.stage2_r[1]);
    $dumpvars(0, uut.stage2_r[2]);
    $dumpvars(0, uut.stage2_r[3]);
    $dumpvars(0, uut.xi_buf[0]);
    $dumpvars(0, uut.xi_buf[1]);
    $dumpvars(0, uut.xi_buf[2]);
    $dumpvars(0, uut.xi_buf[3]);
    $dumpvars(0, uut.xr_buf[0]);
    $dumpvars(0, uut.xr_buf[1]);
    $dumpvars(0, uut.xr_buf[2]);
    $dumpvars(0, uut.xr_buf[3]);
    $dumpvars(0, uut.input_ready);
    $dumpvars(0, uut.sample_cnt);
end

initial begin
    validinput=1;
    clk=0;
    #5;
    rst=1;
    #10
    rst=0;
    #10;
    inputreal=8'sd100;
    inputimag=8'sd0;
    #20;
    inputreal=8'sd71;
    inputimag=8'sd71;
    #20;
    inputreal= 8'sd0;
    inputimag=8'sd100;
    #20;
    inputreal= -8'sd71;
    inputimag=8'sd71;
    #10;
    validinput=0;
    #200;

    $finish;
end

endmodule
