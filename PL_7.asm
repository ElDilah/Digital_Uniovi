	list p=16f877A      	;Para microcontrolador PIC16f877
        include p16f877A.inc

        __CONFIG _XT_OSC & _WDT_OFF & _LVP_OFF

;Declaraci?n de variables auxiliares

Banco_0_RAM	EQU	0x20	; comienzo de RAM de prop?sito general en Banco 0 (PIC16f877A)

; Bloque de variables en RAM, usamos la directiva cblock

    cblock	Banco_0_RAM

		W_tmp		;almac?n temporal para el registro W
		STATUS_tmp	;almac?n temporal para el registro STATUS
		PCLATH_tmp	;almac?n temporal del registro PCLATH
    ; Almacenamos los d?gitos a mostrar en la medida de la tensi?n:
		BCD0		;(DECENAS:UNIDADES)
		BCD1		;(MILLARES:CENTENAS)
		BCD2		;(0:DECENAS DE MIL)
		BCD1_MAX
		BCD1_MIN
		BCD2_MAX
		BCD2_MIN
    ; D?gitos a mostrar en los displays, los emplea el subprograma de barrido
		DSP_H		; (0:D?gito izquierdo)
		DSP_L		; (D?gito centro: D?gito derecho)
    ;Posiciones necesarias para el subprograma que realiza el producto 
		FACTOR1		;Uno de los factores del producto
		FACTOR2		;Otro de los factores del subprograma producto
    ;Resultado del producto:
		BIN_ALTO	;Parte alta del valor medido en binario
		BIN_BAJO	;Parte baja del periodo en binario
    ;Otras posiciones para el producto:
		SUMA_ALTO	;Posici?n que almacena la parte alta de FACTOR1 desplazado a la izq.
		SUMA_BAJO	;almacenar? la parte baja de FACTOR1 desplazado a la izquierda
		CONTADOR	;Para el subprograma de multiplicaci?n, cuenta sumas parciales
		CAMBIO
		ADRESH_MAX
		ADRESH_MIN
		AUX		;Posici?n auxiliar
		TMP		;Otra posici?n auxiliar
	
	endc			;Fin del bloque de variables de usuario

        org 0            	;Posici?n tras RESET
        goto 	INICIO

        org 4	    		;Vector de interrupcion para las generadas
        goto 	PTI 		;por fin de conversi?n A/D
;******************************************************************************
;Subprograma para el control de los diodos led
;Recibe en los cuatro ?ltimos bits de W el d?gito a representar: del 0 al 9
;tambi?n podr?a ser un "blanco" (si se carga en W el valor A en hexadecimal)
;******************************************************************************
TABLALED
    	call  	TABLA		;Vamos a la tabla, volvemos trayendo en W valor 
        movwf 	PORTD		;a sacar por el Puerto D y lo sacamos
        return

;Tabla de b?squeda de los segmentos a activar para cada d?gito:

TABLA   addwf 	PCL,F       	;Suma del PC con el d?gito a representar (en W)
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

