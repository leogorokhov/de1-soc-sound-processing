module part1 (
    input  CLOCK_50, CLOCK2_50,
    input  [0:0] KEY,

    // I2C Audio/Video config interface
    output       FPGA_I2C_SCLK,
    inout        FPGA_I2C_SDAT,

    // Audio CODEC
    output       AUD_XCK,
    input        AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK,
    input        AUD_ADCDAT,
    output       AUD_DACDAT
);
    // Local wires.
    wire         read_ready, write_ready;
    wire         read, write;
    wire [23:0]  readdata_left,  readdata_right;
    wire [23:0]  writedata_left, writedata_right;
    wire         reset = ~KEY[0];

    // -------------------------
    // loopback: adc -> dac
    // -------------------------
    // просто подаем принятые сэмплы на выход
    assign writedata_left  = readdata_left;
    assign writedata_right = readdata_right;

    // одноклочные «стробы»: читаем и пишем, когда обе стороны готовы
    wire do_xfer = read_ready & write_ready;
    assign read  = do_xfer;
    assign write = do_xfer;

    // -------------------------
    // такт на кодек
    // -------------------------
    clock_generator my_clock_gen (
        .CLOCK2_50 (CLOCK2_50),
        .reset     (reset),
        .AUD_XCK   (AUD_XCK)
    );

    // конфигурация WM8731 по I2C
    audio_and_video_config cfg (
        .clk       (CLOCK_50),
        .reset     (reset),
        .I2C_SDAT  (FPGA_I2C_SDAT),
        .I2C_SCLK  (FPGA_I2C_SCLK)
    );

    // аудио интерфейс
    audio_codec codec (
        .clk            (CLOCK_50),
        .reset          (reset),

        .read           (read),
        .write          (write),
        .writedata_left (writedata_left),
        .writedata_right(writedata_right),

        .AUD_ADCDAT     (AUD_ADCDAT),

        .AUD_BCLK       (AUD_BCLK),
        .AUD_ADCLRCK    (AUD_ADCLRCK),
        .AUD_DACLRCK    (AUD_DACLRCK),

        .read_ready     (read_ready),
        .write_ready    (write_ready),
        .readdata_left  (readdata_left),
        .readdata_right (readdata_right),

        .AUD_DACDAT     (AUD_DACDAT)
    );

endmodule