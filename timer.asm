
timer:
	move $t0, $a0         # Guarda o tempo de espera em $t0

	# 1. Pega o tempo inicial do sistema
	li $v0, 30            # Syscall 30: System Time
	syscall               # Retorna o tempo em milissegundos: $a0 (bits baixos) e $a1 (bits altos)
	move $t1, $a0         # Guarda apenas os bits baixos do tempo inicial em $t1

timer_loop:
	# 2. Pega o tempo atual do sistema repetidamente
	li $v0, 30
	syscall
	move $t2, $a0         # $t2 = tempo atual

	# 3. Calcula a diferença: tempo_atual - tempo_inicial
	sub $t3, $t2, $t1     # $t3 = tempo decorrido

	# 4. Verifica se o tempo decorrido atingiu o esperado
	blt $t3, $t0, timer_loop  # Se $t3 < $t0 (tempo de espera), continua no laço

	jr $ra                # Retorna para o código principal