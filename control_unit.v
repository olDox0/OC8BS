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
