/* 
 * comperator_2 module:
 * this module is combinatorical. it comperes 2 given inputs and returns
 * the one with greater or smaller value (c_data and corresponding index) accorging
 * to great_n_small signal. 
 * comperation region is scalable and can be chosen using lo and hi parameters.
 * 
 * PARAMETERS:
 *	data_wd:	width of input data
 *	idx_wd:		width of index 
 *	lo:			bit select. starting mark of significant bits to be taken
				into accound in comperation
 *	hi:			bit select. end of mark region
 *
 * OUTPUT:
 *	c_dat:		choosen element
 *	c_idx:		choosen element index
 *	c_dv:		output data valid indication
 * INPUT:
 *	d0,d1:		input data to be compared
 *	d0_idx,
 *	d1_idx:		input data indexes
 *	d0_dv,
 *	d1_dv:		input data valid indication
 *	great_n_samll:
 *				operation to be performed. '1' - greater index will be returned 
 *				'0' - smaller index will be returned 
 *
 * Author: Kimi
 */
`ifndef _comperator_2
`define _comperator_2

`timescale 1ns /1ps
//`include "../common_defines.v"

module comperator_2 #(parameter data_wd = 16,idx_wd = 4,hi = 15,lo = 0)
	(
	output reg	[data_wd-1:0] 	c_dat,
	output reg	[idx_wd-1 :0] 	c_idx,
	output reg					c_dv,
	input wire	[data_wd-1:0]	d0,		d1,
	input wire	[idx_wd-1 :0]	d0_idx,	d1_idx,
	input wire					d0_dv,	d1_dv,
	input wire					great_n_small
	);
	
	always @(*) begin
		if (d0_dv && d1_dv && great_n_small) begin
			c_dat = (d0[hi:lo] > d1[hi:lo]) ? d0		: d1;
			c_idx = (d0[hi:lo] > d1[hi:lo]) ? d0_idx	: d1_idx;
			c_dv  = 1'b1;
		end
		else if (d0_dv && d1_dv && !great_n_small) begin
			c_dat = (d0[hi:lo] < d1[hi:lo]) ? d0		: d1;
			c_idx = (d0[hi:lo] < d1[hi:lo]) ? d0_idx	: d1_idx;
			c_dv  = 1'b1;
		end
		else if (d0_dv && !d1_dv) begin
			c_dat = d0;
			c_idx = d0_idx;
			c_dv  = 1'b1;
		end
		else if (!d0_dv && d1_dv) begin
			c_dat = d1;
			c_idx = d1_idx;
			c_dv  = 1'b1;
		end
		else begin	/* (!d0_dv && !d1_dv) */
			c_dat = {data_wd{1'b0}};
			c_idx = {idx_wd {1'b0}};
			c_dv  = 1'b0;
		end
	end
endmodule 

`endif