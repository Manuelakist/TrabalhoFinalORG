# ===========================================================
# COMPONENTE: ESCRITA (DISPLAY DE 7 SEGMENTOS)
# Responsável por mostrar um número de 0 a 99 nos dois displays
# de 7 segmentos do Digital Lab Sim (um para dezena, um para
# unidade), além de poder apagar ambos os displays (usado nas
# piscadas de fim de tempo).
# ===========================================================

.data                                       # Início da seção de dados
# Tabela de tradução: índice (0-9) -> padrão de bits dos 7 segmentos correspondente ao dígito
display: .byte 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F
.globl display                              # Torna a tabela "display" visível para outros arquivos, se necessário

letra_O: .byte 0x3F                         # Padrão de segmentos que desenha a letra "O" (usado na mensagem "OP" da porta aberta)
letra_P: .byte 0x73                         # Padrão de segmentos que desenha a letra "P" (usado na mensagem "OP" da porta aberta)

.text                                       # Início da seção de código
.globl escrita                              # Torna "escrita" visível para o main.asm

# ---------------------------------------------------------
# Procedimento: escrita
# Entrada: $a0 = número a ser exibido (0 a 99), ou 100 para
#          apagar os dois displays
# Saída: nenhuma (apenas atualiza os displays físicos)
# ---------------------------------------------------------
escrita:
    beq $a0, 100, apagar_display            # Se $a0 for exatamente 100, é o "código especial" para apagar os displays

    bltz $a0, cap_min                       # Se o número for negativo, satura (limita) para o valor mínimo (0)
    bgt $a0, 99, cap_max                    # Se o número for maior que 99, satura para o valor máximo (99)
    j divide_normal                         # Caso esteja dentro da faixa válida, segue direto para o cálculo normal

cap_min:
    li $a0, 0                               # Força $a0 a valer 0 (limite inferior do display)
    j divide_normal                         # Segue para o cálculo normal com o valor já corrigido

cap_max:
    li $a0, 99                              # Força $a0 a valer 99 (limite superior do display)

divide_normal:
    li $t0, 10                              # Carrega a constante 10, usada para separar dezena e unidade
    div $a0, $t0                            # Divide $a0 por 10: quociente = dezena, resto = unidade
    mflo $t1                                # Move o quociente (dezena) da divisão para $t1
    mfhi $t2                                # Move o resto (unidade) da divisão para $t2
    la $t3, display                         # Carrega em $t3 o endereço base da tabela de tradução "display"

    # --- Display Esquerdo (dígito da dezena) ---
    add $t4, $t3, $t1                       # Calcula o endereço da tabela correspondente ao dígito da dezena
    lb $t5, 0($t4)                          # Lê o padrão de 7 segmentos desse dígito (1 byte)
    li $t6, 0xFFFF0011                      # Endereço de memória mapeada do display esquerdo (porta de saída)
    sb $t5, 0($t6)                          # Escreve o padrão de segmentos no display esquerdo
    nop                                     # Pequeno atraso de sincronismo de hardware
    nop                                     # Pequeno atraso de sincronismo de hardware

    # --- Display Direito (dígito da unidade) ---
    add $t4, $t3, $t2                       # Calcula o endereço da tabela correspondente ao dígito da unidade
    lb $t5, 0($t4)                          # Lê o padrão de 7 segmentos desse dígito (1 byte)
    li $t6, 0xFFFF0010                      # Endereço de memória mapeada do display direito (porta de saída)
    sb $t5, 0($t6)                          # Escreve o padrão de segmentos no display direito
    nop                                     # Pequeno atraso de sincronismo de hardware
    nop                                     # Pequeno atraso de sincronismo de hardware

    jr $ra                                  # Retorna ao código que chamou "escrita"

# ---------------------------------------------------------
# Sub-rotina interna: apagar_display
# Apaga (zera) ambos os displays de 7 segmentos, usada para
# o efeito de "piscar" quando o tempo do micro-ondas zera.
# ---------------------------------------------------------
apagar_display:
    li $t5, 0x00                            # Define o padrão 0x00, que apaga todos os segmentos (nenhum segmento aceso)
    li $t6, 0xFFFF0011                      # Endereço de memória mapeada do display esquerdo
    sb $t5, 0($t6)                          # Escreve 0x00 no display esquerdo, apagando-o
    nop                                     # Pequeno atraso de sincronismo de hardware
    nop                                     # Pequeno atraso de sincronismo de hardware
    li $t6, 0xFFFF0010                      # Endereço de memória mapeada do display direito
    sb $t5, 0($t6)                          # Escreve 0x00 no display direito, apagando-o
    nop                                     # Pequeno atraso de sincronismo de hardware
    nop                                     # Pequeno atraso de sincronismo de hardware
    jr $ra                                  # Retorna ao código que chamou "escrita"