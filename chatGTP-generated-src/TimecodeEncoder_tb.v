module TimecodeEncoder_TB;

  reg [3:0] hours;
  reg [6:0] minutes;
  reg [6:0] seconds;
  reg [23:0] frames;
  wire [79:0] timecode;

  TimecodeEncoder dut (
    .hours(hours),
    .minutes(minutes),
    .seconds(seconds),
    .frames(frames),
    .timecode(timecode)
  );

  initial begin
    $dumpfile("timecode_encoder_tb.vcd");
    $dumpvars(0, TimecodeEncoder_TB);

    hours = 3'b011; // Example input values
    minutes = 7'b0010101;
    seconds = 7'b0101100;
    frames = 24'b101011101100110010101100;

    #10;
    $finish;
  end

endmodule
