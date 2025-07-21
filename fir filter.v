module filter (

);
    reg signed [15:0] coeffs [122:0]; //registers for storing data
    reg signed [15:0] inputx [144:0]; //(5/f1)*48000(sampling frequency) is the number of samples(2400) + 122 samples of padded zeroes
    reg signed [15:0] outputy[144:0];

    integer r,file_coeffs,file_input;
    integer opfile;

    integer i;
    reg signed [31:0]hold;

    initial begin //padding zeroes here for input and output
        for (integer j=0 ;j<122;j++ ) begin
            inputx[j] = 0;
            outputy[j] = 0;
        end
     
        i=0;
        file_coeffs=$fopen("coeffs.txt","r");
        while (i<123) begin

            if ($fscanf(file_coeffs, "%d\n", r) == 1) begin
                coeffs[i] = r;
                //$display("%d", coeffs[i]);
                i++;
            end

            //coeffs[i]=$fscanf(file_coeffs,"%d\n",r);
            //$display("%0d\n",coeffs[i]);
            //i++;
        end
        file_input=$fopen("y4.txt","r");
        i=0;
        //$display("Displaying input values\n");
        while(i<22) begin
            if($fscanf(file_input,"%d,",r)==1) begin
                inputx[i+122]=r;
                
                //$display("%d\n",inputx[i+122]);
                i++;
            end
        end

        
        //$display("%d\n%d",inputx[123],coeffs[0]);

    opfile= $fopen("output4.txt","w");
    
    i=0;
    //Implementing the FIR filtering equation below:
    while (i<122) begin
        hold = 32'd0;

        for (integer k = 0  ;k<123 ;k++ ) begin
            hold = hold + (inputx[k+i]*coeffs[122-k]);
        end
        //outputy[122+i]=hold[31:16];
        outputy[122 + i] = hold >>> 14; // shifting to round off to Q(2,14)
        //$display("%d",outputy[122+i]);
        $fwrite(opfile,"%d\n",outputy[122+i]);
        i++;
        
    end


    end
    

    //$readmemb("coeffs.txt",coeffs);
endmodule