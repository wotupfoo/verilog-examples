// ------------------------------------------------------------------------------------------------------
// Differential Manchester (DM aka Biphase Mark Code (BMC) aka FM aka Freq/DoubleFreq (F2F) decode
// ------------------------------------------------------------------------------------------------------
// NOTE: The counter widths and timing constants assume a 100kHz reference clock input
module differential_manchester_decode
#(  // Params
    parameter CLOCK = 1000000,      // Clock is 1Mhz by default
    parameter BPS = 2400,           // For LTC, at 30fps and 10byte (80bit) packet = 30 * 80 = 2400bps max rate
    parameter OVERSAMPLING_BITS = 4 // For the clock to be somewhat accurate at least 16 (2^4). 32 (2^5) is better
) 
(   // Interface
    input  rst,                     // Reset
    input  clk,                     // Clock - 1MHz
    input  signal,                  // DM encoded input signal
    output reg nosignal,            // No DM detected
    output reg sda,                 // Recovered data
    output reg sck,                 // Recovered clock
    output reg [9:0] sck_width      // Width of recovered clock (in 1uS) - assumes a 1MHz global clk for the width
);

localparam OVERSAMPLING = $pow(2,OVERSAMPLING_BITS);    // Binary value of 2^OVERSAMPLING_BITS
localparam CLOCKDIVIDER = (CLOCK/(BPS*OVERSAMPLING));   // BPS * OVERSAMPLING = 2400*4=9600 ~= 1MHz/CLOCKDIVIDER => 1000000/104 = 9615.38
//localparam CLOCKDIVIDER_BITS = $clog2(CLOCKDIVIDER)+1;  // Bits needed to express CLOCKDIVIDER
localparam CLOCKDIVIDER_BITS = 7;  // Bits needed to express CLOCKDIVIDER

reg [CLOCKDIVIDER_BITS:0] clk_cnt;  // Used to covert clk -> sample_clk
reg sample_clk;                     // clk / OVERSAMPLING

reg sck_done;                       // Signal to show that the SCK has already toggled inside a long (1) signal pulse
reg [OVERSAMPLING_BITS:0] sda_cnt;  // Counter, in OVERSAMPLE units, of SDA
reg [OVERSAMPLING_BITS:0] sck_cnt;  // Counter, in OVERSAMPLE units, of SCK

reg [9:0] signal_width;             // Width between signal edges (0.1023 in 1uS)

// Async input signal -> clocked domain logic
reg [2:0] signalreg;    // A 3 bit register to align the input signal to the FPGA clock logic
wire signal_risingedge;
wire signal_fallingedge;

assign signal_risingedge  = (signalreg[2:1]==2'b01);  // _-x signal rising edge
assign signal_fallingedge = (signalreg[2:1]==2'b10);  // -_x signal falling edge

// Reset handler and global clock domain operations (from clk)
always @(posedge clk)
begin
    if(rst == 1'b1)
    begin
        clk_cnt <= 0;
        sample_clk <= 0;
        sda_cnt <= 0;
        sck_cnt <= 0;
        nosignal <= 1;
        sck_width <= OVERSAMPLING/2;
        signalreg <= 0;
        sda <= 0;
        sck <= 0;
        sck_done <= 0;
    end else begin
        // Handle async signal conversion to clk domain
        signalreg <= {signalreg[1:0], signal};
        // Increment clock counters
        clk_cnt <= clk_cnt + 1;
        if(clk_cnt == CLOCKDIVIDER) clk_cnt <= 0;
        sample_clk <= (clk_cnt == 0);
    end
end

always @(posedge sample_clk)
begin
    sda_cnt <= sda_cnt + 1;
    if(sda_cnt == OVERSAMPLING-1) nosignal <= 1;

    // Handle SCK mid-bit if the signal is late or a long "one" (vs short "zero")
    sck_cnt <= sck_cnt + 1;
    if(sck_cnt == sck_width)
    begin
        if(sck_done == 0)
            begin
                sck <= ~sck;
                sck_cnt <= 0;
                sck_done <= 1;
            end
    end
end

always @(posedge signal_risingedge or posedge signal_fallingedge)
    begin
        // Handle SDA
        nosignal <= 0;
        signal_width <= sda_cnt;
        sda_cnt <= 0;
        //if(signal_risingedge == 1'b1) sda <= 1'b1;
        //if(signal_fallingedge == 1'b1) sda <= 1'b0;
        sda <= ~sda;

        // Handle SCK
        sck <= ~sck;
        sck_done <= 0;
        if(sck_cnt < sck_width)    // Signal arrived early
            begin
                sck_width <= sck_cnt;
            end
        sck_cnt <= 0;

        // Reset the clocks to synchronize to the newly detect edge
        clk_cnt <= 0;
        sck_cnt <= 0;
    end

endmodule   // differential_manchester_decode

