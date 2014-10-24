module simple1(clk,d,q,qb);

// simple1 is a latch, designed with cross cuopled nands.
// it contains feedbacks !!!, 

   input clk;
   input d;
   output q;
   output qb;


   not  #(0.23) not0  (n1,d);
   nand #(0.45) nand0 (n2,d,clk);
   nand #(0.45) nand1 (n3,n1,clk);
   nand #(0.45) nand2 (n4,n2,n5);
   nand #(0.45) nand3 (n5,n3,n4);
   buf  #(0.23) buf0  (q,n4);
   buf  #(0.23) not0  (qb,n5);

endmodule



