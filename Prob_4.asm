  
    CUENTA EQU 0x20
    LIST P=16F877A ; LISTA DE PROGRAMACION 
    INCLUDE P16F877A.INC
    __CONFIG _XT_OSC & _WDT_OFF & _LVP_OFF

    ;config 
     ORG 0x000
    BSF STATUS,RP0;TRISB ESTA EN BANCO 1 
    CLRF TRISD  ; poner trisD salida

        BCF PORTA,2;
    BCF STATUS,RP0 ; volver a banco 1 
    CLRF CUENTA ;PONER A 0 EL VALOR DE CONTABILIDAD
    MOVLW B'11000000' ;GRABAR EN W EL VALOR 0     
      aqMOVWF PORTD; PONER VALOR 0 EN PORTD
    ;bucle 
MIRA BTFSS PORTA,4 ;COMPROBAR PORT4
     GOTO    INCREMETNAR ; 0 "pulsado"
     BTFSS PORTB,0 ;COMPROBAR PORTB 0
     GOTO DECREMENTA ; PULSADO 
     GOTO    MIRA
DECREMENTA DECF CUENTA ;DECREMENTO CUENTA
    CALL REVISA
    CALL TABLA  ;TOMAMOS EL VALOR BINARIO
    MOVWF PORTD ; PASO EL VALOR A PORT D
    GOTO COMPROBARD ;COMPRUEBO SI SE DEJO DE PULSAR
INCREMETNAR INCF CUENTA ;INCREMENTO CUENTA
    MOVF CUENTA,W; PASO CUENTA A w
    call TABLA ;TOMAMOS EL VALOR BINARIO
    MOVWF PORTD ;PASO w A PORT D
    GOTO COMPROBARI; REVISO SI YA SE SOLTO EL PULSADOR
COMPROBARD BTFSS PORTB,0 ;COMPRUEBO EL PUERTO B
        GOTO COMPROBARD ; NO SOLTO
        GOTO MIRA; YA SOLTO
COMPROBARI BTFSS PORTA,4 ;COMPUERBO PUERTO A 
        GOTO COMPROBARI ;NO SOLTO
        GOTO MIRA ;YA SOLTO
REVISA MOVLW 0x0A ;PREGARGO 10 EN W 
     SUBWF CUENTA,W ;RESTAR CUENTA Y W
    BTFSS STATUS,Z ;REVISAR CERO Y BIT DE ACARREO
	RETLW B'10011000' ;COMPROBAR SI ES MAYOR A 9 Y PONE 9
	MOVF CUENTA,W ;PONGO CUENTA EN w
	
	; TABLA 
TABLA ADDWF PCL,F
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
CLRF CUENTA ;ponemos a 0 de nuevo
RETLW B'11000000' ;"0"
end
;otra prueba
