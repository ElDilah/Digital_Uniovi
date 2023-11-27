    LIST P=16F877A ; LISTA DE PROGRAMACION 
    INCLUDE P16F877A.INC
    __CONFIG _XT_OSC & _WDT_OFF & _LVP_OFF

org 0
    GOTO INICIO 
ORG 4 
    MOVWF W_TMP ;SALVAR W
    SWAPF STATUS,W ;MOVER STATUS A W
    BCF STATUS,RP0
    BCF STATUS,RP1 ;BANCO 0 
    MOVWF STATUS_TMP ; GUARDAR STATUS
    MOVF PCLATH,W 
    MOVWF PCLATH_TMP ;SALVAR PCLATH
    ;---------------- SALVAR CONTEXTO ------------------------
    BTFSS PIR1,TMR1IF
        GOTO ;1 DESBORDO TMR1 
     
;CRONOMETRO
;ASIGNACION
CBLOCK 0x20
    UNIDADES 
    MINUTOS 
    DECENAS
    MILESIMAS
    ESTADO 
    RE_E1
    DESBORDO_T0 
    DESBORDO_T1 
    DESBORDO_T3 
    ;GUARDADO DE CONTEXTO
    W_TMP  
    ANTESA ;YA QUE RP4 NO TIENE FLAG CON LO CUAL LA UNICA FORMA DE SABER SI SE HA 
    STATUS_TMP 
    PCLATH_TMP 
ENDC 
;COFIGURACION 
;BANCO 1
 BSF STATUS,RP0  ;CAMBIO A BANCO 1 
    MOVLW 0x01      ;GRABADO DE 1 PARA ASIGNAR PORTb,0 COMO LECTURA 
    MOVWF TRISB     ;ASIGNACION DE PUERTOC COMO ESCRITURA /LECTURA
    CLRF TRISD        	;Puerto D se programa como salida (control de los segmentos)
	MOVLW b'11110001'	;CONFIGURACION DE PUERTO A
    MOVWF TRISA        	;Salidas del Puerto A: RA1, RA2 y RA3
	MOVLW b'00000111'	;Definimos el PORTA
	MOVWF ADCON1    ; CONFIGURACION DE PUERTO A COMO DIGITAL NO COMO ANALOGICO
    MOVLW B'00000111';PRECARGA DE OPTION REG
    MOVwF OPTION_REG ;CONFIGURACION DE PRESCALER 
    CLRF TRISD      ;PONE TODO PORT D COMO SALIDA
     MOVLW B'00000111';PRECARGA DE OPTION REG
    MOVWF OPTION_REG ;CONFIGURACION DE PRESCALER 
    BSF	PIE1,TMR1IE	;INTERRUPCION POR TMR1
	BSF	PIE1,TMR2IE	;INTERRUPCION POR TMR0
   BCF STATUS,RP0  ;VUELTA AL BANCO 0
   ;BANCO 0
   MOVLW b'00110000'	;MOVER LA PRECONFIGURACION DE T1CON
	MOVWF T1CON		;e inicialmente parado
    MOVLW b'01111011'	;Configuramos TMR2 con prescaler y postscaler de 16
	MOVWF T2CON		;e inicialmente parado 
    movlw	0x2C		;Precargamos TMR1H
	movwf	TMR1H		;puesto que est� parado TMR1
	movlw	0xCF		;y cargamos TMR1L
	movwf	TMR1L		
    movlw	b'11000000'	;Habilitamos las interrupciones con
	movwf	INTCON		;GIE=1 y PEIE=1, (TMR1IE y TMR2IE ya se activaron arriba)


    
;INICIALIZACION
INCIO MOVLW D'5'
    MOVWF UNIDADES
    MOVLW D'1'
    MOVWF DECENAS ;COMENZAMOS EN EL VALOR 15;
    CLRF CENTENAS
    CLRF MILESIMAS ;EL RESTO DE VALORES A 0
    CLRF ESTADO ;PONEMOS ESTADO INICIAL RESETEO
    GOTO BUCLE ; SE ENVIA AL BUCLE YA QUE SI NO ENTRARIA EN LA TABLA Y NO INTERESA;
