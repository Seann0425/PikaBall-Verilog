
module sram
#(parameter DATA_WIDTH = 8, ADDR_WIDTH = 16, RAM_SIZE = 65536, FILE = "images.mem")
 (input clk, input we, input en,
  input  [ADDR_WIDTH-1 : 0] addr,
  input  [DATA_WIDTH-1 : 0] data_i,
  output reg [DATA_WIDTH-1 : 0] data_o);
    
// Declareation of the memory cells
(* ram_style = "block" *) reg [DATA_WIDTH-1 : 0] RAM [RAM_SIZE - 1:0];

integer idx;

// ------------------------------------
// SRAM cell initialization
// ------------------------------------
// Initialize the sram cells with the values defined in "image.dat."
initial begin
    $readmemh(FILE, RAM);
end

// ------------------------------------
// SRAM read operation
// ------------------------------------
always@(posedge clk)
begin
  if (en & we)
    data_o <= data_i;
  else
    data_o <= RAM[addr];
end

// ------------------------------------
// SRAM write operation；
// ------------------------------------
always@(posedge clk)
begin
  if (en & we) begin
    RAM[addr] <= data_i;
  end
end

endmodule
