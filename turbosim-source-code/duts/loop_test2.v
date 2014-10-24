`timescale 1ns /1ps

module loop_test2 ( o, a, b );
  output  [1:0] o;
  input  a;
  input  b;
  
  wire n0 ,n1,n2,n3,n4;
   
  nand	#(1.000) U1 ( n1, n0,a );
  not	#(1.000) U2 ( n2, n1 );
  not	#(1.000) U3 ( n3, n2 );
  not	#(1.000) U4 ( n4,n3 );
  not	#(1.000) U7 ( n0, n4 );
  
  buf	#(1.000) U8 (o[0], b );
  buf	#(1.000) U9 (o[1], n3 );
  
endmodule
