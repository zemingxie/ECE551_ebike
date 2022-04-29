module nonoverlap(clk, rst_n, highIn, lowIn, highOut, lowOut);
  input clk, rst_n;                    // 50MHz clock, and reset
  input highIn;                        // Control for high side FET
  input lowIn;                         // Control for low side FET
  output logic highOut;                // Control for high side FET with ensured non-overlap
  output logic lowOut;                 // Control for low side FET with ensured non-overlap
 
  typedef enum reg { READY, CHANGED } state_t;     // two states, either data is ready or data changed.
  state_t state, nxt_state;
  logic highIn_prev;                               // signals to detect change
  logic lowIn_prev;
  logic changed;                                   // if changed, on for one cycle
  logic ready;                                     // on when it is in ready state
  logic[4:0] deadTime;                             // counter

  // counter always increments with asynch reset and a synch reset on input changes
  always_ff @(posedge clk, negedge rst_n)
    if(!rst_n) deadTime <= 5'h00;
    else if(changed) deadTime <= 5'h00;
    else deadTime <= deadTime + 1;

  // state default to ready
  always_ff @(posedge clk, negedge rst_n)
    if(!rst_n) state <= READY;
    else state <= nxt_state;

  // get previous high and low input
  always_ff @(posedge clk, negedge rst_n)
    if(!rst_n) begin
	  highIn_prev <= 1'b0;
	  lowIn_prev <= 1'b0;
	end
    else begin
	  highIn_prev <= highIn;
	  lowIn_prev <= lowIn;
	end

  // when detect change bring both signals down,
  // wait when it is ready, the output signals will take
  // input signal values
  always_ff @(posedge clk, negedge rst_n)
    if(!rst_n) begin
	  highOut <= 1'b0;
	  lowOut <= 1'b0;
	end
    else if(changed) begin
	  highOut <= 1'b0;
	  lowOut <= 1'b0;
	end
    else if(ready) begin
	  highOut <= highIn;
	  lowOut <= lowIn;
	end

  always_comb begin
    nxt_state = state;
	// detect change
    changed = (highIn_prev ^ highIn) | (lowIn_prev ^ lowIn);
	ready = 0;     // will be on when ready
    case(state)
      READY: begin
	    ready = 1;
		// state goes to CHANGED upon a change
        if(changed) begin
          nxt_state = CHANGED;
        end
	  end
      CHANGED: begin
	    ready = 0;
		// wait for count is over
        if(&deadTime) nxt_state = READY;
	  end
    endcase
  end

endmodule
