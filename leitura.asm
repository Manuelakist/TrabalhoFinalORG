# ===========================================================
# COMPONENTE: LEITURA (TECLADO)
# Responsável por toda a interação com o teclado matricial
# hexadecimal do Digital Lab Sim (varredura de linhas/colunas,
# leitura bloqueante de uma tecla e espera por soltura/debounce).
# Usa o componente TEMPORIZADOR (delay_ms) para os atrasos.
# ===========================================================

.globl leitura                              # Torna "leitura" visível para o main.asm
.globl espera_soltar                        # Torna "espera_soltar" visível para outros arquivos (usado também pelo main.asm)
.globl leitura_rapida                       # Torna "leitura_rapida" visível para outros arquivos (usado pelo main.asm)

# ---------------------------------------------------------
# Procedimento: leitura (LEITURA BLOQUEANTE)
# Fica esperando até que alguma tecla seja pressionada,
# depois espera o usuário soltar a tecla (debounce) e só
# então retorna o código da tecla pressionada.
# Saída: $v0 = código da tecla (0-15)
# ---------------------------------------------------------
leitura:
    # Salva o endereço de retorno ($ra) na pilha, pois esta função chama outras (delay_ms, leitura_rapida, espera_soltar)
    addiu $sp, $sp, -4                      # Abre espaço de 4 bytes na pilha (decrementa o ponteiro de pilha)
    sw $ra, 0($sp)                          # Guarda o endereço de retorno atual na posição reservada da pilha

scan_blocking:                              # Rótulo do laço que varre o teclado até alguma tecla ser pressionada
    li $a0, 5                               # Define um pequeno atraso de 5ms entre cada varredura (alívio para o simulador)
    jal delay_ms                            # Chama o temporizador para esperar esses 5ms
    jal leitura_rapida                      # Faz uma varredura rápida (não bloqueante) do teclado, resultado vai para $v0
    beq $v0, -1, scan_blocking              # Se $v0 == -1 (nenhuma tecla pressionada), repete a varredura

    # Chegou aqui: uma tecla foi pressionada! Salva o valor lido na pilha antes de chamar outra função
    addiu $sp, $sp, -4                      # Abre mais 4 bytes de espaço na pilha
    sw $v0, 0($sp)                          # Salva o código da tecla pressionada (estava em $v0) na pilha

    # Chama rotina para aguardar o usuário soltar a tecla (evita repetição/ruído mecânico)
    jal espera_soltar                       # Bloqueia até a tecla ser solta e o ruído mecânico se estabilizar

    # Recupera a tecla digitada que havia sido salva
    lw $v0, 0($sp)                          # Recarrega o código da tecla pressionada de volta em $v0
    addiu $sp, $sp, 4                       # Libera o espaço da pilha usado para guardar a tecla

    lw $ra, 0($sp)                          # Recupera o endereço de retorno salvo no início da função
    addiu $sp, $sp, 4                       # Libera o espaço da pilha usado para guardar $ra
    jr $ra                                  # Retorna ao código que chamou "leitura", com a tecla em $v0

# ---------------------------------------------------------
# Procedimento Auxiliar: espera_soltar (DEBOUNCING SEGURO)
# Em vez de ler todas as linhas (o que pode travar no MARS),
# usamos a leitura rápida repetidamente até nenhuma tecla
# estar mais pressionada, e então aguardamos mais um tempo
# para filtrar ruído mecânico do contato do botão.
# ---------------------------------------------------------
espera_soltar:
    addiu $sp, $sp, -4                      # Abre espaço de 4 bytes na pilha
    sw $ra, 0($sp)                          # Salva o endereço de retorno, pois esta função chama delay_ms e leitura_rapida

