# Procedimento de Escrita (I/O - Display de 7 Segmentos)
escrita:
	# Cálculo para separar as Dezenas e Unidades
	li $t0, 10		# Carrega o divisor (10)
	div $a0, $t0		# Divide o resultado (x) por 10
	mflo $t1			# Armazena o algarismo das dezenas (quociente) em $t1
	mfhi $t2			# Armazena o algarismo das unidades (resto) em $t2
	la $t3, display		# Carrega o endereço base do "dicionário" de códigos

	# Escrever as Dezenas (Display Esquerdo)
	add $t4, $t3, $t1	# Soma o valor da dezena ao endereço base para achar a posição do array
	lb $t5, 0($t4)		# Lê o código de luzes para esse número
	li $t6, 0xFFFF0011	# Guarda o endereço do display esquerdo em $t6
	sb $t5, 0($t6)		# Escreve o código no display esquerdo acendendo as luzes

	# Escrever as Unidades (Display Direito)
	add $t4, $t3, $t2	# Soma o valor da unidade ao endereço base para achar a posição do array
	lb $t5, 0($t4)		# Lê o código de luzes para esse número
	li $t6, 0xFFFF0010	# Guarda o endereço do display direito em $t6
	sb $t5, 0($t6)		# Escreve o código no display direito acendendo as luzes
	
	jr $ra			# Retorna ao chamador