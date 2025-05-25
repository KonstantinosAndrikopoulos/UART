module baud_controller(reset, clk, baud_select, sample_ENABLE, enable_baud);
input reset, clk;
input [2:0] baud_select;
input enable_baud;
output sample_ENABLE;

//reg [16:0] baud_rate; //17 bits for beaud rate to reachfrom the min 300 to the 115200 max baudrate
reg [31:0] clk_counter_div;
reg [31:0] clk_counter;
reg sample_ENABLE;

wire [31:0] sampling_freq;

parameter CLOCKS_300=333333,
          CLOCKS_1200=83333,
          CLOCKS_4800=20833,
          CLOCKS_9600=10417,
          CLOCKS_19200=5208,
          CLOCKS_38400=2604,
          CLOCKS_57600=1736,
          CLOCKS_115200=868;

/*we divide the 100Mhz clock of the board with
the bit rate we need to see in how many pulses of
the board's clock a baud rate pulse should be enabled*/
always@(baud_select)
    begin
        case(baud_select)
            3'b000: clk_counter_div = CLOCKS_300;
            3'b001: clk_counter_div = CLOCKS_1200;
            3'b010: clk_counter_div = CLOCKS_4800;
            3'b011: clk_counter_div = CLOCKS_9600;
            3'b100: clk_counter_div = CLOCKS_19200;
            3'b101: clk_counter_div = CLOCKS_38400;
            3'b110: clk_counter_div = CLOCKS_57600;
            3'b111: clk_counter_div = CLOCKS_115200;
            default: clk_counter_div = 0;
        endcase
    end

/*we need the baud rate to output the (1/16)*(1/baud_rate) period
so we divide the above divisors by 16*/
assign sampling_freq = clk_counter_div >> 4;

/*an always that sends a sample enable signal every
time the original clock pulses as many times as the
sampling frequency*/
always@(posedge clk or posedge reset)
    begin
        if(reset || enable_baud) 
            begin
                clk_counter<=0;
                sample_ENABLE<=0;
            end
        else 
            begin
                if(clk_counter==(sampling_freq-1))
                    begin
                        sample_ENABLE<=1'b1;
                        clk_counter<=0;
                    end
                else
                    begin
                        sample_ENABLE<=1'b0;
                        clk_counter<=clk_counter+1;
                    end
            end
    end

endmodule
