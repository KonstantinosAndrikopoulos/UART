`include "baud_controller.v"

module uart_receiver(reset, clk, Rx_DATA, baud_select, Rx_EN, RxD, Rx_PERROR, Rx_FERROR, Rx_VALID);
input reset, clk;
input [2:0] baud_select;
input Rx_EN;
input RxD;
output [7:0] Rx_DATA;
output Rx_FERROR; // Framing Error //
output Rx_PERROR; // Parity Error //
output Rx_VALID; // Rx_DATA is Valid //

wire Rx_sample_ENABLE;
reg [2:0] currentState, nextState;
reg enable_baud;
reg prev_Rx_D;

//reg [3:0] counter;

reg [3:0] sample_counter, same_sample;
reg valid_sampling_signal, data_read;
reg [3:0] data_counter;
reg [2:0] bits_counter;

reg [7:0] Rx_DATA;
reg Rx_FERROR, Rx_PERROR, Rx_VALID;

reg sample_signal;
reg sample_value;
reg start_sample;

reg [7:0] prev_DATA;
reg prev_VALID, prev_FERROR, prev_PERROR, prev_sample;
reg [2:0] prev_bits_counter;

parameter START_SAMPLING=4'b0100,
          STOP_SAMPLING=4'b1100;

parameter OFF=3'b000,
          ENABLE_BAUD=3'b001,
          READ_START=3'b010,
          READ_DATA=3'b011,
          READ_PARITY=3'b100,
          READ_STOP=3'b101;

baud_controller baud_controller_rx_inst(reset, clk, baud_select, Rx_sample_ENABLE, enable_baud);

always@(posedge clk)
    begin
        prev_DATA=Rx_DATA;
        prev_VALID=Rx_VALID;
        prev_FERROR=Rx_FERROR;
        prev_PERROR=Rx_PERROR;
        prev_bits_counter=bits_counter;
        prev_sample=sample_value;
    end

always@(posedge clk)
    begin
        if(reset) begin
            currentState<=OFF;
        end
        else    
            currentState<=nextState;
    end

always@(currentState or Rx_EN or RxD or sample_counter or sample_signal)
    begin
    nextState=currentState;
    enable_baud=1'b0;
    Rx_PERROR=1'b0;
    Rx_FERROR=1'b0;
    Rx_VALID=1'b0;
    Rx_DATA=8'b0;
    start_sample=1'b0;
    bits_counter=0;
    sample_value=1'b0;
//    bits_counter=0;
    
        case(currentState)
            OFF: begin
                Rx_DATA=8'd0;
                Rx_VALID=1'b0;
                Rx_FERROR=1'b0;
                Rx_PERROR=1'b0;
                start_sample=1'b0;
                bits_counter=0;
                sample_value=1'b0;

                if(Rx_EN)
                    nextState=ENABLE_BAUD;
                else
                    nextState=OFF;
            end

            ENABLE_BAUD: begin
                Rx_DATA=prev_DATA;
                Rx_VALID=prev_VALID;
                Rx_FERROR=prev_PERROR;
                Rx_PERROR=prev_PERROR;
                start_sample=1'b0;
                bits_counter=0;
                sample_value=1'b0;
                
                if(!RxD)
                    begin
                        enable_baud=1'b1;
                        nextState=READ_START;
                        start_sample=1'b1;
                    end
                else
                    nextState=ENABLE_BAUD;

            end

            READ_START: begin
                Rx_DATA=8'd0;
                Rx_VALID=1'b0;
                Rx_FERROR=1'b0;
                Rx_PERROR=1'b0;
                start_sample=1'b0;
                bits_counter=0;
                sample_value=prev_sample;

                if(sample_counter==4'b1111)
                    begin
                        nextState=READ_DATA;
                        start_sample=1'b1;
                    end
                 
                if(sample_signal) begin
                    if(RxD) begin
                        Rx_FERROR=1'b1;
                        nextState=OFF;
                    end
                end
            end

            READ_DATA: begin
                Rx_DATA=prev_DATA;
                Rx_VALID=prev_VALID;
                Rx_FERROR=1'b0;
                Rx_PERROR=1'b0;
                start_sample=1'b0;
                bits_counter=prev_bits_counter;
                sample_value=prev_sample;

                if(sample_counter==START_SAMPLING)
                    sample_value=RxD;
                    
                if(sample_signal) begin
                    if(RxD!=sample_value) begin
                        Rx_FERROR=1'b1;
                        nextState=OFF;
                    end
                end
                
                if(sample_counter==4'b1111) begin
                    Rx_DATA[7-bits_counter]=sample_value;
                    start_sample=1'b1;
            
                    if(bits_counter==7) begin
                        nextState=READ_PARITY;
                    end
                    else
                        bits_counter=bits_counter+1;
                    
                end

            end

            READ_PARITY: begin
                Rx_DATA=prev_DATA;
                Rx_VALID=prev_VALID;
                Rx_FERROR=1'b0;
                Rx_PERROR=1'b0;
                start_sample=1'b0;
                bits_counter=0;
                sample_value=prev_sample;

                if(sample_counter==START_SAMPLING)
                    sample_value=RxD;

                if(sample_signal) begin
                    if(RxD!=sample_value) begin
                        Rx_FERROR=1'b1;
                        nextState=OFF;
                    end
                end

                if(sample_counter==4'b1111) begin
                    if((^Rx_DATA)!=sample_value) begin
                        Rx_PERROR=1'b1;
                        nextState=OFF;
                    end

                    nextState=READ_STOP;
                    start_sample=1'b1;
                end

            end

            READ_STOP: begin
                Rx_DATA=prev_DATA;
                Rx_VALID=prev_VALID;
                Rx_FERROR=1'b0;
                Rx_PERROR=1'b0;
                start_sample=1'b0;
                bits_counter=0;
                sample_value=prev_sample;

                if(sample_counter==START_SAMPLING)
                    sample_value=RxD;

                if(sample_signal) begin
                    if(RxD!=sample_value) begin
                        Rx_FERROR=1'b1;
                        nextState=OFF;
                    end
                end

                if(sample_counter==4'b1111) begin
                    nextState=ENABLE_BAUD;
                    Rx_VALID=1'b1;
                end
            end

            default:
                begin
                    Rx_VALID = prev_VALID;
                    Rx_DATA = prev_DATA;
                    Rx_FERROR = prev_VALID;
                    Rx_PERROR = prev_PERROR;
                    start_sample=1'b0;
                    bits_counter=0;
                    sample_value=1'b0;
                end

        endcase
    end

always@(posedge clk)
    begin
        if(start_sample)
            begin
                sample_counter<=0;
                sample_signal<=0;
            end
        else if(Rx_sample_ENABLE)
            begin
                sample_counter<=sample_counter+1;

                if(sample_counter==START_SAMPLING)
                    sample_signal<=1'b1;

                if(sample_counter==STOP_SAMPLING)
                    sample_signal<=1'b0;
            end

    end
endmodule
