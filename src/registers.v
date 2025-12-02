module register_8bit(input clk, input reset, input load_en, input [7:0] data_in, output logic [7:0] data_out);
  always_ff @(posedge clk or posedge reset) if (reset) data_out <= 8'h00; else if (load_en) data_out <= data_in;
endmodule

module register_16bit(input clk, input reset, input load_en, input [15:0] data_in, output logic [15:0] data_out);
  always_ff @(posedge clk or posedge reset) if (reset) data_out <= 16'h0000; else if (load_en) data_out <= data_in;
endmodule