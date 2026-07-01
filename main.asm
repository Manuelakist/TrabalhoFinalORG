# ===========================================================
# COMPONENTE: MAIN (CONTROLE PRINCIPAL DO MICRO-ONDAS)
# Implementa a máquina de estados do sistema (Início, Funcionando,
# Pausado, Porta Aberta) e orquestra as chamadas aos demais
# componentes: LEITURA (teclado), ESCRITA (display) e
# TEMPORIZADOR (delay_ms / contagem de 1 segundo).
#
# Estados (variável "estado"):
#   0 = INÍCIO (digitando tempo / em espera)
#   1 = FUNCIONANDO (contando regressivamente)
#   2 = PAUSADO
#   3 = PORTA ABERTA (mostra "OP")
# ===========================================================

.data                                       # Início da seção de dados (variáveis globais do sistema)
tempo:           .word 0                    # Guarda o tempo de cozimento atual (0 a 99 segundos)
estado:          .word 0                    # Guarda o estado atual da máquina de estados (0,1,2 ou 3)
estado_salvo:    .word 0                    # Guarda o estado para o qual voltar depois que a porta for fechada
tempo_anterior:  .word 0                    # Guarda a última marcação de tempo do sistema (para medir 1 segundo)

.text                                       # Início da seção de código
.globl main                                 # Torna "main" o ponto de entrada do programa

# ---------------------------------------------------------
# Ponto de entrada do programa
# ---------------------------------------------------------
main:
    sw $zero, tempo                         # Inicializa "tempo" com 0 (display começa zerado)
    sw $zero, estado                        # Inicializa "estado" com 0 (sistema começa no estado INÍCIO)

# ---------------------------------------------------------
# Laço principal: despacha a execução para a rotina do estado atual
# ---------------------------------------------------------
loop_principal:
    # Pequeno atraso de alívio, para não sobrecarregar o simulador com execução excessivamente rápida
    li $a0, 5                               # Define o atraso em 5 milissegundos
    jal delay_ms                            # Chama o componente TEMPORIZADOR para esperar 5ms

    lw $s0, estado                          # Carrega o valor atual da variável "estado" em $s0
    beq $s0, 0, estado_inicio               # Se estado == 0, desvia para a rotina do estado INÍCIO
    beq $s0, 1, estado_func                 # Se estado == 1, desvia para a rotina do estado FUNCIONANDO
    beq $s0, 2, estado_pause                # Se estado == 2, desvia para a rotina do estado PAUSADO
    beq $s0, 3, estado_open                 # Se estado == 3, desvia para a rotina do estado PORTA ABERTA
    j loop_principal                        # Segurança: se nenhum estado bateu, volta ao início do laço

# ================= ESTADO 0: INÍCIO =================
# Sistema parado, aguardando o usuário digitar o tempo ou
# pressionar A (ligar), B (limpar) ou C (abrir porta).
estado_inicio:
    lw $a0, tempo                           # Carrega o tempo atual para exibir no display
    jal escrita                             # Chama o componente ESCRITA para mostrar o tempo nos displays
    jal leitura                             # Chama o componente LEITURA (bloqueante) para capturar a próxima tecla
    move $t0, $v0                           # Copia o código da tecla lida (em $v0) para $t0
    ble $t0, 9, digita_numero               # Se a tecla for 0-9, trata como dígito numérico
    beq $t0, 10, tenta_ligar                # Se a tecla for A (código 10), tenta ligar o micro-ondas
    beq $t0, 11, tenta_limpar               # Se a tecla for B (código 11), tenta limpar o tempo
    beq $t0, 12, abre_porta_inicio          # Se a tecla for C (código 12), abre a porta
    j loop_principal                        # Qualquer outra tecla é ignorada; volta ao laço principal

