`ifndef _turbosim
`define _turbosim

`timescale 1ns /1ps
`include "common_defines.v"
`include "compilation_flags.v"
//`include "rtl_lib/dp_ram.v"

// (un)comment this to disable debug prints
// `define TURBOSIM_DEBUG
// `define PRINT_STATISTICS

/* 
 * Turbosim main module.
 *
 * Input parameters:
 *	clk: input clock for turbosim.
 *	rst: reset the module.
 *	go: begin simulation round.
 *	wr: writes a stimuli to turbosim.
 *	rd: reads an event from turbosim.
 *	in_record: the record to write.
 *
 * Output parameters:
 *	done: high if turbosim is done.
 *	full: high if turbosim's output data structure is full.
 *	empty: high if turbosim's output data structure is empty.
 *	status: can be TURBOSIM_STATUS_OK, TURBOSIM_STATUS_EQ_FULL or TURBOSIM_STATUS_CTU_FULL.
 *	out_record: an output event record.
 *
 * Author: Inger & Michael Kimi
 */
module turbosim(
	input clk, 
	input rst, 
	input go,	
	output reg done, 
	input wr, 
	input rd, 
	output full, 
	output empty, 
	output reg [1:0] status, 
	input [31:0] in_record, 
	output [31:0] out_record
);
	// state registers
	reg [3:0] state;

	reg [15:0] sim_time;

	// input fifo
	wire		in_fifo_rd;
	wire [31:0] in_fifo_rd_data;
	wire		in_fifo_empty;

	// output fifo
	wire		out_fifo_full;
	reg			out_fifo_wr_sel;
	wire		out_fifo_wr;
	wire [31:0] out_fifo_wr_data;

	// ctu
	wire [10:0] ctu_ev_in;
	wire [10:0] ctu_ev_out;
	wire		ctu_cs;
	wire		ctu_rd;
	wire		ctu_wr;
	wire		ctu_empty;
	wire		ctu_full;
	wire [7:0]	ctu_length;

	// event queue
	wire		eq_op;
	wire		eq_cs;
	wire [32:0] eq_ev_in, eq_ev_out;
	wire		eq_busy_rd;
	wire		eq_busy_wr;
	wire		eq_dv;
	wire		eq_empty;
	wire		eq_full;
	wire [7:0]	eq_length;
	reg			eq_op_reg;
	reg			eq_is_zero_delay_reg;
	
	// net RAM
	reg  [111:0]	net_ram_wr_data_reg;
	reg  [10:0]		net_ram_wr_add_reg, net_ram_rd_add_reg;
	wire [111:0]	net_ram_wr_data, net_ram_rd_data;
	wire [10:0]		net_ram_wr_add, net_ram_rd_add;
	wire			net_ram_cs;
	
	// cell RAM
	wire [95:0]		cell_ram_rd_data, cell_ram_wr_data;
	wire [10:0]		cell_ram_rd_add, cell_ram_wr_add;
	wire cell_ram_cs;

	// GET_INPUTS state
	reg [31:0]	get_inputs_saved_in_record;
	reg			get_inputs_start_pipeline;
	wire		get_inputs_end_pipeline;
	wire		get_inputs_suspend_pipeline;
	wire		get_inputs_read_net_ram;
	wire		get_inputs_push_to_eq_update_net_ram;

	// SOLVE state
	reg [32:0]	solve_event;
	reg [95:0]	solve_cell_ram_wr_data;
	reg [111:0]	solve_net;
	reg [1:0]	solve_net_new_value;
	reg [10:0]	solve_ctu_data;
	reg [2:0]	solve_current_load;
	reg [10:0]	solve_cell_ram_rd_add, solve_cell_ram_wr_add;
	reg [3:0]	solve_curr_pin_idx, solve_prev_pin_idx;
	reg			solve_dequeue_event;
	reg			solve_write_event_to_net_ram;
	reg			solve_write_to_ctu;
	reg			solve_read_net_event;
	reg			solve_cell_ram_rd, solve_cell_ram_wr;
	
	// Statistic counters
	reg [15:0]	stat_busy_for_write;
	reg [15:0]	stat_busy_for_read_stall;
	reg [15:0]	stat_dv_stall;
	reg [15:0]	stat_sim_iteration_clk_count;
	
	// GENERATE_EVENTS state
	reg [2:0]	generate_events_pipeline_status;
	reg [1:0]	generate_events_evaluated_value;
	reg [10:0]	generate_events_net_idx;
	reg [15:0]	generate_events_cell_delay;
	wire		generate_events_suspend_pipeline;
	wire		generate_events_stage_1, generate_events_stage_2, generate_events_stage_3;
	wire		generate_events_stage_1_active, generate_events_stage_2_active, generate_events_stage_3_active;
	wire		generate_events_all_one, generate_events_all_zero, generate_events_at_least_one_one, generate_events_at_least_one_zero;
	wire		generate_events_create_new_event;
	
	wire get_inputs_in_pipeline;
	wire net_ram_rd;
	wire net_ram_wr;
	wire cell_ram_rd;
	wire cell_ram_wr;
	wire eq_is_zero_delay;

	
	// generate events pipeline stage
	`define GENERATE_EVENTS_PIPELINE_1		0
	`define GENERATE_EVENTS_PIPELINE_12		1
	`define GENERATE_EVENTS_PIPELINE_123	2
	`define GENERATE_EVENTS_PIPELINE_23		3
	`define GENERATE_EVENTS_PIPELINE_3		4

	// turbosim states
	`define WAIT_GO					0
	`define INITIALIZE_ROUND		1
	`define GET_INPUTS				2
	`define SOLVE_1					3
	`define SOLVE_2					4
	`define SOLVE_3					5
	`define SOLVE_4					6
	`define GENERATE_EVENTS			7
	`define OUTPUT					8
	
	`ifdef SIMULATION
	// show human-readable state string
	reg [8*16 - 1:0] state_str;
	always @(state) begin
		case (state)
			`INITIALIZE_ROUND:		state_str = "INITIALIZE_ROUND";
			`WAIT_GO:				state_str = "WAIT_GO";
			`GET_INPUTS:			state_str = "GET_INPUTS";
			`SOLVE_1:				state_str = "SOLVE_1";
			`SOLVE_2:				state_str = "SOLVE_2";
			`SOLVE_3:				state_str = "SOLVE_3";
			`SOLVE_4:				state_str = "SOLVE_4";
			`GENERATE_EVENTS:		state_str = "GENERATE_EVENTS";
			`OUTPUT:				state_str = "OUTPUT";
			default:				state_str = "UNKNOWN";
		endcase
	end
   `endif
   
	always @(posedge clk)
	if (rst) begin
		state <= #1 `INITIALIZE_ROUND;
	end
	else 
		case (state)
			`INITIALIZE_ROUND: begin
				sim_time     <= #1 0;
				done         <= #1 1;
				
				get_inputs_start_pipeline <= #1 `TRUE;
				get_inputs_saved_in_record <= #1 0;
				
				solve_dequeue_event <= #1 `FALSE;
				solve_event <= #1 0;
				solve_write_event_to_net_ram <= #1 `FALSE;
				solve_net_new_value <= #1 `FALSE;
				solve_write_to_ctu <= #1 `FALSE;
				solve_current_load <= #1 0;
				solve_net <= #1 0;
				solve_ctu_data <= #1 0;
				solve_read_net_event <= #1 `FALSE;
				solve_cell_ram_rd <= #1 `FALSE;
				solve_cell_ram_wr <= #1 `FALSE;
				solve_cell_ram_rd_add <= #1 0;
				solve_cell_ram_wr_add <= #1 0;
				solve_prev_pin_idx <= #1 0;
				solve_curr_pin_idx <= #1 0;

				generate_events_pipeline_status <= #1 `GENERATE_EVENTS_PIPELINE_1;
				generate_events_evaluated_value <= #1 0;
				generate_events_net_idx <= #1 0;
				generate_events_cell_delay <= #1 0;

				stat_busy_for_write	<= #1 0;
				stat_busy_for_read_stall <= #1 0;
				stat_dv_stall <= #1 0;
				
				state        <= #1 `WAIT_GO;
			end
			`WAIT_GO:
				if (go) begin
					done	<= #1 0;

					if (in_fifo_empty)
						state	<= #1 `OUTPUT;
					else
						state	<= #1 `GET_INPUTS;
				end
			`GET_INPUTS: begin
				// the 2-stage pipeline is as follows:
				// stage 1: read the stimuli from the input FIFO and set the net RAM to read the appropriate related net
				// stage 2: insert event to the event queue and update the net RAM
				// if the event queue is busy we hold the entire pipeline until we can execute stage 2
				if (!get_inputs_suspend_pipeline) begin
					// read the input fifo until it's empty
					if (!in_fifo_empty) begin
						// this is the beginning of the pipeline
						if (get_inputs_start_pipeline) begin
							get_inputs_start_pipeline <= #1 `FALSE;
						end
						get_inputs_saved_in_record <= #1 in_fifo_rd_data;
					end
					else begin
						state <= #1 `SOLVE_1;
					end
				end
				else begin// Kimi, added here counter of stalls while writing to EQ in GET INPUTS 
					stat_busy_for_write<= #1 stat_busy_for_write + 1'b1;
				end
				
			end // case: `GET_INPUTS
			`SOLVE_1: begin
				// stop reading and writing from cell ram (from SOLVE_4)
				solve_cell_ram_wr <= #1 `FALSE;
				// stop writing to net ram (net value)
				solve_write_event_to_net_ram <= #1 `FALSE;

				// no more events, we're done here
				if (eq_empty && ctu_empty) begin
					state <= #1 `OUTPUT;
				end	
				else if (eq_empty) begin // ctu is not empty
					state <= #1 `GENERATE_EVENTS;
				end
				else begin // the event queue is not empty
					// eq data must be valid
					if (eq_dv) begin
						// *peek* at the upcoming event and compare to the simlator's time
						if (eq_ev_out[`EQ_TIME] != sim_time && !ctu_empty) begin
							// ctu is not empty, we need to generate new events
							state <= #1 `GENERATE_EVENTS;
						end
						else if (!eq_busy_rd) begin // wait until we can dequeue the event
							// the topmost event's time is different than the current time
							if (eq_ev_out[`EQ_TIME] != sim_time)
								`ifdef TURBOSIM_DEBUG
									if (eq_ev_out[`EQ_TIME] < sim_time) begin
										$display("[Error!] Decreasing time from %d ps to %d ps", sim_time, eq_ev_out[`EQ_TIME]);
									end
								`endif
								// ctu is empty, update simulator's time
								sim_time <= #1 eq_ev_out[`EQ_TIME];

							// dequeue the event
							solve_dequeue_event <= #1 `TRUE;

							// store currently handled event
							solve_event <= #1 eq_ev_out;

							// read the net record related to the peeked event
							solve_read_net_event <= #1 `TRUE;
	
							// finished reading the input FIFO and writing everything to the EQ, move to solving stage
							state <= #1 `SOLVE_2;
						end
						else begin// Kimi: added here counter for bz for read from EQ durig solve 1 state
							stat_busy_for_read_stall <= #1 stat_busy_for_read_stall + 1'b1;
						end
					end
					else begin // Kimi, added here counter for stalls till eq_dv is up
						stat_dv_stall <= #1 stat_dv_stall + 1'b1;
					end
				end
			end
			`SOLVE_2: begin
				// wait for net ram data

				// stop dequeuing
				solve_dequeue_event <= #1 `FALSE;

				state <= #1 `SOLVE_3;
			end
			`SOLVE_3: begin
				`ifdef TURBOSIM_DEBUG
					$display("(%0d ps) [Event Processing] Net: 0x%0x (%0d), Value: %0x [Simtime %0d]", sim_time, solve_event[`EQ_NET_INDEX], solve_event[`EQ_NET_INDEX], solve_event[`EQ_NEXT_VALUE], $stime);
				`endif

				// store data from net RAM
				solve_net <= #1 net_ram_rd_data;

				// stop reading net events
				solve_read_net_event <= #1 `FALSE;

				// if the current value of the net is different than the event's value and the fetched event is the most updated event
				// we have in the system, we process this event. Otherwise we drop it.
				if (net_ram_rd_data[`NET_RAM_CURRENT_VALUE] == solve_event[`EQ_NEXT_VALUE] || (!solve_event[`EQ_IS_STIMULUS] && net_ram_rd_data[`NET_RAM_NEXT_EV_TIME] != sim_time)) begin
					state <= #1 `SOLVE_1;
				end
				else begin
					// execute the event
					solve_net_new_value <= #1 solve_event[`EQ_NEXT_VALUE];

					// push output record to output FIFO

					// add first pushed cell if available, otherwise we have no pushed cells and we can go back to step a.
					if (net_ram_rd_data[`NET_RAM_NET_LOAD0_V]) begin
						solve_ctu_data <= #1 net_ram_rd_data[`NET_RAM_NET_LOAD0_IDX];

						`ifdef TURBOSIM_DEBUG
							$display("(%0d ps) [CTU Insert] Cell: 0x%0x (%0d), Caused by net: 0x%0x (%0d) [Simtime %0d]", sim_time, net_ram_rd_data[`NET_RAM_NET_LOAD0_IDX], 
							net_ram_rd_data[`NET_RAM_NET_LOAD0_IDX], solve_event[`EQ_NET_INDEX], solve_event[`EQ_NET_INDEX], $stime);
						`endif
						solve_current_load <= #1 3'b1;
						solve_write_to_ctu <= #1 `TRUE;
						state <= #1 `SOLVE_4;

						// start reading from cell RAM to update net's value
						solve_cell_ram_rd <= #1 `TRUE;
						solve_cell_ram_rd_add <= #1 net_ram_rd_data[`NET_RAM_NET_LOAD0_IDX];
						solve_prev_pin_idx <= #1 net_ram_rd_data[`NET_RAM_NET_LOAD0_PIN];
					end
					else begin
						solve_write_event_to_net_ram <= #1 `TRUE;
						state <= #1 `SOLVE_1;
					end
				end
			end
			`SOLVE_4: begin
				// begin writing data to cell RAM
				solve_cell_ram_wr <= #1 `TRUE;
				solve_cell_ram_wr_add <= #1 solve_cell_ram_rd_add;
				solve_curr_pin_idx <= #1 solve_prev_pin_idx;

				// insert up to 3 more cells into the CTU, go back to step a when there's an invalid load or if we've gone over all the 3
				case (solve_current_load)
					1: begin
						if (net_ram_rd_data[`NET_RAM_NET_LOAD1_V]) begin
							solve_ctu_data <= #1 net_ram_rd_data[`NET_RAM_NET_LOAD1_IDX];

							`ifdef TURBOSIM_DEBUG
								$display("(%0d ps) [CTU Insert] Cell: 0x%0x (%0d), Caused by net: 0x%0x (%0d) [Simtime %0d]", sim_time, net_ram_rd_data[`NET_RAM_NET_LOAD1_IDX],
								net_ram_rd_data[`NET_RAM_NET_LOAD1_IDX], solve_event[`EQ_NET_INDEX], solve_event[`EQ_NET_INDEX], $stime);
							`endif
							state <= #1 `SOLVE_4;
							solve_current_load <= #1 solve_current_load + 1'b1;

							solve_prev_pin_idx <= #1 net_ram_rd_data[`NET_RAM_NET_LOAD1_PIN];
							solve_cell_ram_rd_add <= #1 net_ram_rd_data[`NET_RAM_NET_LOAD1_IDX];
						end
						else begin
							solve_write_event_to_net_ram <= #1 `TRUE;
							state <= #1 `SOLVE_1;
							solve_write_to_ctu <= #1 `FALSE;
							solve_current_load <= #1 3'b0;
							solve_cell_ram_rd <= #1 `FALSE;
						end
					end
					2: begin
						if (net_ram_rd_data[`NET_RAM_NET_LOAD2_V]) begin
							solve_ctu_data <= #1 net_ram_rd_data[`NET_RAM_NET_LOAD2_IDX];

							`ifdef TURBOSIM_DEBUG
								$display("(%0d ps) [CTU Insert] Cell: 0x%0x (%0d), Caused by net: 0x%0x (%0d) [Simtime %0d]", sim_time, net_ram_rd_data[`NET_RAM_NET_LOAD2_IDX], 
								net_ram_rd_data[`NET_RAM_NET_LOAD2_IDX], solve_event[`EQ_NET_INDEX], solve_event[`EQ_NET_INDEX], $stime);
							`endif
							state <= #1 `SOLVE_4;
							solve_current_load <= #1 solve_current_load + 1'b1;

							solve_prev_pin_idx <= #1 net_ram_rd_data[`NET_RAM_NET_LOAD2_PIN];
							solve_cell_ram_rd_add <= #1 net_ram_rd_data[`NET_RAM_NET_LOAD2_IDX];
						end
						else begin
							solve_write_event_to_net_ram <= #1 `TRUE;
							state <= #1 `SOLVE_1;
							solve_write_to_ctu <= #1 `FALSE;
							solve_current_load <= #1 3'b0;
							solve_cell_ram_rd <= #1 `FALSE;
						end
					end
					3: begin
						if (net_ram_rd_data[`NET_RAM_NET_LOAD3_V]) begin
							solve_ctu_data <= #1 net_ram_rd_data[`NET_RAM_NET_LOAD3_IDX];

							`ifdef TURBOSIM_DEBUG
								$display("(%0d ps) [CTU Insert] Cell: 0x%0x (%0d), Caused by net: 0x%0x (%0d) [Simtime %0d]", sim_time, net_ram_rd_data[`NET_RAM_NET_LOAD3_IDX], 
								net_ram_rd_data[`NET_RAM_NET_LOAD3_IDX], solve_event[`EQ_NET_INDEX], solve_event[`EQ_NET_INDEX], $stime);
							`endif
							state <= #1 `SOLVE_4;
							solve_current_load <= #1 solve_current_load + 1'b1;

							solve_prev_pin_idx <= #1 net_ram_rd_data[`NET_RAM_NET_LOAD3_PIN];
							solve_cell_ram_rd_add <= #1 net_ram_rd_data[`NET_RAM_NET_LOAD3_IDX];
						end
						else begin
							solve_write_event_to_net_ram <= #1 `TRUE;
							state <= #1 `SOLVE_1;
							solve_write_to_ctu <= #1 `FALSE;
							solve_current_load <= #1 3'b0;
							solve_cell_ram_rd <= #1 `FALSE;
						end
					end
					4: begin
							solve_write_event_to_net_ram <= #1 `TRUE;
							state <= #1 `SOLVE_1;
							solve_write_to_ctu <= #1 `FALSE;
							solve_current_load <= #1 3'b0;
							solve_cell_ram_rd <= #1 `FALSE;
						end
				endcase
			end
			`GENERATE_EVENTS: begin
				// work only if pipeline is not suspended
				if (!generate_events_suspend_pipeline) begin
					// generate events until the CTU is empty
					if (ctu_empty) begin
						// clear the pipeline and go back to solving stage when done
						if (generate_events_stage_2_active)
							generate_events_pipeline_status <= #1 `GENERATE_EVENTS_PIPELINE_3;
						else begin
							// reset pipeline and go back to SOLVE_1
							generate_events_pipeline_status <= #1 `GENERATE_EVENTS_PIPELINE_1;
							state <= #1 `SOLVE_1;
						end
					end
					else begin
						if (generate_events_pipeline_status == `GENERATE_EVENTS_PIPELINE_1)
							generate_events_pipeline_status <= #1 `GENERATE_EVENTS_PIPELINE_12;
						else if (generate_events_pipeline_status == `GENERATE_EVENTS_PIPELINE_12)
							generate_events_pipeline_status <= #1 `GENERATE_EVENTS_PIPELINE_123;
					end

					// evaluate updated value of cell's output net
					if (generate_events_stage_2_active) begin
						case (cell_ram_rd_data[`CELL_RAM_TYPE])
							`CELL_TYPE_NOT:
								case (cell_ram_rd_data[`CELL_RAM_NET_INPUT0_VAL])
									`VALUE_0: generate_events_evaluated_value <= #1 `VALUE_1;
									`VALUE_1: generate_events_evaluated_value <= #1 `VALUE_0;
									default: generate_events_evaluated_value <= #1 `VALUE_X;
								endcase
							`CELL_TYPE_BUF:
								case (cell_ram_rd_data[`CELL_RAM_NET_INPUT0_VAL])
									`VALUE_0: generate_events_evaluated_value <= #1 `VALUE_0;
									`VALUE_1: generate_events_evaluated_value <= #1 `VALUE_1;
									default: generate_events_evaluated_value <= #1 `VALUE_X;
								endcase
							`CELL_TYPE_AND:
								if (generate_events_at_least_one_zero)
									generate_events_evaluated_value <= #1 `VALUE_0;
								else if (generate_events_all_one)
									generate_events_evaluated_value <= #1 `VALUE_1;
								else
									generate_events_evaluated_value <= #1 `VALUE_X;
							`CELL_TYPE_OR:
								if (generate_events_at_least_one_one)
									generate_events_evaluated_value <= #1 `VALUE_1;
								else if (generate_events_all_zero)
									generate_events_evaluated_value <= #1 `VALUE_0;
								else
									generate_events_evaluated_value <= #1 `VALUE_X;
							`CELL_TYPE_NAND:
								if (generate_events_at_least_one_zero)
									generate_events_evaluated_value <= #1 `VALUE_1;
								else if (generate_events_all_one)
									generate_events_evaluated_value <= #1 `VALUE_0;
								else
									generate_events_evaluated_value <= #1 `VALUE_X;
							`CELL_TYPE_NOR:
								if (generate_events_at_least_one_one)
									generate_events_evaluated_value <= #1 `VALUE_0;
								else if (generate_events_all_zero)
									generate_events_evaluated_value <= #1 `VALUE_1;
								else
									generate_events_evaluated_value <= #1 `VALUE_X;
						endcase
					end

					// save net index
					generate_events_net_idx <= #1 cell_ram_rd_data[`CELL_RAM_NET_OUTPUT_IDX];
					generate_events_cell_delay <= #1 cell_ram_rd_data[`CELL_RAM_DELAY];
				end
				else begin// Kimi: add here count of EQ bz for write, stalls during generate events
					stat_busy_for_write <= #1 stat_busy_for_write + 1'b1;
				end
				`ifdef TURBOSIM_DEBUG
					if (eq_op === `INSERT_CMD && eq_cs) begin
						$display("(%0d ps) [Event Generation] Net: 0x%0x (%0d), Time: %0d, Value: %0x [Simtime %0d]", sim_time, eq_ev_in[`EQ_NET_INDEX], eq_ev_in[`EQ_NET_INDEX], eq_ev_in[`EQ_TIME], eq_ev_in[`EQ_NEXT_VALUE], $stime);
					end
				`endif
			end
			`OUTPUT:
				// waiting for output fifo to be empty
				if (empty) begin
					done <= #1 `TRUE;
					state <= #1 `INITIALIZE_ROUND;
				end
		endcase // case (state)
	
	// statistics counter, count the pure run (execution) time -Kimi
	always @ (posedge clk) begin
		if(rst || state == `INITIALIZE_ROUND) begin
			stat_sim_iteration_clk_count <= #1 0;
		end
		else if (state == `SOLVE_1 
				|| state == `SOLVE_2 
				|| state == `SOLVE_3 
				|| state == `SOLVE_4 || state == `GENERATE_EVENTS)begin
			stat_sim_iteration_clk_count <= #1 stat_sim_iteration_clk_count + 1'b1;
		end
	end
	
	// cell RAM write data
	always @(*) begin
		case (solve_curr_pin_idx)
			1: solve_cell_ram_wr_data = #1 {cell_ram_rd_data[`CELL_RAM_FROM_INPUT0_VAL], 2'b0, solve_net_new_value, cell_ram_rd_data[`CELL_RAM_UNTIL_INPUT0_VAL]};
			2: solve_cell_ram_wr_data = #1 {cell_ram_rd_data[`CELL_RAM_FROM_INPUT1_VAL], 2'b0, solve_net_new_value, cell_ram_rd_data[`CELL_RAM_UNTIL_INPUT1_VAL]};
			3: solve_cell_ram_wr_data = #1 {cell_ram_rd_data[`CELL_RAM_FROM_INPUT2_VAL], 2'b0, solve_net_new_value, cell_ram_rd_data[`CELL_RAM_UNTIL_INPUT2_VAL]};
			4: solve_cell_ram_wr_data = #1 {cell_ram_rd_data[`CELL_RAM_FROM_INPUT3_VAL], 2'b0, solve_net_new_value};
			default: solve_cell_ram_wr_data = #1 0; // should only happen in initialization stages!
		endcase
	end

	// net RAM read address
	always @(*) begin
		case (state)
			`INITIALIZE_ROUND: 	begin
				net_ram_rd_add_reg = #1 0;
			end
			`GET_INPUTS: begin
				if (!get_inputs_suspend_pipeline && !get_inputs_end_pipeline) begin
					net_ram_rd_add_reg = #1 in_fifo_rd_data[`IN_EVENT_NET_IDX];
				end
				else begin
					net_ram_rd_add_reg = #1 get_inputs_saved_in_record[`IN_EVENT_NET_IDX];
				end
			end
			`SOLVE_1: begin
				net_ram_rd_add_reg = #1 eq_ev_out[`EQ_NET_INDEX];
			end
			`SOLVE_2: begin
				net_ram_rd_add_reg = #1 solve_event[`EQ_NET_INDEX];
			end
			`SOLVE_3: begin
				net_ram_rd_add_reg = #1 solve_event[`EQ_NET_INDEX];
			end
			`GENERATE_EVENTS: begin
				net_ram_rd_add_reg = #1 cell_ram_rd_data[`CELL_RAM_NET_OUTPUT_IDX];
			end
			default:
				net_ram_rd_add_reg = #1 0;
		endcase
	end

	// net RAM write data and address
	always @(*) begin
		case (state)
			`INITIALIZE_ROUND: begin
				net_ram_wr_data_reg	= #1 0;
				net_ram_wr_add_reg	= #1 0;
			end
			`GET_INPUTS: begin
				net_ram_wr_data_reg	= #1 {net_ram_rd_data[`NET_RAM_FROM_NEXT_EV_TIME], get_inputs_saved_in_record[`IN_EVENT_TIME], 2'b0, get_inputs_saved_in_record[`IN_EVENT_NET_VAL]};
				net_ram_wr_add_reg	= #1 get_inputs_saved_in_record[`IN_EVENT_NET_IDX];
			end
			`SOLVE_1: begin
				net_ram_wr_data_reg	= #1 {net_ram_rd_data[`NET_RAM_FROM_CURRENT_VALUE], 2'b0, solve_net_new_value, net_ram_rd_data[`NET_RAM_UNTIL_CURRENT_VALUE]};
				net_ram_wr_add_reg	= #1 solve_event[`EQ_NET_INDEX];
			end
			`GENERATE_EVENTS: begin
				net_ram_wr_data_reg	= #1 {net_ram_rd_data[`NET_RAM_FROM_NEXT_EV_TIME], sim_time + generate_events_cell_delay, 2'b0, generate_events_evaluated_value};
				net_ram_wr_add_reg	= #1 generate_events_net_idx;
			end
			default: begin
				net_ram_wr_data_reg	= #1 0;
				net_ram_wr_add_reg	= #1 0;
			end
		endcase
	end

	// eq operation
	always @(*) begin
		case (state)
			`GET_INPUTS:
				eq_op_reg = #1 !get_inputs_push_to_eq_update_net_ram;
			`SOLVE_2:
				eq_op_reg = #1 solve_dequeue_event;
			`GENERATE_EVENTS:
				eq_op_reg = #1 !generate_events_create_new_event;
			default:
				eq_op_reg = #1 1'b0;
		endcase
	end

	// eq is zero delay
	always @(*) begin
		case (state)
			`GET_INPUTS:
				eq_is_zero_delay_reg = #1 (get_inputs_saved_in_record[`IN_EVENT_TIME] == 0 ? `TRUE : `FALSE);
			`GENERATE_EVENTS:
				eq_is_zero_delay_reg = #1 (generate_events_cell_delay == 0 ? `TRUE : `FALSE);
			default:
				eq_is_zero_delay_reg = #1 `FALSE;
		endcase
	end

	// turbosim's status
	always @(*) begin
		if (ctu_full) begin
			status = #1 `TURBOSIM_STATUS_CTU_FULL;
		end
		else if (eq_full) begin
			status = #1 `TURBOSIM_STATUS_EQ_FULL;
		end
		else begin
			status = #1 `TURBOSIM_STATUS_OK;
		end
	end

	/////////////////////////
	// GET_INPUTS
	/////////////////////////
	assign get_inputs_read_net_ram = (state == `GET_INPUTS && !in_fifo_empty);
	assign get_inputs_in_pipeline  = (state == `GET_INPUTS && !in_fifo_empty && !get_inputs_start_pipeline);
	assign get_inputs_end_pipeline = (state == `GET_INPUTS && in_fifo_empty);
	// create new event if we're not in the beginning of the pipeline and there's a new value for the input net
	assign get_inputs_push_to_eq_update_net_ram = (get_inputs_in_pipeline || get_inputs_end_pipeline);
	// if we want to write to the eq and it's busy, suspend the pipeline
	assign get_inputs_suspend_pipeline = (state == `GET_INPUTS && get_inputs_push_to_eq_update_net_ram && eq_busy_wr);

	/////////////////////////	
	// GENERATE_EVENTS
	/////////////////////////
	assign generate_events_stage_1 = (state == `GENERATE_EVENTS) && (generate_events_pipeline_status == `GENERATE_EVENTS_PIPELINE_1 || generate_events_pipeline_status == `GENERATE_EVENTS_PIPELINE_12 || generate_events_pipeline_status == `GENERATE_EVENTS_PIPELINE_123);
	assign generate_events_stage_2 = (state == `GENERATE_EVENTS) && (generate_events_pipeline_status == `GENERATE_EVENTS_PIPELINE_12 || generate_events_pipeline_status == `GENERATE_EVENTS_PIPELINE_123 || generate_events_pipeline_status == `GENERATE_EVENTS_PIPELINE_23);
	assign generate_events_stage_3 = (state == `GENERATE_EVENTS) && (generate_events_pipeline_status == `GENERATE_EVENTS_PIPELINE_123 || generate_events_pipeline_status == `GENERATE_EVENTS_PIPELINE_23 || generate_events_pipeline_status == `GENERATE_EVENTS_PIPELINE_3);
	assign generate_events_stage_1_active = !ctu_empty && !generate_events_suspend_pipeline && generate_events_stage_1;
	assign generate_events_stage_2_active = !generate_events_suspend_pipeline && generate_events_stage_2;
	assign generate_events_stage_3_active = !generate_events_suspend_pipeline && generate_events_stage_3;

	assign generate_events_all_one = (cell_ram_rd_data[`CELL_RAM_NET_INPUT0_V] == `CELL_INVALID || (cell_ram_rd_data[`CELL_RAM_NET_INPUT0_V] == `CELL_VALID && cell_ram_rd_data[`CELL_RAM_NET_INPUT0_VAL] == `VALUE_1)) && 
									 (cell_ram_rd_data[`CELL_RAM_NET_INPUT1_V] == `CELL_INVALID || (cell_ram_rd_data[`CELL_RAM_NET_INPUT1_V] == `CELL_VALID && cell_ram_rd_data[`CELL_RAM_NET_INPUT1_VAL] == `VALUE_1)) && 
									 (cell_ram_rd_data[`CELL_RAM_NET_INPUT2_V] == `CELL_INVALID || (cell_ram_rd_data[`CELL_RAM_NET_INPUT2_V] == `CELL_VALID && cell_ram_rd_data[`CELL_RAM_NET_INPUT2_VAL] == `VALUE_1)) && 
									 (cell_ram_rd_data[`CELL_RAM_NET_INPUT3_V] == `CELL_INVALID || (cell_ram_rd_data[`CELL_RAM_NET_INPUT3_V] == `CELL_VALID && cell_ram_rd_data[`CELL_RAM_NET_INPUT3_VAL] == `VALUE_1));
	assign generate_events_all_zero = (cell_ram_rd_data[`CELL_RAM_NET_INPUT0_V] == `CELL_INVALID || (cell_ram_rd_data[`CELL_RAM_NET_INPUT0_V] == `CELL_VALID && cell_ram_rd_data[`CELL_RAM_NET_INPUT0_VAL] == `VALUE_0)) && 
									  (cell_ram_rd_data[`CELL_RAM_NET_INPUT1_V] == `CELL_INVALID || (cell_ram_rd_data[`CELL_RAM_NET_INPUT1_V] == `CELL_VALID && cell_ram_rd_data[`CELL_RAM_NET_INPUT1_VAL] == `VALUE_0)) && 
									  (cell_ram_rd_data[`CELL_RAM_NET_INPUT2_V] == `CELL_INVALID || (cell_ram_rd_data[`CELL_RAM_NET_INPUT2_V] == `CELL_VALID && cell_ram_rd_data[`CELL_RAM_NET_INPUT2_VAL] == `VALUE_0)) && 
									  (cell_ram_rd_data[`CELL_RAM_NET_INPUT3_V] == `CELL_INVALID || (cell_ram_rd_data[`CELL_RAM_NET_INPUT3_V] == `CELL_VALID && cell_ram_rd_data[`CELL_RAM_NET_INPUT3_VAL] == `VALUE_0));
	assign generate_events_at_least_one_one = (cell_ram_rd_data[`CELL_RAM_NET_INPUT0_V] == `CELL_VALID && cell_ram_rd_data[`CELL_RAM_NET_INPUT0_VAL] == `VALUE_1) ||
											  (cell_ram_rd_data[`CELL_RAM_NET_INPUT1_V] == `CELL_VALID && cell_ram_rd_data[`CELL_RAM_NET_INPUT1_VAL] == `VALUE_1) ||
											  (cell_ram_rd_data[`CELL_RAM_NET_INPUT2_V] == `CELL_VALID && cell_ram_rd_data[`CELL_RAM_NET_INPUT2_VAL] == `VALUE_1) ||
											  (cell_ram_rd_data[`CELL_RAM_NET_INPUT3_V] == `CELL_VALID && cell_ram_rd_data[`CELL_RAM_NET_INPUT3_VAL] == `VALUE_1);
	assign generate_events_at_least_one_zero = (cell_ram_rd_data[`CELL_RAM_NET_INPUT0_V] == `CELL_VALID && cell_ram_rd_data[`CELL_RAM_NET_INPUT0_VAL] == `VALUE_0) ||
											   (cell_ram_rd_data[`CELL_RAM_NET_INPUT1_V] == `CELL_VALID && cell_ram_rd_data[`CELL_RAM_NET_INPUT1_VAL] == `VALUE_0) ||
											   (cell_ram_rd_data[`CELL_RAM_NET_INPUT2_V] == `CELL_VALID && cell_ram_rd_data[`CELL_RAM_NET_INPUT2_VAL] == `VALUE_0) ||
											   (cell_ram_rd_data[`CELL_RAM_NET_INPUT3_V] == `CELL_VALID && cell_ram_rd_data[`CELL_RAM_NET_INPUT3_VAL] == `VALUE_0);

	assign generate_events_create_new_event = generate_events_stage_3_active && ((generate_events_evaluated_value != net_ram_rd_data[`NET_RAM_NEXT_EV_VALUE]) || (sim_time + generate_events_cell_delay < net_ram_rd_data[`NET_RAM_NEXT_EV_TIME]));
	assign generate_events_suspend_pipeline = (state == `GENERATE_EVENTS && generate_events_stage_3 && eq_busy_wr);

	// input FIFO
	assign in_fifo_rd = (state == `GET_INPUTS && !get_inputs_suspend_pipeline);

	// drive net ram signals
	assign net_ram_cs = generate_events_create_new_event || generate_events_stage_2_active || solve_write_event_to_net_ram || solve_read_net_event || ((get_inputs_read_net_ram || get_inputs_push_to_eq_update_net_ram) && !get_inputs_suspend_pipeline);
	assign net_ram_rd = generate_events_stage_2_active || get_inputs_read_net_ram || solve_read_net_event;
	assign net_ram_rd_add = net_ram_rd_add_reg;
	assign net_ram_wr = generate_events_create_new_event || solve_write_event_to_net_ram || get_inputs_push_to_eq_update_net_ram;
	assign net_ram_wr_add = net_ram_wr_add_reg;
	assign net_ram_wr_data = net_ram_wr_data_reg;

	// cell ram signals
	assign cell_ram_cs = generate_events_stage_1_active || solve_cell_ram_rd || solve_cell_ram_wr;
	assign cell_ram_rd = generate_events_stage_1_active || solve_cell_ram_rd;
	assign cell_ram_rd_add = (state == `GENERATE_EVENTS ? ctu_ev_out : solve_cell_ram_rd_add);
	assign cell_ram_wr = solve_cell_ram_wr;
	assign cell_ram_wr_add = solve_cell_ram_wr_add;
	assign cell_ram_wr_data = solve_cell_ram_wr_data;
	
	// drive eq signals
	assign eq_cs = generate_events_create_new_event || (get_inputs_push_to_eq_update_net_ram && !get_inputs_suspend_pipeline) || solve_dequeue_event;
	assign eq_ev_in = (state == `GET_INPUTS) ? 
		{1'b1, get_inputs_saved_in_record[`IN_EVENT_NET_VAL], 3'b0, get_inputs_saved_in_record[`IN_EVENT_NET_IDX], get_inputs_saved_in_record[`IN_EVENT_TIME]} : 
		{1'b0, generate_events_evaluated_value, 3'b0, generate_events_net_idx, sim_time + generate_events_cell_delay};
	assign eq_op = eq_op_reg;
	assign eq_is_zero_delay = eq_is_zero_delay_reg;

	// output FIFO
	assign out_fifo_wr = solve_write_event_to_net_ram;
	assign out_fifo_wr_data = {solve_event[`EQ_NEXT_VALUE], 3'b0, solve_event[`EQ_NET_INDEX], solve_event[`EQ_TIME]};

	// CTU
	assign ctu_cs = solve_write_to_ctu || generate_events_stage_1_active;
	assign ctu_wr = solve_write_to_ctu;
	assign ctu_rd = generate_events_stage_1_active;
	assign ctu_ev_in = solve_ctu_data;

	////////////////////////////////////////////
	// External Modules Assignments
	////////////////////////////////////////////

	// net ram
	dp_ram #(.add_wd(11), .data_wd(112), .depth(2048)) 
	net_ram (
		.clk(clk),
		.cs(net_ram_cs),
		.rd(net_ram_rd),
		.wr(net_ram_wr),
		.rd_add(net_ram_rd_add),
		.wr_add(net_ram_wr_add),
		.wr_data(net_ram_wr_data),
		.rd_data(net_ram_rd_data)
	);
   
	// cell ram
	dp_ram #(.add_wd(11), .data_wd(96), .depth(2048)) 
	cell_ram (
		.clk(clk),
		.cs(cell_ram_cs),
		.rd(cell_ram_rd),
		.wr(cell_ram_wr),
		.rd_add(cell_ram_rd_add),
		.wr_add(cell_ram_wr_add),
		.wr_data(cell_ram_wr_data),
		.rd_data(cell_ram_rd_data)
	);


	// event queue
	EQ_wrap #(.data_wd(33), .q_add_wd(8), .q_max_len(256), .hi(15), .lo(0))
	eq (
		.EV_in(eq_ev_in),
		.op(eq_op),
		.cs(eq_cs),
		.rst(rst),
		.clk(clk),
		.EV_out(eq_ev_out),
		.dv(eq_dv),
		.full(eq_full),
		.empty(eq_empty),
		.busy_for_rd(eq_busy_rd),
		.busy_for_wr(eq_busy_wr),
		.length(eq_length),
		.is_zero_delay(eq_is_zero_delay)
	);

	// ctu
	ctu #(.data_wd(11),	.max_len(256), .add_wd(8), .hi(10),	.lo(0))
	ctu1 (
		.EV_in(ctu_ev_in), 
		.EV_out(ctu_ev_out), 
		.rd(ctu_rd), 
		.wr(ctu_wr), 
		.clk(clk), 
		.rst(rst),
		.cs(ctu_cs), 
		.full(ctu_full), 
		.empty(ctu_empty),
		.length(ctu_length)
	);
	
	// input FIFO
	// log2(64)+1 = 7
	fifo #(.add_wd(7), .data_wd(32), .depth(64)) 
	in_fifo (
		.clk(clk),
		.rst(rst),
		.rd(in_fifo_rd),
		.wr(wr),
		.empty(in_fifo_empty),
		.full(full),
		.wr_data(in_record),
		.rd_data(in_fifo_rd_data)
	);
	
	// output FIFO
	// log2(8)+1 = 4
	fifo #(.add_wd(4), .data_wd(32), .depth(8)) 
	out_fifo (
		.clk(clk),
		.rst(rst),
		.rd(rd),
		.wr(out_fifo_wr),
		.empty(empty),
		.full(out_fifo_full),
		.wr_data(out_fifo_wr_data),
		.rd_data(out_record)
	);
endmodule // turbosim


`endif
