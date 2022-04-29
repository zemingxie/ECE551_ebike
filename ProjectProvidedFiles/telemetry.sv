module telemetry(
  input clk,                        // 50MHz clk
  input rst_n,                      // asynch low reset
  input [11:0] batt_v,              // three signals needs to be sent
  input [11:0] avg_curr,
  input [11:0] avg_torque,
  output TX                         // output to the receiver
);

  localparam delim1 = 8'hAA;        // 2-byte delimiter
  localparam delim2 = 8'h55;

  logic trmt, tx_done;              // transmit and done signal for transmitter
  logic [2:0] bit_counter;          // count how many bytes sent
  logic [7:0] payload1, payload2, payload3, payload4, payload5, payload6, tx_data;
  logic [19:0] time_counter;        // count the time

  typedef enum reg {IDLE, TRANS} state_t;          // initialize state
  state_t state, nxt_state;

  // Remaining 6 bytes to send
  assign payload1 = {4'h0, batt_v[11:8]};
  assign payload2 = batt_v[7:0];
  assign payload3 = {4'h0, avg_curr[11:8]};
  assign payload4 = avg_curr[7:0];
  assign payload5 = {4'h0, avg_torque[11:8]};
  assign payload6 = avg_torque[7:0];

  // instantiate the transmitter
  UART_tx transmitter(.*);

  // clock counts the time, a full cycle is approx 1/48 s
  always_ff @(posedge clk, negedge rst_n)
    if(!rst_n) time_counter <= 20'h00000;
    else time_counter <= time_counter + 1;

  // bit counter, this helps to know which byte the program is at
  always_ff @(posedge clk, negedge rst_n)
    if(!rst_n) bit_counter <= 3'b000;
    else if(tx_done) bit_counter <= bit_counter + 1;

  // standard state
  always_ff @(posedge clk, negedge rst_n)
    if(!rst_n) state <= IDLE;
    else state <= nxt_state;

  always_comb begin
    // transmit default at 0
    nxt_state = state;
    trmt = 1'b0;
	tx_data = delim1;
    case(state)
      IDLE:
        // when time counter is 20'h000ff, start the first byte
        // 20'h000ff is just a constant I set to give some time
        // after reset to start transmit
        if(time_counter == 20'h000ff) begin
          nxt_state = TRANS;
          trmt = 1'b1;
          tx_data = delim1;    // first byte is delim1
        end
      TRANS:
        // when finish transmit and did not finish all bytes,
        // transmit again
        if(tx_done && !(&bit_counter)) begin
          trmt = 1'b1;
          // notice at first byte, when done, I need to send second
          // byte
          case(bit_counter)
            3'b000: tx_data = delim2;
            3'b001: tx_data = payload1;
            3'b010: tx_data = payload2;
            3'b011: tx_data = payload3;
            3'b100: tx_data = payload4;
            3'b101: tx_data = payload5;
            3'b110: tx_data = payload6;
            // impossible to reach here
            3'b111: tx_data = delim1;
      	  endcase
        end
        // when finished transmitting all, go to IDLE state
        else if(tx_done && (&bit_counter)) nxt_state = IDLE;
    endcase
  end

endmodule
