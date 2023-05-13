module PSKDecoderWithClockDetection_TB;

  reg clk;
  reg psk_signal;
  wire decoded_data;
  
  // Instantiate the module under test
  PSKDecoderWithClockDetection dut (
    .clk(clk),
    .psk_signal(psk_signal),
    .decoded_data(decoded_data)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Stimulus
  initial begin
    clk = 0;
    psk_signal = 0;
    #10;

    // Send PSK-encoded signal with known clock rate
    #10 psk_signal = 1;
    #10 psk_signal = 0;
    #10 psk_signal = 1;
    #10 psk_signal = 0;
    #10 psk_signal = 1;

    // Wait for decoding to start
    #200;

    // Send PSK-encoded data at the detected clock rate
    repeat (10) begin
      #100 psk_signal = ~psk_signal;
    end

    // End simulation
    #10 $finish;
  end

endmodule
