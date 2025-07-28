`timescale 1ns / 1ps

module t1b_cd_fd (
    input clk_1MHz,
    input cs_out,
    output reg [1:0] filter,   // 0=Red, 1=Green, 3=Blue, 2=Done
    output reg [1:0] color     // 1=Red, 2=Green, 3=Blue
);
    reg [8:0] g_stop = 498 ;
    reg [9:0] r_stop = 998 ;
    reg [10:0] b_stop = 1498 ;
    reg [3:0] state = 0;
    reg [5:0] red_count, green_count, blue_count;
    reg [5:0] pulse_counter = 0;
    reg [10:0] delay_counter = 0;
    initial color = 2'd0 ;

     always @(posedge cs_out) begin
         if (delay_counter >496 && delay_counter < g_stop ) begin
           pulse_counter <= pulse_counter + 1;
           green_count <= pulse_counter;
          end
          
          if ( delay_counter == 901) pulse_counter <= 0 ;
          
          if (delay_counter >996 && delay_counter < r_stop ) begin
           pulse_counter <= pulse_counter + 1;
           red_count <= pulse_counter;
          end
         
          if ( delay_counter == 1400) pulse_counter <= 0 ;
          
          if (delay_counter >1496 && delay_counter < b_stop ) begin
           pulse_counter <= pulse_counter + 1;
           blue_count <= pulse_counter;
//           pulse_counter = 0 ;
          end
          
           if ( delay_counter == 1498) pulse_counter <= 0 ;
         
         end
    // Count pulses on cs_out in each phase
//    always @(posedge cs_out) begin
//         pulse_counter <= pulse_counter + 1;
//    end
   

    always @(posedge clk_1MHz) begin
        delay_counter <= delay_counter + 1;
    
    
    
   
        case (state)
            0: begin
               filter <= 2'd3; // green
               state <= 1;
              end
               
                
            1:   begin
                
                if (delay_counter > g_stop) begin state <= 2;  end
                else  state <= 1 ;
                
                end
           
            2: begin
//                red_count <= pulse_counter;
//                pulse_counter <= 0;
                filter <= 2'd0; // red
                state <= 3 ; 
                end
            3:     
                begin
                 if (delay_counter > r_stop) begin state <= 4;  end
                else  state <= 3 ;
                
            end
            
            4: begin
//                green_count <= pulse_counter;
//                pulse_counter <= 0;
                filter <= 2'd1; // blue
                state <= 5 ;
                end
                
            5:  begin  
                if (delay_counter > b_stop) begin state <=6 ;  end
                else  state <= 5 ;
                end
            
            6: begin
//                blue_count <= pulse_counter;
//                pulse_counter <= 0;
                filter <= 2'd2; // Compare
                state <= 7;
          
                // Determine dominant color
                if (red_count >= green_count && red_count >= blue_count)
                    color <= 2'd1; // Red
                else if (green_count >= red_count && green_count >= blue_count)
                    color <= 2'd2; // Green
                else if (blue_count >= red_count && blue_count >= green_count)
                    color <= 2'd3; // Blue
                    
                delay_counter <= 0 ;

                state <= 0; // Restart cycle
            end
            
        endcase
   
        
end
endmodule



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
module uart_rx(
    input clk_3125,
    input rx,
    output reg [7:0] rx_msg,
    output reg rx_parity,
    output reg rx_complete
);

// State definitions
//localparam INIT = 2'b00;
localparam IDLE = 2'b01;
localparam RECEIVE = 2'b10;

reg [1:0] state ;
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


module top_module (
    input clk_1MHz,
    input clk_3125,
    input cs_out,
    input uart_rx_in,
    input parity_type,
    input start_sim,
    output [1:0] filter,
    output [1:0] color,
    output uart_tx_out,
    output tx_done,
    output [7:0] rx_msg,
    output rx_parity,
    output rx_complete
);

    // Internal signals
    wire [1:0] filter_wire;
    wire [1:0] color_wire;
    reg [7:0] tx_data;
    wire tx_done_wire;
    wire [7:0] rx_msg_wire;
    wire rx_parity_wire;
    wire rx_complete_wire;
    reg tx_start = 0;
    reg [1:0] prev_color;

    // --- String Transmission Logic ---
    reg is_transmitting = 0;
    reg [2:0] char_index = 0;
    reg [2:0] string_len = 0;
    reg [1:0] color_to_send = 0;

    // Instantiate all sub-modules
    t1b_cd_fd color_sensor ( .clk_1MHz(clk_1MHz), .cs_out(cs_out), .filter(filter_wire), .color(color_wire) );
    uart_tx uart_transmitter ( .clk_3125(clk_3125), .parity_type(parity_type), .tx_start(tx_start), .data(tx_data), .tx(uart_tx_out), .tx_done(tx_done_wire) );
    uart_rx uart_receiver ( .clk_3125(clk_3125), .rx(uart_rx_in), .rx_msg(rx_msg_wire), .rx_parity(rx_parity_wire), .rx_complete(rx_complete_wire) );

    // Sequential logic to manage the string transmission process
    always @(posedge clk_3125) begin
        prev_color <= color_wire;

        // Default tx_start to 0, it will be pulsed high for one cycle when needed
        tx_start <= 0;

        if (!is_transmitting) begin
            // If a new, valid color is detected, start the transmission process
            if (color_wire != prev_color && color_wire != 0) begin
                is_transmitting <= 1;
                char_index <= 0;
                color_to_send <= color_wire;
                tx_start <= 1; // Start sending the first character
            end
        end else begin
            if (tx_done_wire) begin
                // Check if there are more characters left in the string
                if (char_index < string_len - 1) begin
                    char_index <= char_index + 1;
                    tx_start <= 1; // Start sending the next character
                end else begin
                    is_transmitting <= 0; // Clear the busy flag, transmission is complete
                end
            end
        end
    end

    // Combinational logic to determine which character to send and the string length
    always @(*) begin

        if (start_sim) begin
            case(color_to_send)
                2'd1: begin // RED
                    string_len = 3;
                    case(char_index)
                        0: tx_data = "R";
                        1: tx_data = "E";
                        2: begin tx_data = "D"; $display("LOG @ time %t: UART RX successful. Colour : RED",$time); end //debugging step, display is not ncessary
                        default: tx_data = " ";
                    endcase
                end
                2'd2: begin // GREEN
                    string_len = 5;
                    case(char_index)
                        0: tx_data = "G";
                        1: tx_data = "R";
                        2: tx_data = "E";
                        3: tx_data = "E";
                        4: begin tx_data = "N"; $display("LOG @ time %t: UART RX successful. Colour : GREEN",$time); end //debugging step, display is not ncessary
                        default: tx_data = " ";
                    endcase
                end
                2'd3: begin // BLUE
                    string_len = 4;
                    case(char_index)
                        0: tx_data = "B";
                        1: tx_data = "L";
                        2: tx_data = "U";
                        3: begin tx_data = "E"; $display("LOG @ time %t: UART RX successful. Colour : BLUE",$time); end //debugging step, display is not ncessary
                        default: tx_data = " ";
                    endcase
                end
            endcase
        end else begin 
            string_len = 0;
            tx_data = 8'h00;
            $display("DUT LOG - STOP MODE");
            end
        // NOTE: The $display statements were moved to the testbench as they are for debugging
        // and should not be part of the synthesizable design.
    end 


    assign filter = filter_wire;
    assign color = color_wire;
    assign tx_done = is_transmitting ? tx_done_wire : 1'b1; // Show done when not transmitting
    assign rx_msg = rx_msg_wire;
    assign rx_parity = rx_parity_wire;
    assign rx_complete = rx_complete_wire;

endmodule