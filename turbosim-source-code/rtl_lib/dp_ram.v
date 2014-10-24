`ifndef _dp_ram
`define _dp_ram

`timescale 1ns / 1ns

module dp_ram #(parameter add_wd=4, data_wd=32,depth=16)
	(
	input wire clk, cs, rd, wr, 
	input wire [add_wd-1:0] rd_add, wr_add,
	input wire [data_wd-1:0] wr_data,
	output reg [data_wd-1:0] rd_data
	);

	reg [data_wd-1:0]	ram [depth-1:0]; 

	always @(posedge clk) begin
		if (cs && rd) begin
			// rd_data <= #1 {data_wd{1'bx}};
			rd_data <= #5 ram[rd_add];
		end
		if (cs && wr)
			ram[wr_add] <= #1 wr_data;
	end

endmodule 

`endif