;******************************************************************************
; El programa principal empieza a partir de aqu?:
;******************************************************************************        
INICIO  movlw 	0xFF		;Carga inicial para el PORTA
	movwf 	PORTA		;Desactivamos displays (cuando RA1, RA2 y RA3 sean de salida)
	bsf 	STATUS,RP0    	;Pasamos al banco 1 de RAM
	movlw	b'00001110'	;Definimos l?nea RA0 como anal?gica, resto digitales
	movwf	ADCON1 		;conversi?n entre 0 y Vdd y resultado ajustado a la izq.
        clrf 	TRISD        	;Puerto D se programa como salida (segmentos)
	movlw 	b'11110001'	;Puerto A con 3 l?neas de salida, resto entradas
        movwf	TRISA        	;(RA1, RA2 y RA3 selecci?n de displays)
	MOVLW 0xFF
	movwf TRISB
	bsf	PIE1,ADIE	;Activamos m?scara de int. por fin de conversi?n
	  BSF PIE1,TMR1IE

	movlw	b'00000100'	;Usamos TMR0 para temporizaciones de 5ms en el barrido
	movwf	OPTION_REG	;con prescaler de 32, se precargar? TMR0 con d'100'

       	bcf 	STATUS,RP0    	;Volvemos al banco 0 de datos
	 MOVLW b'00110000'	;MOVER LA PRECONFIGURACION DE T1CON
	MOVWF T1CON	

	movlw	b'11000001'	;Configuramos AD con entrada por canal anal?gico 0 (RA0)
	movwf	ADCON0		;y reloj RC interno de conversi?n TAD=4us t?pico
	MOVWF 0x0B		;Precargamos la parte baja de TMR1: TMR1L
      movwf	TMR1L		;con 0x2C
      movlw	0xDC		;Precargamos la parte alta: TMR1H
      movwf	TMR1H		;con 0xCF CREANDO UNA CUENTA DE 500ms 
    

	bcf	PIR1,ADIF	;Pongo a 0 el flag de fin de conversi?n

	movlw	b'11000000'	;Activamos m?scara global y de perif?ricos
	movwf	INTCON		;para generar interrupciones

        clrf 	BCD2   		;Puesta a cero de unidades de voltio 
				;(antes del final de la primera conversi?n)
        clrf 	BCD1		;Puesta a cero de d?cimas y cent?simas de V
	bsf	T1CON,TMR1ON
	bsf	ADCON0,GO	;Lanzamos una primera conversi?n
	CLRF ADRESH_MAX
	MOVLW 0xFF
	MOVWF ADRESH_MIN    	;INICIACION DE ADRESH_MAX/MIN
;Bucle de ejecuci?n continuo
BUCLE
		BTFSS PORTA,4   ;comprubo si se esta pulsando o no
		  GOTO ESTADO_1 ; 0 "pulsado" 
		BTFSS PORTB,0    ;COMPROBAR ESTADO DE RP0
		  GOTO ESTADO_2
		GOTO ESTADO_0 ;RVALOR DIRECTO
ESTADO_0
	movf  BCD2,W		;Cargamos el resultado del ?ltimo c?lculo
        movwf   DSP_H		;primero la parte alta con el d?gito de voltios
        movf    BCD1,W		;y ahora la parte baja con las d?cimas
        movwf   DSP_L		;y las cent?simas
        call    BARRIDO_DSP	;Llamamos ahora al subprograma que realiza un barrido completo
	goto  	BUCLE
ESTADO_1
      BTFSS CAMBIO,0
	 GOTO MUESTRA_MAX
      GOTO SUP

MUESTRA_MAX  movf BCD2_MAX,W
	movwf BCD2
	MOVF BCD1_MAX,W 
	MOVWF BCD1
	CALL BARRIDO_DSP
	CALL ESPERA
    GOTO BUCLE
ESTADO_2
      BTFSS CAMBIO,0
	 GOTO MUESTRA_MAX
      GOTO INF 
MUESTRA_MIN
      movf BCD2_MIN,W
      movwf BCD2	
      MOVF BCD1_MIN,W 
      MOVWF BCD1
      CALL BARRIDO_DSP
      CALL ESPERA
      GOTO BUCLE
      
      
SUP 
	movlw 	b'11111101'	;Activamos el display de unidades de V
 	movwf 	PORTA		;con RA1 a cero
    MOVLW b'01101101'
    MOVWF PORTD
    CALL ESPERA 
    MOVLW 0xFF
    movwf PORTD
        movlw 	b'11111011'	;Activamos el display de d?cimas de V
 	movwf 	PORTA
    movlw b'00111110'
    movwf PORTD
    call ESPERA
    movlw 0xFF
    movwf PORTD
	     movlw 	b'11110111'     ;Activamos el display de cent?simas de V con
    movwf 	PORTA    
    MOVLW b'01110011'
    movwf PORTD
    call ESPERA
    movlw 0xFF
    movwf PORTD
    RETURN
