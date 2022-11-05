module i2c_tb;
   parameter int clk_rate = 400000;
   time		 period = 1s/clk_rate;

   logic clk  = 0;
   logic data;

   // Read output
   logic [6:0] wr_addr = 7'h2a;
   logic [7:0] wr_data = 8'h74;

   // Read output
   logic [6:0] rd_addr = 7'h2a;
   logic [7:0] rd_data;
   logic       ack     = 1'b0;
   int	       num_read_bytes = 1;



   // Clocking
   initial begin
      forever begin
	 #(period/2) clk = ~clk;
      end
   end



   initial begin
      // Writes
      repeat(10) @(posedge clk);
      dut_master.m_write_data(wr_addr, wr_data);
      repeat(20) @(posedge clk);

      // Reads
      dut_master.m_read_data(rd_addr, rd_data, num_read_bytes, ack);

      $display("============================");
      $display("======= TEST PASSED! =======");
      $display("============================");
      $finish;
   end


   initial begin
      #(1000*period)

      $display("============================");
      $display("======= TEST FAILED! =======");
      $display("============================");
      $finish;
   end


   // DUTs
   i2c_master_bfm #(.clk_freq(clk_rate)) dut_master(clk, data);
   i2c_slave_bfm #(.clk_freq(clk_rate)) dut_slave(clk, data);
endmodule // i2c_tb
