`timescale 1ps /1ps

// uncomment to add future events
// `define FUTURE_EVENTS

module sim_project();

   wire [15:0] o;
   reg [15:0]  a;
   reg [15:0]  b;
   
   integer     i, k,s;
   integer     turbosim_cycle_count;
    
   integer     ref_dut_change_count;
   integer     turbosim_change_count;
 
   time        start_time;
   reg [15:0]  delta_time;
   reg [15:0]  dt;

   reg [31:0] input_vcd_fifo [63:0];
   reg [5:0]  input_vcd_wr_ptr;
   reg [5:0]  input_vcd_rd_ptr;
   reg [7:0]  input_vcd_len;
   reg 	      input_vcd_full;   
   reg 	      input_vcd_empty;   


   reg 	       clk;
   reg 	       rst;
   reg 	       go;
   wire        done;
   reg 	       wr;
   wire        rd;
   wire        full;
   wire        empty;
   wire [1:0]  status;
   
   reg [31:0]  in_record;
   wire [31:0] out_record;
   
   // statistic calculation:
	integer stat_fd; // statistic file descriptor
	integer	print_statistics_ena;
	integer	total_stalls;
	integer	pure_solve_time;
	integer	eq_sum_of_elements;
	integer	ctu_sum_of_elements;
	real	av_eq_elem_num;
	real	av_ctu_elem_num;
	real	utilization_per;
	real	cycles_per_event;
   
   //reg [13:0]  input_nets_to_index_mem [31:0];
   reg [159:0] net_index_to_name_mem [500:0];
   reg [1:0]   new_net_value;
   
   
   always #10000 clk = !clk;  // 50 Mhz clock
   
   ///////////////////////////////////////////
   // init stat file
   task init_stat_file;
	begin
		stat_fd = $fopen("dump/dump_08_q_100iters_zd.txt","w+");
		if(stat_fd==0) begin
			$display("Error can't init statistic file");
			$stop;
		end
		$fwrite(stat_fd,"#\tUTIL%%\tCPE\tPST\tTST\tAV_EQ\tAV_CTU\n");
	end
	endtask
	
	//////////////////////////////////////////
	// write statistics
	task write_stat;
	begin
		$fwrite(stat_fd,"%04d\t%2.1f\t%2.1f\t%04d\t%04d\t%2.2f\t%2.2f\n"	
											,i
											,utilization_per
											,cycles_per_event
											,pure_solve_time
											,total_stalls
											,av_eq_elem_num
											,av_ctu_elem_num
											);
	end
	endtask
	   
   /////////////////////////////////////////
   // test bench
   /////////////////////////////////////////
   initial begin
		// $readmemh("input_nets_to_index_mem.v", input_nets_to_index_mem);
		$readmemh("dut_data/net_index_to_name_mem.v",   net_index_to_name_mem);
		
		
		clk = 0;
		rst = 1;
		go  = 0;
		wr  = 0;
		i   = 1;
		s   = 0;

		a   = 0;
		b   = 0;

		ref_dut_change_count  = 0;
		turbosim_change_count = 0;
		print_statistics_ena = 1;

		turbosim_cycle_count = 0;
		input_vcd_full       = 0 ;   
		input_vcd_empty      = 1;   

		in_record  = 32'h0;      
		start_time = $time;

		#50000;
		rst = 0;
		wait(done);

		if (print_statistics_ena)
			init_stat_file;
			
		while (i<100) begin

			ref_dut_change_count  = 0;
			turbosim_change_count = 0;

			// from this point the real adder add1 starts propagating
			if (i>1) begin
				a = $dist_uniform(s,0,40000);
				b = $dist_uniform(s,0,40000);
			end
			$display("start iteration %d : a = %h, b =%h", i[15:0], a,b);

			start_time = $time;
			// let ref dut work and propagets the inputs
			// all the changes will be captured by the sniffers
			@(posedge clk);
			`ifdef FUTURE_EVENTS
				#50;
				a = $dist_uniform(s,0,40000);
				$display("setting a = %h at dt = %d", a, $time - start_time);
			`endif
			#1000;

			// dumping the input changes accomulated into turbosim 
			while(!input_vcd_empty) begin
				in_record = pop_input(1);
				write_in_fifo;
			end

			pulse_go; // pulsing the go signal,  the done signal should go low.

			// here turbosim is processing the input stimuli
			// ... and emiting net change from time to time.
			// those changes are captured and displayed

			wait_done;
			update_statistics;
			$display("end   iteration %d : turbosim solved in %d clock cycles", i[15:0], turbosim_cycle_count[15:0]);
			$display("Turbosim change count: %d, Modelsim change count: %d", turbosim_change_count, ref_dut_change_count);
			$display("Cycles per event: %f", cycles_per_event);
			if (print_statistics_ena) begin
				print_statistics;
				write_stat;
			end
			
			i=i+1;
		end	
		
		if (print_statistics_ena) $fclose(stat_fd);
		
		$stop;
	end


	/////////////////////////////////////////
	// dut instantiation
	/////////////////////////////////////////

	// add1 ref_dut ( .a(a), .b(b), .o(o));
	add_zero_delay ref_dut ( .a(a), .b(b), .o(o));
	
	/////////////////////////////////////////
	// device instantiation
	/////////////////////////////////////////

	turbosim  turbosim(
				.clk        (clk),
				.rst        (rst),
				.go         (go),
				.done       (done),
				.wr         (wr),
				.rd         (rd),
				.full       (full),
				.empty      (empty),
				.in_record  (in_record),
				.out_record (out_record),
				.status		(status)
				);
	
   /////////////////////////////////////////
   // init all RAM of inner modules in turbosim
	initial begin
		$readmemh("dut_data/net_index_to_data_mem_zd.v", turbosim.net_ram.ram);
		$readmemh("dut_data/cell_index_to_data_mem_zd.v", turbosim.cell_ram.ram);
		$readmemh("ctu/ctu_set_init_ram_image.v", turbosim.ctu1.ram.ram);
	end
	
   /////////////////////////////////////////
   // statistic tracking
	always @ (posedge clk) begin
		if(rst || go) begin
			eq_sum_of_elements = 0;
			ctu_sum_of_elements = 0;
		end
		else begin
			eq_sum_of_elements = eq_sum_of_elements + turbosim.eq_length;
			ctu_sum_of_elements = ctu_sum_of_elements + turbosim.ctu_length;
		end
	end
	
    ////////////////////////////////////////
	// statistics  calculation:
	task update_statistics;
	begin
		utilization_per = 100.0
							-( 100.0 / turbosim.stat_sim_iteration_clk_count )
								*(turbosim.stat_busy_for_read_stall
								  + turbosim.stat_busy_for_write
								  + turbosim.stat_dv_stall);
								  
		total_stalls = turbosim.stat_busy_for_read_stall
											  + turbosim.stat_busy_for_write
											  + turbosim.stat_dv_stall;
											  
		pure_solve_time = turbosim.stat_sim_iteration_clk_count;
		av_eq_elem_num  =	$itor(eq_sum_of_elements)  / $itor(turbosim.stat_sim_iteration_clk_count);
		av_ctu_elem_num =	$itor(ctu_sum_of_elements) / $itor(turbosim.stat_sim_iteration_clk_count);
		cycles_per_event =	$itor(turbosim_cycle_count[15:0])/ $itor(turbosim_change_count);
	end
	endtask
	

    ////////////////////////////////////////
	// statistics  print:
	task print_statistics;
	begin
		$display("\n***********************************");
		$display("* Pure Solve time:\t\t%04d",pure_solve_time);
		$display("* Busy for read stalls:\t%04d",turbosim.stat_busy_for_read_stall);
		$display("* Busy for write stalls:\t%04d",turbosim.stat_busy_for_write);
		$display("* Data valid stalls:\t\t%04d",turbosim.stat_dv_stall);
		$display("* ---------------------------------");
		$display("* Toral stalls:\t\t%04d",total_stalls);
		$display("* Utilization:\t\t%2.1f%%",utilization_per);
		$display("* ---------------------------------");
		$display("* EQ average # of elements:\t%2.2f",av_eq_elem_num);
		$display("* CTU average # of elements:\t%2.2f",av_ctu_elem_num);
		$display("***********************************\n");
	end
	endtask
	
   /////////////////////////////////////////
   /////////////////////////////////////////
   // sniffer on ref_dut input change 
   // this is used to derive the vcd set for turbosim in_fifo
   // the idea is to record the changed values the user drives the real network
   // and to provide them to turbosim

