`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:23:08 04/13/2026 
// Design Name: 
// Module Name:    apb_slaveselect 
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
module apb_slave_interface (
    input  wire       pclk,
    input  wire       preset_n,
    input  wire [2:0] paddr,
    input  wire       pwrite,
    input  wire       psel,
    input  wire       penable,
    input  wire [7:0] pwdata,
    input  wire       ss,
    input  wire [7:0] miso_data,
    input  wire       receive_data,
    input  wire       tip,
    output reg  [7:0] prdata,
    output wire       mstr,
    output wire       cpol,
    output wire       cpha,
    output wire       lsbfe,
    output wire       spiswai,
    output wire [2:0] sppr,
    output wire [2:0] spr,
    output wire       spi_interrupt_request,
    output wire       pready,
    output wire       pslverr,
    output reg        send_data,
    output reg  [7:0] mosi_data,
    output wire [1:0] spi_mode
);

    localparam [7:0] CR_MASK = 8'b00011011;
    localparam [7:0] BR_MASK = 8'b01110111;

    localparam [2:0] ADDR_CR1 = 3'b000;
    localparam [2:0] ADDR_CR2 = 3'b001;
    localparam [2:0] ADDR_BR  = 3'b010;
    localparam [2:0] ADDR_SR  = 3'b011;
    localparam [2:0] ADDR_DR  = 3'b101;
    // If your guide insists on DR at 3'b101, only change ADDR_DR.

    localparam [1:0] IDLE     = 2'b00;
    localparam [1:0] ENABLE_S = 2'b10;
    localparam [1:0] SPI_RUN  = 2'b00;
    localparam [1:0] SPI_WAIT = 2'b01;

    reg  [7:0] spi_cr1;
    reg  [7:0] spi_cr2;
    reg  [7:0] spi_br;
    reg  [7:0] spi_dr;

    wire [7:0] spi_sr;
    wire [1:0] apb_state;

    wire wr_enb;
    wire rd_enb;

    wire modf;
    wire sptef;
    wire spif;
    wire ssoe;
    wire modfen;
    wire spie;
    wire spe;
    wire sptie;

    wire sel0;
    wire sel1;
    wire sel2;
    wire mux1;
    wire mux2;

    apb_fsm u_apb_fsm (
        .pclk     (pclk),
        .preset_n (preset_n),
        .psel     (psel),
        .penable  (penable),
        .state    (apb_state)
    );

    spi_fsm u_spi_fsm (
        .pclk     (pclk),
        .preset_n (preset_n),
        .spe      (spe),
        .spiswai  (spiswai),
        .spi_mode (spi_mode)
    );

    assign wr_enb = (apb_state == ENABLE_S) &&  pwrite;
    assign rd_enb = (apb_state == ENABLE_S) && !pwrite;

    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n)
            spi_cr1 <= 8'h40;
        else if (wr_enb && (paddr == ADDR_CR1))
            spi_cr1 <= pwdata;
    end

    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n)
            spi_cr2 <= 8'h00;
        else if (wr_enb && (paddr == ADDR_CR2))
            spi_cr2 <= (pwdata & CR_MASK);
    end

    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n)
            spi_br <= 8'h00;
        else if (wr_enb && (paddr == ADDR_BR))
            spi_br <= (pwdata & BR_MASK);
    end

    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n)
            spi_dr <= 8'h00;
        else if (wr_enb && (paddr == ADDR_DR))
            spi_dr <= pwdata;
        else if (receive_data && ((spi_mode == SPI_RUN) || (spi_mode == SPI_WAIT)))
            spi_dr <= miso_data;
    end

   always @(posedge pclk or negedge preset_n) begin
    if (!preset_n)
        send_data <= 1'b0;
    else if (wr_enb && (paddr == ADDR_DR) &&
             ((spi_mode == SPI_RUN) || (spi_mode == SPI_WAIT)))
        send_data <= 1'b1;
    else
        send_data <= 1'b0;
end

   always @(posedge pclk or negedge preset_n) begin
    if (!preset_n)
        mosi_data <= 8'h00;
    else if (wr_enb && (paddr == ADDR_DR) &&
             ((spi_mode == SPI_RUN) || (spi_mode == SPI_WAIT)))
        mosi_data <= pwdata;
end

    assign mstr    = spi_cr1[4];
    assign cpol    = spi_cr1[3];
    assign cpha    = spi_cr1[2];
    assign lsbfe   = spi_cr1[0];
    assign spie    = spi_cr1[7];
    assign spe     = spi_cr1[6];
    assign sptie   = spi_cr1[5];
    assign ssoe    = spi_cr1[1];

    assign modfen  = spi_cr2[4];
    assign spiswai = spi_cr2[1];

    assign sppr    = spi_br[6:4];
    assign spr     = spi_br[2:0];

    assign modf  = (~ss) & mstr & modfen & (~ssoe);
    assign sptef = (spi_dr == 8'h00);
    assign spif  = (spi_dr != 8'h00);

    assign spi_sr = (!preset_n) ? 8'b0010_0000 : {spif, 1'b0, sptef, modf, 4'b0000};

    always @(*) begin
        if (rd_enb) begin
            case (paddr)
                ADDR_CR1: prdata = spi_cr1;
                ADDR_CR2: prdata = spi_cr2;
                ADDR_BR : prdata = spi_br;
                ADDR_SR : prdata = spi_sr;
                ADDR_DR : prdata = spi_dr;
                default : prdata = 8'h00;
            endcase
        end
        else begin
            prdata = 8'h00;
        end
    end

    assign pready  = (apb_state == ENABLE_S) ? 1'b1  : 1'b0;
    assign pslverr = (apb_state == ENABLE_S) ? (~tip) : 1'b0;

    assign sel0 = (~spie)  & (~sptie);
    assign sel1 = (~sptie) &   spie;
    assign sel2 = (~spie)  &   sptie;

    assign mux1 = sel2 ? sptef : (spif | modf | sptef);
    assign mux2 = sel1 ? (spif | modf) : mux1;
    assign spi_interrupt_request = sel0 ? 1'b0 : mux2;

endmodule

