interface eBike_bfm(input clk);
  bit RST_n;
  bit [11:0] TORQUE;
  bit [15:0] CADENCE_RATE;
  bit [15:0] YAW_RT;
  bit [11:0] BATT;
  bit [11:0] BRAKE;
  bit tgglMd;

  task reset_eBike();
    RST_n = 1'b0;
    tgglMd = 1'b0;
    @(posedge clk);
    @(negedge clk) RST_n = 1;
  endtask
  
  task wait_clk(input integer clks);
    repeat(clks) @(posedge clk);
  endtask

  task give_value(input [11:0] torque, input [15:0] yaw_rt, input [11:0] batt, input [11:0] brake);
    TORQUE = torque;
    YAW_RT = yaw_rt;
    BATT = batt;
    BRAKE = brake;
  endtask

  task set_cadence(input [15:0] cadence_rate);
    CADENCE_RATE = cadence_rate;
  endtask

  task toggle_once();
    @(posedge clk) tgglMd = 1;
    @(posedge clk) tgglMd = 0;
    repeat(3) @(posedge clk);
  endtask

endinterface
