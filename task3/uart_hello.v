// 8N1 UART transmitter (transmit only)
// One frame = start bit (0) + 8 data bits (LSB first) + stop bit (1)
// Each state lasts exactly one tick of `clk` (= one baud period).
//
// Usage: put a byte on txbyte and raise senddata while busy == 0.
//        The byte is latched on the tick the UART accepts it (busy goes 1).
//        Drop senddata once busy is seen, or a second frame will start.

module uart_tx_8n1 (
    input  wire       clk,       // baud-rate clock (e.g. 9600 Hz)
    input  wire [7:0] txbyte,    // byte to send
    input  wire       senddata,  // request to send (only accepted when idle)
    output wire       busy,      // 1 while a frame is being sent
    output reg        txdone,    // 1-tick pulse when frame is finished
    output wire       tx         // serial line
);

    localparam S_IDLE = 2'd0;
    localparam S_DATA = 2'd1;
    localparam S_STOP = 2'd2;

    reg [1:0] state   = S_IDLE;
    reg [7:0] shifter = 8'd0;
    reg [2:0] bit_idx = 3'd0;
    reg       txbit   = 1'b1;   // line idles high

    assign tx   = txbit;
    assign busy = (state != S_IDLE);

    always @(posedge clk) begin
        txdone <= 1'b0;

        case (state)
            S_IDLE: begin
                txbit <= 1'b1;
                if (senddata) begin
                    shifter <= txbyte;   // latch the byte
                    bit_idx <= 3'd0;
                    txbit   <= 1'b0;     // START bit
                    state   <= S_DATA;
                end
            end

            S_DATA: begin
                txbit   <= shifter[0];           // next data bit, LSB first
                shifter <= {1'b0, shifter[7:1]}; // shift right
                bit_idx <= bit_idx + 3'd1;
                if (bit_idx == 3'd7)
                    state <= S_STOP;
            end

            S_STOP: begin
                txbit  <= 1'b1;                  // STOP bit
                txdone <= 1'b1;
                state  <= S_IDLE;
            end

            default: state <= S_IDLE;
        endcase
    end
endmodule