`include "dut_data/ref_dut_input_sniffer.v"


   /////////////////////////////////////////
   /////////////////////////////////////////
   // sniffer on turbosim outputs
   
	wire [13:0] net_index       = out_record[29:16];   
	wire [15:0] net_change_time = out_record[15:0];
	wire [1:0]  net_value       = out_record[31:30];
	reg 	    net_value1;


	always @(net_value)
		case (net_value)
			2'b00 :net_value1 = 1'b0;
			2'b01 :net_value1 = 1'b1;
			2'b10 :net_value1 = 1'bx;
			2'b11 :net_value1 = 1'bz;
		endcase // case (net_value)
   

   assign rd = !empty;
   
	always @(posedge clk)
		if (!empty) begin
			turbosim_change_count = turbosim_change_count +1;
			$display("=== acc_vcd       time %d ps, value %b, net name %s",
				net_change_time,net_value1, net_index_to_name_mem[net_index]);
		end

   /////////////////////////////////////////
   /////////////////////////////////////////
   
   // sniffer on adder internal nets,
   // this will be used to compare simulator results to our accelerator

`include "dut_data/ref_dut_sniffer.v"

   /////////////////////////////////////////
   /////////////////////////////////////////
   
	function [1:0] encode_bit_value;
	input new_val;

		begin
			if (new_val === 1'b0)
				encode_bit_value = 2'b00;
			else if (new_val === 1'b1)
				encode_bit_value = 2'b01;
			else if (new_val === 1'bx)
				encode_bit_value = 2'b10;
			else if (new_val === 1'bz)
				encode_bit_value = 2'b11;
		end
	endfunction // encode_bit_value

   /////////////////////////////////////////
   /////////////////////////////////////////

  
	initial begin
		input_vcd_wr_ptr= 0;
		input_vcd_rd_ptr= 0;
		input_vcd_len= 0;
	end

   /////////////////////////////////////////
   /////////////////////////////////////////
  
	function [31:0] pop_input;
		input null_bit;
		begin
			pop_input = input_vcd_fifo[input_vcd_rd_ptr];
			input_vcd_rd_ptr = input_vcd_rd_ptr +1;	 
			input_vcd_len    = input_vcd_len-1;

			if (input_vcd_len <= 0)
				input_vcd_empty = 1;
			input_vcd_full = 0;

			if (input_vcd_len < 0)
				$display ("Error,input_vcd_fifo underflow %d ...",input_vcd_len);
		end
	endfunction // pop_input
   /////////////////////////////////////////
   /////////////////////////////////////////
  
	function push_input;

	input [31:0] element;

		begin
			input_vcd_fifo[input_vcd_wr_ptr] = element;
			input_vcd_wr_ptr = input_vcd_wr_ptr +1;	 
			input_vcd_len    = input_vcd_len+1;
			if (input_vcd_len >= 64)
				input_vcd_full = 1;
			input_vcd_empty = 0;
			
			if (input_vcd_len > 64)
				$display ("Error,input_vcd_fifo overflow %d ...",input_vcd_len);
			push_input = 1;
		end
	endfunction // push_input
   
   /////////////////////////////////////////
   /////////////////////////////////////////

	task pulse_go;
		begin
			@(posedge clk); 
			go <= #1000 1;
			@(posedge clk);
			go <= #1000 0;
			@(posedge clk);
			#1000;
		end
   endtask // pulse_go
   /////////////////////////////////////////
   /////////////////////////////////////////

	task wait_done;
		begin
			turbosim_cycle_count = 0;
			while (!done) begin
				@(posedge clk);
				#1000;
				turbosim_cycle_count = turbosim_cycle_count +1;
			end
		end
	endtask // wait_done
   
   /////////////////////////////////////////
   /////////////////////////////////////////
   
	task write_in_fifo;
		begin
			wait(!full);
			wr = 1;
			@(posedge clk);
			#1000;
			wr = 0;
		end
	endtask // write_in_fifo
   
endmodule

/////////////////////////////////////////
/////////////////////////////////////////


/////////////////////////////////////////
/////////////////////////////////////////

