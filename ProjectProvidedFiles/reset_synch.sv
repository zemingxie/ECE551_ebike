module reset_synch(
  input RST_n,
  input clk,
  output logic rst_n
);

  logic metaStableSig;

  always_ff @(posedge clk, negedge RST_n)
    if(!RST_n) begin
      metaStableSig <= 1'b0;
      rst_n <= 1'b0;
    end
    else begin
      metaStableSig <= 1'b1;
      rst_n <= metaStableSig;
    end

endmodule
