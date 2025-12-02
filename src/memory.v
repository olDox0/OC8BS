// (em src/memory.v)

// --- ROM DO PROGRAMA v1.2: Blink ---
module program_rom (
    input  logic [15:0] addr,
    output logic [7:0]  data
);
    logic [7:0] rom_data[0:255];
    initial begin
        // Endereços da PIO
        rom_data[254] = 8'hFE; // PIO_DDR_ADDR_HI
        rom_data[255] = 8'h00; // PIO_DDR_ADDR_LO
        
        // Programa
        rom_data[0] = 8'hA9; // LDA #$01       ; Carrega 1 no Acumulador
        rom_data[1] = 8'h01;
        rom_data[2] = 8'h8D; // STA $FE00      ; Escreve 1 no DDR da PIO (configura pino 0 como saída)
        rom_data[3] = 8'h00; // Endereço Baixo
        rom_data[4] = 8'hFE; // Endereço Alto

        // LOOP_START: (Endereço 5)
        rom_data[5] = 8'hA9; // LDA #$01       ; Carrega 1 (acende LED)
        rom_data[6] = 8'h01;
        rom_data[7] = 8'h8D; // STA $FE01      ; Escreve no PORT da PIO
        rom_data[8] = 8'h01;
        rom_data[9] = 8'hFE;

        // Delay (simplesmente carregando lixo algumas vezes)
        rom_data[10] = 8'hA9; rom_data[11] = 8'hFF;
        rom_data[12] = 8'hA9; rom_data[13] = 8'hFF;

        rom_data[14] = 8'hA9; // LDA #$00      ; Carrega 0 (apaga LED)
        rom_data[15] = 8'h00;
        rom_data[16] = 8'h8D; // STA $FE01     ; Escreve no PORT da PIO
        rom_data[17] = 8'h01;
        rom_data[18] = 8'hFE;
        
        // Delay
        rom_data[19] = 8'hA9; rom_data[20] = 8'hFF;
        rom_data[21] = 8'hA9; rom_data[22] = 8'hFF;

        rom_data[23] = 8'h4C; // JMP $0005     ; Pula de volta para o início do loop
        rom_data[24] = 8'h05;
        rom_data[25] = 8'h00;
    end
    assign data = rom_data[addr[7:0]];
endmodule

//==============================================================================
// MÓDULO RAM (MEMÓRIA DE ACESSO ALEATÓRIO) DE 32KB
//==============================================================================
// 2025/11/24 - Ver2.0, Fnc1.0 - Criação inicial do módulo de RAM.
module ram (
    input  logic         clk,
    input  logic         chip_select,
    input  logic         write_enable, // 1 para Escrita, 0 para Leitura
    input  logic [15:0]  addr,
    input  logic [7:0]   data_in,
    output logic [7:0]   data_out
);
    // A memória em si: um array de 32768 registradores de 8 bits.
    // A palavra-chave 'reg' é usada aqui para memória sintetizável.
    reg [7:0] memory_array [0:32767];

    // Lógica de Escrita (Síncrona)
    always_ff @(posedge clk) begin
        if (chip_select && write_enable) begin
            memory_array[addr[14:0]] <= data_in; // Usamos 15 bits para endereçar 32K
        end
    end

    // Lógica de Leitura (Combinacional) com saída Tri-state
    assign data_out = (chip_select && !write_enable) ? memory_array[addr[14:0]] : 8'hzz;

endmodule