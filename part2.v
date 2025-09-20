module part2 (CLOCK_50, CLOCK2_50, KEY, FPGA_I2C_SCLK, FPGA_I2C_SDAT, AUD_XCK, 
		        AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT, AUD_DACDAT, SW, HEX0, HEX1, HEX2, HEX3);

  input CLOCK_50, CLOCK2_50;
	input [0:3] KEY;
	// I2C Audio/Video config interface
	output FPGA_I2C_SCLK;
	inout FPGA_I2C_SDAT;
	// Audio CODEC
	output AUD_XCK;
	input AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK;
	input AUD_ADCDAT;
	output AUD_DACDAT;
  input [0:7] SW;
  input HEX0;
  input HEX1;
  input HEX2;
  input HEX3;
	
	// Local wires.
	reg read_ready, write_ready, read, write;
	reg [23:0] readdata_left, readdata_right;
	reg [23:0] writedata_left, writedata_right;
	
	wire read_ready_w, write_ready_w, read_w, write_w;
	wire [23:0] readdata_left_w, readdata_right_w;
	wire [23:0] writedata_left_w, writedata_right_w;
	


wire reset = ~KEY[0];
//---------------------------------------------------------
// Подключение делителя частоты
//---------------------------------------------------------
wire slow_clk;
sm_clk_divider #(
    .shift(16),
    .bypass(0)
) div_inst (
    .clkIn   (CLOCK_50),
    .rst_n   (reset),
    .divide  (SW[0:3]),    // нижние переключатели задают делитель
    .enable  (1'b1),
    .clkOut  (slow_clk)
);

//---------------------------------------------------------
// LED индикация (бегущий счетчик)
//---------------------------------------------------------
reg [9:0] led_reg;
  always @(posedge slow_clk or posedge reset) begin
    if (reset)
        led_reg <= 10'b0;
    else
        led_reg <= led_reg + 1;
end
assign LEDR = led_reg;

//---------------------------------------------------------
// HEX индикация (счетчик в HEX0..HEX3)
//---------------------------------------------------------
reg [15:0] hex_counter;
  always @(posedge slow_clk or posedge reset) begin
    if (reset)
        hex_counter <= 16'd0;
    else
        hex_counter <= hex_counter + 1;
end

// HEX-дешифраторы (если hex_decoder уже есть в проекте)
sm_hex_display h0(hex_counter[3:0],   HEX0);
sm_hex_display h1(hex_counter[7:4],   HEX1);
sm_hex_display h2(hex_counter[11:8],  HEX2);
sm_hex_display h3(hex_counter[15:12], HEX3);

//---------------------------------------------------------
// Регулировка тональности звука
//---------------------------------------------------------
// используем SW[7:4] для выбора шага pitch
reg [3:0] pitch_shift;
always @(*) pitch_shift = SW[4:7];

  
// счётчик для управления выборкой
reg [15:0] sample_cnt;
  always @(posedge CLOCK_50 or posedge reset) begin
    if (reset) begin
        sample_cnt <= 0;
        writedata_left  <= 0;
        writedata_right <= 0;
        write_ready     <= 0;
    end else if (read_ready) begin
        sample_cnt <= sample_cnt + 1;
        // только на определённых шагах выдаём сэмпл (меняем частоту выборки)
        if (sample_cnt[pitch_shift]) begin
            // сюда можно добавить mute/swap/noise как раньше
            writedata_left  <= readdata_left;
            writedata_right <= readdata_right;
            write_ready     <= 1'b1;
        end else write_ready     <= 1'b0;
    end else write_ready     <= 1'b0;
end

	assign read_ready_w = read_ready;
	assign write_ready_w = write_ready;
	assign read_w = read;
	assign write_w = write;
	assign readdata_left_w = readdata_left;
	assign readdata_right_w = readdata_right;
	assign writedata_left_w = writedata_left;
	assign writedata_right_w = writedata_right;

	clock_generator my_clock_gen(
		// inputs
		CLOCK2_50,
		reset,

		// outputs
		AUD_XCK
	);

	audio_and_video_config cfg(
		// Inputs
		CLOCK_50,
		reset,

		// Bidirectionals
		FPGA_I2C_SDAT,
		FPGA_I2C_SCLK
	);

	audio_codec codec(
		// Inputs
		CLOCK_50,
		reset,

		read,	write,
		writedata_left, writedata_right,

		AUD_ADCDAT,

		// Bidirectionals
		AUD_BCLK,
		AUD_ADCLRCK,
		AUD_DACLRCK,

		// Outputs
		read_ready_w, write_ready_w,
		readdata_left_w, readdata_right_w,
		AUD_DACDAT
	);
	

endmodule
