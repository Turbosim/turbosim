`ifndef _EQ_wrap
`define _EQ_wrap

`timescale 1ns/1ns
`include "../common_defines.v"
/* 
 * Event_Queue module
 * All inputs are defined in TUBOSIM spec
 *
 * PARAMETERS:
 * 	data_wd: 	width of single Q entry.
 * 	q_add_wd:	address width of event q store element (RAM). for example 
 *				q_add_wd=5 => maximal numbers of entries in q is 32.
 * 	q_max_len:	maximal length of Event Q
 *	lo:			bit select. TIME low bit offset. i.e. TIME "bit location" 
 *				in single Q event entry according to SPEC
 *	hi:			bit select. TIME high bit offset
 *
 * Author: Kimi
 */
 
module EQ_wrap #(parameter data_wd=32,q_add_wd=5,q_max_len=32,hi = 15,lo = 0)
				(	
				input [data_wd-1:0] EV_in,			// input entry
				input wire op,						// desired opereatoin, could be read or write
				input wire cs,						// chip select
				input wire rst,						// reset signal
				input wire clk,						// clock
				input wire is_zero_delay,			// woring in zero delay mode
				output reg [data_wd-1:0] EV_out,	// output entry
				output reg dv,						// data valid of output entry EV_out
				output reg full,					// full signal indication
				output reg empty,					// empty signal indication
				output reg busy_for_rd,				// when raised read operation can't be performed
				output reg busy_for_wr,				// when raised write operation can't be performed
				output reg [q_add_wd-1:0] length	// current number of elements in EQ
				);

wire [data_wd-1:0]	EQ_EV_out;
wire [data_wd-1:0]	fifo_EV_out;
wire [q_add_wd-1:0]	EQ_len;
wire [q_add_wd-1:0]	fifo_len;

wire 	EQ_dv,
		EQ_full,
		EQ_empty,
		EQ_busy_rd,
		EQ_busy_wr,
		fifo_empty,
		fifo_full,
		EQ_cs,
		fifo_wr,
		insert_ena,
		extract_ena,
		fifo_rd;

assign insert_ena = cs && op == `INSERT_CMD ;
assign extract_ena= cs && op == `EXTRACT_CMD;

// write to fifo
assign fifo_wr = insert_ena && is_zero_delay;
// write/ read to EQ
assign EQ_cs = (insert_ena && !is_zero_delay) || (extract_ena && fifo_empty);

// read from fifo 
assign fifo_rd = extract_ena && !fifo_empty;

// muxing outputs
always @ (*) begin
	if(fifo_empty) begin
		EV_out = EQ_EV_out;
		dv = EQ_dv;
		full = EQ_full;
		empty = EQ_empty;		
		busy_for_rd = EQ_busy_rd;		
		busy_for_wr = EQ_busy_wr;
		length = EQ_len;
	
	end
	else begin
		EV_out = fifo_EV_out;
		dv = `TRUE;
		full = fifo_full;
		empty = `FALSE;		
		busy_for_rd = `FALSE;		
		busy_for_wr = `FALSE;
		length = fifo_len;
	end
end

Event_Queue #(.data_wd(data_wd),
		.q_add_wd(q_add_wd),
		.q_max_len(q_max_len),
		.hi(hi),
		.lo(lo)
		)
eq(
	.EV_in(EV_in),
	.op(op),
	.cs(EQ_cs),
	.rst(rst),
	.clk(clk),
	.EV_out(EQ_EV_out),
	.dv(EQ_dv),
	.full(EQ_full),
	.empty(EQ_empty),
	.busy_for_rd(EQ_busy_rd),
	.busy_for_wr(EQ_busy_wr),
	.length(EQ_len)
	);
				
my_fifo #(.max_len(q_max_len), .len_wd(q_add_wd), .entry_wd(data_wd))
fifo(
	.clk(clk), 
	.rst(rst),
	.rd(fifo_rd),
	.wr(fifo_wr),
	.data_in(EV_in),	// input entry
	.full(fifo_full), 
	.empty(fifo_empty),			// fifo status indicators
	.data_out(fifo_EV_out),	// output entry
	.len(fifo_len)
	);
endmodule 				

`endif