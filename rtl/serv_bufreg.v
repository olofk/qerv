module qerv_bufreg #(
      parameter [0:0] MDU = 0,
      parameter W = 1,
      parameter B = W-1,
      parameter LB = $clog2(W)
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
   input wire [B:0] i_rs1,
   input wire [B:0] i_imm,
   // i_shift_counter_lsb[LB] must be zero to support the case LB=0
   input wire [LB:0]  i_shift_counter_lsb,
   output wire [B:0] o_q,
   //External
   output wire [31:0] o_dbus_adr,
   //Extension
   output wire [31:0] o_ext_rs1);

   wire [B:0] zeroB = 0;

   wire 	      c;
   wire [B:0] q;
   reg  [2*W-1:0] next_shifted;
   reg 		      c_r;
   reg [31:0] 	      data;
   reg [1:0]            lsb;
   wire [LB:0]      shift_counter_rev = W - i_shift_counter_lsb;

   wire [LB:0] shift_amount = i_shift_op ? (
       i_right_shift_op ? ((LB == 0) ? 0 : (shift_counter_rev[LB:0])) : i_shift_counter_lsb
   ) : 0;

   wire 	      clr_lsb = i_cnt0 & i_clr_lsb;

   wire [B:0] mask;
   generate
     if (W == 4) begin : gen_mask_w_4
        assign  mask = 4'b1110;
     end else if (W == 1) begin : gen_mask_w_1
	assign  mask = 0;
     end
   endgenerate

   assign {c,q} = {1'b0,(i_rs1_en ? i_rs1 : zeroB)} + {1'b0,((i_imm_en) ? (clr_lsb ? (i_imm & mask) : i_imm) : zeroB)} + { zeroB, c_r };

   always @(posedge i_clk) begin
      //Make sure carry is cleared before loading new data
      c_r <= c & i_en;

      if (i_cnt0)
        next_shifted <= 0;
      if (i_en)
              next_shifted <= ({ zeroB, data[B:0]} << shift_amount);

      if (i_en)
        data <= {i_init ? q : (i_sh_signed ? {W{data[31]}} : zeroB), data[31:W]};
   end

   generate
    if (W == 1) begin : gen_lsb_w_1
      always @(posedge i_clk) begin
        if (i_init ? (i_cnt0 | i_cnt1) : i_en)
            lsb <= {i_init ? q : data[2],lsb[1]};
      end
    end else if (W == 4) begin : gen_lsb_w_4
      always @(posedge i_clk) begin
        if (i_en)
            if (i_cnt0) lsb <= q[1:0];
      end
    end
   endgenerate

   assign o_q = i_en ? ((data[B:0] << shift_amount) | next_shifted[2*W-1:W]) : zeroB;
   assign o_dbus_adr = {data[31:2], 2'b00};
   assign o_ext_rs1  = data;
   assign o_lsb = (MDU & i_mdu_op) ? 2'b00 : lsb;

endmodule