INF 
movlw 	b'11111101'	;Activamos el display de unidades de V
 	movwf 	PORTA		;con RA1 a cero
    MOVLW b'00000110'
    MOVWF PORTD
    CALL ESPERA 
    MOVLW 0xFF
    movwf PORTD
     movlw 	b'11111011'	;Activamos el display de d?cimas de V
 	movwf 	PORTA
    movlw b'01010100'
    movwf PORTD
    call ESPERA
    movlw 0xFF
    MOVWF PORTD
    movlw b'11110111'     ;Activamos el display de cent?simas de V con
    movwf PORTA   
    MOVLW b'01110011'
    movwf PORTD
    call ESPERA
    movlw 0xFF
   movwf PORTD
    RETURN  

;******************************************************************************
;*	Subprograma de Espera de 5ms (aprox.), 
;*	empleamos el TMR0, definido con un prescaler de 32:
;*  5ms = 4/4MHz*32*(256-100) -> Precarga de 100
;******************************************************************************
ESPERA	movlw	d'100'		;cargamos el registro TMR0
	movwf	TMR0		;con la precarga de d'100'
	bcf	INTCON,T0IF	;Ponemos a 0 el flag de desbordamiento
LAZO_1	btfss	INTCON,T0IF	;Exploramos estado del flag
	goto 	LAZO_1		;si no desbord?, seguimos esperando
	return			;si ya desbord?, retornamos (ya van 5ms)
;Final del subprograma de espera
  
;**********************************************************************************
;*	Programa de tratamiento de la interrupci?n generada por fin de conversi?n *
;*	el resultado se recoger? en ADRESH (8 bits altos del resultado)		  *
;**********************************************************************************
PTI
	movwf 	W_tmp       	;Salvamos el registro W
        swapf 	STATUS,W    	;el registro STATUS "girado" en W
	bcf	STATUS,RP0	;Aseguramos el paso al banco 0
	bcf	STATUS,RP1	;cargando RP1 y RP0	
        movwf 	STATUS_tmp  	;Guardamos en el banco 0 STATUS "girado"
	movf	PCLATH,W	;Salvamos tambi?n PCLATH
	movwf	PCLATH_tmp	
	
        BTFSC PIR1,ADIF 	;Si entramos aqu? por otro motivo (por error)
	GOTO NUEVO_VAL
	BTFSC PIR1,TMR1IF
	GOTO INT_T1
	RETFIE
INT_T1
      MOVWF 0x0B		;Precargamos la parte baja de TMR1: TMR1L
      movwf	TMR1L		;con 0x2C
      movlw	0xDC		;Precargamos la parte alta: TMR1H
      movwf	TMR1H		;con 0xCF CREANDO UNA CUENTA DE 500ms 
      incf CAMBIO               ;VARIABLE QUE CUENTA 0,5MS 
      BCF PIR1,TMR1IF  
      GOTO RECUPERA

NUEVO_VAL
	movf	ADRESH,W	;Cargamos el resultado en W
	movwf	FACTOR1		;y se lo pasamos a uno de los factores
	
	movlw	d'195'		;Cargamos d'195' en el otro factor
	movwf	FACTOR2		;que es una constante de multiplicaci?n

	call	PRODUCTO_2	;Llamamos al subprograma de multiplicaci?n
				;y retornamos trayendo en BIN_ALTO - BIN_BAJO
				;el valor en binario del producto
	call	BINBCD		;Llamamos al subprograma de descomposici?n en d?gitos BCD
	CALL COMPROBAR_MAXMIN
	bcf	PIR1,ADIF	;ponemos a cero el flag para la sig. interrupci?n
	bsf	ADCON0,GO	;Lanzamos siguiente conversi?n AD (no modifica STATUS)
RECUPERA movf	PCLATH_tmp,W	;Recuperamos PCLATH
	movwf	PCLATH
	swapf 	STATUS_tmp,W 	;Recuperamos el registro STATUS con un SWAPF
        movwf 	STATUS
	swapf 	W_tmp,F		;Recuperamos tambi?n el W con dos SWAPF
	swapf 	W_tmp,W
