//////////////////////////////////////////////////////////////////////
////                                                              ////
////  can_bsp.v                                                   ////
////                                                              ////
////                                                              ////
////  This file is part of the CAN Protocol Controller            ////
////  http://www.opencores.org/projects/can/                      ////
////                                                              ////
////                                                              ////
////  Author(s):                                                  ////
////       Igor Mohor                                             ////
////       igorm@opencores.org                                    ////
////                                                              ////
////                                                              ////
////  All additional information is available in the README.txt   ////
////  file.                                                       ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2002, 2003 Authors                             ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//// The CAN protocol is developed by Robert Bosch GmbH and       ////
//// protected by patents. Anybody who wants to implement this    ////
//// CAN IP core on silicon has to obtain a CAN protocol license  ////
//// from Bosch.                                                  ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//
// CVS Revision History
//
// $Log: not supported by cvs2svn $
// Revision 1.20  2003/02/10 16:02:11  mohor
// CAN is working according to the specification. WB interface and more
// registers (status, IRQ, ...) needs to be added.
//
// Revision 1.19  2003/02/09 18:40:29  mohor
// Overload fixed. Hard synchronization also enabled at the last bit of
// interframe.
//
// Revision 1.18  2003/02/09 02:24:33  mohor
// Bosch license warning added. Error counters finished. Overload frames
// still need to be fixed.
//
// Revision 1.17  2003/02/04 17:24:41  mohor
// Backup.
//
// Revision 1.16  2003/02/04 14:34:52  mohor
// *** empty log message ***
//
// Revision 1.15  2003/01/31 01:13:37  mohor
// backup.
//
// Revision 1.14  2003/01/16 13:36:19  mohor
// Form error supported. When receiving messages, last bit of the end-of-frame
// does not generate form error. Receiver goes to the idle mode one bit sooner.
// (CAN specification ver 2.0, part B, page 57).
//
// Revision 1.13  2003/01/15 21:59:45  mohor
// Data is stored to fifo at the end of ack stage.
//
// Revision 1.12  2003/01/15 21:05:11  mohor
// CRC checking fixed (when bitstuff occurs at the end of a CRC sequence).
//
// Revision 1.11  2003/01/15 14:40:23  mohor
// RX state machine fixed to receive "remote request" frames correctly.
// No data bytes are written to fifo when such frames are received.
//
// Revision 1.10  2003/01/15 13:16:47  mohor
// When a frame with "remote request" is received, no data is stored to
// fifo, just the frame information (identifier, ...). Data length that
// is stored is the received data length and not the actual data length
// that is stored to fifo.
//
// Revision 1.9  2003/01/14 12:19:35  mohor
// rx_fifo is now working.
//
// Revision 1.8  2003/01/10 17:51:33  mohor
// Temporary version (backup).
//
// Revision 1.7  2003/01/09 21:54:45  mohor
// rx fifo added. Not 100 % verified, yet.
//
// Revision 1.6  2003/01/09 14:46:58  mohor
// Temporary files (backup).
//
// Revision 1.5  2003/01/08 13:30:31  mohor
// Temp version.
//
// Revision 1.4  2003/01/08 02:10:53  mohor
// Acceptance filter added.
//
// Revision 1.3  2002/12/28 04:13:23  mohor
// Backup version.
//
// Revision 1.2  2002/12/27 00:12:52  mohor
// Header changed, testbench improved to send a frame (crc still missing).
//
// Revision 1.1.1.1  2002/12/20 16:39:21  mohor
// Initial
//
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "can_defines.v"

module can_bsp
( 
  clk,
  rst,

  sample_point,
  sampled_bit,
  sampled_bit_q,
  tx_point,
  hard_sync,

  addr,
  data_out,


  /* Mode register */
  reset_mode,
  acceptance_filter_mode,

  /* Command register */
  release_buffer,
  tx_request,

  /* Clock Divider register */
  extended_mode,

  rx_idle,
  transmitting,
  last_bit_of_inter,

  /* This section is for BASIC and EXTENDED mode */
  /* Acceptance code register */
  acceptance_code_0,

  /* Acceptance mask register */
  acceptance_mask_0,
  /* End: This section is for BASIC and EXTENDED mode */
  
  /* This section is for EXTENDED mode */
  /* Acceptance code register */
  acceptance_code_1,
  acceptance_code_2,
  acceptance_code_3,

  /* Acceptance mask register */
  acceptance_mask_1,
  acceptance_mask_2,
  acceptance_mask_3,
  /* End: This section is for EXTENDED mode */
  
  /* Tx data registers. Holding identifier (basic mode), tx frame information (extended mode) and data */
  tx_data_0,
  tx_data_1,
  tx_data_2,
  tx_data_3,
  tx_data_4,
  tx_data_5,
  tx_data_6,
  tx_data_7,
  tx_data_8,
  tx_data_9,
  tx_data_10,
  tx_data_11,
  tx_data_12,
  /* End: Tx data registers */
  
  /* Tx signal */
  tx,
  tx_oen

);

parameter Tp = 1;

input         clk;
input         rst;
input         sample_point;
input         sampled_bit;
input         sampled_bit_q;
input         tx_point;
input         hard_sync;
input   [7:0] addr;
output  [7:0] data_out;


input         reset_mode;
input         acceptance_filter_mode;
input         extended_mode;

/* Command register */
input         release_buffer;
input         tx_request;

output        rx_idle;
output        transmitting;
output        last_bit_of_inter;


/* This section is for BASIC and EXTENDED mode */
/* Acceptance code register */
input   [7:0] acceptance_code_0;

/* Acceptance mask register */
input   [7:0] acceptance_mask_0;

/* End: This section is for BASIC and EXTENDED mode */


/* This section is for EXTENDED mode */
/* Acceptance code register */
input   [7:0] acceptance_code_1;
input   [7:0] acceptance_code_2;
input   [7:0] acceptance_code_3;

/* Acceptance mask register */
input   [7:0] acceptance_mask_1;
input   [7:0] acceptance_mask_2;
input   [7:0] acceptance_mask_3;
/* End: This section is for EXTENDED mode */

/* Tx data registers. Holding identifier (basic mode), tx frame information (extended mode) and data */
input   [7:0] tx_data_0;
input   [7:0] tx_data_1;
input   [7:0] tx_data_2;
input   [7:0] tx_data_3;
input   [7:0] tx_data_4;
input   [7:0] tx_data_5;
input   [7:0] tx_data_6;
input   [7:0] tx_data_7;
input   [7:0] tx_data_8;
input   [7:0] tx_data_9;
input   [7:0] tx_data_10;
input   [7:0] tx_data_11;
input   [7:0] tx_data_12;
/* End: Tx data registers */

/* Tx signal */
output        tx;
output        tx_oen;

reg           reset_mode_q;
reg     [5:0] bit_cnt;

reg     [3:0] data_len;
reg    [28:0] id;
reg     [2:0] bit_stuff_cnt;
reg     [2:0] bit_stuff_cnt_tx;
reg           tx_point_q;

