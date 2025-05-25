`include "uart.v"

module uart_tb;
    reg clk, reset;
    
     //transmitter
    reg [7:0] Tx_DATA;
    reg [2:0] transmitter_baud_select;
    reg Tx_EN, Tx_WR;
    reg test_parity;

    wire Tx_BUSY;

    //receiver
    reg [2:0] receiver_baud_select;
    reg Rx_EN;

    wire [7:0] Rx_DATA;
    wire Rx_FERROR, Rx_PERROR, Rx_VALID;

    reg [2:0] currentState, nextState;
    reg enable_TxWR;

    reg [7:0] messages [3:0];
    reg [2:0] message_counter;

    reg succesfull_test_flag;
    
    uart uart_inst(
    .clk(clk),
    .reset(reset),
    .Tx_DATA(Tx_DATA),
    .transmitter_baud_select(transmitter_baud_select),
    .Tx_EN(Tx_EN),
    .Tx_WR(Tx_WR),
    .Tx_BUSY(Tx_BUSY),
    .receiver_baud_select(receiver_baud_select),
    .Rx_EN(Rx_EN),
    .Rx_DATA(Rx_DATA),
    .Rx_FERROR(Rx_FERROR),
    .Rx_PERROR(Rx_PERROR),
    .Rx_VALID(Rx_VALID),
    .test_parity(test_parity)
    );

    parameter OFF=3'b000,
              ENABLE_CHANNEL=3'b001,
              TEST_DATA=3'b010,
              TEST_PERROR=3'b011,
              TEST_FERROR=3'b100;

    always 
        begin
            #5 clk = ~clk;
        end

    initial begin
        clk=1'b0;
        reset=1'b0;
        #1000 reset=1'b1;
        #1000 reset=1'b0;

        messages[0] = 8'b10101010;
        messages[1] = 8'b01010101;
        messages[2] = 8'b11001100;
        messages[3] = 8'b10001001; 
    end

    always@(posedge clk)
    begin
        if(reset) begin
            currentState<=OFF;
            message_counter<=0;
            succesfull_test_flag<=0;
            test_parity<=0; 
        end
        else    
            currentState<=nextState;
    end

    always@(currentState or Rx_VALID or Rx_FERROR or Rx_PERROR)
        begin
            enable_TxWR=1'b0;

            case(currentState)
                OFF: begin
                    if(!succesfull_test_flag) begin
                        $display("\nTesting UART channel.\n");
                        nextState=ENABLE_CHANNEL;
                        receiver_baud_select=3'b111;
                        transmitter_baud_select=3'b111;
                    end
                end

                ENABLE_CHANNEL: begin
                    $display("\nEnabling Transmitter and Receiver.\n");
                    Rx_EN=1'b1;
                    Tx_EN=1'b1;
                    enable_TxWR=1'b1;
                    nextState=TEST_DATA;
                    $display("\nTesting the 4 messages.\n");
                end

                TEST_DATA: begin
                    
                    Tx_DATA=messages[message_counter];

                    if(Rx_VALID) begin
                        message_counter=message_counter+1;
                        enable_TxWR=1'b1;
                        $display("\nMessage %b sent succesfully\n", Rx_DATA);
                    end
                    else
                        nextState=TEST_DATA;


                    if(message_counter==4) begin
                        nextState=TEST_PERROR;
                        $display("\nTesting PERROR.\n");
                    end
                end

                TEST_PERROR: begin
                    enable_TxWR=1'b1;
                    Tx_DATA=8'b10101010;
                    test_parity=1'b1;

                    if(Rx_PERROR) begin;
                        $display("\nPERROR tested succesfully.\n");
                        test_parity=1'b0;
                        nextState=TEST_FERROR;
                        $display("\nTesting FERROR.\n");
                    end
                end

                TEST_FERROR: begin
                    enable_TxWR=1'b1;
                    Tx_DATA=8'b10101010;
                    receiver_baud_select=3'b110;
                    Rx_EN=1'b1;
                    Tx_EN=1'b1;
                    enable_TxWR=1'b1;
                    if(Rx_FERROR) begin;
                        $display("\nFERROR tested succesfully.\n");
                        succesfull_test_flag=1'b1;
                        nextState=OFF;
                    end
                end
            endcase
        end

always@(posedge clk)
    begin
        if(enable_TxWR) begin
            Tx_WR=1'b1;
        end
        else
            Tx_WR=1'b0;
    end
                 
endmodule