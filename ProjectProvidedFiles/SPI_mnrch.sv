module SPI_mnrch(
  input clk,                      // 50MHz system clock and reset
  input rst_n,
  output logic SS_n,              // SPI protocol signals 
  output SCLK,
  output MOSI,
  input MISO,
  input snd,                      // A high for 1 clock period would initiate a SPI transaction
  input [15:0] cmd,               // Data (command) being sent to inertial sensor
  output logic done,              // Asserted when SPI transaction is complete. Should stay asserted till next wrt
  output logic [15:0] resp        // Data from SPI serf. For inertial sensor we will only ever use bits [7:0]
);

  typedef enum logic [1:0] {IDLE, SHFT, BPRCH} state_t;       // state for idle, shift and backporch
  state_t state, nxt_state;
  logic done16;                   // on when finish all 16 bit
  logic shift;                    // shift at posedge SCLK + 2 clk cycles
  logic full;                     // used for the backporch to signal done
  logic ld_SCLK;                  // signal load for SCLK
  logic init;                     // signal start transition
  logic set_done;                 // signal done
  logic [4:0] bit_cntr;           // bit counter
  logic [4:0] SCLK_div;           // counter for SCLK
  logic [15:0] shft_reg;          // placement of data
  
  assign done16 = bit_cntr == 5'h10;
  assign full = &SCLK_div;
  assign shift = SCLK_div == 5'b10001;
  assign SCLK = SCLK_div[4];
  assign MOSI = shft_reg[15];
  assign resp = shft_reg;

  // bit counter, increaments when shift
  always_ff @(posedge clk, negedge rst_n)
    if(!rst_n) bit_cntr <= 5'h00;
    else if(init) bit_cntr <= 5'h00;
    else if(shift) bit_cntr <= bit_cntr + 1;

  // SCLK counter, load when load signal is on, otherwise keep increamenting
  always_ff @(posedge clk, negedge rst_n)
    if(!rst_n) SCLK_div <= 5'b10111;
    else if(ld_SCLK) SCLK_div <= 5'b10111;
    else SCLK_div <= SCLK_div + 1;

  // placement of data, at each shift, it gives MSB to MOSI, and gets MISO for LSB
  always_ff @(posedge clk, negedge rst_n)
    if(!rst_n) shft_reg <= 16'h0000;
    else if(init) shft_reg <= cmd;
    else if(shift) shft_reg <= {shft_reg[14:0], MISO};

  // state default at IDLE
  always_ff @(posedge clk, negedge rst_n)
    if(!rst_n) state <= IDLE;
    else state <= nxt_state;

  // use ff for SS_n and done to prevent glitch
  always_ff @(posedge clk, negedge rst_n)
    if(!rst_n) begin
      SS_n <= 1'b1;
      done <= 1'b0;
    end
    else if(init) begin
      SS_n <= 1'b0;
      done <= 1'b0;
    end
    else if(set_done) begin 
      SS_n <= 1'b1;
      done <= 1'b1;
    end
    
  always_comb begin
    init = 1'b0;
    ld_SCLK = 1'b0;
    set_done = 1'b0;
    nxt_state = state;

    case(state)
      SHFT: 
        if(done16) nxt_state = BPRCH;
      BPRCH: 
        if(full) begin
          nxt_state = IDLE;
		  ld_SCLK = 1'b1;
          set_done = 1'b1;
        end
		
	  // default state is IDLE
      default: begin
        ld_SCLK = 1'b1;
        if(snd) begin
          nxt_state = SHFT;
          init = 1'b1;
        end
      end
    endcase
  end


endmodule
