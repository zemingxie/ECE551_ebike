package test;
  class tester;
    virtual eBike_bfm bfm;
	
	function new (virtual eBike_bfm b);
	  bfm = b;
	endfunction
	
	task execute();
	  bfm.set_cadence(2200);
	  bfm.give_value(12'h700, 16'h0000, 12'hb80, 12'hfff);
      bfm.reset_eBike();
      bfm.wait_clk(2100000);
	  bfm.set_cadence(8192);
	  bfm.give_value(12'h500, 16'h0000, 12'hb80, 12'hfff);
	  bfm.wait_clk(2100000);
	endtask
  endclass
  
  class scoreboard;
    virtual eBike_bfm bfm;
	
	function new (virtual eBike_bfm b);
	  bfm = b;
	endfunction
	
	task execute();
	  bfm.wait_clk(2000000);
	  $display("TORQUE: %h", bfm.TORQUE);
	endtask
	
  endclass
	
  class testbench;
    virtual eBike_bfm bfm;
	
	tester tester_h;
	scoreboard scoreboard_h;
	
	function new(virtual eBike_bfm b);
	  bfm = b;
	endfunction
	
	task execute();
	  tester_h = new(bfm);
	  scoreboard_h = new(bfm);
	  
	  fork
	    tester_h.execute();
		scoreboard_h.execute();
	  join
	endtask
  endclass
endpackage
