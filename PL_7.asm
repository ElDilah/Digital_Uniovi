;voltimetro
 LIST P=16F877A ; LISTA DE PROGRAMACION 
    INCLUDE P16F877A.INC
    __CONFIG _XT_OSC & _WDT_OFF & _LVP_OFF
    ORG 0x0
         GOTO INICIO
    ORG 0x4 
        GOTO INTERRUPCIONES 
     cblock	0x20
		ESTADO
		W_tmp		;almac�n temporal para el registro W
		STATUS_tmp	;almac�n temporal para el registro STATUS
		PCLATH_tmp	;almac�n temporal del registro PCLATH
    ; Almacenamos los d�gitos a mostrar en la medida de la tensi�n:
		BCD0		;(DECENAS:UNIDADES)
		BCD1		;(MILLARES:CENTENAS)
		BCD2		;(0:DECENAS DE MIL)
		BCD0_MIN		;(DECENAS:UNIDADES)
		BCD1_MIN		;(MILLARES:CENTENAS)
		BCD2_MIN		;(0:DECENAS DE MIL)
		BCD0_MAX		;(DECENAS:UNIDADES)
		BCD1_MAX		;(MILLARES:CENTENAS)
		BCD2_MAX		;(0:DECENAS DE MIL)Ç
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
BUCLE MOVF ESTADO,W
    ADDWF PCL,F
    GOTO ESTADO_0 ;RVALOR DIRECTO
    GOTO ESTADO_1 ;PMINIMO
    GOTO ESTADO_2	;MAXIMO 
ESTADO_0
	  movf    BCD2,W		;Cargamos el resultado del �ltimo c�lculo
        movwf   DSP_H		;primero la parte alta con el d�gito de voltios
        movf    BCD1,W		;y ahora la parte baja con las d�cimas
        movwf   DSP_L		;y las cent�simas
        call    BARRIDO_DSP	;Llamamos ahora al subprograma que realiza un barrido completo
	goto  	BUCLE

ESPERA	movlw	d'100'		;cargamos el registro TMR0
	movwf	TMR0		;con la precarga de d'100'
	bcf	INTCON,T0IF	;Ponemos a 0 el flag de desbordamiento
LAZO_1	btfss	INTCON,T0IF	;Exploramos estado del flag
	goto 	LAZO_1		;si no desbord�, seguimos esperando
	return	
BARRIDO_DSP			;Entramos en el subprograma de barrido de displays
	movlw 	b'11110111'     ;Activamos el display de cent�simas de V con
    	movwf 	PORTA          	;el bit RA3 a cero y el resto a uno

        movlw 	0x0F           	;Extraemos las cent�simas de voltio a representar
        andwf 	DSP_L,W     	;se cargan en W y se llama al subprograma
        call  	TABLALED       	;que controla los 7 diodos led

        call  	ESPERA         	;Esperaremos durante 5 mseg

	movlw 	0xFF		;Anulamos todos los segmentos (t.muerto)
	movwf	PORTD		;antes de buscar el siguiente d�gito

	movlw 	b'11111011'	;Activamos el display de d�cimas de V
 	movwf 	PORTA		;con RA2 a cero

        movlw 	0xF0           	;Extraemos las d�cimas de V a representar
        andwf 	DSP_L,W     	;y se cargan en W

        movwf 	AUX		;Para pasarlo a los 4 bits bajos
        swapf 	AUX,W		;usamos la variable AUX

        call  	TABLALED        ;llamada al programa de control de los led

        call  	ESPERA         	;Retenemos durante otros 5 mseg

	movlw 	0xFF		;Anulamos todos los segmentos
	movwf	PORTD		;con un nuevo tiempo muerto

	movlw 	b'11111101'	;Activamos el display de unidades de V
 	movwf 	PORTA		;con RA1 a cero

        movf 	DSP_H,W     	;se cargan las unidades de voltios en W y
        call  	TABLALED       	;buscamos en la tabla la activaci�n de los segmentos

        bcf	PORTD,7		;Como son unidades de V, activamos el punto decimal

        call  	ESPERA         	;Esperaremos durante 5 mseg

	movlw 	0xFF		;Anulamos todos los segmentos
	movwf	PORTD		;nuevo t.muerto
        return                  ;Retorno del subprograma de barrido de displays

INTERRUPCIONES 
		btfss 	PIR1,ADIF 	;Si entramos aqu� por otro motivo (por error)
        retfie              	;distinto a ADIF=1 salimos de inmediato

        movwf 	W_tmp       	;Salvamos el registro W
        swapf 	STATUS,W    	;el registro STATUS "girado" en W
	bcf	STATUS,RP0	;Aseguramos el paso al banco 0
	bcf	STATUS,RP1	;cargando RP1 y RP0	
        movwf 	STATUS_tmp  	;Guardamos en el banco 0 STATUS "girado"
	movf	PCLATH,W	;Salvamos tambi�n PCLATH
	movwf	PCLATH_tmp
;para salvarlos no podemos emplear la instrucci�n MOVF ya que afecta al registro STATUS,
;para evitarlo hemos empleado la instrucci�n SWAPF

	movf	ADRESH,W	;Cargamos el resultado en W
	movwf	FACTOR1		;y se lo pasamos a uno de los factores

	movlw	d'195'		;Cargamos d'195' en el otro factor
	movwf	FACTOR2		;que es una constante de multiplicaci�n

	call	PRODUCTO_2	;Llamamos al subprograma de multiplicaci�n
				;y retornamos trayendo en BIN_ALTO - BIN_BAJO
				;el valor en binario del producto
	call	BINBCD		;Llamamos al subprograma de descomposici�n en d�gitos BCD

	bcf	PIR1,ADIF	;ponemos a cero el flag para la sig. interrupci�n

	movf	PCLATH_tmp,W	;Recuperamos PCLATH
	movwf	PCLATH
	swapf 	STATUS_tmp,W 	;Recuperamos el registro STATUS con un SWAPF
        movwf 	STATUS
	swapf 	W_tmp,F		;Recuperamos tambi�n el W con dos SWAPF
	swapf 	W_tmp,W
;Para recuperar los registros salvados no podemos usar MOVF porque modifica a STATUS, 
;para evitarlo usamos la instrucci�n SWAPF
	bsf	ADCON0,GO	;Lanzamos siguiente conversi�n AD (no modifica STATUS)
        retfie 