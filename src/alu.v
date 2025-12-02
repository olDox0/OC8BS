// Arquivo: src/alu.v
// Descrição: Contém todos os módulos da Unidade Lógica e Aritmética.

module half_adder(
  input  logic a,
  input  logic b,
  output logic sum,
  output logic carry_out
);
  assign sum       = a ^ b;
  assign carry_out = a & b;
endmodule

module full_adder(
  input  logic a,
  input  logic b,
  input  logic carry_in,
  output logic sum,
  output logic carry_out
);
  logic p_sum, p_c1, p_c2;
  half_adder ha1 (.a(a), .b(b), .sum(p_sum), .carry_out(p_c1));
  half_adder ha2 (.a(p_sum), .b(carry_in), .sum(sum), .carry_out(p_c2));
  assign carry_out = p_c1 | p_c2;
endmodule

module alu_adder_8bit(
  input      logic [7:0] a,
  input      logic [7:0] b,
  input      logic       subtract,
  output     logic [7:0] result,
  output     logic       carry_out
);
  logic c0, c1, c2, c3, c4, c5, c6;
  logic [7:0] b_mod = b ^ {8{subtract}};
  full_adder fa0 (.a(a[0]),.b(b_mod[0]),.carry_in(subtract),.sum(result[0]),.carry_out(c0));
  full_adder fa1 (.a(a[1]),.b(b_mod[1]),.carry_in(c0),.sum(result[1]),.carry_out(c1));
  full_adder fa2 (.a(a[2]),.b(b_mod[2]),.carry_in(c1),.sum(result[2]),.carry_out(c2));
  full_adder fa3 (.a(a[3]),.b(b_mod[3]),.carry_in(c2),.sum(result[3]),.carry_out(c3));
  full_adder fa4 (.a(a[4]),.b(b_mod[4]),.carry_in(c3),.sum(result[4]),.carry_out(c4));
  full_adder fa5 (.a(a[5]),.b(b_mod[5]),.carry_in(c4),.sum(result[5]),.carry_out(c5));
  full_adder fa6 (.a(a[6]),.b(b_mod[6]),.carry_in(c5),.sum(result[6]),.carry_out(c6));
  full_adder fa7 (.a(a[7]),.b(b_mod[7]),.carry_in(c6),.sum(result[7]),.carry_out(carry_out));
endmodule

module alu_8bit(
  input      logic [7:0] a,
  input      logic [7:0] b,
  input      logic [2:0] opcode,
  output     logic [7:0] result,
  output     logic       flag_z,
  output     logic       flag_c
);
  logic [7:0] add_res, and_res, or_res, eor_res;
  logic       add_cout;
  alu_adder_8bit add_sub (.a(a),.b(b),.subtract(opcode==3'b001),.result(add_res),.carry_out(add_cout));
  assign and_res = a & b;
  assign or_res  = a | b;
  assign eor_res = a ^ b;
  always_comb begin
    case (opcode)
      3'b000: result = add_res;
      3'b001: result = add_res;
      3'b010: result = and_res;
      3'b011: result = or_res;
      3'b100: result = eor_res;
      default: result = 8'hXX;
    endcase
  end
  assign flag_z = ~|result;
  assign flag_c = (opcode < 3'b010) ? add_cout : 1'b0;
endmodule