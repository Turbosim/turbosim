`ifndef _fifo
`define _fifo

`timescale 1ns / 1ns
// `include "dp_ram.v"

module fifo #(parameter add_wd=4, data_wd=32,depth=16, t_access = 15) 
   (
    input wire clk, rd, wr, rst, 
    input wire [data_wd-1:0] wr_data,
    output reg 		     full,
    output reg 	     empty,
    output wire [data_wd-1:0] rd_data
    );
   
   localparam size = depth;
   
   reg 			      int_rd;
   wire 		      ram_rd;
   wire 		      ram_wr;
   reg [add_wd-1:0] 	      rd_ptr;
   reg [add_wd-1:0] 	      wr_ptr;
   reg [add_wd:0] 	      len;
   wire 		      cs;
   wire [add_wd-1:0] 	      ram_rd_ptr;
   reg [add_wd-1:0] 	      next_rd_ptr;
  
   
   dp_ram #(.add_wd(add_wd),.data_wd(data_wd), .depth(depth))
   dp_ram (
	   .clk(clk), 
	   .cs(cs), 
	   .rd(ram_rd), 
	   .wr(ram_wr), 
	   .rd_add(ram_rd_ptr), 
	   .wr_add(wr_ptr),
	   .wr_data(wr_data), 
	   .rd_data(rd_data)
	   );
   
  
  assign	ram_rd     = (rd && !empty) || int_rd;
  assign	ram_wr     = (wr && !full);
  assign	cs         = ram_rd || ram_wr;
  assign	ram_rd_ptr = (rd && !empty) ? next_rd_ptr : rd_ptr;
  
  
  always @(*)
    if (rd_ptr < (size - 1))
      next_rd_ptr =  rd_ptr + 1;
    else
      next_rd_ptr =  0;
  
  
  always @(posedge clk)
    if (rst)
      begin
	empty      <= #1 1;
	full       <= #1 0;
	len        <= #1 0;
	rd_ptr     <= #1 0;
	wr_ptr     <= #1 0;
	int_rd     <= #1 0;
      end
    else
      begin
	
        if (((wr && !full)  && (len == 0)) || ((wr && !full) && (rd && !empty) && (len == 1)))
        // if ((wr && !full)  && (len == 0))
          int_rd <= #1 1;
        else
          int_rd <= #1 0;
        
	
	if ((wr && !full) && (rd && !empty))
	  begin
            if (len == 1)
              empty <= #1 1;
            else
              empty <= #1 0;
            
	    rd_ptr<= #1 next_rd_ptr;
	    
	    if (wr_ptr < (size - 1))
	      wr_ptr<= #1 wr_ptr + 1;
	    else
	      wr_ptr<= #1 0;
	    
	  end // if ((wr && !full) && (rd && !empty))
	
	else if (rd && !empty)
	  begin
	    full <= #1 0;
	    
            if (len == 1)
              empty <= #1 1;
            else
              empty <= #1 0;
            
	    len   <= #1 len - 1;
	    
	    rd_ptr<= #1 next_rd_ptr;
	    
	  end
	else if (wr && !full)
	  begin
            if (len == 0)
              empty <= #1 1;
            else
              empty <= #1 0;
            
            len <= #1 len + 1;
	    
	    if (len == size-1)
	      full <= #1 1;
	    
	    if (wr_ptr < (size - 1))
	      wr_ptr<= #1 wr_ptr + 1;
	    else
	      wr_ptr<= #1 0;
	  end // if (wr && !full)
	else if (int_rd)
	  empty <= #1 0;

      end
  
  
endmodule

`endif