reg           rx_idle;
reg           rx_id1;
reg           rx_rtr1;
reg           rx_ide;
reg           rx_id2;
reg           rx_rtr2;
reg           rx_r1;
reg           rx_r0;
reg           rx_dlc;
reg           rx_data;
reg           rx_crc;
reg           rx_crc_lim;
reg           rx_ack;
reg           rx_ack_lim;
reg           rx_eof;
reg           rx_inter;

reg           rtr1;
reg           ide;
reg           rtr2;
reg    [14:0] crc_in;

reg     [7:0] tmp_data;
reg     [7:0] tmp_fifo [0:7];
reg           write_data_to_tmp_fifo;
reg     [2:0] byte_cnt;
reg           bit_stuff_cnt_en;
reg           crc_enable;

reg     [2:0] eof_cnt;
reg     [2:0] passive_cnt;

reg           transmitting;

reg           error_frame;
reg           error_frame_q;
reg           enable_error_cnt2;
reg     [2:0] error_cnt1;
reg     [2:0] error_cnt2;
reg     [2:0] delayed_dominant_cnt;
reg           enable_overload_cnt2;
reg           overload_frame;
reg           overload_frame_blocked;
reg     [2:0] overload_cnt1;
reg     [2:0] overload_cnt2;
reg           tx;
reg           crc_err;

reg           priority_lost;
reg           tx_q;

reg           need_to_tx;   // When the CAN core has something to transmit and a dominant bit is sampled at the third bit
reg     [3:0] data_cnt;     // Counting the data bytes that are written to FIFO
reg     [2:0] header_cnt;   // Counting header length
reg           wr_fifo;      // Write data and header to 64-byte fifo
reg     [7:0] data_for_fifo;// Multiplexed data that is stored to 64-byte fifo

reg     [5:0] tx_pointer;
reg           tx_bit;
reg           tx_state;
reg           transmitter;
reg           finish_msg;

reg     [9:0] rx_err_cnt;
reg     [9:0] tx_err_cnt;
reg           rx_err_cnt_blocked;
reg    [10:0] recessive_cnt;

reg           node_error_passive;
reg           node_bus_off;
reg           ack_err_latched;
reg           bit_err_latched;
reg           stuff_err_latched;
reg           form_err_latched;
reg           rule5;
reg           rule3_exc1_1;
reg           rule3_exc1_2;
reg           rule3_exc2;
reg           suspend;
reg           susp_cnt_en;
reg     [2:0] susp_cnt;
reg           go_error_frame_q;
reg           error_flag_over_blocked;

wire          bit_de_stuff;
wire          bit_de_stuff_tx;


/* Rx state machine */
wire          go_rx_idle;
wire          go_rx_id1;
wire          go_rx_rtr1;
wire          go_rx_ide;
wire          go_rx_id2;
wire          go_rx_rtr2;
wire          go_rx_r1;
wire          go_rx_r0;
wire          go_rx_dlc;
wire          go_rx_data;
wire          go_rx_crc;
wire          go_rx_crc_lim;
wire          go_rx_ack;
wire          go_rx_ack_lim;
wire          go_rx_eof;
wire          go_error_frame;
wire          go_overload_frame;
wire          go_rx_inter;

wire          go_crc_enable;
wire          rst_crc_enable;

wire          bit_de_stuff_set;
wire          bit_de_stuff_reset;

wire          go_early_tx;
wire          go_tx;

wire   [14:0] calculated_crc;
wire   [15:0] r_calculated_crc;
wire          remote_rq;
wire    [3:0] limited_data_len;
wire          form_err;
wire          set_form_error;

wire          error_frame_ended;
wire          overload_frame_ended;
wire          bit_err;
wire          ack_err;
wire          stuff_err;
                                    // of intermission, it starts reading the identifier (and transmitting its own).
wire          overload_needed = 0;  // When receiver is busy, it needs to send overload frame. Only 2 overload frames are allowed to
                                    // be send in a row. This is not implemented because host can not send an overload request. FIX ME !!!!

wire          id_ok;                // If received ID matches ID set in registers
wire          no_byte0;             // There is no byte 0 (RTR bit set to 1 or DLC field equal to 0). Signal used for acceptance filter.
wire          no_byte1;             // There is no byte 1 (RTR bit set to 1 or DLC field equal to 1). Signal used for acceptance filter.

wire    [2:0] header_len;
wire          storing_header;
wire    [3:0] limited_data_len_minus1;
wire          reset_wr_fifo;
wire          err;

wire          tx_successful;
wire          recessive_cnt_ok;
wire          arbitration_field;

wire   [18:0] basic_chain;
wire   [63:0] basic_chain_data;
wire   [18:0] extended_chain_std;
wire   [38:0] extended_chain_ext;
wire   [63:0] extended_chain_data;

wire          rst_tx_pointer;

wire    [7:0] r_tx_data_0;
wire    [7:0] r_tx_data_1;
wire    [7:0] r_tx_data_2;
wire    [7:0] r_tx_data_3;
wire    [7:0] r_tx_data_4;
wire    [7:0] r_tx_data_5;
wire    [7:0] r_tx_data_6;
wire    [7:0] r_tx_data_7;
wire    [7:0] r_tx_data_8;
wire    [7:0] r_tx_data_9;
wire    [7:0] r_tx_data_10;
wire    [7:0] r_tx_data_11;
wire    [7:0] r_tx_data_12;

wire          send_ack;
wire          bit_err_exc1;
wire          bit_err_exc2;
wire          bit_err_exc3;
wire          bit_err_exc4;
wire          bit_err_exc5;
wire          error_flag_over;
wire          overload_flag_over;


