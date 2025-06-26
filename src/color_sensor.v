`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.06.2025 20:26:42
// Design Name: 
// Module Name: cs
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
         if (delay_counter >494 && delay_counter < g_stop ) begin
           pulse_counter <= pulse_counter + 1;
           green_count <= pulse_counter;
          end
          
          if ( delay_counter == 901) pulse_counter <= 0 ;
          
          if (delay_counter >994 && delay_counter < r_stop ) begin
           pulse_counter <= pulse_counter + 1;
           red_count <= pulse_counter;
          end
         
          if ( delay_counter == 1400) pulse_counter <= 0 ;
          
          if (delay_counter >1494 && delay_counter < b_stop ) begin
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




// First we started by understanding the given test bench. We measured how much time each filter lasts using time delay in tb.
// acc to tb each filter lasts 5,00,000 ns which is 500 clock cycles
// there will be three filters with encoding given in table
// green, red , blue phases for filters. In each phase frequency of cs_out will be calculated by pulse_counter. The pulse counter will increase at the posedges of cs_out and this value of count will be stored in respective color_count variables.
// then there will be another phase to which we assigned 2 (Compare Phase)
// In compare phase we will be comparing intensities of colors by comparing the colour_count values for each color. Then in this phase output color will be updated with color with highest count. Initially colour will be zero then it will be updated with respective color.

// We properly understood the timing for each phase. We employed a delay_counter which increases at posedges of clock for timing check.
// We observed the cs_out signal. We noticed that there is a delay in the starting before the actual start of cs_out, . We noticed that this delay is increasing with each iteration.
// then we came up with idea to initialize the pulse_counter at only ends of the cs_out. As the frequency of the cs_out is constant for a filter it works.
// We can measure frequency by analysing only a small portion of cs_out wave at the end. This idea minimized our errors and optimized our DUT.
// We used a FSM which will change the phases(filters) and will update the output filter, it will also update final output color.
// We implemented pulse_counter for 3 clock cycles at the end of cs_out by using always block and if statements.



