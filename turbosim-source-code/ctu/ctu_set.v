/*
 * ctu set mudule, implements a mathematical set data structure. it can
 *	store and retrieve elements in O(1). back 2 back read and write commands
 *	are allowed.
 *	
 *	Authur: Kimi - Sep 2010
 */
`ifndef _ctu
`define _ctu
 
`timescale 1ns/1ns
`include "../common_defines.v"

module ctu #(parameter	data_wd = 11,	// single entry width
						max_len = 128,	// maximal # for entries in CTU
						add_wd = 7,		// width of max_len field
						hi = 10,		// significant bits within CTU entry, other bits will not be
						lo = 0			//		taken into account when soring the entry in CTU
			)
	(
	input wire					clk,
	input wire					rst,
	input wire [data_wd-1:0]	EV_in,		// input entry
	output wire [data_wd-1:0]	EV_out,		// output entry
	input wire					rd, wr,		// read write signals
	input wire					cs,			// chip select signal
	output wire					full, empty,// ctu output indications
	output wire [add_wd-1:0]	length
	);
	
wire	ram_cs;
wire	ram_rd;
wire	ram_wr;
wire	ram_wr_data;
wire	ram_rd_data;
wire	ram_rd_data_valid;
wire	[`CTU_SET_LENGTH_WD-1:0]	ram_rd_add;
wire	[`CTU_SET_LENGTH_WD-1:0]	ram_wr_add;

wire	[data_wd-1:0]	fifo_EV_out;
wire	[data_wd-1:0]	fifo_EV_in;
wire	fifo_rd;
wire	fifo_wr;

wire	continues_write;

wire	ctu_write_ena;
wire	ctu_read_ena;
wire	ctu_enter_new_entry;
wire	ctu_continues_write;
wire	ctu_first_write;
wire	does_cell_exist_in_ram;
wire	rd_wd_to_same_add;
wire	enrty_is_missing_in_ram;
wire	remove_entry_from_ram;

wire	stage2_active_only;
reg		delayed_wr;
reg		sampled_rd_wd_to_same_add;
reg 	sampled_wr;
reg 	delayed_ctu_first_write;

reg		[data_wd-1:0]	delayed_EV_in;

// control logic
assign ctu_read_ena = (cs && rd && !empty);
assign ctu_write_ena = (cs && wr && !full);
assign ctu_first_write = ctu_write_ena && empty;

assign ctu_continues_write = ctu_write_ena && continues_write && !delayed_ctu_first_write;
assign ctu_enter_new_entry = ctu_first_write || stage2_active_only || (ctu_continues_write && enrty_is_missing_in_ram);
assign does_cell_exist_in_ram = ctu_write_ena && !empty;

assign rd_wd_to_same_add = ram_wr && ram_rd && (ram_rd_add == ram_wr_add);
assign enrty_is_missing_in_ram = (ram_rd_data_valid == `FALSE);
assign remove_entry_from_ram = ctu_read_ena;

assign fifo_rd = ctu_read_ena;
assign fifo_wr = ctu_enter_new_entry;	// (C)

// when rd & wr data to same address assign TRUE to ram_rd_data_valid (work around)
assign ram_rd_data_valid = sampled_rd_wd_to_same_add ? `TRUE : ram_rd_data;


// ram control signals
assign ram_cs = remove_entry_from_ram || does_cell_exist_in_ram || ctu_enter_new_entry ;
assign ram_rd = does_cell_exist_in_ram;
assign ram_wr = remove_entry_from_ram || ctu_enter_new_entry ;

assign ram_wr_add = remove_entry_from_ram
					? EV_out[hi:lo] 
					: ctu_first_write
					? EV_in[hi:lo]
					: ctu_enter_new_entry
					? delayed_EV_in[hi:lo]
					: {data_wd{1'b0}};

assign ram_wr_data = remove_entry_from_ram
					? `FALSE 
					: ctu_enter_new_entry
					? `TRUE	
					: `FALSE;

assign ram_rd_add = does_cell_exist_in_ram
					? EV_in[hi:lo]				
					: {`CTU_SET_LENGTH_WD{1'b0}};

// sample EV_in
always @ (posedge clk) begin
	if(rst) begin
		delayed_EV_in	<= #5 {data_wd{1'b0}};
	end
	else begin
		delayed_EV_in	<= #5 EV_in;
	end
end

// stage2 control
assign stage2_active_only = sampled_wr && !wr && !delayed_ctu_first_write;
always @ (posedge clk) begin
	if(rst)
		sampled_wr <= #5 `FALSE;
	else 
		sampled_wr <= #5 wr;
end

// delayed_ctu_first_write signal generation
always @ (posedge clk) begin
	if(rst) 
		delayed_ctu_first_write <= #5 `FALSE;
	else 
		delayed_ctu_first_write <= #5 ctu_first_write;
end

// continues_write control
assign continues_write = delayed_wr && wr;

always @ (posedge clk) begin
	if(rst) begin
		delayed_wr <= #5 `FALSE;
	end
	else begin
		delayed_wr <= #5 wr;
	end
end

// sample rd_wd_to_same_add signal
always @ (posedge clk) begin
	if(rst) begin
		sampled_rd_wd_to_same_add <= #5 `FALSE;
	end
	else begin
		sampled_rd_wd_to_same_add <= #5 rd_wd_to_same_add;
	end
end

// muxing fifo I/O signal
assign fifo_EV_in	= ctu_first_write	? EV_in : delayed_EV_in;
assign EV_out		= empty				? {data_wd{1'b0}} : fifo_EV_out ;

my_fifo #(.max_len(max_len), .len_wd(add_wd), .entry_wd(data_wd))
fifo(
	.clk(clk), 
	.rst(rst),
	.rd(fifo_rd),
	.wr(fifo_wr),
	.data_in(fifo_EV_in),	// input entry
	.full(full), 
	.empty(empty),			// fifo status indicators
	.data_out(fifo_EV_out),	// output entry
	.len(length)
	);

// ram is used to implement mathematical set
dp_ram #(.add_wd(`CTU_SET_LENGTH_WD), .data_wd(1), .depth(`CTU_SET_LENGTH))
ram(
	.clk(clk), 
	.cs(ram_cs), 
	.rd(ram_rd), 
	.wr(ram_wr), 
	.rd_add(ram_rd_add), 
	.wr_add(ram_wr_add),
	.wr_data(ram_wr_data),
	.rd_data(ram_rd_data)
	);

endmodule 

`endif