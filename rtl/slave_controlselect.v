`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:19:45 04/13/2026 
// Design Name: 
// Module Name:    slave_controlselect 
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
module slave_controlselect(
input pclk,
input preset_n,
input mstr,
input spiswai,
input [1:0] spimode,
input send_data,
input [11:0] baudratedivisor,
output reg receive_data,
output reg ss,
output tip
);

wire [15:0] target;
wire spi_enable;
reg [15:0] count;

assign target = baudratedivisor * 8;
assign spi_enable = (mstr == 1'b1) &&
                    (spiswai == 1'b0) &&
                    ((spimode == 2'b00) || (spimode == 2'b01));

assign tip = ~ss;

always @(posedge pclk or negedge preset_n)
begin
    if(!preset_n)
    begin
        receive_data <= 1'b0;
        ss <= 1'b1;
        count <= 16'b0;
    end
    else
    begin
        receive_data <= 1'b0;
        ss <= 1'b1;

        if(spi_enable)
        begin
            if(send_data == 1'b0)
            begin
                if(count <= (target - 1'b1))
                begin
                    count <= count + 1'b1;
                    ss <= 1'b0;
                end

                if(count == (target - 1'b1))
                begin
                    receive_data <= 1'b1;
                end
            end
            else
            begin
                count <= 16'b0;
            end
        end
        else
        begin
            count <= 16'b0;
        end
    end
end

endmodule
