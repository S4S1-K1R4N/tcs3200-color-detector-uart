`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module tb_top_module;

    reg clk_1MHz = 0;
    reg clk_3125 = 0;
    reg cs_out = 0;
    reg parity_type = 0;
    reg start_sim = 0;       // <<--- Add start_sim
    wire uart_tx_out, rx_parity, rx_complete, tx_done;
    wire [1:0] filter, color;
    wire [7:0] rx_msg;

    reg [1:0] exp_color, exp_filter;
    reg [2:0] i, j;
    integer tp, k, l, m, cs_counter;

    // UART loopback directly
    wire uart_rx_in;
    assign uart_rx_in = uart_tx_out;

    top_module uut (
        .clk_1MHz(clk_1MHz),
        .clk_3125(clk_3125),
        .cs_out(cs_out),
        .uart_rx_in(uart_rx_in),
        .parity_type(parity_type),
        .start_sim(start_sim), // <<-- connect it!
        .filter(filter),
        .color(color),
        .uart_tx_out(uart_tx_out),
        .tx_done(tx_done),
        .rx_msg(rx_msg),
        .rx_parity(rx_parity),
        .rx_complete(rx_complete)
    );

    // Generate clocks
    always #500 clk_1MHz = ~clk_1MHz;    // 1 MHz clock
    always begin
        clk_3125 = ~clk_3125; #160;
    end  // ~3.125 MHz clock

    initial begin
        // Initialization
        parity_type = 0;
        exp_filter = 2;
        exp_color = 0;
        i = 0;
        cs_out = 1;
        tp = 0;
        k = 0;
        j = 0;
        l = 0;
        m = 0;
        start_sim = 1;    // <--- start the simulation
    end

    always @(posedge clk_1MHz) begin
        m = (i%3) + 1;
        exp_filter = 3; #500000;
        exp_filter = 0; #500000;
        exp_filter = 1; #500000;
        exp_filter = 2; exp_color = (i%3) + 1;
        i = i + 1'b1; m = m + 1'b1; #1000;
    end

    always begin
        for (j=0; j<6; j=j+1) begin
            #1000;
            for (l = 0; l < 3; l=l+1) begin
                case(exp_filter)
                    0: begin
                        if (m == 1) tp = 10;
                        else tp = 16;
                    end
                    1: begin
                        if (m == 3) tp = 8;
                        else tp = 18;
                    end
                    3: begin
                        if (m == 2) tp = 12;
                        else tp = 19;
                    end
                    default: tp = 17;
                endcase
                cs_counter = 500000/(2*tp);
                for (k = 0; k < cs_counter; k=k+1) begin
                    cs_out = 1; #tp;
                    cs_out = 0; #tp;
                end
                #(500000-(cs_counter*2*tp));
            end
            #1000;
        end
    end

    // Optional: Monitor your color outputs and UART activity
    always @(posedge clk_1MHz) begin
        $display("TESTBENCH LOG - START MODE");
        #5000000
        start_sim=0;
        $display("TESTBENCH LOG - STOP MODE");
        #2000000
        start_sim=1;
        $display("TESTBENCH LOG - START MODE");
        #2000000
        $finish;
        
    end

endmodule