assign go_rx_idle     =                   sample_point &  sampled_bit & last_bit_of_inter;
assign go_rx_id1      =                   sample_point &  (~sampled_bit) & (rx_idle | last_bit_of_inter);
assign go_rx_rtr1     = (~bit_de_stuff) & sample_point &  rx_id1  & (bit_cnt == 10);
assign go_rx_ide      = (~bit_de_stuff) & sample_point &  rx_rtr1;
assign go_rx_id2      = (~bit_de_stuff) & sample_point &  rx_ide  &   sampled_bit;
assign go_rx_rtr2     = (~bit_de_stuff) & sample_point &  rx_id2  & (bit_cnt == 17);
assign go_rx_r1       = (~bit_de_stuff) & sample_point &  rx_rtr2;
assign go_rx_r0       = (~bit_de_stuff) & sample_point & (rx_ide  & (~sampled_bit) | rx_r1);
assign go_rx_dlc      = (~bit_de_stuff) & sample_point &  rx_r0;
assign go_rx_data     = (~bit_de_stuff) & sample_point &  rx_dlc  & (bit_cnt == 3) &  (sampled_bit   |   (|data_len[2:0])) & (~remote_rq);
assign go_rx_crc      = (~bit_de_stuff) & sample_point & (rx_dlc  & (bit_cnt == 3) & ((~sampled_bit) & (~(|data_len[2:0])) | remote_rq) |
                                                          rx_data & (bit_cnt == ((limited_data_len<<3) - 1'b1)));
assign go_rx_crc_lim  = (~bit_de_stuff) & sample_point &  rx_crc  & (bit_cnt == 14);
assign go_rx_ack      =                   sample_point &  rx_crc_lim;
assign go_rx_ack_lim  =                   sample_point &  rx_ack;
assign go_rx_eof      =                   sample_point &  rx_ack_lim  | (~reset_mode) & reset_mode_q;
assign go_rx_inter    =                 ((sample_point &  rx_eof  & (eof_cnt == 6)) | error_frame_ended | overload_frame_ended) & (~overload_needed);

assign go_error_frame = (form_err | stuff_err | bit_err | ack_err | (crc_err & go_rx_eof));
assign error_frame_ended = (error_cnt2 == 7) & tx_point;
assign overload_frame_ended = (overload_cnt2 == 7) & tx_point;

assign go_overload_frame = (   ((sample_point &  rx_eof  & (eof_cnt == 6)) | error_frame_ended | overload_frame_ended) & overload_needed | 
                               sample_point & (~sampled_bit) & rx_inter & (bit_cnt < 2)                                                  |
                               sample_point & (~sampled_bit) & ((error_cnt2 == 7) | (overload_cnt2 == 7))
                           )
                           & (~overload_frame_blocked)
                           ;


assign go_crc_enable  = hard_sync | go_tx;
assign rst_crc_enable = go_rx_crc;

assign bit_de_stuff_set   = go_rx_id1;
assign bit_de_stuff_reset = go_rx_crc_lim | reset_mode | go_error_frame | go_overload_frame;

assign remote_rq = ((~ide) & rtr1) | (ide & rtr2);
assign limited_data_len = (data_len < 8)? data_len : 4'h8;

assign ack_err = rx_ack & sample_point & sampled_bit & tx_state;
assign bit_err = (tx_state | error_frame | overload_frame | rx_ack) & sample_point & (tx !== sampled_bit) & (~bit_err_exc1) & (~bit_err_exc2) & (~bit_err_exc3) & (~bit_err_exc4) & (~bit_err_exc5);
assign bit_err_exc1 = tx_state & arbitration_field & tx;
assign bit_err_exc2 = rx_ack & tx;
assign bit_err_exc3 = error_frame & node_error_passive & (error_cnt1 < 7);
assign bit_err_exc4 = (error_frame & (error_cnt1 == 7) & (~enable_error_cnt2)) | (overload_frame & (overload_cnt1 == 7) & (~enable_overload_cnt2));
assign bit_err_exc5 = (error_frame & (error_cnt2 == 7)) | (overload_frame & (overload_cnt2 == 7));

assign arbitration_field = rx_id1 | rx_rtr1 | rx_ide | rx_id2 | rx_rtr2;

assign last_bit_of_inter = rx_inter & (bit_cnt == 2);


// Rx idle state
always @ (posedge clk or posedge rst)
begin
  if (rst)
    rx_idle <= 1'b0;
  else if (reset_mode | go_rx_id1 | error_frame)
    rx_idle <=#Tp 1'b0;
  else if (go_rx_idle)
    rx_idle <=#Tp 1'b1;
end


// Rx id1 state
always @ (posedge clk or posedge rst)
begin
  if (rst)
    rx_id1 <= 1'b0;
  else if (reset_mode | go_rx_rtr1 | error_frame)
    rx_id1 <=#Tp 1'b0;
  else if (go_rx_id1)
    rx_id1 <=#Tp 1'b1;
end


// Rx rtr1 state
always @ (posedge clk or posedge rst)
begin
  if (rst)
    rx_rtr1 <= 1'b0;
  else if (reset_mode | go_rx_ide | error_frame)
    rx_rtr1 <=#Tp 1'b0;
  else if (go_rx_rtr1)
    rx_rtr1 <=#Tp 1'b1;
end


// Rx ide state
always @ (posedge clk or posedge rst)
begin
  if (rst)
    rx_ide <= 1'b0;
  else if (reset_mode | go_rx_r0 | go_rx_id2 | error_frame)
    rx_ide <=#Tp 1'b0;
  else if (go_rx_ide)
    rx_ide <=#Tp 1'b1;
end


// Rx id2 state
always @ (posedge clk or posedge rst)
begin
  if (rst)
    rx_id2 <= 1'b0;
  else if (reset_mode | go_rx_rtr2 | error_frame)
    rx_id2 <=#Tp 1'b0;
  else if (go_rx_id2)
    rx_id2 <=#Tp 1'b1;
end


// Rx rtr2 state
always @ (posedge clk or posedge rst)
begin
  if (rst)
    rx_rtr2 <= 1'b0;
  else if (reset_mode | go_rx_r1 | error_frame)
    rx_rtr2 <=#Tp 1'b0;
  else if (go_rx_rtr2)
    rx_rtr2 <=#Tp 1'b1;
end


// Rx r0 state
always @ (posedge clk or posedge rst)
begin
  if (rst)
    rx_r1 <= 1'b0;
  else if (reset_mode | go_rx_r0 | error_frame)
    rx_r1 <=#Tp 1'b0;
  else if (go_rx_r1)
    rx_r1 <=#Tp 1'b1;
end


// Rx r0 state
always @ (posedge clk or posedge rst)
begin
  if (rst)
    rx_r0 <= 1'b0;
  else if (reset_mode | go_rx_dlc | error_frame)
    rx_r0 <=#Tp 1'b0;
  else if (go_rx_r0)
    rx_r0 <=#Tp 1'b1;
end


// Rx dlc state
always @ (posedge clk or posedge rst)
begin
  if (rst)
    rx_dlc <= 1'b0;
  else if (reset_mode | go_rx_data | go_rx_crc | error_frame)
    rx_dlc <=#Tp 1'b0;
  else if (go_rx_dlc)
    rx_dlc <=#Tp 1'b1;
end


// Rx data state
always @ (posedge clk or posedge rst)
begin
  if (rst)
    rx_data <= 1'b0;
  else if (reset_mode | go_rx_crc | error_frame)
    rx_data <=#Tp 1'b0;
  else if (go_rx_data)
    rx_data <=#Tp 1'b1;
end


// Rx crc state
always @ (posedge clk or posedge rst)
begin
  if (rst)
    rx_crc <= 1'b0;
  else if (reset_mode | go_rx_crc_lim | error_frame)
    rx_crc <=#Tp 1'b0;
  else if (go_rx_crc)
    rx_crc <=#Tp 1'b1;
end


// Rx crc delimiter state
always @ (posedge clk or posedge rst)
begin
  if (rst)
    rx_crc_lim <= 1'b0;
  else if (reset_mode | go_rx_ack | error_frame)
    rx_crc_lim <=#Tp 1'b0;
  else if (go_rx_crc_lim)
    rx_crc_lim <=#Tp 1'b1;
end


// Rx ack state
always @ (posedge clk or posedge rst)
begin
  if (rst)
    rx_ack <= 1'b0;
  else if (reset_mode | go_rx_ack_lim | error_frame)
    rx_ack <=#Tp 1'b0;
  else if (go_rx_ack)
    rx_ack <=#Tp 1'b1;
end


// Rx ack delimiter state
always @ (posedge clk or posedge rst)
begin
  if (rst)
    rx_ack_lim <= 1'b0;
  else if (reset_mode | go_rx_eof | error_frame)
    rx_ack_lim <=#Tp 1'b0;
  else if (go_rx_ack_lim)
    rx_ack_lim <=#Tp 1'b1;
end


// Rx eof state
always @ (posedge clk or posedge rst)
begin
  if (rst)
    rx_eof <= 1'b0;
  else if (go_rx_inter | error_frame | go_overload_frame)
    rx_eof <=#Tp 1'b0;
  else if (go_rx_eof)
    rx_eof <=#Tp 1'b1;
end



// Interframe space
always @ (posedge clk or posedge rst)
begin
  if (rst)
    rx_inter <= 1'b0;
  else if (go_rx_idle | go_rx_id1 | go_overload_frame | go_error_frame)
    rx_inter <=#Tp 1'b0;
  else if (go_rx_inter)
    rx_inter <=#Tp 1'b1;
end


// ID register
always @ (posedge clk or posedge rst)
begin
  if (rst)
    id <= 0;
  else if (sample_point & (rx_id1 | rx_id2) & (~bit_de_stuff))
    id <=#Tp {id[27:0], sampled_bit};
end


// rtr1 bit
always @ (posedge clk or posedge rst)
begin
  if (rst)
    rtr1 <= 0;
  else if (sample_point & rx_rtr1 & (~bit_de_stuff))
    rtr1 <=#Tp sampled_bit;
end


// rtr2 bit
always @ (posedge clk or posedge rst)
begin
  if (rst)
    rtr2 <= 0;
  else if (sample_point & rx_rtr2 & (~bit_de_stuff))
    rtr2 <=#Tp sampled_bit;
end


// ide bit
always @ (posedge clk or posedge rst)
begin
  if (rst)
    ide <= 0;
  else if (sample_point & rx_ide & (~bit_de_stuff))
    ide <=#Tp sampled_bit;
end


// Data length
always @ (posedge clk or posedge rst)
begin
  if (rst)
    data_len <= 0;
  else if (sample_point & rx_dlc & (~bit_de_stuff))
    data_len <=#Tp {data_len[2:0], sampled_bit};
end


// Data
always @ (posedge clk or posedge rst)
begin
  if (rst)
    tmp_data <= 0;
  else if (sample_point & rx_data & (~bit_de_stuff))
    tmp_data <=#Tp {tmp_data[6:0], sampled_bit};
end


always @ (posedge clk or posedge rst)
begin
  if (rst)
    write_data_to_tmp_fifo <= 0;
  else if (sample_point & rx_data & (~bit_de_stuff) & (&bit_cnt[2:0]))
    write_data_to_tmp_fifo <=#Tp 1'b1;
  else
    write_data_to_tmp_fifo <=#Tp 0;
end


always @ (posedge clk or posedge rst)
begin
  if (rst)
    byte_cnt <= 0;
  else if (write_data_to_tmp_fifo)
    byte_cnt <=#Tp byte_cnt + 1;
  else if (sample_point & go_rx_crc_lim)
    byte_cnt <=#Tp 0;
end


always @ (posedge clk)
begin
  if (write_data_to_tmp_fifo)
    tmp_fifo[byte_cnt] <=#Tp tmp_data;
end



// CRC
always @ (posedge clk or posedge rst)
begin
  if (rst)
    crc_in <= 0;
  else if (sample_point & rx_crc & (~bit_de_stuff))
    crc_in <=#Tp {crc_in[13:0], sampled_bit};
end


// bit_cnt
always @ (posedge clk or posedge rst)
begin
  if (rst)
    bit_cnt <= 0;
  else if (go_rx_id1 | go_rx_id2 | go_rx_dlc | go_rx_data | go_rx_crc | 
           go_rx_ack | go_rx_eof | go_rx_inter | go_error_frame | go_overload_frame)
    bit_cnt <=#Tp 0;
  else if (sample_point & (~bit_de_stuff))
    bit_cnt <=#Tp bit_cnt + 1'b1;
end


// eof_cnt
always @ (posedge clk or posedge rst)
begin
  if (rst)
    eof_cnt <= 0;
  else if (sample_point)
    begin
      if (go_rx_inter | go_error_frame | go_overload_frame)
        eof_cnt <=#Tp 0;
      else if (rx_eof)
        eof_cnt <=#Tp eof_cnt + 1'b1;
    end
end


// Enabling bit de-stuffing
always @ (posedge clk or posedge rst)
begin
  if (rst)
    bit_stuff_cnt_en <= 1'b0;
  else if (bit_de_stuff_set)
    bit_stuff_cnt_en <=#Tp 1'b1;
  else if (bit_de_stuff_reset)
    bit_stuff_cnt_en <=#Tp 1'b0;
end


// bit_stuff_cnt
always @ (posedge clk or posedge rst)
begin
  if (rst)
    bit_stuff_cnt <= 1;
  else if (bit_de_stuff_reset)
    bit_stuff_cnt <=#Tp 1;
  else if (sample_point & bit_stuff_cnt_en)
    begin
      if (bit_stuff_cnt == 5)
        bit_stuff_cnt <=#Tp 1;
      else if (sampled_bit == sampled_bit_q)
        bit_stuff_cnt <=#Tp bit_stuff_cnt + 1'b1;
      else
        bit_stuff_cnt <=#Tp 1;
    end
end


// bit_stuff_cnt_tx
always @ (posedge clk or posedge rst)
begin
  if (rst)
    bit_stuff_cnt_tx <= 1;
  else if (bit_de_stuff_reset)
    bit_stuff_cnt_tx <=#Tp 1;
  else if (tx_point_q & bit_stuff_cnt_en)
    begin
      if (bit_stuff_cnt_tx == 5)
        bit_stuff_cnt_tx <=#Tp 1;
      else if (tx == tx_q)
        bit_stuff_cnt_tx <=#Tp bit_stuff_cnt_tx + 1'b1;
      else
        bit_stuff_cnt_tx <=#Tp 1;
    end
end


assign bit_de_stuff = bit_stuff_cnt == 5;
assign bit_de_stuff_tx = bit_stuff_cnt_tx == 5;



// stuff_err
assign stuff_err = sample_point & bit_stuff_cnt_en & bit_de_stuff & (sampled_bit == sampled_bit_q);



// Generating delayed reset_mode signal
always @ (posedge clk)
begin
  reset_mode_q <=#Tp reset_mode;
end



always @ (posedge clk or posedge rst)
begin
  if (rst)
    crc_enable <= 1'b0;
  else if (go_crc_enable)
    crc_enable <=#Tp 1'b1;
  else if (reset_mode | rst_crc_enable)
    crc_enable <=#Tp 1'b0;
end


// CRC error generation
always @ (posedge clk or posedge rst)
begin
  if (rst)
    crc_err <= 1'b0;
  else if (go_rx_ack)
    crc_err <=#Tp crc_in != calculated_crc;
  else if (reset_mode | error_frame_ended)
    crc_err <=#Tp 1'b0;
end


// Conditions for form error
assign form_err = sample_point & ( ((~bit_de_stuff) & rx_ide     &   sampled_bit & (~rtr1)      ) |
                                   (                  rx_crc_lim & (~sampled_bit)               ) |
                                   (                  rx_ack_lim & (~sampled_bit)               ) |
                                   ((eof_cnt < 6)   & rx_eof     & (~sampled_bit) & (~tx_state) ) |
                                   (                & rx_eof     & (~sampled_bit) &   tx_state  )
                                 );


always @ (posedge clk or posedge rst)
begin
  if (rst)
    ack_err_latched <= 1'b0;
  else if (reset_mode | error_frame_ended | go_overload_frame)
    ack_err_latched <=#Tp 1'b0;
  else if (ack_err)
    ack_err_latched <=#Tp 1'b1;
end


always @ (posedge clk or posedge rst)
begin
  if (rst)
    bit_err_latched <= 1'b0;
  else if (reset_mode | error_frame_ended | go_overload_frame)
    bit_err_latched <=#Tp 1'b0;
  else if (bit_err)
    bit_err_latched <=#Tp 1'b1;
end


// Rule 5 (Fault confinement).
always @ (posedge clk or posedge rst)
begin
  if (rst)
    rule5 <= 1'b0;
  else if (reset_mode | error_flag_over)
    rule5 <=#Tp 1'b0;
  else if ((~node_error_passive) & bit_err & (~bit_err_latched) &  (error_frame    & (error_cnt1    < 7) | 
                                                                    overload_frame & (overload_cnt1 < 7) )
          )
    rule5 <=#Tp 1'b1;
end


// Rule 3 exception 1 - first part (Fault confinement).
always @ (posedge clk or posedge rst)
begin
  if (rst)
    rule3_exc1_1 <= 1'b0;
  else if (reset_mode | error_flag_over | rule3_exc1_2)
    rule3_exc1_1 <=#Tp 1'b0;
  else if (transmitter & node_error_passive & ack_err)
    rule3_exc1_1 <=#Tp 1'b1;
end


// Rule 3 exception 1 - second part (Fault confinement).
always @ (posedge clk or posedge rst)
begin
  if (rst)
    rule3_exc1_2 <= 1'b0;
  else if (reset_mode | error_flag_over)
    rule3_exc1_2 <=#Tp 1'b0;
  else if (rule3_exc1_1)
    rule3_exc1_2 <=#Tp 1'b1;
  else if ((error_cnt1 < 7) & sample_point & (~sampled_bit))
    rule3_exc1_2 <=#Tp 1'b0;
end


// Rule 3 exception 2 (Fault confinement).
always @ (posedge clk or posedge rst)
begin
  if (rst)
    rule3_exc2 <= 1'b0;
  else if (reset_mode | error_flag_over)
    rule3_exc2 <=#Tp 1'b0;
  else if (transmitter & stuff_err & arbitration_field & sample_point & tx & (~sampled_bit))
    rule3_exc2 <=#Tp 1'b1;
end



always @ (posedge clk or posedge rst)
begin
  if (rst)
    stuff_err_latched <= 1'b0;
  else if (reset_mode | error_frame_ended | go_overload_frame)
    stuff_err_latched <=#Tp 1'b0;
  else if (stuff_err)
    stuff_err_latched <=#Tp 1'b1;
end



always @ (posedge clk or posedge rst)
begin
  if (rst)
    form_err_latched <= 1'b0;
  else if (reset_mode | error_frame_ended | go_overload_frame)
    form_err_latched <=#Tp 1'b0;
  else if (form_err)
    form_err_latched <=#Tp 1'b1;
end



// Instantiation of the RX CRC module
can_crc i_can_crc_rx 
(
  .clk(clk),
  .data(sampled_bit),
  .enable(crc_enable & sample_point & (~bit_de_stuff)),
  .initialize(rx_eof | go_error_frame | go_overload_frame),
  .crc(calculated_crc)
);




assign no_byte0 = rtr1 | (data_len<1);
assign no_byte1 = rtr1 | (data_len<2);

can_acf i_can_acf
(
  .clk(clk),
  .rst(rst),
  
  .id(id),

  /* Mode register */
  .reset_mode(reset_mode),
  .acceptance_filter_mode(acceptance_filter_mode),

  // Clock Divider register
  .extended_mode(extended_mode),
  
  /* This section is for BASIC and EXTENDED mode */
  /* Acceptance code register */
  .acceptance_code_0(acceptance_code_0),

  /* Acceptance mask register */
  .acceptance_mask_0(acceptance_mask_0),
  /* End: This section is for BASIC and EXTENDED mode */
  
  /* This section is for EXTENDED mode */
  /* Acceptance code register */
  .acceptance_code_1(acceptance_code_1),
  .acceptance_code_2(acceptance_code_2),
  .acceptance_code_3(acceptance_code_3),

  /* Acceptance mask register */
  .acceptance_mask_1(acceptance_mask_1),
  .acceptance_mask_2(acceptance_mask_2),
  .acceptance_mask_3(acceptance_mask_3),
  /* End: This section is for EXTENDED mode */

  .go_rx_crc_lim(go_rx_crc_lim),
  .go_rx_inter(go_rx_inter),
  .go_error_frame(go_error_frame),
  
  .data0(tmp_fifo[0]),
  .data1(tmp_fifo[1]),
  .rtr1(rtr1),
  .rtr2(rtr2),
  .ide(ide),
  .no_byte0(no_byte0),
  .no_byte1(no_byte1),

  .id_ok(id_ok)

);




assign header_len[2:0] = extended_mode ? (ide? (3'h5) : (3'h3)) : 3'h2;
assign storing_header = header_cnt < header_len;
assign limited_data_len_minus1[3:0] = remote_rq? 4'hf : ((data_len < 8)? (data_len -1'b1) : 4'h7);   // - 1 because counter counts from 0
assign reset_wr_fifo = (data_cnt == (limited_data_len_minus1 + header_len)) | reset_mode;

assign err = form_err | stuff_err | bit_err | ack_err | form_err_latched | stuff_err_latched | bit_err_latched | ack_err_latched | crc_err;



// Write enable signal for 64-byte rx fifo
always @ (posedge clk or posedge rst)
begin
  if (rst)
    wr_fifo <= 1'b0;
  else if (reset_wr_fifo)
    wr_fifo <=#Tp 1'b0;
//  else if (go_rx_inter & id_ok & (~error_frame_ended))                // FIX ME !!! Look following line
  else if (go_rx_inter & id_ok & (~error_frame_ended) & (~tx_state))    // FIX ME !!! This line is the correct one. The above line is for easier debugging only.
    wr_fifo <=#Tp 1'b1;
end


// Header counter. Header length depends on the mode of operation and frame format.
always @ (posedge clk or posedge rst)
begin
  if (rst)
    header_cnt <= 0;
  else if (reset_wr_fifo)
    header_cnt <=#Tp 0;
  else if (wr_fifo & storing_header)
    header_cnt <=#Tp header_cnt + 1;
end


// Data counter. Length of the data is limited to 8 bytes.
always @ (posedge clk or posedge rst)
begin
  if (rst)
    data_cnt <= 0;
  else if (reset_wr_fifo)
    data_cnt <=#Tp 0;
  else if (wr_fifo)
    data_cnt <=#Tp data_cnt + 1;
end


// Multiplexing data that is stored to 64-byte fifo depends on the mode of operation and frame format
always @ (extended_mode or ide or data_cnt or header_cnt or  header_len or 
          storing_header or id or rtr1 or rtr2 or data_len or
          tmp_fifo[0] or tmp_fifo[2] or tmp_fifo[4] or tmp_fifo[6] or 
          tmp_fifo[1] or tmp_fifo[3] or tmp_fifo[5] or tmp_fifo[7])
begin
  if (storing_header)
    begin
      if (extended_mode)      // extended mode
        begin
          if (ide)              // extended format
            begin
              case (header_cnt) // synthesis parallel_case 
                3'h0  : data_for_fifo <= {1'b1, rtr2, 2'h0, data_len};
                3'h1  : data_for_fifo <= id[28:21];
                3'h2  : data_for_fifo <= id[20:13];
                3'h3  : data_for_fifo <= id[12:5];
                3'h4  : data_for_fifo <= {id[4:0], 3'h0};
                default: data_for_fifo <= 0;
              endcase
            end
          else                  // standard format
            begin
              case (header_cnt) // synthesis parallel_case 
                3'h0  : data_for_fifo <= {1'b0, rtr1, 2'h0, data_len};
                3'h1  : data_for_fifo <= id[10:3];
                3'h2  : data_for_fifo <= {id[2:0], 5'h0};
                default: data_for_fifo <= 0;
              endcase
            end
        end
      else                    // normal mode
        begin
          case (header_cnt) // synthesis parallel_case 
            3'h0  : data_for_fifo <= id[10:3];
            3'h1  : data_for_fifo <= {id[2:0], rtr1, data_len};
            default: data_for_fifo <= 0;
          endcase
        end
    end
  else
    data_for_fifo <= tmp_fifo[data_cnt-header_len];
