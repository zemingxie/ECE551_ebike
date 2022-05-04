module top();
 
  // include or import tasks?
  import test::*;

  localparam FAST_SIM = 1;		// accelerate simulation by default

  ///////////////////////////
  // Stimulus of type reg //
  /////////////////////////
  reg clk;
  
  eBike_bfm bfm(clk);


  //////////////////////////////////////////////////
  // Declare any internal signal to interconnect //
  ////////////////////////////////////////////////
  wire A2D_SS_n,A2D_MOSI,A2D_SCLK,A2D_MISO;
  wire highGrn,lowGrn,highYlw,lowYlw,highBlu,lowBlu;
  wire hallGrn,hallBlu,hallYlw;
  wire inertSS_n,inertSCLK,inertMISO,inertMOSI,inertINT;
  logic cadence;
  wire [1:0] LED;			// hook to setting from PB_intf
  
  wire signed [11:0] coilGY,coilYB,coilBG;
  logic [11:0] curr;		// comes from hub_wheel_model
  wire [11:0] BATT_TX, TORQUE_TX, CURR_TX;
  logic vld_TX;
  logic TX_RX;
  logic [7:0] rx_data;
  logic change;
  
  //////////////////////////////////////////////////
  // Instantiate model of analog input circuitry //
  ////////////////////////////////////////////////
  AnalogModel iANLG(.clk(clk),.rst_n(bfm.RST_n),.SS_n(A2D_SS_n),.SCLK(A2D_SCLK),
                    .MISO(A2D_MISO),.MOSI(A2D_MOSI),.BATT(bfm.BATT),
		    .CURR(curr),.BRAKE(bfm.BRAKE),.TORQUE(bfm.TORQUE));

  ////////////////////////////////////////////////////////////////
  // Instantiate model inertial sensor used to measure incline //
  //////////////////////////////////////////////////////////////
  eBikePhysics iPHYS(.clk(clk),.RST_n(bfm.RST_n),.SS_n(inertSS_n),.SCLK(inertSCLK),
	             .MISO(inertMISO),.MOSI(inertMOSI),.INT(inertINT),
		     .yaw_rt(bfm.YAW_RT),.highGrn(highGrn),.lowGrn(lowGrn),
		     .highYlw(highYlw),.lowYlw(lowYlw),.highBlu(highBlu),
		     .lowBlu(lowBlu),.hallGrn(hallGrn),.hallYlw(hallYlw),
		     .hallBlu(hallBlu),.avg_curr(curr));

  //////////////////////
  // Instantiate DUT //
  ////////////////////
  eBike #(FAST_SIM) iDUT(.clk(clk),.RST_n(bfm.RST_n),.A2D_SS_n(A2D_SS_n),.A2D_MOSI(A2D_MOSI),
                         .A2D_SCLK(A2D_SCLK),.A2D_MISO(A2D_MISO),.hallGrn(hallGrn),
			 .hallYlw(hallYlw),.hallBlu(hallBlu),.highGrn(highGrn),
			 .lowGrn(lowGrn),.highYlw(highYlw),.lowYlw(lowYlw),
			 .highBlu(highBlu),.lowBlu(lowBlu),.inertSS_n(inertSS_n),
			 .inertSCLK(inertSCLK),.inertMOSI(inertMOSI),
			 .inertMISO(inertMISO),.inertINT(inertINT),
			 .cadence(cadence),.tgglMd(bfm.tgglMd),.TX(TX_RX),
			 .LED(LED));
			 
			 
  ////////////////////////////////////////////////////////////
  // Instantiate UART_rcv or some other telemetry monitor? //
  //////////////////////////////////////////////////////////
  UART_rcv ircv(.clk(clk), .rst_n(RST_n), .RX(TX_RX), .rdy(vld_TX), .rx_data(rx_data), .clr_rdy(vld_TX));
			 
  initial begin
    clk = 0;
    cadence = 0;
	bfm.give_value(12'h700, 16'h0000, 12'hb80, 12'hfff);
    bfm.reset_eBike();
    repeat(2100000) @(posedge clk);
	bfm.give_value(12'h500, 16'h0000, 12'hb80, 12'hfff);
	repeat(2100000) @(posedge clk);
    $stop();
	
  end
  
  ///////////////////
  // Generate clk //
  /////////////////
  always
    #10 clk = ~clk;

  ///////////////////////////////////////////
  // Block for cadence signal generation? //
  /////////////////////////////////////////
  always begin
    repeat(bfm.CADENCE_RATE) @(posedge clk); 
	cadence = ~cadence;		
  end
	
endmodule

