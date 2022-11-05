module i2c_slave_bfm(scl, sda);
   input logic scl;
   inout logic sda = 1'bZ;

   parameter clk_freq;
   time      period = 1s/clk_freq;

   logic [6:0] addr;
   logic [7:0] rd_data;
   logic [7:0] wr_data = 8'h5b;
   logic       rw;
   logic       rd_ack = 1'b0;


   task m_begin_tx;
      begin
	 // Wait for falling edge of sda
	 @(negedge sda);

	 // Ensure sda negedge precedes scl negedge
	 assert (scl == 1'b1);

	 // Ensure sda remains low until scl negedge
	 @(negedge scl or sda == 1'b1);
	 assert (sda == 1'b0);
      endtask // m_begin_tx


   task m_addr_phase;
      begin
	 // Read 7-bit address
	 for(int i=0; i<7; i++) begin
	    @(posedge scl);
	    addr = {addr[5:0], sda};
	 end

	 // Read RW bit
	 @(posedge scl);
	 rw = sda;

	 // Active low ACK bit
	 @(period/2);
	 sda = 1'b0;

	 @(period);
	 sda = 1'bZ;

      endtask // read_addr


   task m_write_data;
      begin
	 // Read 8-bit data
	 for(int i=0; i<8; i++) begin
	    @(posedge scl);
	    rd_data = {rd_data[6:0], sda};
	 end

	 // Active low ACK bit
	 @(period/2);
	 sda = 1'b0;

	 @(period);
	 sda = 1'bZ;

	 // Wait for posedge scl or sda
	 @(posedge scl or posedge sda);
	 assert(sda == 1'b0);
	 assert(scl == 1'b1);

	 @(negedge scl or posedge sda);
	 assert(sda == 1'b1);
	 assert(scl == 1'b1);
      endtask // read_data


   task m_read_data;
      input logic [7:0] wr_data;

      begin
	 do begin
	    // Read 8-bit data
	    for(int i=7; i>=0; i--) begin
	       sda = wr_data[i];
	       @(posedge scl);
	    end

	    // Active low ACK bit
	    @(period/2);
	    sda = 1'bZ;

	    @(posedge scl);
	    rd_ack = sda;
	    @(period/2);
	    // While the master doesn't take back control of the sda line
	 end while(sda == 1'bZ); // do begin
      endtask // read_data


   initial begin
      this.m_begin_task();
      this.m_addr_phase();

      // If master write
      if(rw == 1'b1) begin
	 this.m_write_data();
      end else begin
	 this.m_read_data(8'hAB);
      end
   end
endmodule // i2c_slave_bfm
