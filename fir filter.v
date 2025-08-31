`timescale 1ns/1ps

module fir_filter_nonpipelined(
    input clk,
    input reset,
    input signed [16:0] x_in,
    input signed [16:0] h [0:122],
    output reg signed [160:0] y_out
);
    
    reg signed [16:0] x_shift_reg [0:122];
    reg signed [33:0] mult_out [0:122];
    reg signed [160:0] sum;
    integer i;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i <= 122; i = i + 1) begin
                x_shift_reg[i] <= 17'b0;
            end
            y_out <= 160'b0;
        end else begin
            // Shift the input values
            for(i = 122; i > 0; i = i - 1) begin
                x_shift_reg[i] <= x_shift_reg[i - 1];
            end
            x_shift_reg[0] <= x_in;
            
            // Perform filtering computation in one clock cycle
            
            sum = 0;
            #1;
            for(i = 0; i <= 122; i = i + 1) begin
                mult_out[i] = $signed(h[i]) * $signed(x_shift_reg[i]);
            end
            #2; sum = mult_out[0] + mult_out[1];
            for(i = 2; i <= 122; i = i + 1) begin
                #2; sum = sum + mult_out[i];
            end

            y_out <= sum;
        end
    end
endmodule


module fir_filter_nonpipelined_tb();
    reg clk, reset;
    reg signed [16:0] x_in;
    reg signed [160:0] y_out;

    reg signed [16:0] sine_100Hz [14521:0];
    reg signed [16:0] sine_2000Hz [841:0];
    reg signed [16:0] sine_6000Hz [361:0];
    reg signed [16:0] sine_11000Hz [251:0];

    reg signed [16:0] h [0:122];

    reg signed [160:0] y_100 [14521:0];
    reg signed [160:0] y_2000 [841:0];
    reg signed [160:0] y_6000 [361:0];
    reg signed [160:0] y_11k [251:0];

    fir_filter_nonpipelined uut(
        .clk(clk),
        .reset(reset),
        .x_in(x_in),
        .y_out(y_out),
        .h(h)
    );

    always #250 clk = ~clk;

    integer j;
    integer file;
    integer status;

    initial begin
        clk = 0;
        reset = 1;
        x_in = 17'b0;

        file = $fopen("coeff_binary.txt", "r");
        for (j = 0; j <= 122; j = j + 1) begin
            status = $fscanf(file, "%b", h[j]);
        end
        $fclose(file);

        file = $fopen("sine_binary.txt", "r");
        for (j = 0; j < 14400; j = j + 1) begin
            status = $fscanf(file, "%b", sine_100Hz[j]);
        end
        for (j = 0; j < 720; j = j + 1) begin
            status = $fscanf(file, "%b", sine_2000Hz[j]);
        end
        for (j = 0; j < 240; j = j + 1) begin
            status = $fscanf(file, "%b", sine_6000Hz[j]);
        end
        for (j = 0; j < 130; j = j + 1) begin
            status = $fscanf(file, "%b", sine_11000Hz[j]);
        end
        $fclose(file);

        #2500 reset = 0;
        for (j = 0; j <= 14521; j = j + 1) begin
            x_in = sine_100Hz[j];
            #500;
            y_100[j] = y_out;
        end

        reset = 1;
        #1000; reset = 0;
        for (j = 0; j < 841; j = j + 1) begin
            x_in = sine_2000Hz[j];
            #500;
            y_2000[j] = y_out;
        end

        reset = 1;
        #1000; reset = 0;
        for (j = 0; j < 361; j = j + 1) begin
            x_in = sine_6000Hz[j];
            #500;
            y_6000[j] = y_out;
        end

        reset = 1;
        #100; reset = 0;
        for (j = 0; j <= 251; j = j + 1) begin
            x_in = sine_11000Hz[j];
            #500;
            y_11k[j] = y_out;
        end

        file = $fopen("100hz_nonpipe.txt", "w");
        for(j = 0; j <= 14521; j = j + 1) begin
            $fwrite(file, "%.14f\n", $signed(y_100[j])/2.0**28);
        end
        $fclose(file);

        file = $fopen("2000hz_nonpipe.txt", "w");
        for(j = 0; j <= 841; j = j + 1) begin
            $fwrite(file, "%.14f\n", $signed(y_2000[j])/2.0**28);
        end
        $fclose(file);

        file = $fopen("6000hz_nonpipe.txt", "w");
        for(j = 0; j <= 361; j = j + 1) begin
            $fwrite(file, "%.14f\n", $signed(y_6000[j])/2.0**28);
        end
        $fclose(file);

        file = $fopen("11khz_nonpipe.txt", "w");
        for(j = 0; j <= 251; j = j + 1) begin
            $fwrite(file, "%.14f\n", $signed(y_11k[j])/2.0**28);
        end
        $fclose(file);

        #500;
        $finish;
    end
endmodule
