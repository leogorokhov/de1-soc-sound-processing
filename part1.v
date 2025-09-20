module part1 (CLOCK_50, CLOCK2_50, KEY, FPGA_I2C_SCLK, FPGA_I2C_SDAT, AUD_XCK, 
		        AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT, AUD_DACDAT);

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
	
	// Local wires.
	reg read_ready, write_ready, read, write;
	reg [23:0] readdata_left, readdata_right;
	reg [23:0] writedata_left, writedata_right;
	wire reset = ~KEY[0];

	/////////////////////////////////
	// Your code goes here 
	/////////////////////////////////

	wire [15:0] noise;
noise_gen ng (
    .clk   (CLOCK_50),
	.reset (reset),
    .noise (noise)
);
	always @(posedge CLOCK_50 or posedge reset) begin
		if (reset) begin
        writedata_left  <= 16'd0;
        writedata_right <= 16'd0;
        write     <= 1'b0;
    end else begin
        if (read) begin
            reg [15:0] L, R;
            L = readdata_left;
            R = readdata_right;

			// KEY[1] — mute левого канала
			if (~KEY[1]) L = 16'd0;

			// KEY[2] — swap каналов
			if (~KEY[2]) begin
                L = readdata_right;
                R = readdata_left;
            end

			// KEY[3] — добавить шум
			if (~KEY[3]) begin
                L = L + noise;
                R = R + noise;
            end

            // записываем в выходной FIFO
            writedata_left  <= L;
            writedata_right <= R;
            write     <= 1'b1;
        end else write  <= 1'b0;
    end
end

/*	
assign writedata_left  = readdata_left;
assign writedata_right = readdata_right;
assign write = read_ready && write_ready;
assign read = read_ready; */
	/*
	assign writedata_left = ... not shown
	assign writedata_right = ... not shown
	assign read = ... not shown
	assign write = ... not shown
	*/
	
	wire read_ready_w, write_ready_w, read_w, write_w;
	wire [23:0] readdata_left_w, readdata_right_w;
	wire [23:0] writedata_left_w, writedata_right_w;
	
	assign read_ready_w = read_ready;
	assign write_ready_w = write_ready;
	assign read_w = read;
	assign write_w = write;
	assign readdata_left_w = readdata_left;
	assign readdata_right_w = readdata_right;
	assign writedata_left_w = writedata_left;
	assign writedata_right_w = writedata_right;
	
/////////////////////////////////////////////////////////////////////////////////
// Audio CODEC interface. 
//
// The interface consists of the following wires:
// read_ready, write_ready - CODEC ready for read/write operation 
// readdata_left, readdata_right - left and right channel data from the CODEC
// read - send data from the CODEC (both channels)
// writedata_left, writedata_right - left and right channel data to the CODEC
// write - send data to the CODEC (both channels)
// AUD_* - should connect to top-level entity I/O of the same name.
//         These signals go directly to the Audio CODEC
// I2C_* - should connect to top-level entity I/O of the same name.
//         These signals go directly to the Audio/Video Config module
/////////////////////////////////////////////////////////////////////////////////
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


