// Arquivo: src/top.v
// Versão do Arquivo: 6.0 - SoC VAA8-S1 Integrado e Funcional
// Descrição: Montagem final de todos os componentes do sistema.

module top(
    input  logic         clk,
    input  logic         reset,
    // Conectando os pinos da PIO ao "mundo exterior" do chip
    input  logic [7:0]   pio_pins_in,
    output logic [7:0]   pio_pins_out
);

    // ================== BARRAMENTOS DO SISTEMA ==================
    wire [15:0] address_bus;
    wire [7:0]  data_bus_from_cpu;
    wire [7:0]  data_bus_to_cpu;

    // ================== FIOS DE CONTROLE ==================
    wire [2:0]  alu_opcode;
    wire        sel_a_from_x, sel_b_from_y, reg_a_load, reg_x_load, reg_y_load;
    wire        reg_a_output_en, pc_inc, pc_load, sp_load;
    wire        cs_ram, cs_pio, cs_rom;
    wire        write_enable; // Sinal global de escrita
    
    // ================== COMPONENTES INTERNOS ==================
    reg [7:0] instruction_register;

    // === LÓGICA DE EXECUÇÃO E FIAÇÃO ===

    // O Registrador de Instrução captura o dado do barramento no clock
    always_ff @(posedge clk or posedge reset) begin
        if (reset) instruction_register <= 8'h00; // NOP no reset
        else instruction_register <= data_bus_to_cpu;
    end
    
    // Decodificador de Endereços: Ouve o barramento de endereço
    address_decoder addr_decoder (
        .addr(address_bus), .cs_ram(cs_ram), .cs_pio(cs_pio), .cs_rom(cs_rom)
    );

    // Unidade de Controle: Lê a instrução e gera os sinais de controle
    instruction_decoder decoder (
        .opcode(instruction_register), .alu_opcode(alu_opcode),
        .sel_a_from_x(sel_a_from_x), .sel_b_from_y(sel_b_from_y),
        .reg_a_load(reg_a_load), .reg_x_load(reg_x_load), .reg_y_load(reg_y_load),
        .reg_a_output_en(reg_a_output_en), .pc_inc(pc_inc), .pc_load(pc_load), .sp_load(sp_load)
    );
    
    // Lógica do sinal de escrita: a UCP quer escrever na memória/periféricos?
    // Em um design real, a UC geraria este sinal. Vamos simplificar.
    // A instrução STA (0x8D) implica uma escrita.
    assign write_enable = (instruction_register == 8'h8D);

    // Unidade Central de Processamento (UCP)
    vaa8_cpu cpu (
        .clk(clk), .reset(reset),
        .address_bus_out(address_bus),
        .data_bus_in(data_bus_to_cpu),
        .data_bus_out(data_bus_from_cpu),
        
        // Conexões de controle da UC para a UCP
        .alu_opcode(alu_opcode), .sel_a_from_x(sel_a_from_x), .sel_b_from_y(sel_b_from_y),
        .reg_a_load(reg_a_load), .reg_x_load(reg_x_load), .reg_y_load(reg_y_load),
        .reg_a_output_en(reg_a_output_en), .pc_load(pc_load), .pc_inc(pc_inc), .sp_load(sp_load)
    );

    // === MEMÓRIA E PERIFÉRICOS ===
    wire [7:0] rom_data_out, ram_data_out, pio_data_out;

    program_rom rom ( .addr(address_bus), .data(rom_data_out) );
    
    ram ram_inst (
        .clk(clk), .chip_select(cs_ram), .write_enable(write_enable),
        .addr(address_bus), .data_in(data_bus_from_cpu), .data_out(ram_data_out)
    );
    
    pio_8bit pio_inst (
        .clk(clk), .reset(reset), .chip_select(cs_pio), .write_enable(write_enable),
        .addr_sel_port(address_bus[0]), .data_in(data_bus_from_cpu), .data_out(pio_data_out),
        .pins_in(pio_pins_in), .pins_out(pio_pins_out)
    );

    // Lógica do Barramento de Dados Tri-state: O MUX do sistema
    // A UCP lê do dispositivo que estiver selecionado.
    assign data_bus_to_cpu = cs_rom ? rom_data_out : 
                             cs_ram ? ram_data_out :
                             cs_pio ? pio_data_out :
                             8'hzz; // Desconectado se ninguém for selecionado

endmodule