;Para recuperar los registros salvados no podemos usar MOVF porque modifica a STATUS, 
;para evitarlo usamos la instrucci?n SWAPF

        retfie               	;Retorno del programa de tratamiento de
				;la interrupci?n
;***************************************************************************
; Subprograma de multiplicaci?n de dos bytes
;
; Recibe los valores en posiciones FACTOR1 y FACTOR2
; y entrega el resultado en dos bytes: BIN_ALTO & BIN_BAJO
;***************************************************************************
PRODUCTO_2
	clrf	BIN_ALTO	;Ponemos a cero el acumulador de
	clrf	BIN_BAJO	;los resultados (en 16 bits)
	movlw	0x08		;Cargamos 8 en el contador de operaciones
	movwf	CONTADOR	;de rotaci?n
	clrf	SUMA_ALTO	;Ponemos a cero parte alta del sumando que ir?
				;recogiendo FACTOR1 desplazado
	movf	FACTOR1,W	;Cargamos FACTOR1 en la parte baja de sumando
	movwf	SUMA_BAJO	;para efectuar rotaciones a izq. 
				;(multiplicar por 2 sucesivas veces FACTOR1)
A_SUMAR	rrf	FACTOR2		;Rotamos a la derecha para comprobar
	btfss	STATUS,C	;en el carry el valor del bit que "toque"
	goto	OTRO_BIT	;si el carry qued? a 0 es que no hay que sumar
	movf	SUMA_BAJO,W	;si qued? a 1 es que hay que sumar
	addwf	BIN_BAJO,F	;la parte baja del acumulador con el sumando
				;que corresponde al FACTOR1 desplazado a la izq.
	btfsc	STATUS,C	;comprobamos si hubo acarreo en esa suma
	incf	BIN_ALTO	;si hubo, sumamos 1 al siguiente byte
	movf	SUMA_ALTO,W	;sumamos la parte alta del acumulador con
	addwf	BIN_ALTO,F	;el FACTOR1 desplazado
OTRO_BIT	
	decfsz	CONTADOR,F	;Decrementamos el contador de operaciones parciales
	goto	A_ROTAR		;si no hemos llegado a cero, seguimos rotando
	return			;si ya hemos hecho 8 veces la operaci?n, retornamos

A_ROTAR	bcf	STATUS,C	;Para rotar FACTOR1 a la izquierda, ponemos a 0 el carry
	rlf	SUMA_BAJO,F	;rotamos encadenando la parte baja
	rlf	SUMA_ALTO,F	;con la parte alta
	goto	A_SUMAR		;y vamos a comprobar si es necesario sumar o no


COMPROBAR_MAXMIN
		movf ADRESH,W      
		subwf ADRESH_MAX	;RESTA DSPH DEL MAXIMMO
		BTFSC STATUS,Z 		;VERIFICAR ES ESTADO DE CARRY 
		GOTO MOVER_ALTO			;SI C ES 0 SIGNIFICA QUE ES MENOR 
		MOVF ADRESH,W
		SUBWF ADRESH_MIN
		BTFSS STATUS,C 	;ES IGUAL 
		GOTO MOVER_BAJO	;YA QUE ES MENOR 
		RETURN

	

MOVER_ALTO
		MOVF BCD2 ,W	
		MOVWF BCD2_MAX   
		MOVF BCD1,W
		MOVWF BCD1_MAX
		RETURN
MOVER_BAJO
		MOVF BCD2,W		;GUARDAR LOS NUEVOS VALORES DE MAXIMO Y MINIMO
		MOVWF BCD2_MIN   
		MOVF BCD1,W
		MOVWF BCD1_MIN 
		RETURN
;
;***************************************************************************
BINBCD  bcf     STATUS,C    	;Puesta a cero del carry
        movlw   d'16'           ;Cargamos 16 en el contador
        movwf   CONTADOR	;de operaciones
        clrf    BCD2            ;Puesta a cero
        clrf    BCD1            ;inicial de las posiciones
        clrf    BCD0            ;finales

