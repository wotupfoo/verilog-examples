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
    output reg [9:0] sck_width_us   // Width of recovered clock (in 1uS) - assumes a 1MHz global clk for the width
);

localparam OVERSAMPLING = $pow(2,OVERSAMPLING_BITS);    // Binary value of 2^OVERSAMPLING_BITS
localparam CLOCKDIVIDER = (CLOCK/(BPS*OVERSAMPLING));   // BPS * OVERSAMPLING = 2400*4=9600 ~= 1MHz/CLOCKDIVIDER => 1000000/104 = 9615.38
//localparam CLOCKDIVIDER_BITS = $clog2(CLOCKDIVIDER)+1;  // Bits needed to express CLOCKDIVIDER
localparam CLOCKDIVIDER_BITS = 7;  // Bits needed to express CLOCKDIVIDER

reg [CLOCKDIVIDER_BITS:0] clk_cnt;  // Used to covert clk -> sample_clk
reg oversample_clk;                 // clk / CLOCKDIVIDER -> Over Sampling clk counter

reg sck_done;                       // Signal to show that the SCK has already toggled inside a long (1) signal pulse
reg [OVERSAMPLING_BITS:0] sda_cnt;  // Counter, in OVERSAMPLE units, of SDA
reg [OVERSAMPLING_BITS:0] sck_cnt;  // Counter, in OVERSAMPLE units, of SCK
reg [OVERSAMPLING_BITS:0] sck_width;// Counter, in OVERSAMPLE units, of SCK

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
        oversample_clk <= 0;
        signalreg <= 'b000;

        sda <= 0;
        sda_cnt <= 0;
        nosignal <= 1;

        sck <= 0;
        sck_cnt <= 0;
        sck_done <= 0;
        sck_width <= 16/*OVERSAMPLING/2*/;
        sck_width_us <= 0;
    end else begin
        // Handle async signal conversion to clk domain
        signalreg <= {signalreg[1:0], signal};

        if(signal_risingedge | signal_fallingedge)
        begin
            // Handle SDA
            sda <= ~sda;
            nosignal <= 0;

            // Handle SCK
            sck <= ~sck;
            sck_done <= 0;            

            if(sck_cnt < sck_width) sck_width <= sck_cnt;    // Signal arrived early

            // Reset the clocks to synchronize to the newly detect edge
            sda_cnt <= 0;
            sck_cnt <= 0;
            clk_cnt <= 0;
            oversample_clk <= ~oversample_clk;
        end else begin
            // Inside the CLK tick
            if(clk_cnt < 52/*CLOCKDIVIDER*/)
            begin
                clk_cnt <= clk_cnt + 1;
            end else begin
                // Inside the OVERCLOCKING tick
                clk_cnt <= 0;
                oversample_clk <= ~oversample_clk;

                // Handle SDA
                sda_cnt <= sda_cnt + 1;
                if(sda_cnt == 15/*OVERSAMPLING-1*/)
                begin
                    nosignal <= 1;
                end

                // Handle SCK
                sck_cnt <= sck_cnt + 1;
                // Handle SCK mid-bit if the signal is late or a long "one" (vs short "zero")
                if(sck_cnt == sck_width)
                begin
                    sck <= ~sck;
                    sck_cnt <= 0;
                end
            end
        end
    end
end

endmodule   // differential_manchester_decode