end




// Instantiation of the RX fifo module
can_fifo i_can_fifo
( 
  .clk(clk),
  .rst(rst),

  .wr(wr_fifo),

  .data_in(data_for_fifo),
  .addr(addr),
  .data_out(data_out),

  .reset_mode(reset_mode),
  .release_buffer(release_buffer),
  .extended_mode(extended_mode)

  
);


// Transmitting error frame.
always @ (posedge clk or posedge rst)
begin
  if (rst)
    error_frame <= 1'b0;
  else if (reset_mode | error_frame_ended | go_overload_frame)
    error_frame <=#Tp 1'b0;
  else if (go_error_frame)
    error_frame <=#Tp 1'b1;
end


always @ (posedge clk)
begin
  if (sample_point)
    error_frame_q <=#Tp error_frame;
end


always @ (posedge clk)
begin
    go_error_frame_q <=#Tp go_error_frame;
end


always @ (posedge clk or posedge rst)
begin
  if (rst)
    error_cnt1 <= 1'b0;
  else if (reset_mode | error_frame_ended | go_error_frame | go_overload_frame)
    error_cnt1 <=#Tp 1'b0;
  else if (error_frame & tx_point & (error_cnt1 < 7))
    error_cnt1 <=#Tp error_cnt1 + 1'b1;
