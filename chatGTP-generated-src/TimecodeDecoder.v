module TimecodeDecoder(
  input wire clk,
  input wire rst,
  input wire [79:0] timecode,
  output reg [3:0] hours,
  output reg [6:0] minutes,
  output reg [6:0] seconds,
  output reg [23:0] frames,
  output reg valid
);

  reg [3:0] hours_reg;
  reg [6:0] minutes_reg;
  reg [6:0] seconds_reg;
  reg [23:0] frames_reg;
  reg valid_reg;
  
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      hours_reg <= 0;
      minutes_reg <= 0;
      seconds_reg <= 0;
      frames_reg <= 0;
      valid_reg <= 0;
    end
    else begin
      if (timecode[79] && checkPacket(timecode)) begin
        // Valid timecode detected with a valid packet
        valid_reg <= 1;
        hours_reg <= timecode[78:75];
        minutes_reg <= timecode[74:68];
        seconds_reg <= timecode[67:61];
        frames_reg <= timecode[60:37];
      end
      else begin
        valid_reg <= 0;
      end
    end
  end
  
  always @(posedge clk) begin
    if (rst) begin
      hours <= 0;
      minutes <= 0;
      seconds <= 0;
      frames <= 0;
      valid <= 0;
    end
    else begin
      // Output the values from the registers
      hours <= hours_reg;
      minutes <= minutes_reg;
      seconds <= seconds_reg;
      frames <= frames_reg;
      valid <= valid_reg;
    end
  end
  
  function automatic bit checkPacket(input wire [79:0] packet) ;
    integer i;
    reg [7:0] checksum;
    begin
      checksum = 8'h00;
      for (i = 0; i < 8; i = i + 1) begin
        checksum = checksum + packet[i * 8 +: 8];
      end
      if (checksum == 8'hFF)
        return 1;
      else
        return 0;
    end
  endfunction

endmodule