# --- Trata dígito numérico digitado em modo de espera ---
digita_numero:
    lw $t1, tempo                           # Carrega o tempo atual em $t1
    li $t2, 10                              # Carrega a constante 10 (usada para "deslocar" os dígitos)
    div $t1, $t2                            # Divide o tempo atual por 10 (quociente descartado, resto em HI)
    mfhi $t1                                # Recupera o resto da divisão (último dígito do tempo atual) em $t1
    mul $t1, $t1, $t2                       # Multiplica esse dígito por 10, deslocando-o para a casa da dezena
    add $t1, $t1, $t0                       # Soma o novo dígito digitado (em $t0) na casa da unidade
    sw $t1, tempo                           # Guarda o novo valor de tempo (dezena antiga + novo dígito)
    j loop_principal                        # Volta ao laço principal

# --- Trata tentativa de ligar o micro-ondas (tecla A) ---
tenta_ligar:
    lw $t1, tempo                           # Carrega o tempo atual em $t1
    beqz $t1, loop_principal                # Se o tempo for 0, não faz nada (não pode ligar sem tempo definido)
    li $t2, 1                               # Carrega o código do estado FUNCIONANDO (1)
    sw $t2, estado                          # Atualiza a variável "estado" para FUNCIONANDO
    li $v0, 30                              # Carrega o código da syscall de leitura do relógio do sistema
    syscall                                 # Executa a syscall; o tempo atual (ms) volta em $a0
    sw $a0, tempo_anterior                  # Guarda esse instante como referência para contar 1 segundo depois
    j loop_principal                        # Volta ao laço principal

# --- Trata tentativa de limpar o tempo (tecla B em modo de espera) ---
tenta_limpar:
    sw $zero, tempo                         # Zera a variável "tempo" (limpa o painel)
    j loop_principal                        # Volta ao laço principal

# --- Trata abertura da porta a partir do estado de espera (tecla C) ---
abre_porta_inicio:
    li $t2, 0                               # Código do estado INÍCIO (0)
    sw $t2, estado_salvo                    # Guarda que, ao fechar a porta, deve-se voltar para o estado INÍCIO
    li $t2, 3                               # Código do estado PORTA ABERTA (3)
    sw $t2, estado                          # Atualiza "estado" para PORTA ABERTA
    j loop_principal                        # Volta ao laço principal

# ================= ESTADO 1: FUNCIONANDO =================
# Sistema contando regressivamente o tempo, decrementando 1
# unidade a cada 1000ms reais medidos pelo relógio do sistema.
estado_func:
    jal leitura_rapida                      # Verifica (sem bloquear) se alguma tecla está sendo pressionada agora
    beq $v0, 11, botao_b_func               # Se a tecla for B (11), trata pedido de pausa
    beq $v0, 12, botao_c_func               # Se a tecla for C (12), trata abertura de porta durante o funcionamento

    li $v0, 30                              # Carrega o código da syscall de leitura do relógio do sistema
    syscall                                 # Executa a syscall; tempo atual (ms) volta em $a0
    lw $t1, tempo_anterior                  # Carrega o último instante em que o tempo foi decrementado
    sub $t2, $a0, $t1                       # Calcula quanto tempo (ms) já se passou desde a última decrementação
    blt $t2, 1000, loop_principal           # Se ainda não se passou 1 segundo (1000ms), volta ao laço sem decrementar

    sw $a0, tempo_anterior                  # Atualiza a referência de tempo, pois 1 segundo já se passou
    lw $t3, tempo                           # Carrega o tempo de cozimento atual em $t3
    addi $t3, $t3, -1                       # Decrementa 1 segundo do tempo de cozimento
    sw $t3, tempo                           # Salva o novo valor decrementado de volta na variável "tempo"

    # IMPORTANTE: o teste de tempo zerado é feito ANTES de chamar "escrita",
    # pois o procedimento "escrita" usa o registrador $t3 internamente e o sobrescreveria
    blez $t3, fim_do_tempo                  # Se o tempo chegou a 0 (ou menos), desvia para a rotina de fim de tempo

    move $a0, $t3                           # Copia o novo tempo (ainda maior que 0) para $a0
    jal escrita                             # Chama o componente ESCRITA para atualizar o display com o novo tempo

    j loop_principal                        # Volta ao laço principal

