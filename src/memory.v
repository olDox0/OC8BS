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
