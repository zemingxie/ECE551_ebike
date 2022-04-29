module cadence_filt(clk, rst_n, cadence, cadence_filt, cadence_rise);
/*******************************************************************
* digital filter for the cadence signal, it will assert a signal if 
* counter measures at least 1ms of stability
*******************************************************************/
  parameter FAST_SIM = 1;

  input clk;                    // 50MHz clk
  input rst_n;                  // Asynch active low reset
  input cadence;                // Raw input from cadence sensor
  output logic cadence_filt;    // Filtered signal to be used elsewhere
  output logic cadence_rise;    // Rise edge detect of cadence

  logic q1, q2, q3;             // synchronizer signals
  logic [15:0] stbl_cnt;        // counter
  logic stbl_cnt_full;

  // synchronizer
  always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
      q1 <= 1'b0;
      q2 <= 1'b0;
      q3 <= 1'b0;
    end
    else begin
      q1 <= cadence;
      q2 <= q1;
      q3 <= q2;
    end
  end

  // counter for stable signal
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      stbl_cnt <= 16'h0000;
    else if (q2!=q3)
      stbl_cnt <= 16'h0000;
    else
      stbl_cnt <= stbl_cnt + 1;
	  
  generate if (FAST_SIM)
    assign stbl_cnt_full = &stbl_cnt[8:0];
  else
    assign stbl_cnt_full = &stbl_cnt;
  endgenerate

  // assert cadence_filt when counter full
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      cadence_filt <= 1'b0;
    else if (stbl_cnt_full)
      cadence_filt <= q3;

  // rise edge detect for cadence
  always_comb begin
    cadence_rise = q2 & (~q3);
  end

endmodule