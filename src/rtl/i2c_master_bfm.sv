module i2c_master_bfm(scl, sda);
   output logic scl = 1'b1;
   inout  logic sda = 1'b1;

   parameter clk_freq;
   time      period = 1s/clk_freq;

   const logic READ_C  1'b1;
   const logic WRITE_C 1'b0;

   logic     clk = 0;
   logic     read_ack;
   logic     write_ack;


   initial begin
      forever begin
	 #(period/2) clk = ~clk;
      end
   end


   task addr_phase;
      input  logic [6:0] addr;
      input  logic	 rw;
      output logic	 ack;

      begin
	 @(posedge clk);
	 sda = 0;

	 @(negedge clk);
	 scl = 0;

	 @(posedge clk);
	 @(negedge clk);

	 for(int i=6; i>=0; i--) begin
	    // Address on falling edge
	    sda = addr[i];
	    @(posedge clk);
	    scl = 1'b1;
	    @(negedge clk);
	    scl = 1'b0;
	 end

	 sda = rw;
	 @(posedge clk);
	 scl = 1'b1;

	 @(negedge clk);
	 scl = 1'b0;
	 sda = 1'bZ;

	 // Read Ack
	 @(posedge clk);
	 scl = 1'b1;
	 ack = sda;

	 @(negedge clk);
	 scl = 1'b0;
      endtask // addr_phase


   task m_write_data;
      input [6:0] wr_addr;
      input [7:0] wr_data;

      begin
	 // Perform address write
	 addr_phase(wr_addr, WRITE_C, write_ack);

	 // Write data
	 for(int i=7; i>0; i--) begin
	    // Data on falling edge
	    sda = wr_data[i];
	    @(posedge clk);
	    scl = 1'b1;
	    @(negedge clk);
	    scl = 1'b0;
	 end

	 // High-z for ack
	 sda = 1'bZ;

	 // Read ack
	 @(posedge clk);
	 scl = 1'b1;
	 write_ack = sda;

	 // Return master line control
	 @(negedge clk);
	 scl = 1'b0;
	 sda = 1'b0;

	 @(posedge clk);

	 @(posedge clk);
	 scl = 1'b1;

	 @(negedge clk);
	 sda = 1'b1;

      endtask // m_write_data


   task m_read_data;
      input  [6:0] rd_addr;
      output [7:0] rd_data;
      input  int   num_bytes;
      input  logic ack;

      begin
	 // Perform address write
	 addr_phase(rd_addr, READ_C, read_ack);


	 for(int x=0; x<num_bytes; x++) begin
	    // Write data
	    for(int i=7; i>0; i--) begin
	       sda = 1'bZ;
	       @(posedge clk);
	       scl = 1'b1;
	       rd_data = {rd_data[6:0], sda};
	       @(negedge clk);
	       scl = 1'b0;
	    end

	    // Set ack value
	    sda = ack;
	    @(posedge clk);
	    scl = 1'b1;

	    if(x == num_bytes-1) begin
	       // If last byte, retain control of lines
	       @(negedge clk);
	       scl = 1'b0;
	       sda = 1'b0;
	    end else begin
	       // Return master line control
	       @(negedge clk);
	       scl = 1'b0;
	       sda = 1'bZ;
	    end
	 end

	 @(posedge clk);
	 @(posedge clk);
	 scl = 1'b1;

	 @(negedge clk);
	 sda = 1'b1;

      endtask // m_read_data


endmodule // i2c_master_bfm