loop_espera_global:                         # Rótulo do laço que espera o usuário soltar qualquer tecla
    li $a0, 5                               # Define atraso de 5ms entre cada checagem
    jal delay_ms                            # Chama o temporizador para esperar 5ms
    jal leitura_rapida                      # Verifica novamente se alguma tecla continua pressionada
    bne $v0, -1, loop_espera_global         # Se $v0 != -1 (ainda há tecla pressionada), continua esperando

    # Quando finalmente solta, espera mais 150ms para ignorar ruído mecânico do botão (debounce)
    li $a0, 150                             # Define o atraso de 150ms pós-soltura
    jal delay_ms                            # Chama o temporizador para esperar esses 150ms

    lw $ra, 0($sp)                          # Recupera o endereço de retorno salvo
    addiu $sp, $sp, 4                       # Libera o espaço da pilha usado para guardar $ra
    jr $ra                                  # Retorna ao código que chamou "espera_soltar"

# ---------------------------------------------------------
# Procedimento: leitura_rapida (LEITURA NÃO-BLOQUEANTE)
# Faz uma única varredura do teclado matricial (4 linhas x 4
# colunas) e retorna imediatamente o código da tecla encontrada,
# ou -1 se nenhuma tecla estiver pressionada no momento.
# Saída: $v0 = código da tecla (0-15) ou -1 se nenhuma tecla
# ---------------------------------------------------------
leitura_rapida:
    li $t0, 0xFFFF0012                      # Endereço de escrita das linhas do teclado (porta de saída do teclado matricial)
    li $t1, 0xFFFF0014                      # Endereço de leitura das colunas do teclado (porta de entrada do teclado matricial)

    # --- Varredura da Linha 0 ---
    li $t2, 1                               # Valor 1 (bit 0 ativo) seleciona a linha 0 do teclado
    sb $t2, 0($t0)                          # Escreve esse valor na porta de linhas, ativando a linha 0
    nop                                     # Pequeno atraso de sincronismo (estabilização do sinal elétrico)
    nop                                     # Pequeno atraso de sincronismo
    nop                                     # Pequeno atraso de sincronismo
    lbu $t3, 0($t1)                         # Lê o valor das colunas (qual tecla da linha 0 está pressionada, se houver)
    beq $t3, 0x11, rp_btn0                  # Se o padrão lido for 0x11, a tecla "0" foi pressionada
    beq $t3, 0x21, rp_btn1                  # Se o padrão lido for 0x21, a tecla "1" foi pressionada
    beq $t3, 0x41, rp_btn2                  # Se o padrão lido for 0x41, a tecla "2" foi pressionada
    beq $t3, 0x81, rp_btn3                  # Se o padrão lido for 0x81, a tecla "3" foi pressionada

    # --- Varredura da Linha 1 ---
    li $t2, 2                               # Valor 2 (bit 1 ativo) seleciona a linha 1 do teclado
    sb $t2, 0($t0)                          # Escreve esse valor na porta de linhas, ativando a linha 1
    nop                                     # Atraso de sincronismo
    nop                                     # Atraso de sincronismo
    nop                                     # Atraso de sincronismo
    lbu $t3, 0($t1)                         # Lê o valor das colunas para a linha 1
    beq $t3, 0x12, rp_btn4                  # Se o padrão lido for 0x12, a tecla "4" foi pressionada
    beq $t3, 0x22, rp_btn5                  # Se o padrão lido for 0x22, a tecla "5" foi pressionada
    beq $t3, 0x42, rp_btn6                  # Se o padrão lido for 0x42, a tecla "6" foi pressionada
    beq $t3, 0x82, rp_btn7                  # Se o padrão lido for 0x82, a tecla "7" foi pressionada

    # --- Varredura da Linha 2 ---
    li $t2, 4                               # Valor 4 (bit 2 ativo) seleciona a linha 2 do teclado
    sb $t2, 0($t0)                          # Escreve esse valor na porta de linhas, ativando a linha 2
    nop                                     # Atraso de sincronismo
    nop                                     # Atraso de sincronismo
    nop                                     # Atraso de sincronismo
    lbu $t3, 0($t1)                         # Lê o valor das colunas para a linha 2
    beq $t3, 0x14, rp_btn8                  # Se o padrão lido for 0x14, a tecla "8" foi pressionada
    beq $t3, 0x24, rp_btn9                  # Se o padrão lido for 0x24, a tecla "9" foi pressionada
    beq $t3, 0x44, rp_btnA                  # Se o padrão lido for 0x44, a tecla "A" (Ligar) foi pressionada
    beq $t3, 0x84, rp_btnB                  # Se o padrão lido for 0x84, a tecla "B" (Parar/Cancelar) foi pressionada

    # --- Varredura da Linha 3 ---
    li $t2, 8                               # Valor 8 (bit 3 ativo) seleciona a linha 3 do teclado
    sb $t2, 0($t0)                          # Escreve esse valor na porta de linhas, ativando a linha 3
    nop                                     # Atraso de sincronismo
    nop                                     # Atraso de sincronismo
    nop                                     # Atraso de sincronismo
    lbu $t3, 0($t1)                         # Lê o valor das colunas para a linha 3
    beq $t3, 0x18, rp_btnC                  # Se o padrão lido for 0x18, a tecla "C" (Sensor da porta) foi pressionada
    beq $t3, 0x28, rp_btnD                  # Se o padrão lido for 0x28, a tecla "D" foi pressionada (não usada no projeto)
    beq $t3, 0x48, rp_btnE                  # Se o padrão lido for 0x48, a tecla "E" foi pressionada (não usada no projeto)
    beq $t3, 0x88, rp_btnF                  # Se o padrão lido for 0x88, a tecla "F" foi pressionada (não usada no projeto)

    # Nenhuma tecla foi encontrada pressionada em nenhuma das 4 linhas
    li $v0, -1                              # Define o valor de retorno como -1 (código "nenhuma tecla")
    jr $ra                                  # Retorna ao código que chamou leitura_rapida

