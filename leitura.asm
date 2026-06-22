# Procedimento de Leitura (I/O - Teclado Matricial)
leitura:
	li $t0, 0xFFFF0012	# Endereço de Comando das Linhas do teclado
	li $t1, 0xFFFF0014	# Endereço de Leitura das Colunas (Retorno Hexadecimal)

scan_teclado:
	# Testa a Linha 0 (Botões 0, 1, 2, 3)
	li $t2, 1		# Carrega o bit 0 (Linha 0)
	sb $t2, 0($t0)		# Envia energia para a linha 0
	lbu $t3, 0($t1)		# Lê o código retornado nas colunas
	
	beq $t3, 0x11, btn0	# Se retornou 0x11, o botão 0 foi pressionado
	beq $t3, 0x21, btn1	# Se retornou 0x21, o botão 1 foi pressionado
	beq $t3, 0x41, btn2	# Se retornou 0x41, o botão 2 foi pressionado
	beq $t3, 0x81, btn3	# Se retornou 0x81, o botão 3 foi pressionado

	# Testa a Linha 1 (Botões 4, 5, 6, 7)
	li $t2, 2		# Carrega o bit 1 (Linha 1)
	sb $t2, 0($t0)		# Envia energia para a linha 1
	lbu $t3, 0($t1)		# Lê o código retornado nas colunas
	
	beq $t3, 0x12, btn4	# Se retornou 0x12, o botão 4 foi pressionado
	beq $t3, 0x22, btn5	# Se retornou 0x22, o botão 5 foi pressionado
	beq $t3, 0x42, btn6	# Se retornou 0x42, o botão 6 foi pressionado
	beq $t3, 0x82, btn7	# Se retornou 0x82, o botão 7 foi pressionado

	# Testa a Linha 2 (Botões 8, 9, a, b)
	li $t2, 4		# Carrega o bit 2 (Linha 2)
	sb $t2, 0($t0)		# Envia energia para a linha 2
	lbu $t3, 0($t1)		# Lê o código retornado nas colunas
	
	beq $t3, 0x14, btn8	# Se retornou 0x14, o botão 8 foi pressionado
	beq $t3, 0x24, btn9	# Se retornou 0x24, o botão 9 foi pressionado
	beq $t3, 0x44, btnA	# Se retornou 0x44, o botão A foi pressionado
	beq $t3, 0x84, btnB	# Se retornou 0x84, o botão B foi pressionado

	# Testa a Linha 3 (Botões c, d, e, f)
	li $t2, 8		# Carrega o bit 3 (Linha 3)
	sb $t2, 0($t0)		# Envia energia para a linha 3
	lbu $t3, 0($t1)		# Lê o código retornado nas colunas
	
	beq $t3, 0x18, btnC	# Se retornou 0x18, o botão C foi pressionado
	beq $t3, 0x28, btnD	# Se retornou 0x28, o botão D foi pressionado
	beq $t3, 0x48, btnE	# Se retornou 0x48, o botão E foi pressionado
	beq $t3, 0x88, btnF	# Se retornou 0x88, o botão F foi pressionado

	# Repetição do Polling
	j scan_teclado		# Se for zero (nada apertado), repete a varredura infinitamente

# Atribuição dos valores exatos (Botões apertados)
btn0: li $v0, 0
      j fim_leitura
btn1: li $v0, 1
      j fim_leitura
btn2: li $v0, 2
      j fim_leitura
btn3: li $v0, 3
      j fim_leitura
btn4: li $v0, 4
      j fim_leitura
btn5: li $v0, 5
      j fim_leitura
btn6: li $v0, 6
      j fim_leitura
btn7: li $v0, 7
      j fim_leitura
btn8: li $v0, 8
      j fim_leitura
btn9: li $v0, 9
      j fim_leitura
btnA: li $v0, 10
      j fim_leitura
btnB: li $v0, 11
      j fim_leitura
btnC: li $v0, 12
      j fim_leitura
btnD: li $v0, 13
      j fim_leitura
btnE: li $v0, 14
      j fim_leitura
btnF: li $v0, 15
      j fim_leitura

# Finalização da Leitura e Debouncing
fim_leitura:
	lbu $t3, 0($t1)		# Verifica o estado atual do sensor de colunas
	bnez $t3, fim_leitura	# Se tiver sinal, fica preso em loop até tirar o dedo do botão
	jr $ra			# Retorna ao procedimento chamador com o número no $v0
	