module regular_iir(
    input clk,
    input reset,
    input signed [16:0] x_in,
    input signed [16:0] b0 [0:47],
    input signed [16:0] b1 [0:47],
    input signed [16:0] b2 [0:47],
    input signed [16:0] a0 [0:47],
    input signed [16:0] a1 [0:47],
    input signed [16:0] a2 [0:47],
    output signed [16:0] y
);

    reg signed [39:0] t_shift_reg [0:2][0:47];
    wire signed [56:0] mult_hold [0:4][0:47];

    wire signed [56:0] sum [0:47];

    genvar i;
    generate
        for (i = 0; i <= 47; i = i + 1) begin : mult_gen
            assign mult_hold[0][i] = $signed(t_shift_reg[1][i]) * $signed(a1[i]);
            assign mult_hold[1][i] = $signed(t_shift_reg[2][i]) * $signed(a2[i]);
            assign mult_hold[2][i] = $signed(t_shift_reg[2][i]) * $signed(b2[i]);
            assign mult_hold[3][i] = $signed(t_shift_reg[1][i]) * $signed(b1[i]);
            assign mult_hold[4][i] = $signed(t_shift_reg[0][i]) * $signed(b0[i]);

            assign sum[i] = mult_hold[2][i] + mult_hold[3][i] + mult_hold[4][i];
        end
    endgenerate

    integer j;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (j = 0; j <= 47; j = j + 1) begin
                t_shift_reg[0][j] = 40'b0;
                t_shift_reg[1][j] = 40'b0;
                t_shift_reg[2][j] = 40'b0;                
            end
        end else begin
            for (j = 0; j <= 47; j = j + 1) begin
                t_shift_reg[2][j] = t_shift_reg[1][j];
                t_shift_reg[1][j] = t_shift_reg[0][j];

                if (j == 0) t_shift_reg[0][j] = x_in - ((mult_hold[0][j] + mult_hold[1][j]) >>> 14);
                else t_shift_reg[0][j] = (sum[j - 1] - (mult_hold[0][j] + mult_hold[1][j])) >>> 14;
            end
        end
    end

    assign y = (sum[47] >>> 14);
endmodule

module tb_regular_iir;
    reg clk;
    reg reset;
    reg signed [16:0] x_in;
    reg signed [16:0] b0 [0:47];
    reg signed [16:0] b1 [0:47];
    reg signed [16:0] b2 [0:47];
    reg signed [16:0] a0 [0:47];
    reg signed [16:0] a1 [0:47];
    reg signed [16:0] a2 [0:47];
    wire signed [16:0] y;

    reg signed [16:0] sine_2000 [0:1439];  
    reg signed [16:0] sine_1000 [0:2879];
    reg signed [16:0] sine_100 [0:28799];
    
    reg signed [16:0] output_2000 [0:1439];
    reg signed [16:0] output_1000 [0:2879];
    reg signed [16:0] output_100 [0:28799];

    integer i, j;
    reg [16:0] sos_matrix [0:287];

    integer f_2000, f_1000, f_100, k;

    regular_iir uut (
        .clk(clk),
        .reset(reset),
        .x_in(x_in),
        .b0(b0),
        .b1(b1),
        .b2(b2),
        .a0(a0),
        .a1(a1),
        .a2(a2),
        .y(y)
    );

    always begin
        #5 clk = ~clk; 
    end

    initial begin
        clk = 0;
        reset = 1;
        x_in = 0;

        $readmemb("iir_coeff_bin.txt", sos_matrix);
        for (i = 0; i < 48; i = i + 1) begin
            b0[i] = sos_matrix[i * 6 + 0];
            b1[i] = sos_matrix[i * 6 + 1];
            b2[i] = sos_matrix[i * 6 + 2];
            a0[i] = sos_matrix[i * 6 + 3];
            a1[i] = sos_matrix[i * 6 + 4];
            a2[i] = sos_matrix[i * 6 + 5];
        end

        $readmemb("sine_2000_bin.txt", sine_2000);
        $readmemb("sine_1000_bin.txt", sine_1000);
        $readmemb("sine_100_bin.txt", sine_100);

        for (i = 0; i < 1440; i = i + 1) begin
            output_2000[i] = 0;
        end
        for (i = 0; i < 2880; i = i + 1) begin
            output_1000[i] = 0;
        end
        for (i = 0; i < 28800; i = i + 1) begin
            output_100[i] = 0;
        end

        #5;
        for (i = 0; i < 1440; i = i + 1) begin
            x_in = sine_2000[i];
            if (i == 0) reset = 0;
            #10;
            output_2000[i] = y;
        end

        reset = 1;
        x_in = 0; #10;

        for (i = 0; i < 2880; i = i + 1) begin
            x_in = sine_1000[i];
            if (i == 0) reset = 0;
            #10;
            output_1000[i] = y;
        end

        reset = 1;
        x_in = 0; #10;

        for (i = 0; i < 28800; i = i + 1) begin
            x_in = sine_100[i];
            if (i == 0) reset = 0;
            #10;
            output_100[i] = y;
        end

        #100;

        f_2000 = $fopen("output_2000.txt", "w");
        for (k = 0; k < 1440; k = k + 1)
            $fwrite(f_2000, "%.14f\n", $signed(output_2000[k])/2.0**14);
        $fclose(f_2000);

        f_1000 = $fopen("output_1000.txt", "w");
        for (k = 0; k < 2880; k = k + 1)
            $fwrite(f_1000, "%.14f\n", $signed(output_1000[k])/2.0**14);
        $fclose(f_1000);

        f_100 = $fopen("output_100.txt", "w");
        for (k = 0; k < 28800; k = k + 1)
            $fwrite(f_100, "%.14f\n", $signed(output_100[k])/2.0**14);
        $fclose(f_100);

        $display("All outputs written.");
        $finish;
    end
endmodule