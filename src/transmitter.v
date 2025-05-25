`include "baud_controller.v"

module uart_transmitter(reset, clk, Tx_DATA, baud_select, Tx_WR, Tx_EN, TxD, Tx_BUSY, test_parity);
input reset, clk;
input [7:0] Tx_DATA;
input [2:0] baud_select;
input Tx_EN;
input Tx_WR;
input test_parity;
output TxD;
output Tx_BUSY;

reg TxD;
reg Tx_BUSY;
wire Tx_sample_ENABLE;
reg [2:0] currentState;
reg [2:0] nextState;
reg [3:0] counter;
wire [10:0] message;
wire parity_bit;


reg [4:0] bits_counter;

reg enable_baud;

parameter OFF=3'b000,
          ENABLE_BAUD=3'b001,
          START_BIT=3'b010,
          SEND_DATA=3'b011,
          PARITY_BIT=3'b100,
          STOP_BIT=3'b101;


baud_controller baud_controller_tx_inst(reset, clk, baud_select, Tx_sample_ENABLE, enable_baud);

/*parity bit with xor operator. If number of ones is even the bit is 0, if it's odd it's 1*/
assign parity_bit= (test_parity) ? ~(^Tx_DATA) : ^Tx_DATA;

/*assign the whole uart message to a variable*/
assign message={1'b0, Tx_DATA[7:0], parity_bit, 1'b1};

/*sequential always block to change states*/
always@(posedge clk)
    begin
        if(reset) begin
            currentState<=OFF;
        end
        else    
            currentState<=nextState;
    end

/*combinational always block for the output and next state logic of the FSM*/
always@(currentState or Tx_EN or Tx_WR or bits_counter or message)
    begin        
        //Default cases
        nextState=OFF;
        TxD=1'b1;
        enable_baud=1'b0;
        Tx_BUSY=1'b0;
        
        case(currentState)
            OFF: //transmitter is off
                begin
                    Tx_BUSY=1'b0;
                    TxD=1'b1;
                    
                    if(Tx_EN) //transmitter turns on
                        nextState=ENABLE_BAUD;
                    else
                        nextState=OFF;
                end

            //a enable_baud/idle state that enables the baud controller in the
            //right time so there are no issues in the sychronisation of the communication.
            ENABLE_BAUD: //transmitter is on but it doesn't send data
                begin
                    Tx_BUSY=1'b0;
                    TxD=1'b1;

                    if(Tx_WR) begin
                        nextState=START_BIT;
                        enable_baud=1'b1;
                    end
                    else
                        nextState=ENABLE_BAUD;
                end

            START_BIT:
                begin
                    enable_baud=1'b0;
                    Tx_BUSY=1'b1;
                    TxD=message[10-bits_counter];

                    if(bits_counter==1)
                        nextState=SEND_DATA;
                    else
                        nextState=START_BIT;
                end

            SEND_DATA:
                begin
                    Tx_BUSY=1'b1;
                    TxD=message[10-bits_counter];

                    if(bits_counter==8)
                        nextState=PARITY_BIT;
                    else
                        nextState=SEND_DATA;
                end

            PARITY_BIT:
                begin
                    Tx_BUSY=1'b1;                
                    TxD=message[10-bits_counter];

                    if(bits_counter==9)
                        nextState=STOP_BIT;
                    else
                        nextState=PARITY_BIT;
                end

            STOP_BIT:
                begin
                    Tx_BUSY=1'b1;                
                    TxD=message[10-bits_counter];

                    if(bits_counter==10)
                        nextState=ENABLE_BAUD;
                    else
                        nextState=STOP_BIT;
                end
        endcase
    end


//an always blobk that counts 16 pulses of the Tx_sample_ENABLE,
//so the transmitter can send a bit based on the baud rate.
always@(posedge clk or posedge reset)
    begin
        if(reset)
            begin
                counter <= 4'b0000;
                bits_counter <= 0;
            end
        else begin
            if(Tx_sample_ENABLE)
                    counter<=counter+1;
            
            if(counter==4'b1111)
                begin
                    bits_counter<=bits_counter+1; //a bit was sent
                    counter<=4'b0000;
                end

            if(currentState==ENABLE_BAUD) begin //reset the bits_counter when a symbol has been sent
                bits_counter <=0;
                counter<=4'b0000;
            end
        end
    end
endmodule
