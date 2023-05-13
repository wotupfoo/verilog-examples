module PSKEncoder_TB;

  reg clk;
  reg data;
  wire psk_signal;
  
  // Instantiate the module under test
  PSKEncoder dut (
    .clk(clk),
    .data(data),
    .psk_signal(psk_signal)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Stimulus
  initial begin
    clk = 0;
    data = 0;
    #10;

    // Send data to be encoded
    #10 data = 1;
    #10 data = 0;
    #10 data = 1;
    #10 data = 0;
    #10 data = 1;

    // Wait for encoding to start
    #200;

    // Capture the encoded PSK signal
    repeat (10) begin
      #100;
    end

    // End simulation
    #10 $finish;
  end

endmodule
