`timescale 1ns / 1ps

module uart_rx(
    input clk_3125,
    input rx,
    output reg [7:0] rx_msg,
    output reg rx_parity,
    output reg rx_complete
);

// State definitions
localparam INIT = 2'b00;
localparam IDLE = 2'b01;
localparam RECEIVE = 2'b10;

reg [1:0] state = INIT;
reg [7:0] bit_cycle_count = 0;  // Changed to 8-bit
reg [7:0] data_reg = 0;
reg parity_reg = 0;
reg stop_reg = 0;

initial begin
    rx_msg = 8'h00;
    rx_parity = 1'b0;
    rx_complete = 1'b0;
end

always @(posedge clk_3125) begin
    case (state)

        
        IDLE: begin
            rx_complete <= 1'b0;
            
            // Wait for start bit (falling edge)
            if (rx == 1'b0) begin
                state <= RECEIVE;
                bit_cycle_count <= 2;
                data_reg <= 8'h00;
            end
        end
        
        RECEIVE: begin
            bit_cycle_count <= bit_cycle_count + 1;
            
            // Sample at specific cycles (middle of each bit)
            case (bit_cycle_count)
                8'd7: ; // start bit - no action needed
                8'd21: data_reg[7] <= rx;
                8'd35: data_reg[6] <= rx;
                8'd49: data_reg[5] <= rx;
                8'd63: data_reg[4] <= rx;
                8'd77: data_reg[3] <= rx;
                8'd91: data_reg[2] <= rx;
                8'd105: data_reg[1] <= rx;
                8'd119: data_reg[0] <= rx;
                8'd133: parity_reg <= rx;
                8'd147: stop_reg <= rx;
            endcase
            
            // Complete frame after 154 cycles
            if (bit_cycle_count == 8'd154) begin
                // Validate frame and set outputs
                if (stop_reg == 1'b1) begin  // Valid stop bit
                    rx_parity <= parity_reg;
                    // Check parity: XOR of all data bits should equal parity bit
                    if (parity_reg == (^data_reg)) begin
                        rx_msg <= data_reg;  // Parity correct
                        rx_complete <= 1'b1;
                    end else begin
                        rx_msg <= 8'h3F;    // Parity error - output '?'
                        rx_complete <= 1'b1;
                    end
                end else begin  // Framing error (stop bit not high)
                    rx_msg <= 8'h00;        // Framing error - output '?'
                    rx_parity <= parity_reg;
                end
                state <= IDLE;
            end else begin
                rx_complete <= 1'b0;
            end
        end
        
        default: begin
            state <= IDLE;
        end
    endcase
end

endmodule

