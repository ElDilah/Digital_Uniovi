;voltimetro
 LIST P=16F877A ; LISTA DE PROGRAMACION 
    INCLUDE P16F877A.INC
    __CONFIG _XT_OSC & _WDT_OFF & _LVP_OFF
    ORG 0x0
         GOTO INICIO
    ORG 0x4 
        GOTO INTERRUPCIONES 
    cblock 0x20
         VOLTIOS
         DECIMAS
         MILESIMAS 
         ESTADO 
         DESBORDO_T2 
         ;GUARDADO DE VALOR 
          MAX_VAL
          MIN_VAL
     ;producto
          SUMA_ALTO	;
		SUMA_BAJO	;
		CONTADOR
          AUX 
          TPM 
        ;GUARDADO DE CONTEXTO
         W_TMP  
         STATUS_TMP 
         PCLATH_TMP 
    ENDC 

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