TABLA_U ADDWF PCL,F ;SE PONE AQUI LA TABLA PARA EVITAR  
RETLW B'11000000' ;"0"
RETLW B'11111001' ;"1"
RETLW B'10100100' ;"2"
RETLW B'10110000' ;"3"
RETLW B'10011001' ;"4"
RETLW B'10010010' ;"5"
RETLW B'10000010' ;"6"
RETLW B'11111000' ;"7"
RETLW B'10000000' ;"8"
RETLW B'10011000' ;"9"
CLRF UNIDADES     ;RECARGA 0 
RETLW B'11000000' ;"0"
;BUCLE
BUCLE 
MOVF PORTA,W ; GUARDAMOS LO QUE HAY EN PUERTO A NOS INTERESA EL VALOR DE RP4
MOVWF ANTESA ;GUARDAMOS EL VALOR DE PORT A
    BTFSC MINUTOS ;COMPROBACION SI HAY MINUTOS 
    GOTO SIN_MIN ;NO
    GOTO CON_MIN ;SI 
CON_MIN movlw 	b'11111101'	;Activamos el display de la izquierda
 	movwf 	PORTA		;con RA1 a 0 y resto a 1
    movf 	MINUTOS,W     	;se cargan en W el contenido a mostrar en el display izquierdo 
    call  	TABLA_U     	;y se llama al subprograma que controla los 7 diodos led
    MOVWF PORTD     ;SE MUESTRA EL VALOR
    BSF PORTD,7 ;PONER EL PUNTO 
    call ESPERA
    movlw 	b'11111011'	;Activamos el display central
 	movwf 	PORTA		;con RA2 a 0 y el resto a 1
    movf 	DECENAS,W     	;CARGAR LAS DECENAS DE SEGUNDO
    call  	TABLA_U     	;y se llama al subprograma que controla los 7 diodos led
    MOVWF PORTD ;VALOR
    CALL ESPERA
    movlw 	b'11110111'     ;Activamos el display de la derecha con
    movwf 	PORTA          	;el bit RA3 a 0 y el resto a 1
    movf 	UNIDADES,W     	;CARGAR LAS DECENAS DE SEGUNDO
    call  	TABLA_U     	;y se llama al subprograma que controla los 7 diodos led
    MOVWF PORTD ;VALOR

SIN_MIN movlw 	b'11111101'	;Activamos el display de la izquierda
 	movwf 	PORTA		;con RA1 a 0 y resto a 1
    movf 	DECENAS,W     	;CARGAR LAS DECENAS DE SEGUNDO
    call  	TABLA_U     	;y se llama al subprograma que controla los 7 diodos led
    MOVWF PORTD ;VALOR
    CALL ESPERA
    movlw 	b'11111011'	;Activamos el display central
 	movwf 	PORTA		;con RA2 a 0 y el resto a 1
    movf 	UNIDADES,W     	;CARGAR LAS DECENAS DE SEGUNDO
    call  	TABLA_U     	;y se llama al subprograma que controla los 7 diodos led
    MOVWF PORTD ;VALOR
    BSF PORTD,7
    CALL ESPERA
    movlw 	b'11110111'     ;Activamos el display de la derecha con
    movwf 	PORTA          	;el bit RA3 a 0 y el resto a 1
    movf 	MILESIMAS,W     	;CARGAR LAS DECENAS DE SEGUNDO
    call  	TABLA_U     	;y se llama al subprograma que controla los 7 diodos led
    MOVWF PORTD ;VALOR
