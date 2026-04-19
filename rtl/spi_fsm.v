`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:29:45 04/13/2026 
// Design Name: 
// Module Name:    spi_fsm 
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
module spi_fsm (
    input  wire       pclk,
    input  wire       preset_n,
    input  wire       spe,
    input  wire       spiswai,
    output reg  [1:0] spi_mode
);

    localparam SPI_RUN  = 2'b00;
    localparam SPI_WAIT = 2'b01;
    localparam SPI_STOP = 2'b10;

    reg [1:0] next_state;

    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n)
            spi_mode <= SPI_RUN;
        else
            spi_mode <= next_state;
    end

    always @(*) begin
        next_state = spi_mode;
        case (spi_mode)
            SPI_RUN: begin
                if (!spe)
                    next_state = SPI_WAIT;
                else
                    next_state = SPI_RUN;
            end

            SPI_WAIT: begin
                if (spiswai)
                    next_state = SPI_STOP;
                else if (!spe)
                    next_state = SPI_WAIT;
                else
                    next_state = SPI_RUN;
            end

            SPI_STOP: begin
                if (spe)
                    next_state = SPI_RUN;
                else if (!spiswai)
                    next_state = SPI_WAIT;
                else
                    next_state = SPI_STOP;
            end

            default: next_state = SPI_RUN;
        endcase
    end

endmodule
