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


`define Q0_IDX 3'd0
`define Q1_IDX 3'd1
`define Q2_IDX 3'd2
`define Q3_IDX 3'd3
`define Q4_IDX 3'd4
`define Q5_IDX 3'd5
`define Q6_IDX 3'd6
`define Q7_IDX 3'd7

`define Q_num 		8 // number of Qs connected to "compare window"
`define Q_num_wd 	3 //set to be log2(`Q_num)

//////////////////
// declarations //
//////////////////
reg [`Q_num-1:0]		cs_bus;

//Qs status indication signals
wire [`Q_num-1:0]	full_bus;	
wire [`Q_num-1:0]	empty_bus;
wire [`Q_num-1:0]	busy_bus;
wire [`Q_num-1:0]	dv_bus;

wire [`Q_num_wd-1:0]	insert_Q_idx, 	//chosen insert Q index
					insert_Q_0_1_idx,
					insert_Q_2_3_idx,
					insert_Q_4_5_idx,
					insert_Q_6_7_idx,
					insert_Q_1_to_3_idx,
					insert_Q_4_to_7_idx,
					extract_Q_idx, 	//chosen extract Q idx
					extract_Q_0_1_idx,
					extract_Q_2_3_idx,
					extract_Q_4_5_idx,
					extract_Q_6_7_idx,
					extract_Q_1_to_3_idx,
					extract_Q_4_to_7_idx					
					;
					
wire [data_wd-1: 0]	EV_out_bus [`Q_num-1:0];
wire [data_wd-1: 0]	extract_Q_0_1_EV_out, 
					extract_Q_2_3_EV_out,
					extract_Q_4_5_EV_out,
					extract_Q_6_7_EV_out,
					extract_Q_1_to_3_EV_out,
					extract_Q_4_to_7_EV_out
					;
					
wire [q_add_wd-1:0]	len_bus [`Q_num-1:0];
wire [q_add_wd-1:0]	insert_Q_len,
					insert_Q_0_1_len,
					insert_Q_2_3_len,
					insert_Q_4_5_len,
					insert_Q_6_7_len,
					insert_Q_1_to_3_len,
					insert_Q_4_to_7_len
					;
					
wire 				extract_Q_dv,					//chosen extract Q dv
					dv_in_all_Qs,
					at_least_one_Q_busy;
// wires declaratios so synthesisy tool will be happy!
wire insert_Q_dv;
wire insert_Q_1_to_3_dv;
wire insert_Q_4_to_7_dv;
wire insert_Q_0_1_dv;
wire insert_Q_2_3_dv;
wire insert_Q_4_5_dv;
wire insert_Q_6_7_dv;
wire extract_Q_1_to_3_dv;
wire extract_Q_4_to_7_dv;
wire extract_Q_0_1_dv;
wire extract_Q_2_3_dv;
wire extract_Q_4_5_dv;
wire extract_Q_6_7_dv;

					
					
					
reg extract_Q_busy;

////////////////////////////////
// inner logic implementation //
////////////////////////////////
assign length		= len_bus[0] + len_bus[1] + len_bus[2] + len_bus[3] + len_bus[4] + len_bus[5] + len_bus[6] + len_bus[7];
assign full			= q_max_len == length;
assign empty		= empty_bus[0]	&& empty_bus[1]	&& empty_bus[2]	&& empty_bus[3]	&& empty_bus[4]	&& empty_bus[5]	&& empty_bus[6]	&& empty_bus[7];
assign busy_for_wr	= busy_bus[0]		&& busy_bus[1]	&& busy_bus[2]	&& busy_bus[3]	&& busy_bus[4]	&& busy_bus[5]	&& busy_bus[6]	&& busy_bus[7];
assign busy_for_rd	= dv_in_all_Qs ? extract_Q_busy : at_least_one_Q_busy;
assign dv			= extract_Q_dv;

