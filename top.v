
module top(input clk, input reset, output [7:0] accumulator_out, output [15:0] pc_out);
  wire [15:0] address_bus;
  wire [7:0] data_bus, unused_data_out; // CORRIGIDO
  wire [2:0] alu_opcode;
  wire sel_a_from_x, sel_b_from_y, reg_a_load, reg_x_load, reg_y_load;
  wire reg_a_output_en, pc_inc, pc_load, sp_load;
  reg [7:0] instruction_register;

  always_ff @(posedge clk or posedge reset) if (reset) instruction_register <= 8'h00; else instruction_register <= data_bus;
  
  program_rom rom (.addr(address_bus), .data(data_bus));
  instruction_decoder decoder (.opcode(instruction_register), .alu_opcode(alu_opcode), .sel_a_from_x(sel_a_from_x), .sel_b_from_y(sel_b_from_y), .reg_a_load(reg_a_load), .reg_x_load(reg_x_load), .reg_y_load(reg_y_load), .reg_a_output_en(reg_a_output_en), .pc_inc(pc_inc), .pc_load(pc_load), .sp_load(sp_load));
  vaa8_cpu cpu (.clk(clk), .reset(reset), .data_bus_in(data_bus), .data_bus_out(unused_data_out), .address_bus_out(address_bus), .alu_opcode(alu_opcode), .sel_a_from_x(sel_a_from_x), .sel_b_from_y(sel_b_from_y), .reg_a_load(reg_a_load), .reg_x_load(reg_x_load), .reg_y_load(reg_y_load), .reg_a_output_en(reg_a_output_en), .pc_load(pc_load), .pc_inc(pc_inc), .sp_load(sp_load), .reg_a_out_debug(accumulator_out), .pc_out_debug(pc_out));
endmodule