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


`define Q0_IDX 2'd0
`define Q1_IDX 2'd1
`define Q2_IDX 2'd2
`define Q3_IDX 2'd3

localparam Q_num 	= 4; // number of Qs connected to "compare window"
localparam Q_num_wd 	= 2; //set to be log2(Q_num)

//////////////////
// declarations //
//////////////////

reg	[Q_num-1:0]		cs_bus;

//Qs status indication signals
wire [Q_num-1:0]	full_bus;	
wire [Q_num-1:0]	empty_bus;
wire [Q_num-1:0]	busy_bus;
wire [Q_num-1:0]	dv_bus;

wire [Q_num_wd:0]	extract_Q_dv_bus;				//chosen extract Q dv

wire [Q_num_wd-1:0]	insert_Q_idx_bus [Q_num_wd:0], 	//chosen insert Q index
					extract_Q_idx_bus [Q_num_wd:0]; //chosen extract Q idx
					
wire [data_wd-1: 0]	EV_out_bus [Q_num-1:0], 
					extract_Q_EV_out_bus [Q_num_wd:0];
					
wire [q_add_wd-1:0]	len_bus [Q_num-1:0],
					insert_Q_len_bus [Q_num_wd:0];
					
wire 				dv_in_all_Qs,
					at_least_one_Q_busy;

reg extract_Q_busy;

////////////////////////////////
// inner logic implementation //
////////////////////////////////
assign length		= len_bus[0] + len_bus[1] + len_bus[2] + len_bus[3];
assign full			= q_max_len == length;
assign empty		= empty_bus[0]	&& empty_bus[1]	&& empty_bus[2]	&& empty_bus[3];
assign busy_for_wr	= busy_bus[0]	&& busy_bus[1]	&& busy_bus[2]	&& busy_bus[3];
assign busy_for_rd	= dv_in_all_Qs ? extract_Q_busy : at_least_one_Q_busy;
assign dv			= extract_Q_dv_bus[0];
assign EV_out		= extract_Q_EV_out_bus[0];

// Q select DECODER
always @(*) begin
	if(cs && op == `INSERT_CMD) begin
		case (insert_Q_idx_bus[0])
			2'd0:	cs_bus = 4'b0001;
			2'd1:	cs_bus = 4'b0010;
			2'd2:	cs_bus = 4'b0100;
			2'd3:	cs_bus = 4'b1000;
			default:cs_bus = 4'b0000;
		endcase
	end
	else if (cs && op == `EXTRACT_CMD) begin
		case (extract_Q_idx_bus[0])
			2'd0:	cs_bus = 4'b0001;
			2'd1:	cs_bus = 4'b0010;
			2'd2:	cs_bus = 4'b0100;
			2'd3:	cs_bus = 4'b1000;
			default:cs_bus = 4'b0000;
		endcase
	end
	else begin
		cs_bus = 4'b0000;
	end
end

// busy for read control mechanism
always @ (*) begin
	case(extract_Q_idx_bus[0])
	`Q0_IDX: extract_Q_busy = busy_bus[0];
	`Q1_IDX: extract_Q_busy = busy_bus[1];
	`Q2_IDX: extract_Q_busy = busy_bus[2];
	`Q3_IDX: extract_Q_busy = busy_bus[3];
	default: extract_Q_busy = `FALSE;
	endcase
end

assign dv_in_all_Qs = dv_bus[0] && dv_bus[1] && dv_bus[2] && dv_bus[3];
assign at_least_one_Q_busy = busy_bus[0] || busy_bus[1] || busy_bus[2] || busy_bus[3];

///////////////////////////////////////////////////////////////////////
// 						modules instantiation 						 //			
///////////////////////////////////////////////////////////////////////

/////////////////////////
// insertion mechanizm //
/////////////////////////

// current event would be inserted into Q with minimal number of elements (minimal length)
comperator_2 #(.data_wd(q_add_wd),.idx_wd(Q_num_wd),.hi(q_add_wd-1),.lo(0))
insert_cmp0(
	.c_dat	(insert_Q_len_bus[0]),
	.c_idx	(insert_Q_idx_bus[0]),
	.c_dv	(insert_Q_dv),
	
	.d0		(insert_Q_len_bus[1]),
	.d0_idx	(insert_Q_idx_bus[1]),
	.d0_dv	(insert_Q_0_1_dv),
	
	.d1		(insert_Q_len_bus[2]),
	.d1_idx	(insert_Q_idx_bus[2]),
	.d1_dv	(insert_Q_2_3_dv),
	
	.great_n_small(`FALSE)
	);

// compare length of Q 0 and 1 for insertion Q selection mechanizm
comperator_2 #(.data_wd(q_add_wd),.idx_wd(Q_num_wd),.hi(q_add_wd-1),.lo(0))
insert_cmp1(
	.c_dat(insert_Q_len_bus[1]),
	.c_idx(insert_Q_idx_bus[1]),
	.c_dv(insert_Q_0_1_dv),
	
	.d0(len_bus[0]),
	.d0_idx(`Q0_IDX),
	.d0_dv(!full_bus[0] && !busy_bus[0] ),
	
	.d1(len_bus[1]),
	.d1_idx(`Q1_IDX),
	.d1_dv(!full_bus[1] && !busy_bus[1] ),
	
	.great_n_small(`FALSE)
	);

// compare length of Q 2 and 3 for insertion Q selection mechanizm
comperator_2 #(.data_wd(q_add_wd),.idx_wd(Q_num_wd),.hi(q_add_wd-1),.lo(0))
insert_cmp2(
	.c_dat(insert_Q_len_bus[2]),
	.c_idx(insert_Q_idx_bus[2]),
	.c_dv(insert_Q_2_3_dv),
	
	.d0(len_bus[2]),
	.d0_idx(`Q2_IDX),
	.d0_dv(!full_bus[2] && !busy_bus[2] ),
	
	.d1(len_bus[3]),
	.d1_idx(`Q3_IDX),
	.d1_dv(!full_bus[3] && !busy_bus[3] ),
	
	.great_n_small(`FALSE)
	);
	