;-----------------------------1 PARTE MOSTRAR VALOR ---------------------------------
    MOVF ESTADO,W
    ADDWF PCL,F
    GOTO ESTADO_0 ;RESETEADO
    GOTO ESTADO_1 ;PARADO
    GOTO ESTADO_2 ;CUENTA
;_______________________________Estado 0 -> reseteado _______________________________
ESTADO_0
     BCF T1CON,TMR1ON	;
	BCF	T2CON,TMR2ON	; SE DESAHIBILITA CUENTA 
    BTFSC INTCON,INTF ; COMPROBAR BIT DE PARADO 
    GOTO SUMA_15 ;0 EN CASO DE QUE EXISTA FLAG 
    GOTO COMP_A
SUMA_15 
    MOVLW 0x05 ;CARGAR 
    ADDWF UNIDADES ;SUMAMOS EL VALOR 5 EN SEGUNDOS 
    CALL COMP_UNI ;COMPROBAMOS QUE NO NOS HEMOS PASADO DE 10; 
    INCF DECENAS ;AÑADIMOS 1 EN DECENAS CREANDO ASI EL 15 ;
    CALL COMP_DEC ;POR ULTIMO REVISAMOS QUE NO HAYAMOS PASADO A MINUTOS PORQUE DESBORDO LAS DECENAS
    BCF INTCON,INTF ;QUITAMOS EL FLAG ;
COMP_A 
    BTFSS PORTA,4 ;ESTA EL PUERTO A PULSADO
    GOTO FIN_A  ;0 SE PULSO PRA4
    BTFSS ANTESA,4 ;1- SIGUE SIN PULSAR
    GOTO FIN_A  ;
    GOTO BUCLE ;MISMO ESTAD
FIN_A MOVLW 0x02;CARGAMOS 2 EN W 
    MOVWF ESTADO ;CARGAMOS EL ESTADO CONTANDO ->2 
    GOTO BUCLE ;FINALMENTE REGRESAMOS AL BUCLE
;__________________________________ESTADO 1 -> PARADO ______________________________
ESTADO_1 MOVLW 
    MOVWF RE_E1 ;ASIGNAR EL VALOR A 2s
    bcf	T1CON,TMR1ON	;Si estamos en el estado 2, TMR1 parado 
;_____________________________ ZONA PARA LA PARTE DE LAS LLAMADAS____________________
ESPERA	MOVLW	d'217'		;precargamos el valor de TMR0
	MOVWF 	TMR0		;para que desborde tras 5ms
    BCF	INTCON,T0IF	;Se pone a cero el flag de TMR0
DESBORDO_T0
    btfss	INTCON,T0IF	;Comprobamos si el flag se puso a 1
	goto	DESBORDO_T0	;si no se puso a 1, seguimos esperando

    movlw 0xFF		;Apagamos todos los segmentos
	movwf PORTD		;para establecer un tiempo muerto antes de cambiar
	return			;Si ya se puso a 1, retornamos (pasaron ya 5 ms)
COMP_UNI MOVWF 0x0A  ;CARGAMOS EN W EL VALOR 10
    XORWF UNIDADES,W ;COMPROBAMOS EL VALOR Y GUARDAMOS EN W
    BTFSS STATUS,Z ;COMPROBAMOS ESTADO DE Z
    RETURN  ; 0- NO NOS HEMOS PASADO DE 10
    INCF DECENAS ; AÑADIMOS 1 A LAS DECENAS EN CASO DE PASARNOS 
    RETURN
COMP_DEC MOVWF 0x0A  ;CARGAMOS EN W EL VALOR 10
    XORWF DECENAS,W ;COMPROBAMOS EL VALOR Y GUARDAMOS EN W
    BTFSS STATUS,Z ;COMPROBAMOS ESTADO DE Z
    RETURN  ; 0- NO NOS HEMOS PASADO DE 10
    INCF MINUTOS ; AÑADIMOS 1 A LAS DECENAS EN CASO DE PASARNOS 
    RETURN

