# ===========================================================
# COMPONENTE: TEMPORIZADOR
# Responsável por gerar atrasos (delays) em milissegundos,
# usando a chamada de sistema (syscall) 30, que lê o relógio
# do sistema operacional em milissegundos.
# Este componente é usado por todos os outros módulos sempre
# que for necessário esperar um tempo controlado (debounce,
# piscadas no display, intervalo de 1 segundo da contagem, etc).
# ===========================================================

.text                                       # Início da seção de código (instruções)
.globl delay_ms                             # Torna o rótulo delay_ms visível para outros arquivos (main.asm, leitura.asm, escrita.asm)

# ---------------------------------------------------------
# Procedimento: delay_ms
# Entrada:  $a0 = quantidade de milissegundos a esperar
# Saída:    nenhuma (apenas consome tempo)
# Registradores usados internamente: $t7, $t8, $t9, $v0, $a0
# ---------------------------------------------------------
delay_ms:
    move $t7, $a0                           # Guarda em $t7 a duração do delay pedida pelo chamador (ela viria de $a0)
    li $v0, 30                              # Carrega em $v0 o código 30, que é o syscall de "tempo do sistema"
    syscall                                 # Executa a syscall; o tempo atual (em ms) é devolvido em $a0 (baixo) e $a1 (alto)
    move $t8, $a0                           # Guarda em $t8 o instante de tempo inicial (momento em que o delay começou)

loop_delay:                                 # Início do laço que fica girando até o tempo pedido passar
    li $v0, 30                              # Carrega novamente o código 30 (ler relógio do sistema)
    syscall                                 # Executa a syscall; $a0 recebe o tempo atual (em ms) novamente
    sub $t9, $a0, $t8                       # Calcula quanto tempo já se passou: tempo_atual - tempo_inicial
    blt $t9, $t7, loop_delay                # Se o tempo decorrido ainda for menor que o tempo pedido, continua esperando (volta ao laço)

    jr $ra                                  # Tempo já decorrido: retorna ao código que chamou delay_ms