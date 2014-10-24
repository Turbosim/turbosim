/*
 * This is a test bench file of the Queue module.
 * 
 * Author: Kimi
 * Date: 29/01/11
 **/
`timescale 1ns /1ps 

module queue_test_bench();
  
  // define prams
  localparam DAT_WD = 16;
  localparam DEPTH  = 20;
  localparam ADD_WD = clogb2(DEPTH);
  //localparam HI =     clogb2(DEPTH);
  localparam WRITE_OP = 1'b0;
  localparam READ_OP = 1'b1;
  
  // dut related signals
  reg [DAT_WD-1:0] EV_in;
  wire [DAT_WD-1:0] EV_out;
  wire [ADD_WD:0]   dut_len;
  reg 		    op, cs, rst, clk;
  wire 		    full, empty, busy, dv;
  
  reg [DAT_WD-1:0]  data_in;
  reg [DAT_WD-1:0]  dut_data_out;
  reg [DAT_WD-1:0]  gm_data_out;
  // heap related variables
  reg [DAT_WD-1:0]  ram [0:DEPTH-1];
  reg [ADD_WD-1:0]  gm_len;
  
  integer 	    s;
  integer 	    round;
  localparam 	    mean = 3;
  localparam 	    std_dev = 2;
  reg [8*10:1] 	    op_str;
  
  integer stat_rd;
  integer stat_wr;
  
  //////////////////////////////////////////////////
  // clock generation
  always begin
    clk = 0;
    #5;
    clk = 1;
    #10;
    clk = 0;
    #5;
  end
  
  //////////////////////////////////////////////////
  // operation decoding into human-readable state
  always @* begin
    if(cs)
      if(op==READ_OP) begin
      	op_str = "R";
      	stat_rd = stat_rd + 1;
    	 end
      else begin
      	op_str = "W";
      	stat_wr = stat_wr + 1;
    	 end
    else
      op_str = "NOP";
  end
  
  initial begin
    // init all signals
    rst = 1;
    clk = 0;
    cs = 0;
    op = 0;
    data_in = 0;
    dut_data_out = 0;
    gm_data_out = 0;
    s = 15;
    gm_len = 0;
    round = 0;
    stat_rd = 0;
    stat_wr = 0;
    #50;
    rst = 0;    
    
    $display("\n\n********************Start***************************\n");

    for (round = 0; round < 150 ; round = round + 1 ) begin
      // cast an operation
      //usage:  $dist_normal ( seed , mean , standard_deviation )
      if ( IsEmpty(dut_len) ) begin
      	op = WRITE_OP;
      end
      else if ( IsFull(dut_len) ) begin
      	op = READ_OP;
      end
      else begin
	     op = ( $dist_normal ( s , mean , std_dev ) < 5 ) ? WRITE_OP : READ_OP ;
      end
      
      case (op)
	     WRITE_OP: begin
        data_in = {$random}%15;//{DAT_WD{1'b1}}; // allow data [0,...,max_allowed_by_DAT_WD]
        $display("Write @%04d [%04h]", $time, data_in );
        fork
	        begin
           Insert_dut(data_in);
	        end
          begin
	          @(posedge clk) // write to GM at posedge clk (for sync of 2 models)
	           Insert_gm(data_in);
	        end
	      join
	     end
	     READ_OP: begin
      	  $display("Read  @%04d", $time);
      	  fork
	         begin
            Extract_dut(dut_data_out);
	         end
	         begin
	           @(posedge clk) // (for sync of 2 models)
              Extract_gm(gm_data_out);
	         end
	       join
	     $display(" read data, dut [%04h] , gm [%04h] @%04d", dut_data_out, gm_data_out, $time);
	     end
      endcase // case (op)

      wait (!busy);
      
    end
    
    #50;
    
    $display("\n\n********************End***************************\n");
    $display("Statistics\n\tread count: [%04d]\n\twrite count:[%04d]", stat_rd ,stat_wr);

  end
  
  //////////////////////////////////////////
  // test processes
  
  always @( negedge busy ) begin
    #1;
    Compare_rams;
  end
  
  always @( posedge dv ) begin
    #1;
    Compare_top;
  end
  
  task Compare_rams;
    integer j;
    begin
      for( j=0; j < gm_len ; j=j+1) begin
	     if (ram[j] != dut.ram.ram[j])
        $display("\tError @%04d: Rams are not equal at index [%04d] dut[%04h] , gm[%04h]", $time, j, dut.ram.ram[j], ram[j]);
      end
    end
  endtask
  
  task Compare_top;
    begin
      if ( ram[0] != EV_out )
	     $display("\tError @%04d: Topmost elements are not equal dut [%04h] gm [%04h]", $time, ram[0], dut.ram.ram[0]);
    end
  endtask
  
  ///////////////////////////////////////////
  // DUT module instantiation
  Queue #(.data_wd(DAT_WD),
	  .q_add_wd(ADD_WD),
	  .q_max_len(DEPTH),
	  .hi(DAT_WD-1),
	  .lo(0)
	  )
    dut(
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
	.length(dut_len)
	);
  
  ////////////////////////////////////////////////
  // dut related tasks
  task Insert_dut(
   input reg [DAT_WD-1:0] key);
    begin
      op = 0;
      cs = 0;
      EV_in = key;
      wait(!busy);
      cs=1;
      op = WRITE_OP;
      @(posedge clk);
      @(negedge clk);
      EV_in = 0;
      cs = 0;
      op = 0;
    end
  endtask
  
  task Extract_dut(
   output reg [DAT_WD-1:0] key);
    begin
      op = 0;
      cs = 0;
      wait((dv && !busy));
      cs=1;
      op = READ_OP;
      @(posedge clk);
      key = EV_out;
      @(negedge clk);
      cs = 0;
      op = 0;
    end
  endtask
  
  ////////////////////////////////////////////////
  // inner tasks
  
  task Print;
    integer i;
    reg [DAT_WD-1:0] top;
    begin
      for (i=0; i<DEPTH; i=i+1) begin
	Extract_gm(top);
	#10;
	$display("%d",top);
      end
    end
  endtask
  
  // extrac top most element from Heap
  task Extract_gm ;
    output [DAT_WD-1:0] top;
    reg [DAT_WD-1:0] 	smallest;
    reg [ADD_WD-1:0] 	smallest_idx;
    reg [ADD_WD-1:0] 	i;
    begin
      i = 0;
      if( !IsEmpty(gm_len) ) begin
	     top = ram[0];
	     gm_len = gm_len - 1'b1;
	     Swap(0, gm_len);
	     min3(0, LeftChild(i), RigthChild(i), smallest, smallest_idx);
	     while ( smallest_idx != i) begin
	       Swap(smallest_idx, i);
	       i = smallest_idx;
	       min3(i, LeftChild(i), RigthChild(i), smallest, smallest_idx);
	       #5;
	     end
	
      end
    end
  endtask
  
  // return min of three elements: left_child_idx, right_child_idx and i
  // and corresponding ram entry
  task min3(	input [ADD_WD-1:0] i, left_child_idx, right_child_idx,
   output [DAT_WD-1:0] smallest, 
   output [ADD_WD-1:0] smallest_idx
		);
    begin
      smallest = ram[i];
      smallest_idx = i;
      if( left_child_idx < gm_len ) begin
	smallest  =     (ram[i] < ram[left_child_idx]) ? ram[i] : ram[left_child_idx];
	smallest_idx =  (ram[i] < ram[left_child_idx]) ? i : left_child_idx;
      end
      if ( right_child_idx < gm_len ) begin
	smallest =      (ram[smallest_idx] < ram[right_child_idx]) ? ram[smallest_idx]: ram[right_child_idx];
	smallest_idx =  (ram[smallest_idx] < ram[right_child_idx]) ? smallest_idx : right_child_idx;
      end
    end	
  endtask
  
  // insert key into the heap
  task Insert_gm;
    input [DAT_WD-1:0] key;
    reg [ADD_WD-1:0]   i;
    begin
      if ( !IsFull(gm_len) ) begin
	ram[gm_len] = key;
	i = gm_len;
	gm_len = gm_len + 1'b1;
	while( i>0 && ram[i] < ram[Parent(i)] ) begin
	  Swap( i, Parent(i) );
	  i = Parent(i);
	  #5;
	end
      end
    end
  endtask
  
  // return true iff heap is  full
  function automatic IsEmpty(input reg [ADD_WD-1:0] length);
    IsEmpty = length == {ADD_WD{1'b0}};
  endfunction
  
  // return true iff heap is  full
  function automatic IsFull(input reg [ADD_WD-1:0] length);
    IsFull = length == DEPTH;
  endfunction
  
  // swaps the i'th and j'th indexes in the ram
  task Swap;
    input [ADD_WD-1:0] i, j;
    reg [DAT_WD-1:0]   temp;
    begin
      temp = ram[i];
      ram[i] = ram[j];
      ram[j] = temp;
    end
  endtask
  
  // returns parent index of idx
  function [ADD_WD-1:0] Parent(input reg [ADD_WD-1:0] idx);
    Parent = (idx-1)/2;
  endfunction
  
  // returns left child index of idx
  function [ADD_WD-1:0] LeftChild(input reg [ADD_WD-1:0] i);
    LeftChild = (2*i)+1;
  endfunction
  
  // returns right child index of idx
  function [ADD_WD-1:0] RigthChild(input reg [ADD_WD-1:0] i);
    RigthChild = 2*(i+1);
  endfunction
  
  //define the clogb2 function
  function integer clogb2;
    input [31:0] value;
    begin
      value = value - 1;
      for (clogb2 = 0; value > 0; clogb2 = clogb2 + 1)
	value = value >> 1;
    end
  endfunction
  
endmodule 