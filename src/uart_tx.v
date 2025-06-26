`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.06.2025 11:00:14
// Design Name: 
// Module Name: UART_Tx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_tx( 
    input clk_3125, 
    input parity_type, tx_start, 
    input [7:0] data, 
    output reg tx, tx_done
);

// State machine states
localparam IDLE = 3'd0, START = 3'd1, DATA = 3'd2, 
           PARITY = 3'd3, STOP = 3'd4, DONE = 3'd5;
           
reg [2:0] state = IDLE;
reg [3:0] counter = 0;  
reg [2:0] bit_cnt = 0;
reg parity_bit = 0;
reg [7:0] shift_reg = 0;

always @(posedge clk_3125) begin
    case(state)
        IDLE: begin
            tx <= 1'b1;
            tx_done <= 0;
            counter <= 0;
            if (tx_start) begin
                shift_reg <= data;
                parity_bit <= parity_type ? ~(^data) : (^data);
                bit_cnt <= 0;
                state <= START;
            end
        end
        
        START: begin
            tx <= 1'b0;
            if (counter == 13) begin
                counter <= 0;
                state <= DATA;
            end else begin
                counter <= counter + 1;
            end
        end
        
        DATA: begin
            tx <= shift_reg[7];  //MSB
            if (counter == 13) begin   
                counter <= 0;
                shift_reg <= shift_reg << 1;  //Left shift
                bit_cnt <= bit_cnt + 1;
                if (bit_cnt == 7) begin  
                    state <= PARITY;
                end
            end else begin
                counter <= counter + 1;
            end
        end
        
        PARITY: begin
            tx <= parity_bit;
            if (counter == 13) begin
                counter <= 0;
                state <= STOP;
            end else begin
                counter <= counter + 1;
            end
        end
        
        STOP: begin
            tx <= 1'b1;
            if (counter == 13) begin  
                counter <= 0;
                tx_done <= 1;
                state <= DONE;
            end else begin
                counter <= counter + 1;
            end
        end
        
        DONE: begin
            tx_done <= 0;
            state <= IDLE;
        end
        
        default: state <= IDLE;
    endcase
end

endmodule



//At first we read and understood the given test bench
//then implemented a 6-state FSM (IDLE, START, DATA, PARITY, STOP, DONE) to sequence transmission phases, ensuring precise timing control.
//Used a 14-cycle counter (counter[3:0]) at 3125 Hz to time each bit duration (14 cycles/bit = ~223 baud), leveraging clock division for bit timing.
//Pre-computed parity during IDLE state using: parity_bit = parity_type ? ~(^data) : (^data) (Supports both even/odd parity based on parity_type)
//Then Employed an 8-bit shift register for serialization. Bit counter (bit_cnt[2:0]) tracks transmitted bits during DATA state
//tx drives output with appropriate bit values per state, tx_done pulses high in STOP state to indicate completion