//////////////////////////
// extraction mechanizm //
//////////////////////////

//next event will be extracted from Q with lowest EV_out
comperator_2 #(.data_wd(data_wd),.idx_wd(Q_num_wd),.hi(hi),.lo(lo))
extract_cmp0(
	.c_dat	(extract_Q_EV_out_bus[0]),
	.c_idx	(extract_Q_idx_bus[0]),
	.c_dv	(extract_Q_dv_bus[0]),
	
	.d0		(extract_Q_EV_out_bus[1]),
	.d0_idx	(extract_Q_idx_bus[1]),
	.d0_dv	(extract_Q_dv_bus[1]),
	
	.d1		(extract_Q_EV_out_bus[2]),
	.d1_idx	(extract_Q_idx_bus[2]),
	.d1_dv	(extract_Q_dv_bus[2]),
	
	.great_n_small(`FALSE)
	);

	
// compare EV_out of Qs 0 and 1 for extraction mechanizm
comperator_2 #(.data_wd(data_wd),.idx_wd(Q_num_wd),.hi(hi),.lo(lo))
extract_cmp1(
	.c_dat	(extract_Q_EV_out_bus[1]),
	.c_idx	(extract_Q_idx_bus[1]),
	.c_dv	(extract_Q_dv_bus[1]),
	
	.d0(EV_out_bus[0]),
	.d0_idx(`Q0_IDX),
	.d0_dv(dv_bus[0]),
	
	.d1(EV_out_bus[1]),
	.d1_idx(`Q1_IDX),
	.d1_dv(dv_bus[1]),
	
	.great_n_small(`FALSE)
	);

// compare EV_out of Qs 2 and 3 for extraction mechanizm
comperator_2 #(.data_wd(data_wd),.idx_wd(Q_num_wd),.hi(hi),.lo(lo))
extract_cmp2(
	.c_dat	(extract_Q_EV_out_bus[2]),
	.c_idx	(extract_Q_idx_bus[2]),
	.c_dv	(extract_Q_dv_bus[2]),
	
	.d0(EV_out_bus[2]),
	.d0_idx(`Q2_IDX),
	.d0_dv(dv_bus[2]),
	
	.d1(EV_out_bus[3]),
	.d1_idx(`Q3_IDX),
	.d1_dv(dv_bus[3]),
	
	.great_n_small(`FALSE)
	);

//////////////////////
// Qs instantiation //
//////////////////////

Queue #(.data_wd(data_wd),
		.q_add_wd(q_add_wd-1),
		.q_max_len((q_max_len+Q_num-1)/Q_num),
		.hi(hi),
		.lo(lo)
		)
q0(
	.EV_in(EV_in),
	.op(op),
	.cs(cs_bus[0]),
	.rst(rst),
	.clk(clk),
	.EV_out(EV_out_bus[0]),
	.dv(dv_bus[0]),
	.full(full_bus[0]),
	.empty(empty_bus[0]),
	.busy(busy_bus[0]),
	.length(len_bus[0])
	);
			
Queue #(.data_wd(data_wd),
		.q_add_wd(q_add_wd-1),
		.q_max_len((q_max_len+Q_num-1)/Q_num),
		.hi(hi),
		.lo(lo)
		)
q1(
	.EV_in(EV_in),
	.op(op),
	.cs(cs_bus[1]),
	.rst(rst),
	.clk(clk),
	.EV_out(EV_out_bus[1]),
	.dv(dv_bus[1]),
	.full(full_bus[1]),
	.empty(empty_bus[1]),
	.busy(busy_bus[1]),
	.length(len_bus[1])
	);

Queue #(.data_wd(data_wd),
		.q_add_wd(q_add_wd-1),
		.q_max_len((q_max_len+Q_num-1)/Q_num),
		.hi(hi),
		.lo(lo)
		)
q2(
	.EV_in(EV_in),
	.op(op),
	.cs(cs_bus[2]),
	.rst(rst),
	.clk(clk),
	.EV_out(EV_out_bus[2]),
	.dv(dv_bus[2]),
	.full(full_bus[2]),
	.empty(empty_bus[2]),
	.busy(busy_bus[2]),
	.length(len_bus[2])
	);
				

Queue #(.data_wd(data_wd),
		.q_add_wd(q_add_wd-1),
		.q_max_len((q_max_len+Q_num-1)/Q_num),
		.hi(hi),
		.lo(lo)
		)
q3(
	.EV_in(EV_in),
	.op(op),
	.cs(cs_bus[3]),
	.rst(rst),
	.clk(clk),
	.EV_out(EV_out_bus[3]),
	.dv(dv_bus[3]),
	.full(full_bus[3]),
	.empty(empty_bus[3]),
	.busy(busy_bus[3]),
	.length(len_bus[3])
	);
				

endmodule

`endif