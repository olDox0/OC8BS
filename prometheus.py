# Arquivo: prometheus.py
# v3.1 - Finalizado como biblioteca de teste para o Pytest.

import subprocess, sys
from pathlib import Path

class VerilogTester:
    def __init__(self, config):
        self.config = config
        self.test_name = self.config["test_name"]
        self.tb_file = Path(f"{self.test_name}_tb.v")
        self.vvp_file = Path(f"{self.test_name}.vvp")
        self.vcd_file = Path(f"{self.test_name}.vcd")

    def run(self):
        print(f"\n--- Iniciando teste para: {self.config['top_module']} ---")
        success = False
        try:
            if not self._generate_testbench(): return False
            if not self._run_simulation(): return False
            print(f"[PASS] O teste '{self.test_name}' executou sem erros.")
            success = True
        finally:
            self._cleanup()
        return success

    def _run_command(self, command):
        try:
            result = subprocess.run(command, check=True, capture_output=True, text=True, encoding='utf-8')
            if result.stdout:
                print(result.stdout.strip())
            return True
        except (subprocess.CalledProcessError, FileNotFoundError) as e:
            print(f"[ERRO] Falha ao executar: {' '.join(command)}")
            print(f"   > Saída: {e.stderr.strip()}", file=sys.stderr)
            return False

    def _generate_testbench(self):
        print(f"1. Gerando testbench: {self.tb_file}")
        generator = self.config["testbench_generator"]
        # Passa os parâmetros corretos para o gerador
        code = generator(self.config["top_module"], self.config["includes"]) 
        try:
            self.tb_file.write_text(code, encoding='utf-8')
            return True
        except IOError as e:
            print(f"[ERRO] Falha ao escrever o arquivo de testbench: {e}", file=sys.stderr)
            return False

    def _run_simulation(self):
        print("2. Compilando o design...")
        # Apenas o arquivo de testbench é passado para o compilador
        compile_cmd = ['iverilog', '-g2012', '-o', str(self.vvp_file), str(self.tb_file)]
        if not self._run_command(compile_cmd):
            return False
        
        print("\n3. Executando a simulação...")
        run_cmd = ['vvp', str(self.vvp_file)]
        return self._run_command(run_cmd)

    def _cleanup(self):
        print("\n4. Limpando arquivos temporários...")
        for f in [self.tb_file, self.vvp_file, self.vcd_file]:
            f.unlink(missing_ok=True)

# ==============================================================================
# == BIBLIOTECA DE CONFIGURAÇÕES DE TESTE
# ==============================================================================

TEST_CONFIG_HALF_ADDER = {
    "test_name": "half_adder",
    "top_module": "half_adder",
    "includes": ["src/alu.v"],
    "testbench_generator": lambda name, includes: (
        "".join([f'`include "{inc}"\n' for inc in includes]) +
        f"""
        module {name}_tb;
          logic a, b;
          logic sum, carry_out;
          {name} uut (.*);
          initial begin
            $monitor("a=%b b=%b -> sum=%b carry=%b", a, b, sum, carry_out);
            a=0; b=0; #10;
            a=0; b=1; #10;
            a=1; b=0; #10;
            a=1; b=1; #10;
            $finish;
          end
        endmodule
        """
    )
}

TEST_CONFIG_FULL_ADDER = {
    "test_name": "full_adder",
    "top_module": "full_adder",
    "includes": ["src/alu.v"],
    "testbench_generator": lambda name, includes: (
        "".join([f'`include "{inc}"\n' for inc in includes]) +
        f"""
        module {name}_tb;
          logic a, b, carry_in; logic sum, carry_out;
          {name} uut (.*);
          initial begin
            $monitor("a=%b b=%b cin=%b -> sum=%b cout=%b", a, b, carry_in, sum, carry_out);
            a=0; b=0; carry_in=0; #10; a=1; #10; b=1; #10; a=0; #10;
            carry_in=1; #10; a=1; #10; b=0; #10; a=0; #10; $finish;
          end
        endmodule
        """
    )
}

TEST_CONFIG_ALU_8BIT = {
    "test_name": "alu_8bit",
    "top_module": "alu_8bit",
    "includes": ["src/alu.v"],
    "testbench_generator": lambda name, includes: (
        "".join([f'`include "{inc}"\n' for inc in includes]) +
        f"""
        module {name}_tb;
          logic [7:0] a, b;
          logic [2:0] opcode;
          logic [7:0] result;
          logic flag_z, flag_c;

          {name} uut (.*);

          initial begin
            $monitor("op=%3b a=%8h b=%8h -> res=%8h z=%b c=%b", opcode, a, b, result, flag_z, flag_c);
            // Teste ADD
            a=10; b=20; opcode=3'b000; #10;
            // Teste SUB (resultando em zero)
            a=50; b=50; opcode=3'b001; #10;
            // Teste AND
            a=8'h0F; b=8'h55; opcode=3'b010; #10;
            $finish;
          end
        endmodule
        """
    )
}

