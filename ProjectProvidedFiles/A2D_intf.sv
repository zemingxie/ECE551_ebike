module A2D_intf(clk, rst_n, batt, curr, brake, torque, SS_n, SCLK, MOSI, MISO);
	input clk;
	input rst_n;
	output logic [11:0] batt;
	output logic [11:0] curr;
	output logic [11:0] brake;
	output logic [11:0] torque;
	output SS_n;
	output SCLK;
	output MOSI;
	input MISO;
	
	logic snd;
	logic [15:0] cmd;				// Data (command) being sent to inertial sensor
	logic done;						// Asserted when SPI transaction is complete. Should stay asserted till next wrt
	logic [15:0] resp;
	logic [13:0] counter;
	logic [1:0] num_chnnl;
	logic [2:0] chnnl;
	logic start;
	logic cnv_cmplt;
	logic torque_en, curr_en, batt_en, brake_en;
	typedef enum logic [1:0] {IDLE, SEND, WAIT, RECEIVE} state_t;
	state_t state, nxt_state;
	
	SPI_mnrch spi(.*);
	
	assign cmd = {2'b00, chnnl, 11'h000};
	assign start = &counter;
	assign torque_en = cnv_cmplt && (num_chnnl == 2'b11);
	assign curr_en = cnv_cmplt && (num_chnnl == 2'b01);
	assign batt_en = cnv_cmplt && (num_chnnl == 2'b00);
	assign brake_en = cnv_cmplt && (num_chnnl == 2'b10);
	
        //the counter
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n) counter <= '1;
		else counter <= counter + 1;
		
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n) state <= IDLE;
		else state <= nxt_state;
	//change the channel
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n) num_chnnl <= 2'b00;
		else if(cnv_cmplt) num_chnnl <= num_chnnl + 1;
		
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n) torque <= 12'h000;
		else if(torque_en) torque <= resp;
	
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n) curr <= 12'h000;
		else if(curr_en) curr <= resp;
		
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n) batt <= 12'h000;
		else if(batt_en) batt <= resp;
		
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n) brake <= 12'h000;
		else if(brake_en) brake <= resp;
		
	always_comb begin
		nxt_state = state;
		snd = 0;
		cnv_cmplt = 0;
		case(state)
			IDLE:
				if(start) begin
					snd = 1;
					nxt_state = SEND;
				end
			
			SEND:
				if(done) nxt_state = WAIT;
				
			WAIT: begin
				snd = 1;
				nxt_state = RECEIVE;
			end
			
			RECEIVE:
				if(done) begin
					cnv_cmplt = 1;
					nxt_state = IDLE;
				end
		endcase
		case(num_chnnl)
			2'b00: chnnl = 3'b000;
			2'b01: chnnl = 3'b001;
			2'b10: chnnl = 3'b011;
			2'b11: chnnl = 3'b100;
		endcase
	end
	
endmodule
