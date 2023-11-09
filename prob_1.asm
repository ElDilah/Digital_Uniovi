    CUENTA EQU 0x20
    LIST P=16F877A ; LISTA DE PROGRAMACION 
    INCLUDE P16F877A.INC
    __CONFIG _XT_OSC & _WDT_OFF & _LVP_OFF
;config
    ORG 0x000
    BSF STATUS,RP0;TRISB ESTA EN BANCO 1 
    CLRF TRISB ; TRISB TODO A 0 -> PORTB SALIDA 
    BCF STATUS,RP0 ;VUELVO A BANCO 0
    CLRF CUENTA     ;PONER A 0 CUENTA
MIRA    BTFSS PORTA,4   ;comprubo si se esta pulsando o no
        GOTO    INCREMETNAR ; 0 "pulsado"
        GOTO    MIRA    ;1 "no pulsado"
INCREMETNAR   INCF CUENTA   ;incrementa cuenta
    MOVF CUENTA,W
    MOVWF   PORTB   ; saca por el puerto B
NOSOLTO BTFSS PORTA,4   
    GOTO NOSOLTO    ; 0 = sigue pulsado
    GOTO MIRA   ; 1 = ya solto
END
;PEUWB