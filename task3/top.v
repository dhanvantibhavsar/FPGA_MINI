`include "uart_hello.v"

// Sends "HELLO\r\n" once every time timer[24] goes low -> high (about every 2.8 s).

module top (
    output wire led_red,
    output wire led_blue,
    output wire led_green,
    output wire uarttx,
    input  wire hw_clk          // unused, internal oscillator is used
);

    // 1. Internal 12 MHz clock
    wire clk_12m;
    SB_HFOSC #(.CLKHF_DIV("0b10")) u_osc (
        .CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk_12m)
    );

    // 2. Slow timer
    reg [24:0] timer = 0;
    always @(posedge clk_12m) timer <= timer + 1'b1;

    wire [1:0] color_select = timer[24:23];

    // 3. 9600 Hz baud clock (12 MHz / 1250)
    localparam HALF_PERIOD = 625;
    reg       clk_9600   = 0;
    reg [9:0] baud_count = 0;
    always @(posedge clk_12m) begin
        if (baud_count == HALF_PERIOD - 1) begin
            baud_count <= 0;
            clk_9600   <= ~clk_9600;
        end else
            baud_count <= baud_count + 1'b1;
    end

    // 4. Message
    localparam LAST = 4'd6;              // index of the last character
    reg [7:0] tx_char;
    reg [3:0] idx = 0;
    always @(*) begin
        case (idx)
            4'd0: tx_char = "H";
            4'd1: tx_char = "E";
            4'd2: tx_char = "L";
            4'd3: tx_char = "L";
            4'd4: tx_char = "O";
            4'd5: tx_char = 8'h0D;       // carriage return
            default: tx_char = 8'h0A;    // line feed
        endcase
    end

    // 5. Trigger: rising edge of timer[24], synchronised to the baud clock
    reg sync1 = 0, sync2 = 0, sync3 = 0;
    always @(posedge clk_9600) begin
        sync1 <= timer[24];
        sync2 <= sync1;
        sync3 <= sync2;
    end
    wire trigger = sync2 & ~sync3;       // one baud-tick pulse

    // 6. Sender state machine (runs on the baud clock)
    localparam M_IDLE = 2'd0;   // wait for trigger
    localparam M_REQ  = 2'd1;   // hold senddata until UART says busy
    localparam M_WAIT = 2'd2;   // wait for UART to finish this character

    reg [1:0] msg_state = M_IDLE;
    reg       send      = 0;
    wire      uart_busy;

    always @(posedge clk_9600) begin
        case (msg_state)
            M_IDLE: if (trigger) begin
                idx       <= 0;
                send      <= 1;
                msg_state <= M_REQ;
            end

            M_REQ: if (uart_busy) begin
                send      <= 0;
                msg_state <= M_WAIT;
            end

            M_WAIT: if (!uart_busy) begin
                if (idx == LAST)
                    msg_state <= M_IDLE;
                else begin
                    idx       <= idx + 1'b1;
                    send      <= 1;
                    msg_state <= M_REQ;
                end
            end

            default: msg_state <= M_IDLE;
        endcase
    end

    // 7. UART
    uart_tx_8n1 DanUART (
        .clk      (clk_9600),
        .txbyte   (tx_char),
        .senddata (send),
        .busy     (uart_busy),
        .txdone   (),
        .tx       (uarttx)
    );

    // 8. RGB LED
    SB_RGBA_DRV #(
        .CURRENT_MODE ("0b1"),
        .RGB0_CURRENT ("0b000001"),
        .RGB1_CURRENT ("0b000001"),
        .RGB2_CURRENT ("0b000001")
    ) RGB_DRIVER (
        .RGBLEDEN(1'b1), .CURREN(1'b1),
        .RGB0PWM (color_select == 2'b11),
        .RGB1PWM (color_select == 2'b10),
        .RGB2PWM (color_select == 2'b01),
        .RGB0(led_green), .RGB1(led_blue), .RGB2(led_red)
    );
endmodule

