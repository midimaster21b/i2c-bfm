module i2c_slave_bfm(scl, sda);
   input logic scl;
   inout logic sda;

   parameter clk_freq;
   time      period = 1s/clk_freq;

   logic [6:0] addr;
   logic [7:0] rd_data;
   logic [7:0] wr_data = 8'h5b;
   logic       rw;
   logic       rd_ack = 1'b0;

   logic     sda_out;
   logic     sda_in;
   logic     sda_z   = 1'b1;

   assign sda = (sda_z == 1'b1) ? 'bz : sda_out;
   assign sda_in = sda;

   task m_begin_tx;
      begin
	 $timeformat(-9, 2, " ns", 20);
	 $display("%t: I2C Slave - Transaction Found", $time);

	 // Wait for falling edge of sda
	 @(negedge sda_in);

	 // Ensure sda negedge precedes scl negedge
	 assert (scl == 1'b1);

	 // Ensure sda remains low until scl negedge
	 @(negedge scl or sda_in == 1'b1);
	 assert (sda_in == 1'b0);
      end
   endtask // m_begin_tx


   task m_addr_phase;
      begin
	 $timeformat(-9, 2, " ns", 20);
	 $display("%t: I2C Slave - Address Phase", $time);

	 // Read 7-bit address
	 for(int i=0; i<7; i++) begin
	    @(posedge scl);
	    addr = {addr[5:0], sda_in};
	 end

	 $display("%t: I2C Slave - Address found '%h'", $time, addr);

	 // Read RW bit
	 @(posedge scl);
	 rw <= sda_in;

	 // Active low ACK bit
	 @(period/2);
	 sda_z   <= 1'b0;
	 sda_out <= 1'b0;

	 @(period);
	 sda_z <= 1'b1;

      end
   endtask // m_addr_phase


   task m_write_data;
      begin
	 $timeformat(-9, 2, " ns", 20);
	 $display("%t: I2C Slave - Write Phase", $time);

	 // Read 8-bit data
	 for(int i=0; i<8; i++) begin
	    @(posedge scl);
	    rd_data = {rd_data[6:0], sda_in};
	 end

	 // Active low ACK bit
	 @(period/2);
	 sda_z   <= 1'b0;
	 sda_out <= 1'b0;

	 @(period);
	 sda_z   <= 1'b1;

	 // Wait for posedge scl or sda
	 @(posedge scl or posedge sda_in);
	 assert(sda_in == 1'b0);
	 assert(scl == 1'b1);

	 @(negedge scl or posedge sda_in);
	 assert(sda_in == 1'b1);
	 assert(scl == 1'b1);
      end
   endtask // read_data


   task m_read_data;
      input logic [7:0] wr_data;

      begin
	 do begin
	    $timeformat(-9, 2, " ns", 20);
	    $display("%t: I2C Slave - Read Phase", $time);

	    sda_z <= 1'b0;

	    // Read 8-bit data
	    for(int i=7; i>=0; i--) begin
	       sda_out <= wr_data[i];
	       @(posedge scl);
	    end

	    // Active low ACK bit
	    @(period/2);
	    sda_z <= 1'b1;

	    @(posedge scl);
	    rd_ack <= sda_in;
	    @(period/2);
	    // While the master doesn't take back control of the sda line
	 end while(sda_in == 1'bZ); // do begin
      end
   endtask // read_data


   // Main slave BFM operation
   initial begin
      sda_out <= 1'b0;
      sda_z   <= 1'b1;

      forever begin
	 m_begin_tx();
	 m_addr_phase();

	 // If master write
	 if(rw == 1'b1) begin
	    m_write_data();
	 end else begin
	    m_read_data(8'hAB);
	 end
      end
   end
endmodule // i2c_slave_bfm