# --- Trata pedido de pausa (tecla B) durante o funcionamento ---
botao_b_func:
    jal espera_soltar                       # Aguarda o usuário soltar a tecla B (evita múltiplos acionamentos)
    li $t2, 2                               # Código do estado PAUSADO (2)
    sw $t2, estado                          # Atualiza "estado" para PAUSADO
    j loop_principal                        # Volta ao laço principal

# --- Trata abertura de porta (tecla C) durante o funcionamento ---
botao_c_func:
    jal espera_soltar                       # Aguarda o usuário soltar a tecla C
    li $t2, 1                               # Código do estado FUNCIONANDO (1)
    sw $t2, estado_salvo                    # Guarda que, ao fechar a porta, deve-se voltar a FUNCIONANDO
    li $t2, 3                               # Código do estado PORTA ABERTA (3)
    sw $t2, estado                          # Atualiza "estado" para PORTA ABERTA (interrompe o aquecimento)
    j loop_principal                        # Volta ao laço principal

# --- Rotina executada quando o tempo de cozimento chega a zero naturalmente ---
fim_do_tempo:
    # --- LÓGICA DAS 3 PISCADELAS DE "00" ---
    li $s1, 3                               # Define o contador de piscadelas: deve piscar 3 vezes
loop_pisca:
    # 1. Mostra "00" nos displays
    li $a0, 0                               # Define o valor 0 (vira "00" nos dois displays) em $a0
    jal escrita                             # Chama ESCRITA para acender "00"
    li $a0, 500                             # Define o tempo de exibição: 500ms com o display aceso
    jal delay_ms                            # Chama o TEMPORIZADOR para esperar esses 500ms

    # 2. Apaga os displays
    li $a0, 100                             # Usa o código especial 100, que o componente ESCRITA interpreta como "apagar"
    jal escrita                             # Chama ESCRITA para apagar os displays
    li $a0, 500                             # Define o tempo de exibição: 500ms com o display apagado
    jal delay_ms                            # Chama o TEMPORIZADOR para esperar esses 500ms

    addi $s1, $s1, -1                       # Decrementa o contador de piscadelas restantes
    bnez $s1, loop_pisca                    # Se ainda restam piscadelas (contador != 0), repete o laço

    # --- RESET TOTAL: volta o sistema para o estado inicial, pronto para novo uso ---
    sw $zero, tempo                         # Zera a variável "tempo" (painel limpo)
    sw $zero, estado                        # Volta "estado" para 0 (estado INÍCIO)
    sw $zero, tempo_anterior                # Zera a referência de tempo (evita comportamento incorreto ao religar)
    sw $zero, estado_salvo                  # Zera também o estado salvo, por consistência

    # Força a escrita de "00" para deixar o display limpo ao final das piscadelas
    li $a0, 0                               # Define o valor 0 em $a0
    jal escrita                             # Chama ESCRITA para mostrar "00" fixo no display

    # Aguarda o usuário tirar o dedo de qualquer tecla antes de liberar o laço principal novamente
    jal espera_soltar                       # Chama LEITURA para garantir que nenhuma tecla ficou "presa"

    j loop_principal                        # Volta ao laço principal, já no estado INÍCIO

# ================= ESTADO 2: PAUSADO =================
# Sistema com a contagem congelada, aguardando o usuário
# religar (A), limpar (B) ou abrir a porta (C).
estado_pause:
    lw $a0, tempo                           # Carrega o tempo atual (congelado) para exibir
    jal escrita                             # Chama ESCRITA para manter o tempo exibido no display
    jal leitura                             # Chama LEITURA (bloqueante) para capturar a próxima tecla
    move $t0, $v0                           # Copia o código da tecla lida para $t0
    beq $t0, 10, botao_a_pause              # Se a tecla for A (10), tenta retomar a contagem
    beq $t0, 11, botao_b_pause              # Se a tecla for B (11), limpa o tempo e volta ao estado INÍCIO
    beq $t0, 12, botao_c_pause              # Se a tecla for C (12), abre a porta a partir do estado pausado
    j loop_principal                        # Qualquer outra tecla é ignorada

