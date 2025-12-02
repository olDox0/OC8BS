module vaa8_cpu(input clk, input reset, input [7:0] data_bus_in, output [7:0] data_bus_out, output [15:0] address_bus_out, input [2:0] alu_opcode, input sel_a_from_x, input sel_b_from_y, input reg_a_load, input reg_x_load, input reg_y_load, input reg_a_output_en, input pc_load, input pc_inc, input sp_load, output [7:0] reg_a_out_debug, output [15:0] pc_out_debug);
  logic [7:0] bus_a, bus_b, bus_w, reg_x_out, reg_y_out;
  logic [15:0] sp_out, pc_in; logic flag_z, flag_c;
  register_8bit acc_a (.clk(clk),.reset(reset),.load_en(reg_a_load),.data_in(bus_w),.data_out(reg_a_out_debug));
  register_8bit idx_x (.clk(clk),.reset(reset),.load_en(reg_x_load),.data_in(bus_w),.data_out(reg_x_out));
  register_8bit idx_y (.clk(clk),.reset(reset),.load_en(reg_y_load),.data_in(bus_w),.data_out(reg_y_out));
  register_16bit prog_counter (.clk(clk),.reset(reset),.load_en(pc_load||pc_inc),.data_in(pc_load?{bus_a,bus_b}:pc_out_debug+1),.data_out(pc_out_debug));
  register_16bit stack_pointer(.clk(clk),.reset(reset),.load_en(sp_load),.data_in({reg_a_out_debug,reg_x_out}),.data_out(sp_out));
  assign address_bus_out = pc_out_debug;
  assign bus_a = (sel_a_from_x) ? reg_x_out : reg_a_out_debug;
  assign bus_b = (sel_b_from_y) ? reg_y_out : data_bus_in;
  alu_8bit the_alu (.a(bus_a),.b(bus_b),.opcode(alu_opcode),.result(bus_w),.flag_z(flag_z),.flag_c(flag_c));
  assign data_bus_out = (reg_a_output_en) ? reg_a_out_debug : 8'hzz;
endmodule