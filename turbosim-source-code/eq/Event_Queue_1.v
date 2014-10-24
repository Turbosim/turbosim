`ifndef _Event_Queue
`define _Event_Queue

`include "Queue.v"
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
 
module Event_Queue #(parameter data_wd=32,q_add_wd=5,q_max_len=32,hi = 15,lo = 0)
				(	
				input [data_wd-1:0] EV_in,			// input entry
				input op,							// desired opereatoin, could be read or write
				input cs,							// chip select
				input rst,							// reset signal
				input clk,							// clock
				output wire [data_wd-1:0] EV_out,	// output entry
				output wire dv,						// data valid of output entry EV_out
				output wire full,					// full signal indication
				output wire empty,					// empty signal indication
				output wire busy_for_rd,			// when raised read operation can't be performed
				output wire busy_for_wr,			// when raised write operation can't be performed
				output wire [q_add_wd-1:0] length	// current number of elements in EQ
				);
wire busy;

assign busy_for_rd = busy;
assign busy_for_wr = busy;

//////////////////////
// Qs instantiation //
//////////////////////

Queue #(.data_wd(data_wd),
		.q_add_wd(q_add_wd),
		.q_max_len(q_max_len),
		.hi(hi),
		.lo(lo)
		)
q0(
	.EV_in(EV_in),
	.op(op),
	.cs(cs),
	.rst(rst),
	.clk(clk),
	.EV_out(EV_out),
	.dv(dv),
	.full(full),
	.empty(empty),
	.busy(busy),
	.length(length)
	);

endmodule 

`endif