# --- Rótulos de retorno: cada um define o código numérico da tecla e retorna ---
rp_btn0: li $v0, 0                          # Tecla "0": retorna o código 0
jr $ra                                      # Retorna ao chamador
rp_btn1: li $v0, 1                          # Tecla "1": retorna o código 1
jr $ra                                      # Retorna ao chamador
rp_btn2: li $v0, 2                          # Tecla "2": retorna o código 2
jr $ra                                      # Retorna ao chamador
rp_btn3: li $v0, 3                          # Tecla "3": retorna o código 3
jr $ra                                      # Retorna ao chamador
rp_btn4: li $v0, 4                          # Tecla "4": retorna o código 4
jr $ra                                      # Retorna ao chamador
rp_btn5: li $v0, 5                          # Tecla "5": retorna o código 5
jr $ra                                      # Retorna ao chamador
rp_btn6: li $v0, 6                          # Tecla "6": retorna o código 6
jr $ra                                      # Retorna ao chamador
rp_btn7: li $v0, 7                          # Tecla "7": retorna o código 7
jr $ra                                      # Retorna ao chamador
rp_btn8: li $v0, 8                          # Tecla "8": retorna o código 8
jr $ra                                      # Retorna ao chamador
rp_btn9: li $v0, 9                          # Tecla "9": retorna o código 9
jr $ra                                      # Retorna ao chamador
rp_btnA: li $v0, 10                         # Tecla "A" (Ligar): retorna o código 10
jr $ra                                      # Retorna ao chamador
rp_btnB: li $v0, 11                         # Tecla "B" (Parar/Cancelar): retorna o código 11
jr $ra                                      # Retorna ao chamador
rp_btnC: li $v0, 12                         # Tecla "C" (Sensor da porta): retorna o código 12
jr $ra                                      # Retorna ao chamador
rp_btnD: li $v0, 13                         # Tecla "D" (não usada): retorna o código 13
jr $ra                                      # Retorna ao chamador
rp_btnE: li $v0, 14                         # Tecla "E" (não usada): retorna o código 14
jr $ra                                      # Retorna ao chamador
rp_btnF: li $v0, 15                         # Tecla "F" (não usada): retorna o código 15
jr $ra                                      # Retorna ao chamador