`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:01:30 04/14/2026 
// Design Name: 
// Module Name:    topblock_tb 
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
module top_tb();
reg pclk;
reg preset_n;
reg [2:0]paddr;
reg pwrite;
reg penable;
reg psel;
reg [7:0]pwdata;
reg miso;
wire ss;
wire sclk;
wire spi_interrupt_request;
wire mosi;
wire [7:0]prdata;
wire pready;
wire pslverr;
 integer i;
top t1(.pclk(pclk),.preset_n(preset_n),.penable(penable),.paddr(paddr),.pwrite(pwrite),.psel(psel),.pwdata(pwdata),.miso(miso),.ss(ss),.sclk(sclk),.spi_interrupt_request(spi_interrupt_request),.mosi(mosi),.prdata(prdata),.pready(pready),.pslverr(pslverr));


initial begin
pclk=1'b0;
forever #5 pclk=~pclk;
end

task reset;
begin
@(posedge pclk)
preset_n=1'b0;
@(posedge pclk)
preset_n=1'b1;
end
endtask



task write(input [7:0] cr1,input [7:0]cr2,input [7:0]bd);
begin
@(posedge pclk)
paddr=3'b0;
pwrite=3'b1;
psel=1'b1;
penable=1'b0;
pwdata=cr1;
@(posedge pclk)
paddr=3'b0;
       pwrite=1'b1;
       psel=1'b1;
pwdata=cr1;
penable=1'b1;
@(posedge pclk)
wait(pready);
penable=1'b0;
@(posedge pclk)
                paddr=3'b001;
                pwrite=3'b1;
                psel=1'b1;
                penable=1'b1;
                pwdata=cr2;
@(posedge pclk)
                wait(pready);
                penable=1'b0;
@(posedge pclk)
                paddr=3'b010;
                pwrite=3'b1;
                psel=1'b1;
                penable=1'b1;
                pwdata=bd;
                @(posedge pclk);
                wait(pready);
                penable=1'b0;


end
endtask

task write_dr(input [7:0] data);
begin
@(posedge pclk)
                paddr=3'b101;
                pwrite=3'b1;
                psel=1'b1;
                penable=1'b0;
                pwdata=data;

                @(posedge pclk)
          paddr=3'b101;
                pwrite=1'b1;
                psel=1'b1;
                penable=1'b1;

@(posedge pclk)
wait(pready)
                paddr=3'b101;
                pwrite=3'b1;
                psel=1'b0;
                penable=1'b0;
                pwdata=data;

end
endtask

task read;
begin
@(posedge pclk)
paddr=3'b0;
pwrite=1'b0;
psel=1'b1;
penable=1'b0;
@(posedge pclk)
paddr=3'b0;
                pwrite=1'b0;
                psel=1'b1;
penable=1'b1;
@(posedge pclk)
$display("w1");
wait(pready);
penable=1'b0;

@(posedge pclk)
                paddr=3'b1;
                pwrite=1'b0;
                psel=1'b1;
                penable=1'b0;
                @(posedge pclk)
                penable=1'b1;
                @(posedge pclk)
$display("w2");
                wait(pready);
                penable=1'b0;

@(posedge pclk)
                paddr=3'b010;
                pwrite=1'b0;
                psel=1'b1;
                penable=1'b0;
                @(posedge pclk)
                penable=1'b1;
                @(posedge pclk)
$display("w3");
                wait(pready);
                penable=1'b0;

@(posedge pclk)
                paddr=3'b011;
                pwrite=1'b0;
                psel=1'b1;
                penable=1'b0;
                @(posedge pclk)
                penable=1'b1;
                @(posedge pclk)
$display("w4");
                wait(pready);
                penable=1'b0;

@(posedge pclk)
                paddr=3'b101;
                pwrite=1'b0;
                psel=1'b1;
                penable=1'b0;
                @(posedge pclk)
                penable=1'b1;
                @(posedge pclk)
$display("w5");
                wait(pready);
                penable=1'b0;
psel=1'b0;
$display("w6");
end
endtask
initial
begin
   miso=1'b0;
reset();
write(8'b1101_1110,8'b1101_0000,8'b0001_0000);
write_dr(8'b1111_1010);
$display("b1");
read();


end
endmodule
