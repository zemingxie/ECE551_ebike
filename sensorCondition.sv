module sensorCondition(clk, rst_n, torque, cadence_raw, curr, incline, scale, batt, error, not_pedaling, TX);

  parameter FAST_SIM = 1;
  
  input clk;
  input rst_n;
  input [11:0] torque;
  input cadence_raw;
  input [11:0] curr;
  input signed [12:0] incline;
  input [2:0] scale;
  input [11:0] batt;
  output signed [12:0] error;
  output not_pedaling;
  output TX;
  
  localparam LOW_BATT_THRES = 12'hA98;
  
  logic cadence_rise;
  logic cadence_filt;
  logic [7:0] cadence_per;
  logic [4:0] cadence;
  logic [11:0] target_curr;
  logic [11:0] avg_torque;
  logic [11:0] avg_curr;
  logic include_smpl;
  logic [21:0] counter;
  logic [13:0] curr_accum;
  logic [15:0] curr_accumTime3;
  logic [16:0] torque_accum;
  logic [21:0] torque_accumTime31;
  logic not_pedaling_stg_1;
  logic pedaling_resumes;
  // generate fast simulation
  generate if (FAST_SIM)
    assign include_smpl = &counter[15:0];
  else
    assign include_smpl = &counter;
  endgenerate
  
  assign curr_accumTime3 = (curr_accum << 2) - curr_accum;								//avg_curr = curr_accum*3/4 + curr 
  assign avg_curr = curr_accum[13:2];									
  assign pedaling_resumes = ~not_pedaling & not_pedaling_stg_1;						// falling edge detect
  assign torque_accumTime31 = (torque_accum << 5) - torque_accum;							//avg_torque = torque_accum*31/32 + torque
  assign avg_torque = torque_accum[16:5];
  assign error = (not_pedaling || batt < LOW_BATT_THRES) ? 13'h0000 : target_curr - avg_curr;		// error produced during pedaling

  cadence_filt #(FAST_SIM) icadence_filt(.clk(clk), .rst_n(rst_n), .cadence(cadence_raw), .cadence_filt(cadence_filt), .cadence_rise(cadence_rise));
  cadence_meas #(FAST_SIM) icadence_meas(.clk(clk), .rst_n(rst_n), .cadence_filt(cadence_filt), .cadence_per(cadence_per), .not_pedaling(not_pedaling));
  cadence_LU icadence_LU(.cadence_per(cadence_per), .cadence(cadence));
  desiredDrive idesiredDrive(.clk(clk), .rst_n(rst_n), .avg_torque(avg_torque), .cadence(cadence), .not_pedaling(not_pedaling), .incline(incline), .scale(scale), .target_curr(target_curr));
  telemetry itelemetry(.clk(clk), .rst_n(rst_n), .batt_v(batt), .avg_curr(avg_curr), .avg_torque(avg_torque), .TX(TX));
  
  always_ff @(posedge clk, negedge rst_n)								//store not_pedaling for edge detect
    if(!rst_n) not_pedaling_stg_1 <= 1'b0;
	else not_pedaling_stg_1 <= not_pedaling;
	
  always_ff @(posedge clk, negedge rst_n)								//counter for sample time
    if(!rst_n) counter <= 22'h000000;
	else counter <= counter + 1;
	
  always_ff @(posedge clk, negedge rst_n)								//avg_curr updates
    if(!rst_n) curr_accum <= 14'h0000;
	else if(include_smpl) curr_accum <= curr + curr_accumTime3[15:2];
	
  always_ff @(posedge clk, negedge rst_n)								//avg_torque updates
    if(!rst_n) torque_accum <= 17'h00000;
	else if(pedaling_resumes) torque_accum <= {1'b0, torque, 4'b0000};				//seeds when resumed
	else if(cadence_rise) torque_accum <= torque + torque_accumTime31[21:5];			//accumulates on cadence_rise

endmodule