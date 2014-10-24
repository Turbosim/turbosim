`timescale 1ns /1ps

module loop_test ( o, a, b );
  output [5:0] o;
  input [15:0] a;
  input [1:0] b;
  
  wire n0 ,n1,n3,n4;
   
  not	#(1.000) U1 ( o[0], b[1] );
  nor	#(1.000) U2 ( o[1], a[2], a[3],a[4],a[5] );
  and	#(0.800) U3 ( o[2], a[6], a[7],a[8],a[9] );
  nand	#(1.000) U4 ( n0,n1,n4 );
  not	#(1.000) U7 ( n1, n0 );
  and	#(0.800) U8 ( n4,n1,n3 );
  or	#(1.000) U5 ( n3, a[14], a[15],a[0],a[1]);
  buf	#(0.800) U6 ( o[5], b[0]  );
endmodule
