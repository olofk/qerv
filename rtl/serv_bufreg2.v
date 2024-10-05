module qerv_bufreg2
  #(
   parameter W = 1,
   parameter B = W-1,
   parameter LB = $clog2(W)
  )
  (
   input wire 	      i_clk,
   //State
   input wire 	      i_en,
   input wire 	      i_init,
   input wire 	      i_cnt_done,
   input wire [1:0]   i_lsb,
   input wire 	      i_byte_valid,
   output wire 	      o_sh_done,
   output wire 	      o_sh_done_r,
   //Control
   input wire 	      i_op_b_sel,
   input wire 	      i_shift_op,
   //Data
   input wire [B:0] i_rs2,
   input wire [B:0] i_imm,
   output wire [B:0] o_op_b,
   output wire [B:0] o_q,
   output wire [LB:0] o_shift_counter_lsb,
   //External
   output wire [31:0] o_dat,
   input wire 	      i_load,
   input wire [31:0]  i_dat);

   reg [31:0] 	 dat;

   assign o_op_b = i_op_b_sel ? i_rs2 : i_imm;

   wire 	 dat_en = i_shift_op | (i_en & i_byte_valid);

   /* The dat register has three different use cases for store, load and
    shift operations.
    store : Data to be written is shifted to the correct position in dat during
            init by dat_en and is presented on the data bus as o_wb_dat
    load  : Data from the bus gets latched into dat during i_wb_ack and is then
            shifted out at the appropriate time to end up in the correct
            position in rd
    shift : Data is shifted in during init. After that, the six LSB are used as
            a downcounter (with bit 5 initially set to 0) that triggers
            o_sh_done and o_sh_done_r when they wrap around to indicate that
            the requested number of shifts have been performed
    */

   // verilator lint_off WIDTH
   wire [5:0] dat_shamt = (i_shift_op & !i_init) ?
	      //Down counter mode
              dat[5:0]-W :
	      //Shift reg mode with optional clearing of bit 5
	      {dat[5+W] & !(i_shift_op & i_cnt_done),dat[4+W:W]};
   // verilator lint_on WIDTH

   assign o_sh_done = dat[5];
   assign o_sh_done_r = dat[5];
   assign o_shift_counter_lsb = ((1 << LB) - 1) & dat[LB:0]; // clear dat[LB] as a workaround for LB==0 

   assign o_q =
	       ({W{(i_lsb == 2'd3)}} & dat[23+W:24]) |
	       ({W{(i_lsb == 2'd2)}} & dat[15+W:16]) |
	       ({W{(i_lsb == 2'd1)}} & dat[7+W:8])   |
	       ({W{(i_lsb == 2'd0)}} & dat[-1+W:0]);

   assign o_dat = dat;

   always @(posedge i_clk) begin
      if (dat_en | i_load)
	dat <= i_load ? i_dat : {o_op_b, dat[31:6+W], dat_shamt};
   end

endmodule
