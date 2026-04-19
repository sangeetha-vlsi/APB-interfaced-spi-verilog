`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:17:20 04/13/2026 
// Design Name: 
// Module Name:    Baud_gen 
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
module baud_generator(   //generate serial clock  from pclk for  transmission and reception
input pclk,
input preset_n,
input [1:0] spimode,
input spiswai,
input [2:0] sppr,         //spi baud reg pre selection bits
input [2:0] spr,          //spi baud reg selection bits
input cpol,
input cpha,
input ss,
output reg sclk,
output reg miso_receive_sclk,    //signals for sending and receiving based on cpol and cphase
output reg miso_receive_sclk0,
output reg mosi_send_sclk,
output reg mosi_send_sclk0,
output [11:0] baudratedivisor
);

wire pre_sclk;
wire spi_enable;
wire [11:0] half_baudratedivisor;
reg [11:0] count;

assign baudratedivisor = (sppr + 1'b1) * (2**(spr + 1'b1));
assign half_baudratedivisor = baudratedivisor/2;
assign pre_sclk = (cpol)?1'b1 : 1'b0;

assign spi_enable = (ss == 1'b0) &&
                    (spiswai == 1'b0) &&
                    ((spimode == 2'b00) || (spimode == 2'b01));

always @(posedge pclk or negedge preset_n)
begin
    if(!preset_n)
    begin
        sclk <= pre_sclk;
        count <= 12'b0;
        miso_receive_sclk <= 1'b0;
        miso_receive_sclk0 <= 1'b0;
        mosi_send_sclk <= 1'b0;
        mosi_send_sclk0 <= 1'b0;
    end
    else
    begin
        miso_receive_sclk <= 1'b0;
        miso_receive_sclk0 <= 1'b0;
        mosi_send_sclk <= 1'b0;
        mosi_send_sclk0 <= 1'b0;

        if(spi_enable)
        begin
            if(count == (half_baudratedivisor - 1'b1))
            begin
                count <= 12'b0;

                // receive pulse generation
                if((cpol == 1'b0 && cpha == 1'b0) || (cpol == 1'b1 && cpha == 1'b1))
                begin
                    if(sclk == 1'b0)
                        miso_receive_sclk <= 1'b1;
                end
                else
                begin
                    if(sclk == 1'b1)
                        miso_receive_sclk0 <= 1'b1;
                end

                // toggle serial clock
                sclk <= ~sclk;
            end
            else
            begin
                count <= count + 1'b1;

                // send pulse generation one pclk earlier
                if(count == (half_baudratedivisor - 2'b10))
                begin
                    if((cpol == 1'b0 && cpha == 1'b0) || (cpol == 1'b1 && cpha == 1'b1))
                    begin
                        if(sclk == 1'b1)
                            mosi_send_sclk <= 1'b1;
                    end
                    else
                    begin
                        if(sclk == 1'b0)
                            mosi_send_sclk0 <= 1'b1;
                    end
                end
            end
        end
        else
        begin
            sclk <= pre_sclk;
            count <= 12'b0;
        end
    end
end

endmodule
