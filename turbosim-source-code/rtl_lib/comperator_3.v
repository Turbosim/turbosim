/* 
 * TODO: add input and out put buffers that drive I/O signal
 */

/*
 * Comperator module:
 * compare 3 inputs and forward to output samllest element and it's index
 * this module is combinatorical.
 *
 * INPUTS:
 *	d0,d1,d2:	are the data inputs
 *	great_n_small:
 *				operation to be performed. '1' - greater index will be returned 
 *				'0' - smaller index will be returned 
 * OUTPUT:
 *	c_dat:		choosen data amoung d0,d1,d2
 *	c_idx:		index of choosen data 
 *	c_vd:		data valid of output signal
 *
 * PARAMETERS:
 *	data_wd:	width of input data
 *	idx_wd:		width of index 
 *	lo:			bit select. starting mark of significant bits to be taken
				into accound in comperation
 *	hi:			bit select. end of mark region
 *
 * ASSUME: at least one of data inputs are valid
 *
 * Author: Kimi
 */
`ifndef _comperator_3
`define _comperator_3

`timescale 1ns /1ps
// `include "../rtl_lib/comperator_2.v"

module comperator_3 #(parameter data_wd = 16,idx_wd = 4,hi = 15, lo = 0)
	(
	output wire	[data_wd-1:0] 	c_dat,
	output wire	[idx_wd-1 :0] 	c_idx,
	output wire 				c_dv,
	input wire	[data_wd-1:0]	d0,		d1, 	d2,
	input wire	[idx_wd-1 :0]	d0_idx,	d1_idx,	d2_idx,
	input wire					d0_dv,	d1_dv,	d2_dv,
	input wire					great_n_small
	);
	
wire [data_wd-1:0]	c_dat_tmp;
wire [idx_wd-1:0] 	c_idx_tmp;
wire 				c_dv_tmp;

comperator_2 #(.data_wd(data_wd),.idx_wd(idx_wd),.hi(hi),.lo(lo))
c1	(
	.c_dat(c_dat_tmp),
	.c_idx(c_idx_tmp),
	.c_dv(c_dv_tmp),
	.d0(d0),
	.d0_idx(d0_idx),
	.d0_dv(d0_dv),
	.d1(d1),
	.d1_idx(d1_idx),
	.d1_dv(d1_dv),
	.great_n_small(great_n_small)
	);
	
comperator_2 #(.data_wd(data_wd),.idx_wd(idx_wd),.hi(hi),.lo(lo))
c2	(
	.c_dat(c_dat),
	.c_idx(c_idx),
	.c_dv(c_dv),
	.d0(c_dat_tmp),
	.d0_idx(c_idx_tmp),
	.d0_dv(c_dv_tmp),
	.d1(d2),
	.d1_idx(d2_idx),
	.d1_dv(d2_dv),
	.great_n_small(great_n_small)
	);

endmodule 

`endif