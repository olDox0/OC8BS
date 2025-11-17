// Diretorio/VAA8/vaa8_final_test.v
// Versão do Projeto: 2.0 (VAA8)
// Versão do Arquivo: 6.0 - Sistema Integrado FINAL

// =============================================================================
// == MÓDULOS DE BASE (Validados e Finalizados)
// =============================================================================

module half_adder(input logic a, input logic b, output logic sum, output logic carry_out);
  assign sum = a ^ b; assign carry_out = a & b;
endmodule

module full_adder(input logic a, input logic b, input logic carry_in, output logic sum, output logic carry_out);
  logic p_sum, p_c1, p_c2;
  half_adder ha1 (.a(a), .b(b), .sum(p_sum), .carry_out(p_c1));
  half_adder ha2 (.a(p_sum), .b(carry_in), .sum(sum), .carry_out(p_c2));
  assign carry_out = p_c1 | p_c2;
endmodule

module alu_adder_8bit(input [7:0] a, input [7:0] b, input subtract, output [7:0] result, output carry_out);
  logic c0, c1, c2, c3, c4, c5, c6; logic [7:0] b_mod = b ^ {8{subtract}};
  full_adder fa0 (.a(a[0]),.b(b_mod[0]),.carry_in(subtract),.sum(result[0]),.carry_out(c0));
  full_adder fa1 (.a(a[1]),.b(b_mod[1]),.carry_in(c0),.sum(result[1]),.carry_out(c1));
  full_adder fa2 (.a(a[2]),.b(b_mod[2]),.carry_in(c1),.sum(result[2]),.carry_out(c2));
  full_adder fa3 (.a(a[3]),.b(b_mod[3]),.carry_in(c2),.sum(result[3]),.carry_out(c3));
  full_adder fa4 (.a(a[4]),.b(b_mod[4]),.carry_in(c3),.sum(result[4]),.carry_out(c4));
  full_adder fa5 (.a(a[5]),.b(b_mod[5]),.carry_in(c4),.sum(result[5]),.carry_out(c5));
  full_adder fa6 (.a(a[6]),.b(b_mod[6]),.carry_in(c5),.sum(result[6]),.carry_out(c6));
  full_adder fa7 (.a(a[7]),.b(b_mod[7]),.carry_in(c6),.sum(result[7]),.carry_out(carry_out));
endmodule

module alu_8bit(input [7:0] a, input [7:0] b, input [2:0] opcode, output [7:0] result, output flag_z, output flag_c);
  logic [7:0] add_res, and_res, or_res, eor_res; logic add_cout;
  alu_adder_8bit add_sub (.a(a),.b(b),.subtract(opcode==3'b001),.result(add_res),.carry_out(add_cout));
  assign and_res = a & b; assign or_res = a | b; assign eor_res = a ^ b;
  always_comb case (opcode)
    3'b000: result = add_res; 3'b001: result = add_res; 3'b010: result = and_res;
    3'b011: result = or_res;  3'b100: result = eor_res; default: result = 8'hXX;
  endcase
  assign flag_z = ~|result; assign flag_c = (opcode < 3'b010) ? add_cout : 1'b0;
endmodule

module register_8bit(input clk, input reset, input load_en, input [7:0] data_in, output logic [7:0] data_out);
  always_ff @(posedge clk or posedge reset) if (reset) data_out <= 8'h00; else if (load_en) data_out <= data_in;
endmodule

module register_16bit(input clk, input reset, input load_en, input [15:0] data_in, output logic [15:0] data_out);
  always_ff @(posedge clk or posedge reset) if (reset) data_out <= 16'h0000; else if (load_en) data_out <= data_in;
endmodule

// =============================================================================
// == MÓDULOS DA UCP
// =============================================================================

module instruction_decoder(input [7:0] opcode, output logic [2:0] alu_opcode, output logic sel_a_from_x, output logic sel_b_from_y, output logic reg_a_load, output logic reg_x_load, output logic reg_y_load, output logic reg_a_output_en, output logic pc_inc, output logic pc_load, output logic sp_load);
  always_comb begin
    {alu_opcode,sel_a_from_x,sel_b_from_y,reg_a_load,reg_x_load,reg_y_load,reg_a_output_en,pc_inc,pc_load,sp_load} = 12'b000_0_0_0_0_0_0_1_0_0;
    case (opcode)
      8'hA9: {sel_b_from_y, reg_a_load} = 2'b01;
      8'h01: {reg_a_load} = 1'b1;
      8'h4C: {pc_inc, pc_load} = 2'b01;
      default: ; // CORRIGIDO
    endcase
  end
endmodule

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

// =============================================================================
// == MÓDULOS DE MEMÓRIA
// =============================================================================

module program_rom (input [15:0] addr, output [7:0] data);
  logic [7:0] rom_data[0:255];
  initial begin
    rom_data[0] = 8'hA9; // LDA #$00
    rom_data[1] = 8'h00; // Valor 0
    rom_data[2] = 8'h01; // ADD #$01
    rom_data[3] = 8'h01; // Valor 1
    rom_data[4] = 8'h4C; // JMP $0002
    rom_data[5] = 8'h02; // Endereço baixo
    rom_data[6] = 8'h00; // Endereço alto
  end
  assign data = rom_data[addr[7:0]];
endmodule

// =============================================================================
// == MÓDULO DE TOPO: O COMPUTADOR VAA8 COMPLETO
// =============================================================================

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