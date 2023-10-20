module qerv_bufreg #(
      parameter [0:0] MDU = 0,
      parameter BITS_PER_CYCLE = 1,
      parameter LB = $clog2(BITS_PER_CYCLE)
)(
   input wire 	      i_clk,
   //State
   input wire 	      i_cnt0,
   input wire 	      i_cnt1,
   input wire 	      i_en,
   input wire 	      i_init,
   input wire           i_mdu_op,
   output wire [1:0]    o_lsb,
   //Control
   input wire 	      i_rs1_en,
   input wire 	      i_imm_en,
   input wire 	      i_clr_lsb,
   input wire         i_shift_op,
   input wire         i_right_shift_op,
   input wire 	      i_sh_signed,
   //Data
   input wire [BITS_PER_CYCLE-1:0] i_rs1,
   input wire [BITS_PER_CYCLE-1:0] i_imm,
   // i_shift_counter_lsb[LB] must be zero to support the case LB=0
   input wire [LB:0]  i_shift_counter_lsb,
   output wire [BITS_PER_CYCLE-1:0] o_q,
   //External
   output wire [31:0] o_dbus_adr,
   //Extension
   output wire [31:0] o_ext_rs1);

   wire [BITS_PER_CYCLE-1:0] zeroB = 0;

   wire 	      c;
   wire [BITS_PER_CYCLE-1:0] q;
   reg  [2*BITS_PER_CYCLE-1:0] next_shifted;
   reg 		      c_r;
   reg [31:0] 	      data;
   reg [1:0]            lsb;
   wire [LB:0]      shift_counter_rev = BITS_PER_CYCLE - i_shift_counter_lsb;

   wire [LB:0] shift_amount = i_shift_op ? (
       i_right_shift_op ? (i_shift_counter_lsb == 00 ? 0 : (shift_counter_rev[LB:0])) : i_shift_counter_lsb
   ) : 0;

   wire 	      clr_lsb = i_cnt0 & i_clr_lsb;

   wire [BITS_PER_CYCLE-1:0] mask;
   generate
     if (BITS_PER_CYCLE == 4)
        assign  mask = 4'b1110;
     else if (BITS_PER_CYCLE == 1)
	assign  mask = 0;
   endgenerate

   assign {c,q} = {1'b0,(i_rs1_en ? i_rs1 : zeroB)} + {1'b0,((i_imm_en) ? (clr_lsb ? (i_imm & mask) : i_imm) : zeroB)} + { zeroB, c_r };

   always @(posedge i_clk) begin
      //Make sure carry is cleared before loading new data
      c_r <= c & i_en;

      if (i_cnt0)
        next_shifted <= 0;
      if (i_en)
              next_shifted <= ({ zeroB, data[BITS_PER_CYCLE-1:0]} << shift_amount);

      if (i_en)
        data <= {i_init ? q : (i_sh_signed ? {BITS_PER_CYCLE{data[31]}} : zeroB), data[31:BITS_PER_CYCLE]};
   end

   generate
    if (BITS_PER_CYCLE == 1)
      always @(posedge i_clk) begin
        if (i_init ? (i_cnt0 | i_cnt1) : i_en)
            lsb <= {i_init ? q : data[2],lsb[1]};
      end
    else if (BITS_PER_CYCLE == 4)
      always @(posedge i_clk) begin
        if (i_en)
            if (i_cnt0) lsb <= q[1:0];
      end
   endgenerate

   assign o_q = i_en ? ((data[BITS_PER_CYCLE-1:0] << shift_amount) | next_shifted[2*BITS_PER_CYCLE-1:BITS_PER_CYCLE]) : zeroB;
   assign o_dbus_adr = {data[31:2], 2'b00};
   assign o_ext_rs1  = data;
   assign o_lsb = (MDU & i_mdu_op) ? 2'b00 : lsb;

endmodule