# --- Retoma a contagem a partir do estado pausado (tecla A) ---
botao_a_pause:
    li $t2, 1                               # Código do estado FUNCIONANDO (1)
    sw $t2, estado                          # Atualiza "estado" para FUNCIONANDO, retomando a contagem
    li $v0, 30                              # Carrega o código da syscall de leitura do relógio do sistema
    syscall                                 # Executa a syscall; tempo atual (ms) volta em $a0
    sw $a0, tempo_anterior                  # Reinicia a referência de tempo, para contar certo o próximo segundo
    j loop_principal                        # Volta ao laço principal

# --- Limpa o tempo e volta ao estado de espera (tecla B em modo pausado) ---
botao_b_pause:
    sw $zero, tempo                         # Zera o tempo de cozimento (limpa o painel)
    sw $zero, estado                        # Volta "estado" para 0 (estado INÍCIO)
    j loop_principal                        # Volta ao laço principal

# --- Abre a porta a partir do estado pausado (tecla C) ---
botao_c_pause:
    li $t2, 2                               # Código do estado PAUSADO (2)
    sw $t2, estado_salvo                    # Guarda que, ao fechar a porta, deve-se voltar a PAUSADO
    li $t2, 3                               # Código do estado PORTA ABERTA (3)
    sw $t2, estado                          # Atualiza "estado" para PORTA ABERTA
    j loop_principal                        # Volta ao laço principal

# ================= ESTADO 3: PORTA ABERTA =================
# Mostra a mensagem "OP" nos displays e bloqueia o aquecimento
# até que a porta seja fechada novamente (tecla C).
estado_open:
    li $t0, 0xFFFF0011                      # Endereço de memória mapeada do display esquerdo
    li $t1, 0x3F                            # Padrão de segmentos da letra "O"   # O
    sb $t1, 0($t0)                          # Escreve "O" no display esquerdo
    li $t0, 0xFFFF0010                      # Endereço de memória mapeada do display direito
    li $t1, 0x73                            # Padrão de segmentos da letra "P"  # P
    sb $t1, 0($t0)                          # Escreve "P" no display direito (juntos formam "OP")

    jal leitura_rapida                      # Verifica (sem bloquear) se alguma tecla está pressionada
    beq $v0, -1, loop_principal             # Se nenhuma tecla pressionada, apenas continua mostrando "OP"
    bne $v0, 12, loop_principal             # Se a tecla pressionada não for C (fechar porta), ignora e continua

    jal espera_soltar                       # Aguarda o usuário soltar a tecla C (fechamento da porta)
    lw $t2, estado_salvo                    # Recupera o estado que estava ativo antes de abrir a porta
    sw $t2, estado                          # Restaura "estado" para esse valor salvo (INÍCIO, FUNC ou PAUSADO)
    lw $a0, tempo                           # Carrega o tempo (que ficou congelado) para reexibir
    jal escrita                             # Chama ESCRITA para mostrar novamente o tempo correto no display

    li $t3, 1                               # Código do estado FUNCIONANDO (1), para comparação
    bne $t2, $t3, open_sem_reset            # Se o estado restaurado NÃO for FUNCIONANDO, pula o reset do timer
    li $v0, 30                              # Caso volte para FUNCIONANDO: carrega a syscall do relógio
    syscall                                 # Executa a syscall; tempo atual (ms) volta em $a0
    sw $a0, tempo_anterior                  # Reinicia a referência de tempo, para a contagem retomar corretamente
open_sem_reset:
    j loop_principal                        # Volta ao laço principal