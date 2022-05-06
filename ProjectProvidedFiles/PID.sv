module PID
#(parameter FAST_SIM = 0)
(
  input clk,                    // 50MHz clock
  input rst_n,                  // Active low asynch reset
  input signed [12:0] error,    // 13-bit signed error
  input not_pedaling,           // Asserted if rider is not pedaling
  output [11:0] drv_mag         // Unsigned output that determines motor drive
);

  logic signed [13:0] P_term;
  logic signed [11:0] I_term;
  logic signed [9:0] D_term;
  logic signed [13:0] PID;
  logic signed [17:0] sign_extend_error, integrator, integrator_in, adder;
  logic signed [12:0] d_flop1, d_flop2, prev_err, D_diff;
  logic signed [8:0] saturated_diff;
  logic signed [17:0] negCheck;
  logic signed [17:0] overflowCheck;
  logic signed [17:0] decimatedSignal;
  logic signed [17:0] pedalCheck;
  logic [19:0] decimator;
  logic decimator_full, pos_ov;

  assign P_term = {error[12], error};                                            // P_term is signed_extend error to 14 bits
  assign I_term = integrator[16:5];                                              // I_term is the middle 12 bits of the integrator
  assign sign_extend_error = {{5{error[12]}}, error};                            // Sign extend error to match integrator
  assign adder = integrator + sign_extend_error;                                 // Integrating accumulator
  assign negCheck = adder[17] ? 18'h00000 : adder;
  assign pos_ov = adder[17] & integrator[16];                                    // Positive overflow can only occur when MSB of adder and integrator[16] are 1
  assign overflowCheck = pos_ov ? 18'h1FFFF : negCheck;
  assign decimatedSignal = decimator_full ? overflowCheck : integrator;
  assign pedalCheck = not_pedaling ? 18'h00000 : decimatedSignal;
  assign D_diff = error - prev_err;                                              // Derivative term
  assign saturated_diff = (D_diff[12] && !(&D_diff[11:8])) ? 9'h100:             // saturate derivertive to 9 bits
                          (!D_diff[12] && (|D_diff[11:8])) ? 9'h0ff:
                          D_diff[8:0];
  assign D_term = {saturated_diff, 1'b0};                                        // D_term is saturate derivertive x 2
  assign PID = P_term + {2'b00, I_term} + {{4{D_term[9]}}, D_term};              // sum of all terms to get PID
  assign drv_mag = PID[13] ? 12'h000 :                                           // saturate PID to 12 bits to get drv_mag
                   PID[12] ? 12'hfff :
                   PID[11:0];

  generate if(FAST_SIM)                                                          // Speed up for simulation
    assign decimator_full = &decimator[14:0];
  else
    assign decimator_full = &decimator;
  endgenerate

  always_ff @(posedge clk, negedge rst_n)                                        // counter to get 1/48th of a second
    if(!rst_n) decimator <= 20'h00000;
    else decimator <= decimator + 1;
  
  always_ff @(posedge clk, negedge rst_n)                                        // integrator logic
    if(!rst_n) integrator <= 18'h00000;                                          // asynch reset
    else integrator <= pedalCheck;                                                                     // else, keep value (omit)

  always_ff @(posedge clk, negedge rst_n)                                        // flops to obtain previous error values
    if(!rst_n) begin
      d_flop1 <= 13'h0000;
      d_flop2 <= 13'h0000;
      prev_err <= 13'h0000;
    end
    else if(decimator_full) begin
      d_flop1 <= error;
      d_flop2 <= d_flop1;
      prev_err <= d_flop2;
    end

endmodule
