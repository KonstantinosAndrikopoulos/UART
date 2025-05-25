`include "transmitter.v"
`include "receiver.v"

module uart(clk, reset, Tx_DATA, transmitter_baud_select, Tx_EN, Tx_WR, Tx_BUSY, receiver_baud_select, Rx_EN, Rx_DATA, Rx_FERROR, Rx_PERROR, Rx_VALID, test_parity);
    input clk, reset;
    
    //transmitter
    input [7:0] Tx_DATA;
    input [2:0] transmitter_baud_select;
    input Tx_EN, Tx_WR;
    input test_parity;

    output Tx_BUSY;

    //receiver
    input [2:0] receiver_baud_select;
    input Rx_EN;

    output [7:0] Rx_DATA;
    output Rx_FERROR, Rx_PERROR, Rx_VALID;
    
    wire Tx_Rx_BUS;

    uart_receiver uart_receiver_inst(
        .clk(clk),
        .reset(reset),
        .baud_select(receiver_baud_select),
        .RxD(Tx_Rx_BUS),
        .Rx_EN(Rx_EN),
        .Rx_DATA(Rx_DATA),
        .Rx_VALID(Rx_VALID),
        .Rx_FERROR(Rx_FERROR),
        .Rx_PERROR(Rx_PERROR)
    );

    uart_transmitter transmitter_inst(
        .clk(clk),
        .reset(reset),
        .Tx_DATA(Tx_DATA),
        .baud_select(transmitter_baud_select),
        .Tx_EN(Tx_EN),
        .Tx_WR(Tx_WR),
        .TxD(Tx_Rx_BUS),
        .Tx_BUSY(Tx_BUSY),
        .test_parity(test_parity)
    );

endmodule