module TimecodeEncoder(
  input wire [3:0] hours,
  input wire [6:0] minutes,
  input wire [6:0] seconds,
  input wire [23:0] frames,
  output reg [79:0] timecode
);

  always @* begin
    timecode = {1'b1, hours, minutes, seconds, frames};
    timecode[79:64] = ~timecode[79:64]; // Invert the first 16 bits for checksum calculation
    timecode[63:56] = ~(timecode[7:0] + timecode[15:8] + timecode[23:16] + timecode[31:24] +
                        timecode[39:32] + timecode[47:40] + timecode[55:48] + timecode[63:56]); // Calculate checksum
  end

endmodule
