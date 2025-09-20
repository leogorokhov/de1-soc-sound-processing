module sm_clk_divider
#(
  parameter shift  = 16,
            bypass = 0
)
(
  input           clkIn,
  input           rst_n,
  input   [ 3:0 ] divide,
  input           enable,
  output          clkOut
);
  wire [31:0] cntr;
  wire [31:0] cntrNext = cntr + 1;
  sm_register_we r_cntr(clkIn, rst_n, enable, cntrNext, cntr);

  assign clkOut = bypass ? clkIn 
                         : cntr[shift + divide];
endmodule