end



assign error_flag_over = ((~node_error_passive) & sample_point & (error_cnt1 == 7) | node_error_passive  & sample_point & (passive_cnt == 5)) & (~enable_error_cnt2);


always @ (posedge clk or posedge rst)
begin
  if (rst)
    error_flag_over_blocked <= 1'b0;
  else if (reset_mode | error_frame_ended | go_error_frame | go_overload_frame)
    error_flag_over_blocked <=#Tp 1'b0;
  else if (error_flag_over)
    error_flag_over_blocked <=#Tp 1'b1;
end



always @ (posedge clk or posedge rst)
begin
  if (rst)
    enable_error_cnt2 <= 1'b0;
  else if (reset_mode | error_frame_ended | go_error_frame | go_overload_frame)
    enable_error_cnt2 <=#Tp 1'b0;
  else if (error_frame & (error_flag_over & sampled_bit))
    enable_error_cnt2 <=#Tp 1'b1;
end


always @ (posedge clk or posedge rst)
begin
  if (rst)
    error_cnt2 <= 0;
  else if (reset_mode | error_frame_ended | go_error_frame | go_overload_frame)
    error_cnt2 <=#Tp 0;
  else if (enable_error_cnt2 & tx_point)
    error_cnt2 <=#Tp error_cnt2 + 1'b1;
