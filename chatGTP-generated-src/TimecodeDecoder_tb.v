module TimecodeDecoder_TB;

  reg clk;
  reg rst;
  reg [79:0] timecode;
  wire [3:0] hours;
  wire [6:0] minutes;
  wire [6:0] seconds;
  wire [23:0] frames;
  wire valid;

  TimecodeDecoder dut (
    .clk(clk),
    .rst(rst),
    .timecode(timecode),
    .hours(hours),
    .minutes(minutes),
    .seconds(seconds),
    .frames(frames),
    .valid(valid)
  );

  initial begin
    $dumpfile("timecode_decoder_tb.vcd");
    $dumpvars(0, TimecodeDecoder_TB);

    clk = 0;
    rst = 1;
    timecode = 80'b00000000000000000000000000000000000000000000000000000000000000000000000000000;

    #10;
    rst = 0;
    timecode = 80'b11100011101010101010101010101010011111111111111111111111111111111111111111111;

    #100;
    timecode = 80'b00000000000000000000000000000000000000000000000000000000000000000000000000000;

    #10;
    $finish;
  end

  always begin
    #5 clk = ~clk;
  end

endmodule
