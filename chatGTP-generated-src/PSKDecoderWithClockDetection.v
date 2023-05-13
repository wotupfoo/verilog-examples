module PSKDecoderWithClockDetection (
  input wire clk,
  input wire psk_signal,
  output reg decoded_data
);

reg [15:0] count;
reg [15:0] prev_count;
reg sample_flag;
reg [1:0] psk_state;
reg detect_clock_rate;
reg [15:0] clock_rate;

parameter THRESHOLD = 2000; // Adjust this threshold based on the expected clock rate

always @(posedge clk) begin
  // Detect the rising or falling edge of the PSK signal
  if (psk_signal != psk_state) begin
    // Toggle the sample flag to capture the data at the edge
    sample_flag <= ~sample_flag;
  end
  
  // Increment the count on each clock cycle
  count <= count + 1;
  
  if (sample_flag) begin
    // Calculate the clock rate based on the number of clock cycles between phase changes
    clock_rate <= count - prev_count;
    // Store the current count for the next phase change
    prev_count <= count;
    
    // If the clock rate is detected, set the flag to start decoding
    if (detect_clock_rate == 0 && clock_rate > THRESHOLD) begin
      detect_clock_rate <= 1;
      decoded_data <= psk_signal;
    end
  end
  
  if (detect_clock_rate) begin
    // Update the decoded data at the detected clock rate
    if (count == clock_rate/2) begin
      decoded_data <= psk_signal;
    end
  end
  
  psk_state <= psk_signal;
end

endmodule
