module mtr_drv(
  input clk,                         // system clock
  input rst_n,                       // asynch low reset
  input [10:0] duty,                 // duty cycle
  input [1:0] selGrn,                // select signals for how motor should drive
  input [1:0] selYlw,
  input [1:0] selBlu,
  output PWM_synch,                  // Used to synchronize hall reading with PWM cycle
  output highGrn,                    // used to set motor control
  output lowGrn,
  output highYlw,
  output lowYlw,
  output highBlu,
  output lowBlu
);

  logic PWM_sig, highGrnIn, lowGrnIn, highYlwIn, lowYlwIn, highBluIn, lowBluIn;

  PWM iPWM(.*);                                                                                                               // PWM block
  nonoverlap iGrn(.clk(clk), .rst_n(rst_n), .highIn(highGrnIn), .lowIn(lowGrnIn), .highOut(highGrn), .lowOut(lowGrn));        // nonoverlap block for each control signal
  nonoverlap iYlw(.clk(clk), .rst_n(rst_n), .highIn(highYlwIn), .lowIn(lowYlwIn), .highOut(highYlw), .lowOut(lowYlw));        // for make sure high and low drive will not
  nonoverlap iBlu(.clk(clk), .rst_n(rst_n), .highIn(highBluIn), .lowIn(lowBluIn), .highOut(highBlu), .lowOut(lowBlu));        // overlap

  // using select signals to set actual motor control signal
  assign highGrnIn = (selGrn == 2'b00) ? 1'b0 :
                     (selGrn == 2'b01) ? ~PWM_sig :
                     (selGrn == 2'b10) ? PWM_sig :
                                         1'b0;

  assign lowGrnIn = (selGrn == 2'b00) ? 1'b0 :
                    (selGrn == 2'b01) ? PWM_sig :
                    (selGrn == 2'b10) ? ~PWM_sig :
                                        PWM_sig;

  assign highYlwIn = (selYlw == 2'b00) ? 1'b0 :
                     (selYlw == 2'b01) ? ~PWM_sig :
                     (selYlw == 2'b10) ? PWM_sig :
                                         1'b0;

  assign lowYlwIn = (selYlw == 2'b00) ? 1'b0 :
                    (selYlw == 2'b01) ? PWM_sig :
                    (selYlw == 2'b10) ? ~PWM_sig :
                                        PWM_sig;

  assign highBluIn = (selBlu == 2'b00) ? 1'b0 :
                     (selBlu == 2'b01) ? ~PWM_sig :
                     (selBlu == 2'b10) ? PWM_sig :
                                         1'b0;

  assign lowBluIn = (selBlu == 2'b00) ? 1'b0 :
                    (selBlu == 2'b01) ? PWM_sig :
                    (selBlu == 2'b10) ? ~PWM_sig :
                                        PWM_sig;


endmodule