TEST_CONFIG_REGISTER_8BIT = {
    "test_name": "register_8bit",
    "top_module": "register_8bit",
    "includes": ["src/registers.v"],
    "testbench_generator": lambda name, includes: (
        "".join([f'`include "{inc}"\n' for inc in includes]) +
        f"""
        module {name}_tb;
          logic clk=0, reset, load_en;
          logic [7:0] data_in, data_out;
          
          always #5 clk = ~clk; // Gera um clock
          {name} uut (.*);

          initial begin
            $monitor("t=%0t clk=%b rst=%b en=%b din=%h -> dout=%h", $time, clk, reset, load_en, data_in, data_out);
            reset=1; #10; // Aplica o reset
            reset=0; #10; // Libera o reset
            // Carrega 9B
            data_in=8'h9B; load_en=1; #10;
            // Mantém valor
            data_in=8'h45; load_en=0; #10;
            // Carrega 45
            data_in=8'h45; load_en=1; #10;
            $finish;
          end
        endmodule
        """
    )
}

TEST_CONFIG_ADDR_DECODER = {
    "test_name": "address_decoder_test",
    "top_module": "address_decoder",
    "includes": ["src/registers.v", "src/soc.v"],
    "testbench_generator": lambda name, includes: (
        "".join([f'`include "{inc}"\n' for inc in includes]) +
        f"""
        module {name}_tb;
          logic [15:0] addr;
          logic cs_ram, cs_pio, cs_rom;

          {name} uut (.*);

          initial begin
            $monitor("addr=%4h -> cs_ram=%b cs_pio=%b cs_rom=%b", addr, cs_ram, cs_pio, cs_rom);
            // Teste RAM
            addr = 16'h0000; #10;
            addr = 16'h7FFF; #10;
            // Teste PIO
            addr = 16'hFE00; #10;
            addr = 16'hFEFF; #10;
            // Teste ROM
            addr = 16'hFF00; #10;
            addr = 16'hFFFF; #10;
            // Teste Fora do Mapa
            addr = 16'h8000; #10;
            $finish;
          end
        endmodule
        """
    )
}

TEST_CONFIG_PIO = {
    "test_name": "pio_test",
    "top_module": "pio_8bit",
    "includes": ["src/registers.v", "src/soc.v"], # PIO depende do register_8bit e está em soc.v
    "testbench_generator": lambda name, includes: (
        "".join([f'`include "{inc}"\n' for inc in includes]) +
        f"""
        module {name}_tb;
          logic clk=0, reset, chip_select, write_en, addr_sel_port;
          logic [7:0] data_in, pins_in, data_out, pins_out;
          
          always #5 clk = ~clk;
          {name} uut (.*);

          initial begin
            $monitor("t=%0t cs=%b we=%b sel=%b din=%h pin=%h | dout=%h pout=%h", $time, chip_select, write_en, addr_sel_port, data_in, pins_in, data_out, pins_out);
            // 1. Reset
            reset=1; #10;
            reset=0; #10;
            
            // 2. Configurar pino 0 como SAÍDA
            chip_select=1; write_en=1; addr_sel_port=0; data_in=8'h01; #10;
            
            // 3. Acender LED no pino 0
            chip_select=1; write_en=1; addr_sel_port=1; data_in=8'h01; #10;
            
            // 4. Apagar LED no pino 0
            data_in=8'h00; #10;
            
            // 5. Ler estado dos pinos (assumindo pins_in = AAh)
            chip_select=1; write_en=0; addr_sel_port=1; pins_in=8'hAA; #10;
            $finish;
          end
        endmodule
        """
    )
}

TEST_CONFIG_RAM = {
    "test_name": "ram_test",
    "top_module": "ram",
    "includes": ["src/memory.v"],
    "testbench_generator": lambda name, includes: (
        "".join([f'`include "{inc}"\n' for inc in includes]) +
        f"""
        module {name}_tb;
          logic clk=0, chip_select, write_enable;
          logic [15:0] addr;
          logic [7:0] data_in, data_out;
          
          always #5 clk = ~clk;
          {name} uut (.*);

          initial begin
            $monitor("t=%0t cs=%b we=%b addr=%h din=%h -> dout=%h", $time, chip_select, write_enable, addr, data_in, data_out);
            // 1. Escrever AAh no endereço 1234h
            chip_select=1; write_enable=1; addr=16'h1234; data_in=8'hAA; #10;
            
            // 2. Tentar escrever 55h sem chip select (deve falhar)
            chip_select=0; write_enable=1; addr=16'h5678; data_in=8'h55; #10;

            // 3. Ler do endereço 1234h (deve retornar AAh)
            chip_select=1; write_enable=0; addr=16'h1234; data_in=8'hXX; #10;

            // 4. Ler de um endereço não escrito (deve retornar XXh - indefinido)
            addr=16'h1235; #10;
            $finish;
          end
        endmodule
        """
    )
}