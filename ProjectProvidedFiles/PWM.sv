module PWM(clk, rst_n, duty, PWM_sig, PWM_synch);
  input clk;                                   // 50MHz system clk
  input rst_n;                                 // Asynch active low
  input [10:0] duty;                           // Specifies duty cycle(unsigned 11 bit)
  output reg PWM_sig;                          // PWM signal out (glitch free)
  output PWM_synch;                            // When cnt is 11’h001 output a signal to allow
                                               // commutator to synch to PWM
											   
  logic [10:0] cnt;                            // counter

  assign PWM_synch = (cnt == 11'h001);
  
  // counter that always increments
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) cnt <= 11'h000;
    else cnt <= cnt + 1;

  // PWM sig will be on one cycle longer than duty specifies 
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) PWM_sig <= 1'b0;
    else PWM_sig <= (cnt <= duty);

endmodule
