`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:21:29 04/13/2026 
// Design Name: 
// Module Name:    shift_reg 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module shift_reg (
    input              pclk,
    input              preset_n,
    input              ss,                 // active low
    input              send_data,
    input              lsbfe,
    input              cpha,
    input              cpol,
    input              miso_receive_sclk,
    input              miso_receive_sclk0,
    input              mosi_send_sclk,
    input              mosi_send_sclk0,
    input      [7:0]   data_mosi,
    input              miso,
    input              receive_data,
    output reg         mosi,
    output     [7:0]   data_miso
);

    reg [7:0] shift_reg; //for transmitting
    reg [7:0] temp_reg;  //for receiving

    reg [2:0] tx_count_up;       //count        
    reg [2:0] tx_count_down;      //count1
    reg [2:0] rx_count_up;       //count2
    reg [2:0] rx_count_down;     //count3

    wire mode_a;        // CPOL=0,CPHA=1 or CPOL=1,CPHA=0
    assign mode_a = ((cpol == 1'b0) && (cpha == 1'b1)) || ((cpol == 1'b1) && (cpha == 1'b0));

    wire tx_pulse;   //assign mosi send flags depending on cpol and cphase
    wire rx_pulse;   //assign miso receive flags depending on cpol and cphase

    assign tx_pulse = mode_a ? mosi_send_sclk  : mosi_send_sclk0;
    assign rx_pulse = mode_a ? miso_receive_sclk0 : miso_receive_sclk;

    assign data_miso = receive_data ? temp_reg : 8'b0;    //load values of temp reg to data_miso depending on receive_data signal

    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n) begin
            shift_reg      <= 8'b0;
            temp_reg       <= 8'b0;      
            mosi           <= 1'b0;

            tx_count_up    <= 3'd0;
            tx_count_down  <= 3'd7;
            rx_count_up    <= 3'd0;
            rx_count_down  <= 3'd7;
        end
        else begin
            // load transmit data
            if (send_data) begin
                shift_reg <= data_mosi;     //if send_data is active,load the values of data_mosi to shift_reg
            end

            // frame inactive
            if (ss) begin
                mosi           <= 1'b0;
                tx_count_up    <= 3'd0;   //if ss=1
                tx_count_down  <= 3'd7;
                rx_count_up    <= 3'd0;
                rx_count_down  <= 3'd7;
            end
            else begin
                // MOSI transmit
                if (tx_pulse) begin
                    if (lsbfe) begin
                        mosi <= shift_reg[tx_count_up];
                        if (tx_count_up < 3'd7)
                            tx_count_up <= tx_count_up + 1'b1;
                    end
                    else begin
                        mosi <= shift_reg[tx_count_down];
                        if (tx_count_down > 3'd0)
                            tx_count_down <= tx_count_down - 1'b1;
                    end
                end

                // MISO receive
                if (rx_pulse) begin
                    if (lsbfe) begin
                        temp_reg[rx_count_up] <= miso;
                        if (rx_count_up < 3'd7)
                            rx_count_up <= rx_count_up + 1'b1;
                    end
                    else begin
                        temp_reg[rx_count_down] <= miso;
                        if (rx_count_down > 3'd0)
                            rx_count_down <= rx_count_down - 1'b1;
                    end
                end
            end
        end
    end

endmodule
