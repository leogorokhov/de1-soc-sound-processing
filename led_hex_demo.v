module led_hex_demo (
    input        clkIn,      
    input        rst_n,      
    input  [3:0] divide,     // скорость
    input        enable,     
    output [9:0] LEDR,       
    output [6:0] HEX0        
);

    wire slow_clk;
    sm_clk_divider #(.shift(16)) u_div (
        clkIn,
        rst_n,
        divide,
        1'b1,       
        slow_clk
    );

    reg [9:0] led_run = 10'b0000000001;

    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n)
            led_run <= 10'b0000000001;
        else if (led_run == 10'b1000000000)
            led_run <= 10'b0000000001;    
        else
            led_run <= led_run << 1;      
    end

    reg [3:0] hex_cnt = 4'h0;
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n)
            hex_cnt <= 4'h0;
        else
            hex_cnt <= hex_cnt + 4'h1;
    end

    wire [6:0] hex0_segments;
    sm_hex_display u_hex0 (
        .digit          (hex_cnt),
        .seven_segments (hex0_segments) 
    );

    assign LEDR = enable ? led_run       : 10'b0;
    assign HEX0 = enable ? hex0_segments : 7'h7F;

endmodule