// Q select DECODER
always @(*) begin
	if(cs && op == `INSERT_CMD) begin
		case (insert_Q_idx)
			`Q_num_wd'd0:	cs_bus = `Q_num'b0000_0001;
			`Q_num_wd'd1:	cs_bus = `Q_num'b0000_0010;
			`Q_num_wd'd2:	cs_bus = `Q_num'b0000_0100;
			`Q_num_wd'd3:	cs_bus = `Q_num'b0000_1000;
			`Q_num_wd'd4:	cs_bus = `Q_num'b0001_0000;
			`Q_num_wd'd5:	cs_bus = `Q_num'b0010_0000;
			`Q_num_wd'd6:	cs_bus = `Q_num'b0100_0000;
			`Q_num_wd'd7:	cs_bus = `Q_num'b1000_0000;
			default:		cs_bus = `Q_num'b0000_0000;
		endcase
	end
	else if (cs && op == `EXTRACT_CMD) begin
		case (extract_Q_idx)
			`Q_num_wd'd0:	cs_bus = `Q_num'b0000_0001;
			`Q_num_wd'd1:	cs_bus = `Q_num'b0000_0010;
			`Q_num_wd'd2:	cs_bus = `Q_num'b0000_0100;
			`Q_num_wd'd3:	cs_bus = `Q_num'b0000_1000;
			`Q_num_wd'd4:	cs_bus = `Q_num'b0001_0000;
			`Q_num_wd'd5:	cs_bus = `Q_num'b0010_0000;
			`Q_num_wd'd6:	cs_bus = `Q_num'b0100_0000;
			`Q_num_wd'd7:	cs_bus = `Q_num'b1000_0000;
			default:		cs_bus = `Q_num'b0000_0000;
		endcase
	end
	else begin
		cs_bus = `Q_num'b0000_0000;
	end
end

