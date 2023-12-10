;voltimetro
 LIST P=16F877A ; LISTA DE PROGRAMACION 
    INCLUDE P16F877A.INC
    __CONFIG _XT_OSC & _WDT_OFF & _LVP_OFF
    ORG 0x0
         GOTO INICIO
    ORG 0x4 
        GOTO INTERRUPCIONES 
     cblock	0x20

		W_tmp		;almac�n temporal para el registro W
		STATUS_tmp	;almac�n temporal para el registro STATUS
		PCLATH_tmp	;almac�n temporal del registro PCLATH
    ; Almacenamos los d�gitos a mostrar en la medida de la tensi�n:
		BCD0		;(DECENAS:UNIDADES)
		BCD1		;(MILLARES:CENTENAS)
		BCD2		;(0:DECENAS DE MIL)
    ; D�gitos a mostrar en los displays, los emplea el subprograma de barrido
		DSP_H		; (0:D�gito izquierdo)
		DSP_L		; (D�gito centro: D�gito derecho)
    ;Posiciones necesarias para el subprograma que realiza el producto 
		FACTOR1		;Uno de los factores del producto
		FACTOR2		;Otro de los factores del subprograma producto
    ;Resultado del producto:
		BIN_ALTO	;Parte alta del valor medido en binario
		BIN_BAJO	;Parte baja del periodo en binario
    ;Otras posiciones para el producto:
		SUMA_ALTO	;Posici�n que almacena la parte alta de FACTOR1 desplazado a la izq.
		SUMA_BAJO	;almacenar� la parte baja de FACTOR1 desplazado a la izquierda
		CONTADOR	;Para el subprograma de multiplicaci�n, cuenta sumas parciales

		AUX		;Posici�n auxiliar
		TMP		;Otra posici�n auxiliar
	
	endc
TABLALED
    	call  	TABLA		;Vamos a la tabla, volvemos trayendo en W valor 
        movwf 	PORTD		;a sacar por el Puerto D y lo sacamos
        return
TABLA   addwf 	PCL,F       	;Suma del PC con el d�gito a representar (en W)
	retlw 	0xC0          	;Para ver el cero, segmentos a mostrar
        retlw 	0xF9          	;el uno
        retlw 	0xA4          	;el dos
        retlw 	0xB0          	;el tres
        retlw 	0x99          	;el cuatro
        retlw 	0x92          	;el cinco
        retlw 	0x82          	;el seis
        retlw 	0xF8          	;el siete
        retlw 	0x80          	;el ocho
        retlw 	0x90          	;el nueve
        retlw 	0xFF          	;en blanco
;Final del subprograma de sacar los led
INICIO  movlw 	0xFF		;Carga inicial para el PORTA
	movwf 	PORTA		;Desactivamos displays (cuando RA1, RA2 y RA3 sean de salida)
	bsf 	STATUS,RP0    	;Pasamos al banco 1 de RAM
	movlw	b'00001110'	;Definimos l�nea RA0 como anal�gica, resto digitales
	movwf	ADCON1 		;conversi�n entre 0 y Vdd y resultado ajustado a la izq.
        clrf 	TRISD        	;Puerto D se programa como salida (segmentos)
	movlw 	b'11110001'	;Puerto A con 3 l�neas de salida, resto entradas
        movwf	TRISA        	;(RA1, RA2 y RA3 selecci�n de displays)

	bsf	PIE1,ADIE	;Activamos m�scara de int. por fin de conversi�n

	movlw	b'00000100'	;Usamos TMR0 para temporizaciones de 5ms en el barrido
	movwf	OPTION_REG	;con prescaler de 32, se precargar� TMR0 con d'100'

       	bcf 	STATUS,RP0    	;Volvemos al banco 0 de datos

	movlw	b'11000001'	;Configuramos AD con entrada por canal anal�gico 0 (RA0)
	movwf	ADCON0		;y reloj RC interno de conversi�n TAD=4us t�pico

	bcf	PIR1,ADIF	;Pongo a 0 el flag de fin de conversi�n

	movlw	b'11000000'	;Activamos m�scara global y de perif�ricos
	movwf	INTCON		;para generar interrupciones

        clrf 	BCD2   		;Puesta a cero de unidades de voltio 
				;(antes del final de la primera conversi�n)
        clrf 	BCD1		;Puesta a cero de d�cimas y cent�simas de V

	bsf	ADCON0,GO	;Lanzamos una primera conversi�n
BUCLE 