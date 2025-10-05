module DE10_Standard_golden_top(
    input              CLOCK2_50,
    input              CLOCK3_50,
    input              CLOCK4_50,
    input              CLOCK_50,

    input       [3:0]  KEY,       
    input       [9:0]  SW,       

    output      [9:0]  LEDR,

    output      [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,

    output             DRAM_CLK, DRAM_CKE,
    output     [12:0]  DRAM_ADDR,
    output      [1:0]  DRAM_BA,
    inout      [15:0]  DRAM_DQ,
    output             DRAM_LDQM, DRAM_UDQM,
    output             DRAM_CS_N, DRAM_WE_N, DRAM_CAS_N, DRAM_RAS_N,

    input              TD_CLK27, TD_HS, TD_VS,
    input       [7:0]  TD_DATA,
    output             TD_RESET_N,

    output             VGA_CLK, VGA_HS, VGA_VS,
    output      [7:0]  VGA_R, VGA_G, VGA_B,
    output             VGA_BLANK_N, VGA_SYNC_N,

    inout              AUD_BCLK,
    inout              AUD_ADCLRCK,
    inout              AUD_DACLRCK,
    output             AUD_XCK,
    input              AUD_ADCDAT,
    output             AUD_DACDAT,

    inout              PS2_CLK, PS2_CLK2, PS2_DAT, PS2_DAT2,

    output             ADC_SCLK,
    input              ADC_DOUT,
    output             ADC_DIN,
    output             ADC_CONVST,

    output             FPGA_I2C_SCLK,
    inout              FPGA_I2C_SDAT,

    inout      [35:0]  GPIO,

    output             IRDA_TXD,
    input              IRDA_RXD
);

    wire reset = ~KEY[0];

	 
	 wire [9:0] demo_ledr;
    wire [6:0] demo_hex0;
	 
	 
    clock_generator u_clkgen (
        .CLOCK2_50 (CLOCK2_50),
        .reset     (reset),
        .AUD_XCK   (AUD_XCK)
    );

    audio_and_video_config u_cfg (
        .clk       (CLOCK2_50),
        .reset     (reset),
        .I2C_SDAT  (FPGA_I2C_SDAT),
        .I2C_SCLK  (FPGA_I2C_SCLK)
    );

	 
	 led_hex_demo u_demo (
    .clkIn  (CLOCK2_50),
    .rst_n  (KEY[0]),       
    .divide (SW[3:0]),      
    .enable (SW[8]),       
    .LEDR   (demo_ledr),
    .HEX0   (demo_hex0)
);

    localparam integer AUDIO_DATA_WIDTH = 24;

    wire                        read_ready, write_ready;
    wire [AUDIO_DATA_WIDTH-1:0] readdata_left, readdata_right;
    reg                         read_pulse, write_pulse;
    reg  [AUDIO_DATA_WIDTH-1:0] writedata_left, writedata_right;

    audio_codec #(
        .AUDIO_DATA_WIDTH (AUDIO_DATA_WIDTH)
    ) u_audio (
        .clk             (CLOCK2_50),
        .reset           (reset),

        .read            (read_pulse),
        .write           (write_pulse),
        .writedata_left  (writedata_left),
        .writedata_right (writedata_right),

        .AUD_ADCDAT      (AUD_ADCDAT),
        .AUD_BCLK        (AUD_BCLK),
        .AUD_ADCLRCK     (AUD_ADCLRCK),
        .AUD_DACLRCK     (AUD_DACLRCK),

        .read_ready      (read_ready),
        .write_ready     (write_ready),
        .readdata_left   (readdata_left),
        .readdata_right  (readdata_right),

        .AUD_DACDAT      (AUD_DACDAT)
    );

    wire [3:0] pitch_shift = SW[3:0];

    reg        swap_mode;
    reg  [1:0] key1_sync;
    wire       key1_pressed_edge;

    localparam integer DEBOUNCE_MAX = 500_000; 
    reg [18:0] db_cnt1;
    reg        key1_stable;

    always @(posedge CLOCK2_50 or posedge reset) begin
        if (reset) begin
            db_cnt1     <= 19'd0;
            key1_stable <= 1'b1;
        end else if (KEY[1] != key1_stable) begin
            if (db_cnt1 == DEBOUNCE_MAX-1) begin
                key1_stable <= KEY[1];
                db_cnt1     <= 19'd0;
            end else begin
                db_cnt1 <= db_cnt1 + 1'b1;
            end
        end else begin
            db_cnt1 <= 19'd0;
        end
    end

    always @(posedge CLOCK2_50 or posedge reset) begin
        if (reset) key1_sync <= 2'b11;
        else       key1_sync <= { key1_sync[0], key1_stable };
    end
    assign key1_pressed_edge = (key1_sync[1] == 1'b1) && (key1_sync[0] == 1'b0);

    always @(posedge CLOCK2_50 or posedge reset) begin
        if (reset) swap_mode <= 1'b0;
        else if (key1_pressed_edge) swap_mode <= ~swap_mode;
    end

    reg [23:0] lfsrL;
    reg [23:0] lfsrR;

    localparam integer NOISE_SHIFT = 4;

    wire signed [23:0] noiseL = $signed(lfsrL) >>> NOISE_SHIFT;
    wire signed [23:0] noiseR = $signed(lfsrR) >>> NOISE_SHIFT;

    wire signed [23:0] baseL = swap_mode ? $signed(readdata_right[23:0])
                                         : $signed(readdata_left [23:0]);
    wire signed [23:0] baseR = swap_mode ? $signed(readdata_left [23:0])
                                         : $signed(readdata_right[23:0]);
    wire signed [23:0] addL  = (~KEY[2]) ? noiseL : 24'sd0;
    wire signed [23:0] addR  = (~KEY[2]) ? noiseR : 24'sd0;

    wire signed [24:0] sumL_ext = $signed({baseL[23], baseL}) + $signed({addL[23], addL});
    wire signed [24:0] sumR_ext = $signed({baseR[23], baseR}) + $signed({addR[23], addR});

    wire [23:0] mixL_sat = (sumL_ext[24:23]==2'b01) ? 24'h7FFFFF :
                           (sumL_ext[24:23]==2'b10) ? 24'h800000 :
                                                       sumL_ext[23:0];

    wire [23:0] mixR_sat = (sumR_ext[24:23]==2'b01) ? 24'h7FFFFF :
                           (sumR_ext[24:23]==2'b10) ? 24'h800000 :
                                                       sumR_ext[23:0];

    reg led_flow;
	 
	 wire pitch_clk;
	 
	 sm_clk_divider #(
		.shift(10)
	 ) pitch_div (
	 
		.clkIn(CLOCK2_50),
		.rst_n(~reset),
		.devide(pitch_shift),
		.enable(1'b1),
		.clkOut (pitch_clk)
	 );

    always @(posedge pitch_clk or posedge reset) begin
        if (reset) begin
            read_pulse      <= 1'b0;
            write_pulse     <= 1'b0;
            writedata_left  <= 24'sd0;
            writedata_right <= 24'sd0;
            led_flow        <= 1'b0;
            lfsrL           <= 24'h5AEC3D;
            lfsrR           <= 24'hC3197B;
        end else begin
            read_pulse  <= 1'b0;
            write_pulse <= 1'b0;

            if (read_ready && write_ready) begin
                lfsrL <= (lfsrL==24'd0) ? 24'h5AEC3D
                                        : ({1'b0, lfsrL[23:1]} ^ (lfsrL[0] ? 24'h0E0002 : 24'h0));
                lfsrR <= (lfsrR==24'd0) ? 24'hC3197B
                                        : ({1'b0, lfsrR[23:1]} ^ (lfsrR[0] ? 24'h0D0008 : 24'h0));
                writedata_left  <= mixL_sat;
                writedata_right <= mixR_sat;

                read_pulse  <= 1'b1;
                write_pulse <= 1'b1;
                led_flow    <= ~led_flow;
            end
        end
    end

    assign LEDR = SW[8] ? demo_ledr
                    : {7'b0, ~KEY[2], swap_mode, led_flow};

assign HEX0 = SW[8] ? demo_hex0 : 7'h7F;

    assign VGA_CLK     = 1'b0;
    assign VGA_HS      = 1'b0;
    assign VGA_VS      = 1'b0;
    assign VGA_R       = 8'b0;
    assign VGA_G       = 8'b0;
    assign VGA_B       = 8'b0;
    assign VGA_BLANK_N = 1'b0;
    assign VGA_SYNC_N  = 1'b0;

    assign TD_RESET_N  = 1'b0;

    assign DRAM_CLK    = 1'b0;
    assign DRAM_CKE    = 1'b0;
    assign DRAM_ADDR   = 13'b0;
    assign DRAM_BA     = 2'b0;
    assign DRAM_LDQM   = 1'b0;
    assign DRAM_UDQM   = 1'b0;
    assign DRAM_CS_N   = 1'b1;
    assign DRAM_WE_N   = 1'b1;
    assign DRAM_CAS_N  = 1'b1;
    assign DRAM_RAS_N  = 1'b1;

    assign ADC_SCLK    = 1'b0;
    assign ADC_DIN     = 1'b0;
    assign ADC_CONVST  = 1'b0;

    assign IRDA_TXD    = 1'b0;

    // неиспользуемые INOUT — в высокоомное состояние
    assign GPIO        = {36{1'bz}};
    assign PS2_CLK     = 1'bz;
    assign PS2_DAT     = 1'bz;
    assign PS2_CLK2    = 1'bz;
    assign PS2_DAT2    = 1'bz;

endmodule
