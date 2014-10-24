// TODO define funciton for retriving left and rigth children
/*
 * Queue moudle
 * All inputs are defined in TUBOSIM spec
 *
 * INPUTS:
 *	EV_in:		input event, to be inserted into the Q
 *	op:			operation; insert command = 0, extract command = 1
 *  cs:			chip select
 *  rst:		reste, will reset all inner variables
 *  clk:		clock
 *
 * OUTPUTS:
 *	EV_out:		output event, with highest priority
 *	dv:			data valid
 *  full:		full indication
 *  empty:		empty indication
 *  busy:		busy indication
 *	length:		current number of elements in Q
 *
 * PARAMETERS:
 * 	data_wd: 	width of single Q entry.
 * 	q_add_wd:	address width of Q store element (RAM). for example
 *				q_add_wd=5 => maximal numbers of entries in q is 32.
 * 	q_max_len:	maximal length of the Q
 *	lo:			bit select. TIME low bit offset. i.e. TIME "bit location"
 *				in single Q event entry according ot SPEC
 *	hi:			bit select. TIME high bit offest
 *
 * ASSUME:
 *		1. all event values aren't negative i.e. 0 or positive number!
 *		2. data_wd have to be at least 16 bits, cause TIME constant is 16 bits
 *			digit.
 *
 * Author: Kimi
 */
`ifndef _Queue
`define _Queue

