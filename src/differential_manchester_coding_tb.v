`timescale 1us/100ns

`define ONESECOND 1000000
`define HALFSECOND 500000

// ------------------------------------------------------------------------------------------------------
// Differential Manchester (DM aka Biphase Mark Code (BMC) aka FM aka Freq/DoubleFreq (F2F) decode testbench
module differential_manchester_decode_testbench();
    integer step = 0;

    reg  rst;   // global reset
    reg  clk;   // 1Mhz

    // logic for reading the LTC signal from a file as stimulas
    integer file, r, offset;
    `define SEEK_SET 0
    `define SEEK_CUR 1
    `define SEEK_END 2
    reg [7:0]signal_value;

    // ***********************************************************************************************
    // INSTANTIATE MODULES
    // ***********************************************************************************************

    // Unit Under Test signals
    wire signal_stream;             // to UUT
    wire nosignal;                  // from UUT if no signal detected
    wire sda;                       // from UUT recovered\decoded signal
    wire sck;                       // from UUT recovered clock
    wire [9:0] sck_width;           // uS width of the recovered SCK
    
    differential_manchester_decode #(
        //.CLOCK(1000000),          // Clock is 1Mhz by default
        //.BPS(2400),               // For LTC, at 30fps and 10byte (80bit) packet = 30 * 80 = 2400bps max rate
        //.OVERSAMPLING_BITS(4)     // For the clock to be somewhat accurate at least 16 (2^4). 32 (2^5) is better
    ) dmc
    (
        .rst(rst),                  // Reset
        .clk(clk),                  // Clock - 1MHz
        .signal(signal_stream),     // DM encoded input signal
        .nosignal(nosignal),        // No DM detected
        .sda(sda),                  // Recovered data
        .sck(sck),                  // Recovered clock
        .sck_width(sck_width)       // Width of recovered clock (in 1uS) - assumes a 1MHz global clk for the width
    );

    // ***********************************************************************************************
    // INITIAL STATEMENTS
    // ***********************************************************************************************

    // LTC Input stream
    initial 
        begin
            $display("Starting differential machester (DM) aka biphase mark coding (BMC) decode test");
            $dumpfile(".pio/build/simulation/differential_manchester_coding_tb.vcd");
            $dumpvars;
            //$monitor("step %d file %H offset %d sample %0H return=%d", step, file, offset, signal_value, r);
            // 10min of LTC @48kHz 8-bit mono starting at 1:00:00.00
            file = $fopen("LTC_01000000_10mins_24fps_48000x8.wav","rb");
            offset = $ftell(file);
            r = $fseek(file, 44, `SEEK_SET); // Jump past the WAV header
        end

    // Testbench stimulas defaults inc toggling global reset
    initial 
        begin
            rst <= 1'b1;
            clk <= 1'b0;
            signal_value <= 8'b0;
            #10
            rst <= 1'b0;
        end

    // ***********************************************************************************************
    // ALWAYS STATEMENTS
    // ***********************************************************************************************

    // Generate 1MHz clock
    always
        begin
            #0.5            // Wait 500nSec (1MHz tick edge change)
            clk <= ~clk;
        end

    always @(posedge clk)
        begin
            step <= step + 1;
            //$display("step = %d",step);
            // Finish simulation after running for 2.1 seconds
            //if(step == 2100000) // 2.1M 1uS steps
            //if(step ==  250000) // 250ms 
            if(step ==  50000) // 50ms 
            //if(step ==  5000) // 5ms 
                begin
                    $finish;
                end
        end

    // Generate the input signal from a raw u8 stream of values of a 48kHz LTC signal
    always
        begin
            #(`ONESECOND/48000)                 // 48kHz sample rate
            offset = $ftell(file);
            r = $fread(signal_value,file);      // 8-bit mono stream
        end
    assign signal_stream = signal_value[7];    // Convert to 1-bit stream (i.e. >128 is a logic high)

endmodule   // differential_manchester_decode_testbench
