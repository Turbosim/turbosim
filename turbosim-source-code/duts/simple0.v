

module simple0 ( a,b,c,d,e,f,g,o1,o2);
input a;
input b;
input c;
input d;
output o1;
output o2;

  or	#(1.132) or1  (e,a,b);
  or	#(1.01)  or2  (n1,e,d);
  buf   #(0.321) buf1 (o2,n1);
  and	#(0.225) and1 (f,e,c);
  nor	#(0.646) nor1 (o1,f,g);
  not	#(0.340) not1 (g,n1);

endmodule

