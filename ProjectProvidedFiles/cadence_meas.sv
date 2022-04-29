module cadence_meas(clk, rst_n, cadence_filt, cadence_per, not_pedaling);

  parameter FAST_SIM = 1;
  
  input clk;
  input rst_n;
  input cadence_filt;
  output logic [7:0] cadence_per;
  output not_pedaling;
  
  localparam THIRD_SEC_REAL = 24'hE4E1C0;
  localparam THIRD_SEC_FAST = 24'h007271;
  localparam THIRD_SEC_UPPER = 8'hE4;
  
  logic [23:0] THIRD_SEC;
  logic cadence_filt_stg_1;
  logic cadence_rise;
  logic [23:0] counter;
  logic [7:0] cadence_per_in;
  logic isTHIRD_SEC;
  // fast sim generater
  generate if (FAST_SIM) begin
    assign THIRD_SEC = THIRD_SEC_FAST;
	assign cadence_per_in = counter[14:7];
  end
  else begin
    assign THIRD_SEC = THIRD_SEC_REAL;
	assign cadence_per_in = counter[23:16];
  end
  endgenerate
  
  assign cadence_rise = cadence_filt & ~cadence_filt_stg_1; //rising edge detector
  assign isTHIRD_SEC = counter == THIRD_SEC; //checks if third sec equals counter
  assign not_pedaling = cadence_per == THIRD_SEC_UPPER; //checks not pedaling
  //stores cadence_filt
  always_ff @(posedge clk, negedge rst_n)
    if(!rst_n) cadence_filt_stg_1 <= 1'b0;
	else cadence_filt_stg_1 <= cadence_filt;
  //timer to check third second and capture for cadence_per
  always_ff @(posedge clk, negedge rst_n)
    if(!rst_n) counter <= 24'h000000;
	else if(cadence_rise) counter <= 24'h000000;
	else if(!isTHIRD_SEC) counter <= counter + 1;
  // flop for cadence_per
  always_ff @(posedge clk)
    if(!rst_n) cadence_per <= THIRD_SEC_UPPER;
	else if(cadence_rise|isTHIRD_SEC) cadence_per <= cadence_per_in;
  
endmodule
