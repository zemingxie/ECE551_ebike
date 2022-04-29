module brushless(
  input clk,                     // 50MHz clock
  input rst_n,                   // asynch active low reset
  input [11:0] drv_mag,          // From PID control. How much motor assists (unsigned)
  input hallGrn,                 // Raw hall effect sensors (asynch)
  input hallYlw,
  input hallBlu,
  input brake_n,                 // If low activate regenerative braking at 75% duty cycle
  input PWM_synch,               // Used to synchronize hall reading with PWM cycle
  output [10:0] duty,            // Duty cycle to be used for PWM inside mtr_drv.
                                 // Should be 0x400+drv_mag[11:2] in normal operation
                                 // and 0x600 if braking.
  output logic [1:0] selGrn,     // 2-bit vectors directing how mtr_drv should drive the
  output logic [1:0] selYlw,     // FETs. 00=>HIGH_Z, 01=>rev_curr, 10=>frwd_curr,
  output logic [1:0] selBlu      // 11=>regen braking
);

  logic synchGrn, synchYlw, synchBlu, q1Grn, q2Grn, q1Ylw, q2Ylw, q1Blu, q2Blu;
  logic [2:0] rotation_state;
  localparam HIGH_Z = 2'b00;
  localparam rev_curr = 2'b01;
  localparam for_curr = 2'b10;
  localparam braking = 2'b11;

  assign rotation_state = {synchGrn, synchYlw, synchBlu};
  assign duty = (brake_n) ? drv_mag[11:2] + 11'h400 : 11'h600;

  always_ff @(posedge clk, negedge rst_n)
    if(!rst_n) begin
      synchGrn <= 1'b0;
      synchYlw <= 1'b0;
      synchBlu <= 1'b0;
    end
    else if(PWM_synch) begin
      synchGrn <= q2Grn;
      synchYlw <= q2Ylw;
      synchBlu <= q2Blu;
    end

  always_ff @(posedge clk) begin
    q1Grn <= hallGrn;
    q2Grn <= q1Grn;
    q1Ylw <= hallYlw;
    q2Ylw <= q1Ylw;
    q1Blu <= hallBlu;
    q2Blu <= q1Blu;
  end

  always_comb begin
    selGrn = HIGH_Z;
    selYlw = HIGH_Z;
    selBlu = HIGH_Z;
    if(!brake_n) begin
      selGrn = braking;
      selYlw = braking;
      selBlu = braking;
    end
    else
      case(rotation_state)
        3'b101: begin
          selGrn = for_curr;
          selYlw = rev_curr;
        end
        3'b100: begin
          selGrn = for_curr;
          selBlu = rev_curr;
        end
        3'b110: begin
          selYlw = for_curr;
          selBlu = rev_curr;
        end
        3'b010: begin
          selYlw = for_curr;
          selGrn = rev_curr;
        end
        3'b011: begin
          selBlu = for_curr;
          selGrn = rev_curr;
        end
        3'b001: begin
          selBlu = for_curr;
          selYlw = rev_curr;
        end
        // default state would take default value
      endcase
  end

endmodule
