`timescale 1ns / 1ps

module cic #(
    parameter M=2,
    parameter N=4,
    parameter R=512,
    parameter Bin=2,
    parameter Bmax=42
)
(
    input signed [Bin-1:0] data_in,
    input clk, rst, enable,
    output signed [19:0] data_out,
    output outready
);

    wire signed [Bmax-1:0] data_ext = $signed(data_in);
    reg signed [Bmax-1:0] intreg [N-1:0];
    
    // For M=2, comb section needs a 2-stage delay per stage: [stage][0=1-delay, 1=2-delay]
    reg signed [Bmax-1:0] del [N-1:0][1:0];
    reg signed [Bmax-1:0] dif [N-1:0];
    
    reg [8:0] count;
    assign outready = (count == 9'd511);
    
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 0;
            for (i = 0; i < N; i = i + 1) begin
                intreg[i] <= 0;
                dif[i] <= 0;
                del[i][0] <= 0;
                del[i][1] <= 0;
            end
        end
        else if (enable) begin
            // Integrator sections
            intreg[0] <= intreg[0] + data_ext;
            for (i = 1; i < N; i = i + 1) begin
                intreg[i] <= intreg[i] + intreg[i-1];
            end
            
            count <= count + 1;
            
            // Comb sections (executed at decimated output rate when outready is high)
            if (outready) begin
                // Stage 0 M=2 comb
                dif[0] <= intreg[N-1] - del[0][1];
                del[0][1] <= del[0][0];
                del[0][0] <= intreg[N-1];

                // Stages 1 to N-1 M=2 comb
                for (i = 1; i < N; i = i + 1) begin
                    dif[i] <= dif[i-1] - del[i][1];
                    del[i][1] <= del[i][0];
                    del[i][0] <= dif[i-1];
                end
            end
        end
    end

    // Extracts the top 20 bits of the 42-bit bus
    assign data_out = dif[N-1][Bmax-1 : Bmax-20];

endmodule