`timescale 1ns /1ps

//`include "../rtl_lib/comperator_3.v"
// `include "../rtl_lib/dp_ram_duo.v"
`include "../common_defines.v"

module Queue #(parameter data_wd=32,q_add_wd=5,q_max_len=32,hi = 15,lo = 0)
				(
				input [data_wd-1:0] EV_in,
				input op,
				input cs,
				input rst,
				input clk,
				output reg [data_wd-1:0] EV_out,
				output reg  dv,
				output wire full,
				output wire empty,
				output wire busy,
				// output wire [q_add_wd-1:0] length
				output wire [q_add_wd:0] length
				);
localparam 					STATE_WD	= 2;
localparam [STATE_WD-1:0]	WAIT_OP 	= 2'd0; //Q module in wait for operation mode
localparam [STATE_WD-1:0]	INSERT_FIRST= 2'd1;
localparam [STATE_WD-1:0]	INSERTING 	= 2'd2;
localparam [STATE_WD-1:0]	EXTRACT		= 2'd3;

`define OFFSET_BIAS	{{(q_add_wd){1'b0}},1'b1} //offset of stored indexes in ram

/* Description of the F.S.M
 * WAIT_OP state: during this state Q waites changes in input signals
 * 		and the enter into one of the following states according to
 *		to input signals. one of the following action could be completed
 * 		in this state, when there is a translation from other states
 * 		into WAIT_OP state.
 * INSERTING state: this state perform the insertin loop into Q as
 * 		it described in Corman (algorithm book)
 * INSERT_FIRST state: this is a sub routine of INSERTING state. This
 *		state needed inorder to save one cycle when inserting the first
 *		element into the Q (in compare to INSERTING state).
 * EXTRACT state: implements Q extraction algorith as it described in
 * 		Corman (algorithm book)
 */

/////////////////////////////////
// definitions of inner signals//
/////////////////////////////////
reg [q_add_wd+1:0] n;			//help vars
wire update_last;			//'1' in case we have to update last element
reg  update_last_insert_cmd;
reg  update_last_extract_cmd;
reg  update_first_wait_op_state;
							//'1' in case we have to update first elem in wait op state
reg update_first_extract_state;
							//'1' in case we have to update first elem in extract state
reg [q_add_wd+1: 0] q_len;  //hold length of the Q

reg [data_wd-1:0] last;		//stores last element in Q
reg [data_wd-1:0] key;		//samples EV_in vector
wire [data_wd-1:0] last_fast; // in case last isn't valid yet, it will hold 
                              // last value 
                              
wire [data_wd-1 :0] sml_key;//compare's smallest element data
wire [q_add_wd+1:0]	sml_idx;//compare's smallest element index
wire				sml_dv; //compare's smallest element data vaild sig

reg [STATE_WD-1:0] state;		//state of Q module F.S.M
reg [STATE_WD-1:0] prev_state;	//hold the previous state

wire [q_add_wd:0] rd_add0;	//hold address we want to read from RAM
wire [q_add_wd:0] rd_add1;

wire [data_wd-1:0] rd_dat0;	//data we read from RAM
wire [data_wd-1:0] rd_dat1;

wire [q_add_wd:0] wr_add0;//hold address we want to write to RAM
wire [q_add_wd:0] wr_add1;

wire [data_wd-1:0] wr_dat0;	//hold data we wanna write to RAM
wire [data_wd-1:0] wr_dat1;

wire [q_add_wd:0]	biased_rd_add0;	//biased addresses offest to be
wire [q_add_wd:0]	biased_wr_add0;	// written to ram.
wire [q_add_wd:0]	biased_rd_add1;
wire [q_add_wd:0]	biased_wr_add1;

wire wr_ram0,wr_ram1;		//I/O control signals of RAM element
wire rd_ram0,rd_ram1;
wire cs_ram;

wire [q_add_wd:0] d0_idx,d1_idx,d2_idx,c_idx;//cmp help wires
// wires declaratios so synthesisy tool will be happy!
wire wait_op_insert_condition;
wire wait_op_not_empty_parent_exitst;
wire wait_op_extract_condition;
wire wait_op_extract_write_last_to_head;
wire wait_op_extract_left_child_exist;
wire wait_op_extract_right_child_exist;
wire seek_for_keys_place;
wire inserting_continue_inserting;
wire inserting_key_to_its_place;
wire extract_continue_extracting;
wire extract_cont_extracting_left_child_exist;
wire extract_cont_extracting_right_child_exist;
wire extract_cont_extracting_out_of_Q_bounds;

///////////////////////
// conditional wires //
///////////////////////
// wait op state - insert
assign wait_op_insert_condition 	   = (op==`INSERT_CMD && cs==`TRUE && q_len!=q_max_len);			// Q isn't full during insertion
assign wait_op_not_empty_parent_exitst = (wait_op_insert_condition && !empty && (Parent(q_len+1) != 0));	//(A)
// wait op state - extract
assign wait_op_extract_condition 		  = (op==`EXTRACT_CMD && cs==`TRUE && q_len >= 1); 			//Q isn't empty during extraction
assign wait_op_extract_write_last_to_head = wait_op_extract_condition && (q_len != 1) ; 				// (G)
assign wait_op_extract_left_child_exist   =	wait_op_extract_condition && q_len >= 1 && ((2)<=q_len-1);	// (I)
assign wait_op_extract_right_child_exist  =	wait_op_extract_condition && q_len >= 1 && ((3)<=q_len-1);	// (J)
//inserting state
assign seek_for_keys_place 			=	(n>1 && key[hi:lo] < rd_dat1[hi:lo]);
assign inserting_continue_inserting =	(state == INSERTING) && seek_for_keys_place;	//(B), (C)
assign inserting_key_to_its_place 	=	(state == INSERTING) && !seek_for_keys_place;	// (D)
//extract state
assign extract_continue_extracting 				= 	(state == EXTRACT && sml_idx != n);
assign extract_cont_extracting_left_child_exist =	extract_continue_extracting && (LeftChild(sml_idx)<=q_len) ;		//(M)
assign extract_cont_extracting_right_child_exist=	extract_continue_extracting && (RightChild(sml_idx)<=q_len) ;	//(N)
assign extract_cont_extracting_out_of_Q_bounds	=	extract_continue_extracting && (!IsExist(LeftChild(sml_idx)) && !IsExist(RightChild(sml_idx)));

assign update_last = update_last_insert_cmd | update_last_extract_cmd;

// Q management FSM
always @(posedge clk) begin
	if(rst) begin
		//reset output signals
		EV_out 	<= #5 {data_wd{1'b0}};
		dv 		<= #5 `FALSE;
		q_len	<= #5 {(q_add_wd+2){1'b0}};
		//reset states
		state		<= #5 WAIT_OP;
		//reset inner vars
		n			<= #5 {(q_add_wd+2){1'b0}};
		last		<= #5 {data_wd{1'b0}};
		key			<= #5 {data_wd{1'b0}};
		update_last_insert_cmd	<= #5 `FALSE;
		update_last_extract_cmd<= #5 `FALSE;
		update_first_wait_op_state	<= #5 `FALSE;
		update_first_extract_state	<= #5 `FALSE;
	end
	else begin
		case(state)
		WAIT_OP:begin
			if(wait_op_insert_condition) begin
				key		<= #5 EV_in;
				q_len	<= #5 q_len + 1'b1;
				n		<= #5 q_len + 1'b1;

				if(!empty) begin
					state		<= #5 INSERTING;
					update_last_insert_cmd	<= #5 `TRUE;
					//if((q_len+1)>>1 != 0)	// in case parent exist
					//	rd_add1 = #5 (q_len+1)>>1;	//get key's parent (A)
				end
				else begin	// Q is empty
					state	<= #5 INSERT_FIRST;
				end

				if(q_len>0 && EV_out[hi:lo] <= EV_in[hi:lo])	// first element will be updated
					dv	<= #5 `TRUE;
				else
					dv	<= #5 `FALSE;
			end
			else if (wait_op_extract_condition) begin
				q_len	<= #5 q_len - 1'b1;
				dv		<= #5 `FALSE;
				n		<= #5 { {(q_add_wd){1'b0}} , 1'b1 };	// set n=1
				key		<= #5 last_fast;								// save last node (that is inserted into Q[1])

				if(q_len == 1) begin
					state	<= WAIT_OP;
					update_first_wait_op_state	<= #5 `TRUE;
				end
				else begin
					update_first_extract_state	<= #5 `TRUE;
					state	<= #5 EXTRACT;
					// wr_add0 = 1;			// write last node to Q's head - Q[1] (G)
					// wr_dat0 = last;
					// cs_ram  = 1; wr_ram0 = 1;
				// if((2)<=q_len-1)	//read left child (I)
					// rd_add0 = (2);
				// if((3)<=q_len-1)	//read right child (J)
					// rd_add1 = (3);
				end
			end

			if(prev_state==INSERTING && update_first_wait_op_state) begin
				EV_out	<= #5 rd_dat0;	// complete read first elem from INSERTING state
				dv		<= #5 `TRUE;
				update_first_wait_op_state <= #5 `FALSE;
			end
			if(prev_state==EXTRACT && update_last) begin
				last		<= #5 rd_dat0;
				if( update_last_insert_cmd )  // deassert corespongind update cmd
				  update_last_insert_cmd <= #5 `FALSE;
				else
				  update_last_extract_cmd <= #5 `FALSE;
			end
		end

		INSERT_FIRST:begin
			last	<= #5 key;
			EV_out	<= #5 key;
			//wr_add0	<= #5 1;	//write key to first palace in RAM (F)
			//wr_dat0	<= #5 key;
			state	<= #5 WAIT_OP;
			dv		<= #5 `TRUE;
		end

		INSERTING:begin
			if(n>1 && key[hi:lo] < rd_dat1[hi:lo]) begin
				//wr_dat0 <= #5 rd_dat1;	// insert parent to lower level node (B)
				//wr_add0 <= #5 n;
				n	<= #5 n>>1;
				//rd_add1 <= #5 n>>2;		// read parent node from rd_dat1 (C)
				if(update_last) begin
					last		<= #5 rd_dat1;
					if( update_last_insert_cmd )  // deassert corespongind update cmd
            update_last_insert_cmd <= #5 `FALSE;
				  else
				    update_last_extract_cmd <= #5 `FALSE;
				end
			end
			else begin // insert key element into its place
				if(update_last) begin
					last <= #5 key;
					if( update_last_insert_cmd )  // deassert corespongind update cmd
            update_last_insert_cmd <= #5 `FALSE;
				  else
				    update_last_extract_cmd <= #5 `FALSE;
				end
				//wr_dat0	<= #5 key;	//insert key elem to its place (D)
				//wr_add0	<= #5 n;

				if(wr_add0 != rd_add0) begin//to prevent read & write to same add
					//rd_add0	<= #5 1;	//read first elem (E)
					update_first_wait_op_state	<= #5 `TRUE;
				end
				else begin
					EV_out	<= #5 key;
					dv		<= #5 `TRUE;
					update_first_wait_op_state	<= #5 `FALSE;
				end
				state	<= #5 WAIT_OP;	//go to wait op sate
			end
		end// end of INSERTING case

		EXTRACT:begin
			if(sml_idx != n) begin	//rd_dat0 treated as left child
									//rd_dat1 as right child

				// wr_dat0 = sml_key;	//swap n-th with sml_idx's elements
				// wr_add0 = n;			//enter sml_key to n-th place (K)
				// wr_ram0 = 1;
				// cs_ram  = 1;

				// wr_dat1 = key;		//enter key to sml_idx's place (L)
				// wr_add1 = sml_idx;
				// wr_ram = 1;

				n <= #5 sml_idx;

				// if((sml_idx<<1)<=q_len)	//read left child (M)
					// rd_add0 = (sml_idx<<1);
					// rd_ram0 = 1;

				// if(((sml_idx<<1)+1)<=q_len)//read right child (N)
					// rd_add1 = ((sml_idx<<1)+1);
					// rd_ram1 = 1;

				if(!IsExist(LeftChild(sml_idx)) && !IsExist(RightChild(sml_idx))) begin // we are out of Q bounds
					state	<= #5 WAIT_OP;
					dv		<= #5 `TRUE;
					if(q_len[q_add_wd:0] == wr_add1) begin// to prevent rd & wr to same address
						update_last_extract_cmd <= #5 `FALSE;
						last <= #5 wr_dat1;
					end
					else begin
						//rd_add0 = q_len		// update last elem (O)
						//rd_ram0 = 1;
						update_last_extract_cmd <= #5 `TRUE;
					end
				end
			end
			else begin
				//rd_add0 = q_len		// update last elem (P)
				//rd_ram0 = 1;
				update_last_extract_cmd	<= #5 `TRUE;
				state		<= #5 WAIT_OP;
			end

			if(update_first_extract_state) begin
					EV_out		<= #5 sml_key;
					dv			<= #5 `TRUE;
					update_first_extract_state<= #5 `FALSE;
			end

		end	// end of EXTRACT case
		endcase	//end of state case
	end
end

////////////////////////
//Q I/O wires control //
////////////////////////
assign busy =	(state != WAIT_OP);
assign empty=	(q_len==0);
assign full =	(q_len==q_max_len);
// assign length=	q_len[q_add_wd-1:0];
assign length=	q_len;

///////////////////////////
//ram IO signals control //
///////////////////////////
assign cs_ram = (	wait_op_not_empty_parent_exitst		//(A)
				||	(state==INSERTING	)				//(B),(C),(D),(E)
				||	(state==INSERT_FIRST)				//(F)
				||	wait_op_extract_write_last_to_head	//(G)
				||	(state==EXTRACT)					//(K),(L),(M),(N),(O),(P)
				);

assign wr_ram0 =(	(state==INSERTING 	)				//(B),(D)
				||	(state==INSERT_FIRST)				//(F)
				||	(wait_op_extract_write_last_to_head)//(G)
				||	(extract_continue_extracting)		//(K)
				);

assign wr_ram1 =(	(extract_continue_extracting)		//(L)
				);

assign rd_ram0 =(	(inserting_key_to_its_place && wr_add0 != rd_add0)//(E)
				||	(wait_op_extract_left_child_exist)			//(I)
				||	(extract_cont_extracting_left_child_exist)	//(M)
				||	(extract_cont_extracting_out_of_Q_bounds
						&& q_len[q_add_wd:0] != wr_add1)					//(O)
				|| (state==EXTRACT && sml_idx==n)				//(P)
				);

assign rd_ram1 =(	(wait_op_not_empty_parent_exitst)			//(A)
				||	(inserting_continue_inserting)				//(C)
				||	(wait_op_extract_right_child_exist)			//(J)
				||	(extract_cont_extracting_right_child_exist)	//(N)
				);

////////////////////////////
// muxing ram I/O signals //
////////////////////////////
assign rd_add0 = (state==INSERTING)						 	//(E)
				? {{(q_add_wd-1){1'b0}},1'b1}	//assign 0..01    TODO change
				: (wait_op_extract_left_child_exist)			//(I)
				? {{(q_add_wd-2){1'b0}},2'b10}	// assign 0..010 (2)   TODO change
				: (extract_cont_extracting_left_child_exist)	//(M)
				? LeftChild(sml_idx)
				: (extract_cont_extracting_out_of_Q_bounds
						&& q_len[q_add_wd:0] != wr_add1)					//(O)    todo change
				? q_len[q_add_wd:0]   // todo change
				: (state==EXTRACT  && sml_idx==n)				//(P)
				? q_len[q_add_wd:0]   // todo change
				: {(q_add_wd){1'b0}};				//assign 0..00  todo change

assign rd_add1 = (wait_op_not_empty_parent_exitst)				//(A)
				? Parent(q_len+1)	// get key's parent
				: (inserting_continue_inserting)				//(C)
				? n>>2 		//read upper node
				: (wait_op_extract_right_child_exist)			//(J)
				? {{(q_add_wd-1){1'b0}},2'b11}	// assign 0..011 (3)   todo change
				: (extract_cont_extracting_right_child_exist)	//(N)
				? RightChild(sml_idx)
				: {(q_add_wd){1'b0}};

assign wr_add0 = (state==INSERTING)							//(B),(D)
				? n[q_add_wd:0]   // todo change
				: (state==INSERT_FIRST)						//(F)
				? {{(q_add_wd){1'b0}},1'b1}	// assign 0..01  todo change
				: (wait_op_extract_write_last_to_head)			//(G),TODO combine with case (F)
				? {{(q_add_wd){1'b0}},1'b1}	// assign 0..01  todo change
				: (extract_continue_extracting)					//(K)
				? n[q_add_wd:0]   // todo change
				: {(q_add_wd){1'b0}};

assign wr_add1 = (extract_continue_extracting)			//(L)
				? sml_idx
				: {(q_add_wd){1'b0}};

assign wr_dat0 = (inserting_continue_inserting)			//(B)
				? rd_dat1
				: (inserting_key_to_its_place)			//(D)
				? key
				: (state==INSERT_FIRST)				//(F), TODO combine with case (D)
				? key
				: (wait_op_extract_write_last_to_head)	//(G)
				? last_fast 
				: (extract_continue_extracting)			//(K)
				? sml_key
				: {data_wd{1'b0}};
// update last==1 and last isn't valid here thus take last elem from rd_dat0				
assign last_fast = (update_last && wait_op_extract_write_last_to_head )? rd_dat0 : last;

assign wr_dat1 = (extract_continue_extracting)			//(L)
				? key
				: {data_wd{1'b0}};

/////////////////////////////////////
// bias offset of addresses in ram //
/////////////////////////////////////
assign biased_rd_add0 = rd_add0 - `OFFSET_BIAS;
assign biased_rd_add1 = rd_add1 - `OFFSET_BIAS;
assign biased_wr_add0 = wr_add0 - `OFFSET_BIAS;
assign biased_wr_add1 = wr_add1 - `OFFSET_BIAS;

////////////////////////
// previous state FSM //
////////////////////////
always @(posedge clk) begin
	if(rst)
		prev_state	<= #5 WAIT_OP;
	else
		prev_state	<= #5 state;
end


///////////////////////////
// modules instantiation //
///////////////////////////

// depth = 2^(q_add_wd)
dp_ram_duo #(q_add_wd+1,data_wd, q_max_len)
ram	(
	.clk(clk),
	.cs(cs_ram),
	.rst(rst),
	.rd0(rd_ram0),
	.rd1(rd_ram1),
	.wr0(wr_ram0),
	.wr1(wr_ram1),
	.rd_add0(biased_rd_add0),
	.wr_add0(biased_wr_add0),
	.rd_add1(biased_rd_add1),
	.wr_add1(biased_wr_add1),
	.wr_data0(wr_dat0),
	.wr_data1(wr_dat1),
	.rd_data0(rd_dat0),
	.rd_data1(rd_dat1)
	);

// help wires assingnemt, so i can choose their width to be assigned
assign d0_idx = LeftChild(n);
assign d1_idx = RightChild(n);
assign d2_idx = n;


assign sml_idx = {{1'b0},{c_idx}};  // todo change it

// find minimal event amonge 3 nodes in Q: left child, right child
// and their parent. returnt the minimal event and it's index
comperator_3 #(.data_wd(data_wd),.idx_wd(q_add_wd+1),.hi(hi),.lo(lo))
cmp(
	.great_n_small(`FALSE),
	.c_dat(sml_key),			//out put
	.c_idx(c_idx),
	.c_dv(sml_dv),
	.d0(rd_dat0),				//input 0, left child
	.d0_idx(d0_idx),
	.d0_dv(IsExist(LeftChild(n))),
	.d1(rd_dat1),				//input 1, rigth child
	.d1_idx(d1_idx),		//((n<<1)+1)
	.d1_dv(((n<<1)+1) <= q_len),
	.d2(key),					//input 2, current node
	.d2_idx(d2_idx),
	.d2_dv(`TRUE)
);

  // returns parent index of idx
  function automatic [q_add_wd-1:0] Parent(input reg [q_add_wd-1:0] i);
    //Parent = (i-1)/2;//use when indexes based from 0
    Parent = i/2;
  endfunction
  
  // returns left child index of idx
  function automatic [q_add_wd-1:0] LeftChild(input reg [q_add_wd-1:0] i);
    //LeftChild = (2*i)+1; //use when indexes based from 0
    LeftChild = 2*i;
  endfunction
  
  // returns right child index of idx
  function automatic [q_add_wd-1:0] RightChild(input reg [q_add_wd-1:0] i);
    //RightChild = 2*(i+1); //use when indexes based from 0
    RightChild = 2*i + 1;
  endfunction
  
  function automatic IsExist( input reg [q_add_wd-1:0] i);
    IsExist = (i <= q_len);
  endfunction
  
endmodule

`endif
