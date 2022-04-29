module PB_intf(clk, rst_n, tgglMd, setting, scale);
  input clk;
  input rst_n;
  input tgglMd;
  output logic [1:0] setting;
  output [2:0] scale;

  logic rise_edge, tgglMd_stg1, tgglMd_stg2, tgglMd_stg3;

  assign rise_edge = tgglMd_stg2 & ~tgglMd_stg3;
  assign scale = setting[1] ? (setting[0] ? 3'b111 : 3'b101) : (setting[0] ? 3'b011 : 3'b000);

  always_ff @(posedge clk, negedge rst_n)
    if(!rst_n) setting <= 2'b00;
    else if(rise_edge) setting <= setting + 1;

  always_ff @(posedge clk, negedge rst_n)
    if(!rst_n) begin
      tgglMd_stg1 <= 1'b0;
      tgglMd_stg2 <= 1'b0;
      tgglMd_stg3 <= 1'b0;
    end
    else begin
      tgglMd_stg1 <= tgglMd;
      tgglMd_stg2 <= tgglMd_stg1;
      tgglMd_stg3 <= tgglMd_stg2;
    end

endmodule
