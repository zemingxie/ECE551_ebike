module desiredDrive(clk, rst_n, avg_torque, cadence, not_pedaling, incline, scale, target_curr);
/****************************************************************
* This block do some math on sensor inputs to get desired drive
****************************************************************/
  input clk;						   // 50MHz clk
  input rst_n;						   // asynch low reset
  input [11:0] avg_torque;             // Unsigned number representing the toque the rider is
                                       // putting on the cranks (force of their pedaling)
  input [4:0] cadence;                 // Unsigned number proportional to the sqrt the speed
                                       // of the rider?s pedaling.
  input not_pedaling;                  // Asserts if cadence is so slow it has been determined
                                       // rider is not pedaling.
  input signed [12:0] incline;         // Incline from inertial senor (signed)
  input [2:0] scale;                   // unsigned. Represents level of assist motor provides
                                       // 111 => a lot of assist, 101 => medium, 011 =>
                                       // little, 000 => no assist
  output [11:0] target_curr;           // Unsigned output setting the target current the motor
                                       // should be running at. This will go to the PID
                                       // controller to eventually form the duty cycle the motor
                                       // driver is run at.
  
  localparam TORQUE_MIN = 12'h380;     // minimum of torque value

  logic signed [9:0] incline_sat;      // 10-bit saturated (signed) result
  logic signed [10:0] incline_factor;  // sign extended (to 11-bits) incline_sat + 256
  logic signed [8:0] incline_lim;      // 9-bit saturated signal that is clipped with respect to 
                                       // negative values
  logic [5:0] cadence_factor;          // modified cadence value
  logic [12:0] torque_off;             // 0 extend avg_torque - 0 extend TORQUE_MIN
  logic [11:0] torque_pos;             // zero clipped version of torque_off
  logic [29:0] assist_prod;            // how much we wish the motor to assist the rider
  logic [14:0] torque_pos_mult_scale;
  logic [14:0] incline_lim_mult_cadence_factor;
  
  always_ff @(posedge clk, negedge rst_n)
    if(!rst_n) torque_pos_mult_scale <= 15'h0000;
	else torque_pos_mult_scale <= torque_pos * scale;
	
  always_ff @(posedge clk, negedge rst_n)
    if(!rst_n) incline_lim_mult_cadence_factor <= 15'h0000;
	else incline_lim_mult_cadence_factor <= incline_lim * cadence_factor;

  //always_ff @(posedge clk, negedge rst_n)
    //if(!rst_n) assist_prod <= 30'h00000000;
	//else if(not_pedaling) assist_prod <= 30'h00000000;
	//else assist_prod <= torque_pos_mult_scale * incline_lim_mult_cadence_factor;
  
  // value too negative and too positive saturates, otherwise keep the
  // value
  assign incline_sat = (incline[12] && !(&incline[11:9])) ? 10'h200 :
                       (!incline[12] && |incline[11:9]) ? 10'h1ff :
			incline[9:0];

  // sign extended (to 11-bits) incline_sat + 256 
  assign incline_factor = {incline_sat[9], incline_sat} + 256;
  
  // 9-bit saturated signal that is clipped with respect to negative values
  assign incline_lim = (incline_factor[10]) ? 9'h000 :
                       (incline_factor > 9'h1ff) ? 9'h1ff :
                       incline_factor[8:0];

  // modified cadence value
  assign cadence_factor = (cadence > 1) ? cadence + 32 : 0;

  // 0 extend avg_torque - 0 extend TORQUE_MIN
  assign torque_off = {1'b0, avg_torque} - {1'b0, TORQUE_MIN};

  // zero clipped version of torque_off
  assign torque_pos = (torque_off[12]) ? 12'h000:
                      torque_off[11:00];

  // how much we wish the motor to assist the rider
  assign assist_prod = (not_pedaling) ? 0 : torque_pos_mult_scale * incline_lim_mult_cadence_factor;

  // the output that will eventually go to the PID controller
  assign target_curr = (|assist_prod[29:27]) ? 12'hfff : assist_prod[26:15];
  
endmodule