end


always @ (posedge clk or posedge rst)
begin
  if (rst)
    delayed_dominant_cnt <= 0;
  else if (reset_mode | enable_error_cnt2 | go_error_frame | enable_overload_cnt2 | go_overload_frame)
    delayed_dominant_cnt <=#Tp 0;
  else if (sample_point & (~sampled_bit) & ((error_cnt1 == 7) | (overload_cnt1 == 7)))
    delayed_dominant_cnt <=#Tp delayed_dominant_cnt + 1'b1;
end


// passive_cnt
always @ (posedge clk or posedge rst)
begin
  if (rst)
    passive_cnt <= 0;
  else if (reset_mode | error_frame_ended | go_error_frame | go_overload_frame)
    passive_cnt <=#Tp 0;
  else if (sample_point & (passive_cnt < 5))
    begin
      if (error_frame_q & (~enable_error_cnt2) & (sampled_bit == sampled_bit_q))
        passive_cnt <=#Tp passive_cnt + 1'b1;
      else
        passive_cnt <=#Tp 0;
    end
end



// Transmitting overload frame.
always @ (posedge clk or posedge rst)
begin
  if (rst)
    overload_frame <= 1'b0;
  else if (reset_mode | overload_frame_ended | go_error_frame)
    overload_frame <=#Tp 1'b0;
  else if (go_overload_frame)
    overload_frame <=#Tp 1'b1;
end


always @ (posedge clk or posedge rst)
begin
  if (rst)
    overload_cnt1 <= 1'b0;
  else if (reset_mode | overload_frame_ended | go_error_frame | go_overload_frame)
    overload_cnt1 <=#Tp 1'b0;
  else if (overload_frame & tx_point & (overload_cnt1 < 7))
    overload_cnt1 <=#Tp overload_cnt1 + 1'b1;
end


assign overload_flag_over = sample_point & (overload_cnt1 == 7) & (~enable_overload_cnt2);


always @ (posedge clk or posedge rst)
begin
  if (rst)
    enable_overload_cnt2 <= 1'b0;
  else if (reset_mode | overload_frame_ended | go_error_frame | go_overload_frame)
    enable_overload_cnt2 <=#Tp 1'b0;
  else if (overload_frame & (overload_flag_over & sampled_bit))
    enable_overload_cnt2 <=#Tp 1'b1;
end


always @ (posedge clk or posedge rst)
begin
  if (rst)
    overload_cnt2 <= 0;
  else if (reset_mode | overload_frame_ended | go_error_frame | go_overload_frame)
    overload_cnt2 <=#Tp 0;
  else if (enable_overload_cnt2 & tx_point)
    overload_cnt2 <=#Tp overload_cnt2 + 1'b1;
