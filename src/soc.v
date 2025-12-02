// Arquivo: src/soc.v
// Descrição: Contém os módulos de nível de sistema (SoC).

//==============================================================================
// MÓDULO DECODIFICADOR DE ENDEREÇOS
//==============================================================================
// 2025/11/24 - Ver2.0, Fnc1.0 - Criação inicial para o mapa de memória v0.1.
module address_decoder(
  input  logic [15:0] addr,
  output logic        cs_ram, // Chip Select para a RAM
  output logic        cs_pio, // Chip Select para a PIO
  output logic        cs_rom  // Chip Select para a ROM
);

  // A RAM é selecionada se o bit 15 for 0 (0x0000 - 0x7FFF).
  assign cs_ram = (addr[15] == 0);
  
  // A PIO é selecionada se os 8 bits superiores forem 0xFE (0xFE00 - 0xFEFF).
  assign cs_pio = (addr[15:8] == 8'hFE);
  
  // A ROM é selecionada se os 8 bits superiores forem 0xFF (0xFF00 - 0xFFFF).
  assign cs_rom = (addr[15:8] == 8'hFF);

endmodule

//==============================================================================
// MÓDULO INTERFACE DE E/S PARALELA (PIO) v1.2
//==============================================================================
// 2025/11/24 - Ver2.0, Fnc1.2 - Design final e verificado.
module pio_8bit (
    input  logic         clk,
    input  logic         reset,
    input  logic         chip_select,
    input  logic         write_en,
    input  logic         addr_sel_port,
    input  logic [7:0]   data_in,
    output logic [7:0]   data_out,
    input  logic [7:0]   pins_in,
    output logic [7:0]   pins_out
);
    logic [7:0] ddr_reg;
    logic [7:0] port_reg;
    
    wire ddr_load_en  = chip_select && write_en && !addr_sel_port;
    wire port_load_en = chip_select && write_en &&  addr_sel_port;

    register_8bit ddr_instance ( .clk(clk), .reset(reset), .load_en(ddr_load_en), .data_in(data_in), .data_out(ddr_reg) );
    register_8bit port_instance( .clk(clk), .reset(reset), .load_en(port_load_en), .data_in(data_in), .data_out(port_reg));
    
    assign pins_out = port_reg & ddr_reg;
    assign data_out = (chip_select && !write_en) ? (addr_sel_port ? (pins_in & ~ddr_reg) | (port_reg & ddr_reg) : ddr_reg) : 8'hzz;
endmodule