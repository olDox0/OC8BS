# Arquivo: test_hardware.py
# Descrição: Suíte de testes Pytest para os módulos de hardware do VAA8.

from prometheus import (
    VerilogTester,
    TEST_CONFIG_HALF_ADDER,
    TEST_CONFIG_FULL_ADDER,
    TEST_CONFIG_ALU_8BIT,
    TEST_CONFIG_REGISTER_8BIT,
    TEST_CONFIG_ADDR_DECODER,
    TEST_CONFIG_PIO,
    TEST_CONFIG_RAM
)

def test_half_adder_simulation():
    """Verifica se a simulação do half_adder executa sem erros."""
    tester = VerilogTester(TEST_CONFIG_HALF_ADDER)
    success = tester.run()
    assert success, "A simulação do Verilog para 'half_adder' falhou."

def test_full_adder_simulation():
    """Verifica se a simulação do full_adder executa sem erros."""
    tester = VerilogTester(TEST_CONFIG_FULL_ADDER)
    success = tester.run()
    assert success, "A simulação do Verilog para 'full_adder' falhou."

def test_alu_8bit_simulation():
    """Verifica a funcionalidade básica da ULA de 8 bits."""
    tester = VerilogTester(TEST_CONFIG_ALU_8BIT)
    success = tester.run()
    assert success, "A simulação do Verilog para 'alu_8bit' falhou."

def test_register_8bit_simulation():
    """Verifica a funcionalidade de carga e retenção do registrador de 8 bits."""
    tester = VerilogTester(TEST_CONFIG_REGISTER_8BIT)
    success = tester.run()
    assert success, "A simulação do Verilog para 'register_8bit' falhou."

def test_address_decoder_simulation():
    """Verifica a lógica de seleção de chip do decodificador de endereços."""
    tester = VerilogTester(TEST_CONFIG_ADDR_DECODER)
    success = tester.run()
    assert success, "A simulação do Verilog para 'address_decoder' falhou."
    
def test_pio_simulation():
    """Verifica a lógica de E/S do módulo PIO."""
    tester = VerilogTester(TEST_CONFIG_PIO)
    success = tester.run()
    assert success, "A simulação do Verilog para 'pio_8bit' falhou."

def test_ram_simulation():
    """Verifica a lógica de escrita e leitura da RAM."""
    tester = VerilogTester(TEST_CONFIG_RAM)
    success = tester.run()
    assert success, "A simulação do Verilog para 'ram' falhou."