end


always @ (posedge clk or posedge rst)
begin
  if (rst)
    overload_frame_blocked <= 0;
  else if (reset_mode | go_error_frame | go_rx_id1)
    overload_frame_blocked <=#Tp 0;
  else if (go_overload_frame & overload_frame)            // This is a second sequential overload
    overload_frame_blocked <=#Tp 1'b1;
end


assign send_ack = (~tx_state) & rx_ack & (~err);


always @ (posedge clk or posedge rst)
begin
  if (rst)
    tx <= 1'b1;
  else if (reset_mode)                                                          // Reset
    tx <=#Tp 1'b1;
  else if (tx_point)
    begin
      if (tx_state)                                                             // Transmitting message
        tx <=#Tp ((~bit_de_stuff_tx) & tx_bit) | (bit_de_stuff_tx & (~tx_q));
      else if (send_ack)                                                        // Acknowledge
        tx <=#Tp 1'b0;
      else if (overload_frame)                                                  // Transmitting overload frame
        begin
          if (overload_cnt1 < 6)
            tx <=#Tp 1'b0;
          else
            tx <=#Tp 1'b1;
        end
      else if (error_frame)                                                     // Transmitting error frame
        begin
          if (error_cnt1 < 6)
            begin
              if (node_error_passive)
                tx <=#Tp 1'b1;
              else
                tx <=#Tp 1'b0;
            end
          else
            tx <=#Tp 1'b1;
        end
      else
        tx <=#Tp 1'b1;
    end
end


always @ (posedge clk)
begin
  if (tx_point)
    tx_q <=#Tp tx;
end


/* Delayed tx point */
always @ (posedge clk)
begin
  tx_point_q <=#Tp tx_point;
end


/* Changing bit order from [7:0] to [0:7] */
can_ibo i_ibo_tx_data_0  (.di(tx_data_0),  .do(r_tx_data_0));
can_ibo i_ibo_tx_data_1  (.di(tx_data_1),  .do(r_tx_data_1));
can_ibo i_ibo_tx_data_2  (.di(tx_data_2),  .do(r_tx_data_2));
can_ibo i_ibo_tx_data_3  (.di(tx_data_3),  .do(r_tx_data_3));
can_ibo i_ibo_tx_data_4  (.di(tx_data_4),  .do(r_tx_data_4));
can_ibo i_ibo_tx_data_5  (.di(tx_data_5),  .do(r_tx_data_5));
can_ibo i_ibo_tx_data_6  (.di(tx_data_6),  .do(r_tx_data_6));
can_ibo i_ibo_tx_data_7  (.di(tx_data_7),  .do(r_tx_data_7));
can_ibo i_ibo_tx_data_8  (.di(tx_data_8),  .do(r_tx_data_8));
can_ibo i_ibo_tx_data_9  (.di(tx_data_9),  .do(r_tx_data_9));
can_ibo i_ibo_tx_data_10 (.di(tx_data_10), .do(r_tx_data_10));
can_ibo i_ibo_tx_data_11 (.di(tx_data_11), .do(r_tx_data_11));
can_ibo i_ibo_tx_data_12 (.di(tx_data_12), .do(r_tx_data_12));