// busy for read control mechanism
always @ (*) begin
	case(extract_Q_idx)
	`Q0_IDX: extract_Q_busy = busy_bus[0];
	`Q1_IDX: extract_Q_busy = busy_bus[1];
	`Q2_IDX: extract_Q_busy = busy_bus[2];
	`Q3_IDX: extract_Q_busy = busy_bus[3];
	`Q4_IDX: extract_Q_busy = busy_bus[4];
	`Q5_IDX: extract_Q_busy = busy_bus[5];
	`Q6_IDX: extract_Q_busy = busy_bus[6];
	`Q7_IDX: extract_Q_busy = busy_bus[7];
	default: extract_Q_busy = `FALSE;
	endcase
end

assign dv_in_all_Qs = dv_bus[0] && dv_bus[1] && dv_bus[2] && dv_bus[3] && dv_bus[4] && dv_bus[5] && dv_bus[6] && dv_bus[7];
assign at_least_one_Q_busy = busy_bus[0] || busy_bus[1] || busy_bus[2] || busy_bus[3] || busy_bus[4] || busy_bus[5] || busy_bus[6] || busy_bus[7];


///////////////////////////////////////////////////////////////////////
// 						modules instantiation 						 //			
///////////////////////////////////////////////////////////////////////

/////////////////////////
// insertion mechanizm //
/////////////////////////

// current event would be inserted into Q with minimal number of elements (minimal length)
comperator_2 #(.data_wd(q_add_wd),.idx_wd(`Q_num_wd),.hi(q_add_wd-1),.lo(0))
insert_cmp0_0(
	.c_dat	(insert_Q_len),
	.c_idx	(insert_Q_idx),
	.c_dv	(insert_Q_dv),
	
	.d0		(insert_Q_1_to_3_len),
	.d0_idx	(insert_Q_1_to_3_idx),
	.d0_dv	(insert_Q_1_to_3_dv	),
	
	.d1		(insert_Q_4_to_7_len),
	.d1_idx	(insert_Q_4_to_7_idx),
	.d1_dv	(insert_Q_4_to_7_dv	),
	
	.great_n_small(`FALSE)
	);
	
comperator_2 #(.data_wd(q_add_wd),.idx_wd(`Q_num_wd),.hi(q_add_wd-1),.lo(0))
insert_cmp1_0(
	.c_dat	(insert_Q_1_to_3_len),
	.c_idx	(insert_Q_1_to_3_idx),
	.c_dv	(insert_Q_1_to_3_dv	),
	
	.d0		(insert_Q_0_1_len),
	.d0_idx	(insert_Q_0_1_idx),
	.d0_dv	(insert_Q_0_1_dv),
	
	.d1		(insert_Q_2_3_len),
	.d1_idx	(insert_Q_2_3_idx),
	.d1_dv	(insert_Q_2_3_dv),
	
	.great_n_small(`FALSE)
	);
	

comperator_2 #(.data_wd(q_add_wd),.idx_wd(`Q_num_wd),.hi(q_add_wd-1),.lo(0))
insert_cmp1_1(
	.c_dat	(insert_Q_4_to_7_len),
	.c_idx	(insert_Q_4_to_7_idx),
	.c_dv	(insert_Q_4_to_7_dv	),
	
	.d0		(insert_Q_4_5_len),
	.d0_idx	(insert_Q_4_5_idx),
	.d0_dv	(insert_Q_4_5_dv),
	
	.d1		(insert_Q_6_7_len),
	.d1_idx	(insert_Q_6_7_idx),
	.d1_dv	(insert_Q_6_7_dv),
	
	.great_n_small(`FALSE)
	);

// compare length of Q 0 and 1 for insertion Q selection mechanizm
comperator_2 #(.data_wd(q_add_wd),.idx_wd(`Q_num_wd),.hi(q_add_wd-1),.lo(0))
insert_cmp2_1(
	.c_dat(insert_Q_0_1_len),
	.c_idx(insert_Q_0_1_idx),
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
comperator_2 #(.data_wd(q_add_wd),.idx_wd(`Q_num_wd),.hi(q_add_wd-1),.lo(0))
insert_cmp2_2(
	.c_dat(insert_Q_2_3_len),
	.c_idx(insert_Q_2_3_idx),
	.c_dv(insert_Q_2_3_dv),
	
	.d0(len_bus[2]),
	.d0_idx(`Q2_IDX),
	.d0_dv(!full_bus[2] && !busy_bus[2] ),
	
	.d1(len_bus[3]),
	.d1_idx(`Q3_IDX),
	.d1_dv(!full_bus[3] && !busy_bus[3] ),
	
	.great_n_small(`FALSE)
	);

// compare length of Q 4 and 5 for insertion Q selection mechanizm
comperator_2 #(.data_wd(q_add_wd),.idx_wd(`Q_num_wd),.hi(q_add_wd-1),.lo(0))
insert_cmp2_3(
	.c_dat(insert_Q_4_5_len),
	.c_idx(insert_Q_4_5_idx),
	.c_dv(insert_Q_4_5_dv),
	
	.d0(len_bus[4]),
	.d0_idx(`Q4_IDX),
	.d0_dv(!full_bus[4] && !busy_bus[4] ),
	
	.d1(len_bus[5]),
	.d1_idx(`Q5_IDX),
	.d1_dv(!full_bus[5] && !busy_bus[5] ),
	
	.great_n_small(`FALSE)
	);

// compare length of Q 6 and 7 for insertion Q selection mechanizm
comperator_2 #(.data_wd(q_add_wd),.idx_wd(`Q_num_wd),.hi(q_add_wd-1),.lo(0))
insert_cmp2_4(
	.c_dat(insert_Q_6_7_len),
	.c_idx(insert_Q_6_7_idx),
	.c_dv(insert_Q_6_7_dv),
	
	.d0(len_bus[6]),
	.d0_idx(`Q6_IDX),
	.d0_dv(!full_bus[6] && !busy_bus[6] ),
	
	.d1(len_bus[7]),
	.d1_idx(`Q7_IDX),
	.d1_dv(!full_bus[7] && !busy_bus[7] ),
	
	.great_n_small(`FALSE)
	);
	
//////////////////////////
// extraction mechanizm //
//////////////////////////

//next event will be extracted from Q with lowest EV_out
comperator_2 #(.data_wd(data_wd),.idx_wd(`Q_num_wd),.hi(hi),.lo(lo))
extract_cmp0_0(
	.c_dat	(EV_out),
	.c_idx	(extract_Q_idx),
	.c_dv	(extract_Q_dv),
	
	.d0		(extract_Q_1_to_3_EV_out),
	.d0_idx	(extract_Q_1_to_3_idx),
	.d0_dv	(extract_Q_1_to_3_dv	),
	
	.d1		(extract_Q_4_to_7_EV_out),
	.d1_idx	(extract_Q_4_to_7_idx),
	.d1_dv	(extract_Q_4_to_7_dv	),
	
	.great_n_small(`FALSE)
	);
	
comperator_2 #(.data_wd(data_wd),.idx_wd(`Q_num_wd),.hi(hi),.lo(lo))
extract_cmp1_0(
	.c_dat	(extract_Q_1_to_3_EV_out),
	.c_idx	(extract_Q_1_to_3_idx),
	.c_dv	(extract_Q_1_to_3_dv	),
	
	.d0		(extract_Q_0_1_EV_out),
	.d0_idx	(extract_Q_0_1_idx),
	.d0_dv	(extract_Q_0_1_dv),
	
	.d1		(extract_Q_2_3_EV_out),
	.d1_idx	(extract_Q_2_3_idx),
	.d1_dv	(extract_Q_2_3_dv),
	
	.great_n_small(`FALSE)
	);
	

comperator_2 #(.data_wd(data_wd),.idx_wd(`Q_num_wd),.hi(hi),.lo(lo))
extract_cmp1_1(
	.c_dat	(extract_Q_4_to_7_EV_out),
	.c_idx	(extract_Q_4_to_7_idx),
	.c_dv	(extract_Q_4_to_7_dv	),
	
	.d0		(extract_Q_4_5_EV_out),
	.d0_idx	(extract_Q_4_5_idx),
	.d0_dv	(extract_Q_4_5_dv),
	
	.d1		(extract_Q_6_7_EV_out),
	.d1_idx	(extract_Q_6_7_idx),
	.d1_dv	(extract_Q_6_7_dv),
	
	.great_n_small(`FALSE)
	);
	
// compare EV_out of Qs 0 and 1 for extraction mechanizm
comperator_2 #(.data_wd(data_wd),.idx_wd(`Q_num_wd),.hi(hi),.lo(lo))
extract_cmp2_0(
	.c_dat	(extract_Q_0_1_EV_out),
	.c_idx	(extract_Q_0_1_idx),
	.c_dv	(extract_Q_0_1_dv),
	
	.d0(EV_out_bus[0]),
	.d0_idx(`Q0_IDX),
	.d0_dv(dv_bus[0]),
	
	.d1(EV_out_bus[1]),
	.d1_idx(`Q1_IDX),
	.d1_dv(dv_bus[1]),
	
	.great_n_small(`FALSE)
	);

// compare EV_out of Qs 2 and 3 for extraction mechanizm
comperator_2 #(.data_wd(data_wd),.idx_wd(`Q_num_wd),.hi(hi),.lo(lo))
extract_cmp2_1(
	.c_dat	(extract_Q_2_3_EV_out),
	.c_idx	(extract_Q_2_3_idx),
	.c_dv	(extract_Q_2_3_dv),
	
	.d0(EV_out_bus[2]),
	.d0_idx(`Q2_IDX),
	.d0_dv(dv_bus[2]),
	
	.d1(EV_out_bus[3]),
	.d1_idx(`Q3_IDX),
	.d1_dv(dv_bus[3]),
	
	.great_n_small(`FALSE)
	);

	
// compare EV_out of Qs 4 and 5 for extraction mechanizm
comperator_2 #(.data_wd(data_wd),.idx_wd(`Q_num_wd),.hi(hi),.lo(lo))
extract_cmp2_2(
	.c_dat	(extract_Q_4_5_EV_out),
	.c_idx	(extract_Q_4_5_idx),
	.c_dv	(extract_Q_4_5_dv),
	
	.d0(EV_out_bus[4]),
	.d0_idx(`Q4_IDX),
	.d0_dv(dv_bus[4]),
	
	.d1(EV_out_bus[5]),
	.d1_idx(`Q5_IDX),
	.d1_dv(dv_bus[5]),
	
	.great_n_small(`FALSE)
	);

// compare EV_out of Qs 6 and 7 for extraction mechanizm
comperator_2 #(.data_wd(data_wd),.idx_wd(`Q_num_wd),.hi(hi),.lo(lo))
extract_cmp2_3(
	.c_dat	(extract_Q_6_7_EV_out),
	.c_idx	(extract_Q_6_7_idx),
	.c_dv	(extract_Q_6_7_dv),
	
	.d0(EV_out_bus[6]),
	.d0_idx(`Q6_IDX),
	.d0_dv(dv_bus[6]),
	
	.d1(EV_out_bus[7]),
	.d1_idx(`Q7_IDX),
	.d1_dv(dv_bus[7]),
	
	.great_n_small(`FALSE)
	);

//////////////////////
// Qs instantiation //
//////////////////////

Queue #(.data_wd(data_wd),
		.q_add_wd(q_add_wd-1),
		.q_max_len((q_max_len+`Q_num-1)/`Q_num),
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
		.q_max_len((q_max_len+`Q_num-1)/`Q_num),
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
		.q_max_len((q_max_len+`Q_num-1)/`Q_num),
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
		.q_max_len((q_max_len+`Q_num-1)/`Q_num),
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

 
Queue #(.data_wd(data_wd),
		.q_add_wd(q_add_wd-1),
		.q_max_len((q_max_len+`Q_num-1)/`Q_num),
		.hi(hi),
		.lo(lo)
		)
q4(
	.EV_in(EV_in),
	.op(op),
	.cs(cs_bus[4]),
	.rst(rst),
	.clk(clk),
	.EV_out(EV_out_bus[4]),
	.dv(dv_bus[4]),
	.full(full_bus[4]),
	.empty(empty_bus[4]),
	.busy(busy_bus[4]),
	.length(len_bus[4])
	);
			
Queue #(.data_wd(data_wd),
		.q_add_wd(q_add_wd-1),
		.q_max_len((q_max_len+`Q_num-1)/`Q_num),
		.hi(hi),
		.lo(lo)
		)
q5(
	.EV_in(EV_in),
	.op(op),
	.cs(cs_bus[5]),
	.rst(rst),
	.clk(clk),
	.EV_out(EV_out_bus[5]),
	.dv(dv_bus[5]),
	.full(full_bus[5]),
	.empty(empty_bus[5]),
	.busy(busy_bus[5]),
	.length(len_bus[5])
	);

Queue #(.data_wd(data_wd),
		.q_add_wd(q_add_wd-1),
		.q_max_len((q_max_len+`Q_num-1)/`Q_num),
		.hi(hi),
		.lo(lo)
		)
q6(
	.EV_in(EV_in),
	.op(op),
	.cs(cs_bus[6]),
	.rst(rst),
	.clk(clk),
	.EV_out(EV_out_bus[6]),
	.dv(dv_bus[6]),
	.full(full_bus[6]),
	.empty(empty_bus[6]),
	.busy(busy_bus[6]),
	.length(len_bus[6])
	);
				

Queue #(.data_wd(data_wd),
		.q_add_wd(q_add_wd-1),
		.q_max_len((q_max_len+`Q_num-1)/`Q_num),
		.hi(hi),
		.lo(lo)
		)
q7(
	.EV_in(EV_in),
	.op(op),
	.cs(cs_bus[7]),
	.rst(rst),
	.clk(clk),
	.EV_out(EV_out_bus[7]),
	.dv(dv_bus[7]),
	.full(full_bus[7]),
	.empty(empty_bus[7]),
	.busy(busy_bus[7]),
	.length(len_bus[7])
	);

 
endmodule 

`endif