DESPLAZAR 
	rlf     BIN_BAJO        ;Rotaci?n total
        rlf     BIN_ALTO        ;desde el byte bajo
        rlf     BCD0            ;hasta el byte m?s alto
        rlf     BCD1            ;de los datos finales
        rlf     BCD2            ;en BCD

        decfsz  CONTADOR        ;Si el contador es cero ya van 16 desplazamientos
        goto    AJUSTE         	;si no, seguimos con el ajuste a BCD
        return                	;si ya van 16 desplazamientos retornamos

AJUSTE  movlw   BCD0            ;Empleamos direccionamiento indirecto
        movwf   FSR             ;para llamar al subprograma de ajuste
        call    AJBCD           ;decimal de cada byte, primero con BCD0

        movlw   BCD1            ;Lo mismo con BCD1
        movwf   FSR		;le pasamos la direcci?n a FSR
        call	AJBCD		;y llamamos al ajuste

        movlw   BCD2            ;Y lo mismo con BCD2
        movwf   FSR		;cargando su direcci?n en FSR
        call    AJBCD		;llamamos al ajuste a BCD

        goto    DESPLAZAR       ;Volvemos a las rotaciones

;***************************************************************************
; Subprograma para ajuste BCD de cada byte previo a un desplazamiento
;***************************************************************************
AJBCD   movlw   3               ;Sumamos 3 a la posici?n a la que apunta FSR
        addwf   INDF,W          ;el contenido queda en W

        movwf   TMP             ;Exploramos si en el primer d?gito el 
        btfsc   TMP,3           ;resultado es mayor que 7
        movwf   INDF            ;si es as? corregimos almacenando ese valor

        movlw   0x30            ;Hacemos lo mismo con el d?gito BCD superior
        addwf   INDF,W          ;sum?ndole 3 al nibble alto

        movwf   TMP             ;Exploramos sumando 30 al byte completo
        btfsc   TMP,7           ;y si el d?gito superios es mayor que 7
        movwf   INDF            ;lo almacenamos para corregir

        return               	;Retorno desde el subprograma AJBCD
;***************************************************************************
;   Subprograma que realiza un barrido completo de los displays
;
;   Recoge los d?gitos a mostrar de las posiciones DSP_H y DSP_L
;	------------------------------------
; DSP_H |     0000      | D?gito izquierdo  |
;	------------------------------------
; DSP_L | D?gito Centro | D?gito Derecho    |
;	------------------------------------
;****************************************************************************
BARRIDO_DSP			;Entramos en el subprograma de barrido de displays
	movlw 	b'11110111'     ;Activamos el display de cent?simas de V con
    	movwf 	PORTA          	;el bit RA3 a cero y el resto a uno

        movlw 	0x0F           	;Extraemos las cent?simas de voltio a representar
        andwf 	DSP_L,W     	;se cargan en W y se llama al subprograma
        call  	TABLALED       	;que controla los 7 diodos led

        call  	ESPERA         	;Esperaremos durante 5 mseg

	movlw 	0xFF		;Anulamos todos los segmentos (t.muerto)
	movwf	PORTD		;antes de buscar el siguiente d?gito

	movlw 	b'11111011'	;Activamos el display de d?cimas de V
 	movwf 	PORTA		;con RA2 a cero

        movlw 	0xF0           	;Extraemos las d?cimas de V a representar
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
        call  	TABLALED       	;buscamos en la tabla la activaci?n de los segmentos

        bcf	PORTD,7		;Como son unidades de V, activamos el punto decimal

        call  	ESPERA         	;Esperaremos durante 5 mseg

	movlw 	0xFF		;Anulamos todos los segmentos
	movwf	PORTD		;nuevo t.muerto
        return                  ;Retorno del subprograma de barrido de displays
;*********************************************************************************
	END                  	;fin del fichero