/* Changing bit order from [14:0] to [0:14] */
can_ibo i_calculated_crc0 (.di(calculated_crc[14:7]), .do(r_calculated_crc[7:0]));
can_ibo i_calculated_crc1 (.di({calculated_crc[6:0], 1'b0}), .do(r_calculated_crc[15:8]));


assign basic_chain = {r_tx_data_1[7:4], 2'h0, r_tx_data_1[3:0], r_tx_data_0[7:0], 1'b0};
assign basic_chain_data = {r_tx_data_9, r_tx_data_8, r_tx_data_7, r_tx_data_6, r_tx_data_5, r_tx_data_4, r_tx_data_3, r_tx_data_2};
assign extended_chain_std = {r_tx_data_0[7:4], 2'h0, r_tx_data_0[1], r_tx_data_2[2:0], r_tx_data_1[7:0], 1'b0};
assign extended_chain_ext = {r_tx_data_0[7:4], 2'h0, r_tx_data_0[1], r_tx_data_4[4:0], r_tx_data_3[7:0], r_tx_data_2[7:3], 1'b1, 1'b1, r_tx_data_2[2:0], r_tx_data_1[7:0], 1'b0};
assign extended_chain_data = {r_tx_data_12, r_tx_data_11, r_tx_data_10, r_tx_data_9, r_tx_data_8, r_tx_data_7, r_tx_data_6, r_tx_data_5};

always @ (extended_mode or rx_data or tx_pointer or extended_chain_data or rx_crc or r_calculated_crc or
          r_tx_data_0   or extended_chain_ext or extended_chain_std or basic_chain_data or basic_chain or
          finish_msg)
begin
  if (extended_mode)
    begin
      if (rx_data)  // data stage
        tx_bit = extended_chain_data[tx_pointer];
      else if (rx_crc)
        tx_bit = r_calculated_crc[tx_pointer];
      else if (finish_msg)
        tx_bit = 1'b1;
      else
        begin
          if (r_tx_data_0[0])    // Extended frame
            tx_bit = extended_chain_ext[tx_pointer];
          else
            tx_bit = extended_chain_std[tx_pointer];
        end
    end
  else  // Basic mode
    begin
      if (rx_data)  // data stage
        tx_bit = basic_chain_data[tx_pointer];
      else if (rx_crc)
        tx_bit = r_calculated_crc[tx_pointer];
      else if (finish_msg)
        tx_bit = 1'b1;
      else
        tx_bit = basic_chain[tx_pointer];
    end
end


assign rst_tx_pointer = ((~bit_de_stuff_tx) & tx_point & (~rx_data) &   extended_mode  & tx_pointer == 38                      ) |   // arbitration + control for extended format
                        ((~bit_de_stuff_tx) & tx_point & (~rx_data) & (~extended_mode) & tx_pointer == 18                      ) |   // arbitration + control for standard format
                        ((~bit_de_stuff_tx) & tx_point &   rx_data  &   extended_mode  & tx_pointer == (8 * tx_data_0[3:0] - 1)) |   // data
                        ((~bit_de_stuff_tx) & tx_point &   rx_data  & (~extended_mode) & tx_pointer == (8 * tx_data_1[3:0] - 1)) |   // data
                        (                     tx_point &   rx_crc_lim                                                          ) |   // crc
                        (go_rx_idle                                                                                            ) |   // at the end
                        (reset_mode                                                                                            ) |
                        (overload_frame                                                                                        ) |
                        (error_frame                                                                                           ) ;

always @ (posedge clk or posedge rst)
begin
  if (rst)
    tx_pointer <= 'h0;
  else if (rst_tx_pointer)
    tx_pointer <=#Tp 'h0;
  else if (go_early_tx | (tx_point & tx_state & (~bit_de_stuff_tx)))
    tx_pointer <=#Tp tx_pointer + 1'b1;
end


assign tx_successful = transmitter & go_rx_inter & (~error_frame_ended) & (~overload_frame_ended) & (~priority_lost);


always @ (posedge clk or posedge rst)
begin
  if (rst)
    need_to_tx <= 1'b0;
  else if (tx_successful | node_bus_off)
    need_to_tx <=#Tp 1'h0;
  else if (tx_request)
    need_to_tx <=#Tp 1'b1;
end



assign go_early_tx = need_to_tx & (~tx_state) & (~suspend) & sample_point & (~sampled_bit) & (rx_idle | last_bit_of_inter);
assign go_tx       = need_to_tx & (~tx_state) & (~suspend) & (go_early_tx | rx_idle);


// Tx state
always @ (posedge clk or posedge rst)
begin
  if (rst)
    tx_state <= 1'b0;
  else if (go_rx_inter | error_frame | priority_lost)
    tx_state <=#Tp 1'b0;
  else if (go_tx)
    tx_state <=#Tp 1'b1;
end



// Node is a transmitter
always @ (posedge clk or posedge rst)
begin
  if (rst)
    transmitter <= 1'b0;
  else if (go_tx)
    transmitter <=#Tp 1'b1;
  else if (go_rx_inter)
    transmitter <=#Tp 1'b0;
end



// Signal "transmitting" signals that the core is a transmitting (message, error frame or overload frame). No synchronization is done meanwhile.
// Node might be both transmitter or receiver (sending error or overload frame)
always @ (posedge clk or posedge rst)
begin
  if (rst)
    transmitting <= 1'b0;
  else if (go_error_frame | go_overload_frame | go_tx)
    transmitting <=#Tp 1'b1;
  else if (reset_mode | go_rx_idle | (go_rx_id1 & (~tx_state)) | (priority_lost & tx_state))
    transmitting <=#Tp 1'b0;
end


always @ (posedge clk or posedge rst)
begin
  if (rst)
    suspend <= 0;
  else if (reset_mode | (sample_point & (susp_cnt == 7)))
    suspend <=#Tp 0;
  else if (go_rx_inter & transmitter & node_error_passive)
    suspend <=#Tp 1'b1;
end


always @ (posedge clk or posedge rst)
begin
  if (rst)
    susp_cnt_en <= 0;
  else if (reset_mode | (sample_point & (susp_cnt == 7)))
    susp_cnt_en <=#Tp 0;
  else if (suspend & sample_point & last_bit_of_inter)
    susp_cnt_en <=#Tp 1'b1;
end


always @ (posedge clk or posedge rst)
begin
  if (rst)
    susp_cnt <= 0;
  else if (reset_mode | (sample_point & (susp_cnt == 7)))
    susp_cnt <=#Tp 0;
  else if (susp_cnt_en & sample_point)
    susp_cnt <=#Tp susp_cnt + 1'b1;
end




always @ (posedge clk or posedge rst)
begin
  if (rst)
    finish_msg <= 1'b0;
  else if (go_rx_idle | go_rx_id1 | error_frame | reset_mode)
    finish_msg <=#Tp 1'b0;
  else if (go_rx_crc_lim)
    finish_msg <=#Tp 1'b1;
end


always @ (posedge clk or posedge rst)
begin
  if (rst)
    priority_lost <= 1'b0;
  else if (go_rx_idle | error_frame | reset_mode)
    priority_lost <=#Tp 1'b0;
  else if (tx_state & sample_point & tx & arbitration_field)
    priority_lost <=#Tp (~sampled_bit);
end



always @ (posedge clk or posedge rst)
begin
  if (rst)
    rx_err_cnt <= 'h0;
  else if (reset_mode)
    rx_err_cnt <=#Tp 'h0;
  else
    begin
      if ((~transmitter) & go_rx_ack_lim & (~err) & (rx_err_cnt > 0))
        begin
          if (rx_err_cnt > 127)
            rx_err_cnt <=#Tp 127;
          else
            rx_err_cnt <=#Tp rx_err_cnt - 1'b1;
        end
      else if ((rx_err_cnt < 1023) & (~transmitter))
        begin
          if (go_error_frame_q & (~rule5))                                                                          // 1  (rule 5 is just the opposite then rule 1 exception
            rx_err_cnt <=#Tp rx_err_cnt + 1'b1;
          else if ( (error_frame & sample_point & (~sampled_bit) & (error_cnt1 == 7) & (~rx_err_cnt_blocked)  ) |   // 2
                    (go_error_frame_q & rule5                                                                 ) |   // 5
                    (error_frame & sample_point & (~sampled_bit) & (delayed_dominant_cnt == 7)                )     // 6
                  )
            rx_err_cnt <=#Tp rx_err_cnt + 4'h8;
        end
    end
end


always @ (posedge clk or posedge rst)
begin
  if (rst)
    tx_err_cnt <= 'h0;
  else if (reset_mode | node_bus_off)
    tx_err_cnt <=#Tp 'h0;
  else
    begin
      if ((tx_err_cnt > 0) & tx_successful)
        tx_err_cnt <=#Tp tx_err_cnt - 1'h1;
      else if ((tx_err_cnt < 1023) & transmitter)
        begin
          if ( (sample_point & (~sampled_bit) & (delayed_dominant_cnt == 7)                     ) |       // 6
               (error_flag_over & (~error_flag_over_blocked) & rule5                            ) |       // 4  (rule 5 is the same as rule 4)
               (error_flag_over & (~error_flag_over_blocked) & (~rule3_exc1_2) & (~rule3_exc2)  )         // 3
             )
            tx_err_cnt <=#Tp tx_err_cnt + 4'h8;
        end
    end
end



always @ (posedge clk or posedge rst)
begin
  if (rst)
    rx_err_cnt_blocked <= 1'b0;
  else if (reset_mode | error_frame_ended)
    rx_err_cnt_blocked <=#Tp 1'b0;
  else if (sample_point & (error_cnt1 == 7))
    rx_err_cnt_blocked <=#Tp 1'b1;
end



always @ (posedge clk or posedge rst)
begin
  if (rst)
    node_error_passive <= 1'b0;
  else if (reset_mode | node_bus_off | ((rx_err_cnt < 128) & (tx_err_cnt < 128) & error_frame_ended))
    node_error_passive <=#Tp 1'b0;
  else if (((rx_err_cnt >= 128) | (tx_err_cnt >= 128)) & error_frame_ended)
    node_error_passive <=#Tp 1'b1;
end


always @ (posedge clk or posedge rst)
begin
  if (rst)
    node_bus_off <= 1'b0;
  else if (reset_mode | ((rx_err_cnt == 0) & (tx_err_cnt == 0) & recessive_cnt_ok))
    node_bus_off <=#Tp 1'b0;
  else if (tx_err_cnt >= 256)
    node_bus_off <=#Tp 1'b1;
end


always @ (posedge clk or posedge rst)
begin
  if (rst)
    recessive_cnt <= 1'b0;
  else if (sample_point)
    begin
      if (node_bus_off & sampled_bit)
        recessive_cnt <=#Tp recessive_cnt + 1'b1;
      else
        recessive_cnt <=#Tp 0;
    end
end


assign recessive_cnt_ok = recessive_cnt == 128 * 11;


assign tx_oen = node_bus_off;


endmodule
