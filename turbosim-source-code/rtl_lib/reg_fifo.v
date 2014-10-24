/*
 * fifo module implements simple fifo which could read
 *  and write entry in same cycle.
 * 	NOTE:	when issued rd command fifo shouldn't be empty,
 * 			when issued wr command fifo shouldn't be full,
 * 			when issued rd and wr commands fifo shouldn't be empty or full
 *			only when fifo is empty data_out isn't valid
 * Author: Kimi - Aug 2010
 */
`ifndef _my_fifo
`define _my_fifo

`timescale 1ns / 1ns

module my_fifo #(parameter max_len = 16, len_wd = 4, entry_wd = 32)
	(
	input wire 					clk, rst,	// standard input signals
	input wire 					rd,  wr, 	// raed and write signals
	input wire [entry_wd-1:0]	data_in,	// input entry
	output wire 				full, empty,// fifo status indicators
	output wire [entry_wd-1:0]	data_out,	// output entry
	output reg	[len_wd-1:0]	len			// indicated current fifo length
	);

reg	[entry_wd-1:0]	reg_ram [max_len-1:0];	// registers array that implements ram.

reg [len_wd:0]		rd_ptr,			// point to ram address of entry that will be retrieved in next read command
					wr_ptr;			// point to next free ram address that will be occupied during next write cmd.

assign full		= (len == max_len);
assign empty	= (len == 0);
assign data_out	= reg_ram[rd_ptr];

// pointers and length managements FSM
always @ (posedge clk) begin
	if(rst) begin
		len		<= #5 0;
		rd_ptr	<= #5 0;
		wr_ptr	<= #5 0;
	end
	else begin
		if(rd && wr && rd_ptr != wr_ptr) begin // to prevent read and write to same address (read and write)
			
			if(rd_ptr == max_len-1) begin
				rd_ptr <= #5 {len_wd{1'b0}}; // 0
			end
			else begin
				rd_ptr <= #5 rd_ptr + {{(len_wd-1){1'b0}},1'b1}; // 1
			end
			
			if(wr_ptr == max_len-1) begin
				wr_ptr	<= #5 {len_wd{1'b0}}; // 0
			end
			else begin
				wr_ptr	<= #5 wr_ptr + {{(len_wd-1){1'b0}},1'b1}; // 1
			end
		end
		else if (rd && !empty) begin	// read only
			len <= #5 len - {{(len_wd-1){1'b0}},1'b1}; // len--
			if(rd_ptr == max_len-1) begin
				rd_ptr <= #5 {len_wd{1'b0}}; // 0
			end
			else begin
				rd_ptr <= #5 rd_ptr + {{(len_wd-1){1'b0}},1'b1}; // rd_ptr++
			end
		end
		else if (wr && !full) begin	// write only
			len <= #5 len + {{(len_wd-1){1'b0}},1'b1}; // len++
			if(wr_ptr == max_len-1) begin
				wr_ptr	<= #5 {len_wd{1'b0}}; // 0
			end
			else begin
				wr_ptr	<= #5 wr_ptr + {{(len_wd-1){1'b0}},1'b1}; // wr_ptr++
			end
		end
	end
end

// write data into fifo
always @ (posedge clk) begin
	if(!rst && ((wr && !full) || (rd && wr && rd_ptr != wr_ptr))) begin
		reg_ram[wr_ptr] <= #5 data_in;
	end
end

endmodule 

`endif