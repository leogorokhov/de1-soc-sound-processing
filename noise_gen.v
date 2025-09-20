//=========================================================
// Noise Generator (LFSR-based)
//=========================================================
module noise_gen (
    input        clk,
    input        reset,
    output reg [15:0] noise
);
    reg [15:0] lfsr;

    always @(posedge clk or posedge reset) begin
        if (reset)
            lfsr <= 16'hACE1;   // seed
        else begin
            // taps: 16,14,13,11 (XOR feedback)
            lfsr <= {lfsr[14:0], 
                     lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
        end
    end

    always @(*) begin
        noise = lfsr;
    end
endmodule
