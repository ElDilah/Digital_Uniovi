 ;JUEGO DE LUCES
    LIST P=16F877A ; LISTA DE PROGRAMACION 
    INCLUDE P16F877A.INC
    __CONFIG _XT_OSC & _WDT_OFF & _LVP_OFF
;ASIGNACION
    CUENTA EQU 0x20
    TIEMPO EQU 0x21
    ESTADO EQU 0x22
    ANTES_A EQU 0x23
    ANTES_B EQU 0x24
    EFECTO EQU 0x25
    RECUENTO EQU 0x26

;INICIALIZACION

   org 0
   BSF STATUS,RP0  ;CAMBIO A BANCO 1 
    MOVLW 0x01      ;GRABADO DE 1 PARA ASIGNAR PORTC,0 COMO LECTURA 
    MOVWF TRISB     ;ASIGNACION DE PUERTOC COMO ESCRITURA /LECTURA
    BCF TRISA,2 
    MOVLW B'00000111';PRECARGA DE OPTION REG
    MOVwF OPTION_REG ;CONFIGURACION DE PRESCALER 
    CLRF TRISD      ;PONE TODO PORT D COMO SALIDA
   BCF STATUS,RP0  ;VUELTA AL BANCO 0
   BCF PORTA,2
    MOVLW 0x05      ; CARGA EL VALOR 5
    MOVWF TIEMPO    ; LO PONE EN CUENTA 
    CLRF ESTADO     ;BORRADO DE VALOR RESIDUAL EN ESTADO
    CLRF CUENTA     ;BORRADO DE ESTADO POR RESIDUO
    CLRF ANTES_A    ;"EN ANTES A"
    CLRF ANTES_B    ;"EN ANTES B"
    CLRF PORTC
    CLRF PORTB
    CLRF EFECTO
;BUCLE
BUCLE 
    MOVF PORTA,W ;COPIA DEL PUERTO A
    MOVWF ANTES_A  ;GUARDADO EN ANTES A
    MOVF PORTB,W ;COPIA DEL PUERTO B 
    MOVWF ANTES_B  ;GUARDADO EN ANTES B
    CALL TEMPORIZAR 
    MOVF EFECTO,W 
    GOTO  MOSTRAR ; CARGAMOS EL EFECTO
    
    
MOSTRAR ADDWF PCL,F  ;SELECCION DE EFECTO 
    GOTO EFECTO_0   ;IR A EFECTO 1 
    GOTO EFECTO_1   ;IR A EFECTO 2 
    GOTO EFECTO_2   ;IR A EFECTO 3
    CLRF EFECTO     ; EN CASO DE UNA 4 PULSACION PASAMOS A EFECTO 0
    GOTO EFECTO_0   ;IR A EFECTO 1
COMUN BTFSC PORTA,4 ;REVISO PUERTO A 
      GOTO COMP_B    ;SI NO SE CUMPLE 
      BTFSC ANTES_A,0 ;REVISAMOS SI ANTES ESTABA EN 0 ANTESA
      GOTO COMP_B    ;ERA EL MISMO ESTADO 
      INCF EFECTO 
COMP_B BTFSC PORTB,0 ; COMPROBAMOS EL PUERTOB
      GOTO BUCLE     ;SE VA AL INICIO
       BTFSS ANTES_B,0 ;ESTADO ANTERIOR IGUAL ?
       GOTO BUCLE
       INCF TIEMPO    ; INCREMENTO TIEMPO SI SE HA PULSAO 
       GOTO BUCLE     ;VOLVEMOS AL BUCLE
      
;TEMPORIZACION DE 0,1 X TIEMPO CON TMR0
TEMPORIZAR MOVF TIEMPO,W    ;CARGA DE CUENTA DE TIEMPO EN W 
    CALL TABLA  ; PONEMOS EL NUMERO EN EL 7SEG
    MOVWF PORTD ; MUESTRA EL NUMERO   
    MOVF TIEMPO,W ;PASO TIEMPO A W
    MOVWF RECUENTO ;Y W A RECUENTO PARA MULTIPLICAR 0,1 x tiempo
RECARGA MOVLW 0x02 ;precarga de 1ms
 MOVWF CUENTA   ; CARGA EN CUENTA DE TIEMPO 
 PRECARGA   MOVLW D'61'     ;   AJUSTE DE PRECARGA 
    MOVWF TMR0      ; ESTABLECER PRECARGA 
    BCF INTCON,T0IF ; RESETEO DE FLAG 
ESPERA BTFSS INTCON,T0IF    ; COMPROBACION DE FLAG 
    GOTO ESPERA     ; SI TODAVIA NO DESBORDO VOLVEMOS A COMPROBAR
    DECFSZ CUENTA,F ; CUANDO LLEGA A 0 LA CUENTA VUELVE 
    GOTO PRECARGA   ; SI NO VUELVE A PRECARGAR EL TIEMPO Y VUELVE A CONTAR
    DECFSZ RECUENTO,
    GOTO RECARGA ;EN CASO DE QUE NO SE HAYA 
    RETURN
EFECTO_0 INCF ESTADO 
   MOVF ESTADO,W
   CALL TAB_1 ;TABLA DEL PRIMER EFECTO
   MOVWF PORTB ;MOVEMOS EL CODIGO OBTENIDO A PORT D
   GOTO COMUN ;PONER PUNTO COMUN

EFECTO_1 INCF ESTADO
   MOVF ESTADO,W ;
   CALL TAB_3	;TABLA DEL SEGUNDO EFECTO
   MOVWF PORTB	;MOSTRAR 
   GOTO COMUN	;TRASLADAR A COMUN
EFECTO_2 INCF ESTADO
   MOVF ESTADO,W ;
   CALL TAB_2	;TABLA DEL SEGUNDO EFECTO
   MOVWF PORTB	;MOSTRAR 
   GOTO COMUN	;TRASLADAR A COMUN
TAB_1 ADDWF PCL,F 
   RETLW B'00000000'  ;APAGADO
   RETLW B'00001110' ;ENCENDIDO
   CLRF ESTADO	     ;EN CASO DE ESTADO 3 COMO NO EXISTE SE RESETEA
   RETLW B'00000000'  ;APAGADO
TAB_2 ADDWF PCL,F 
   RETLW B'00000010'  ;1 POSICION
   RETLW B'00000100' ;2 POSICION
   RETLW B'00001000' ;3 POSICION
   CLRF ESTADO	     ;EN CASO DE ESTADO 4 COMO NO EXISTE SE RESETEA
   RETLW B'00000010'  ;1 POSICION
TAB_3 ADDWF PCL,F 
   RETLW B'00001000'  ;1 POS
   RETLW B'00000100' ;2 POS
   RETLW B'00000010' ;3 POS
   CLRF ESTADO	     ;EN CASO DE ESTADO 4 COMO NO EXISTE SE RESETEA
   RETLW B'00001000'  ;1 POS
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
MOVLW 0x01 ; CARGAMOS 1 EN W
MOVWF TIEMPO ;ponemos a 1 DE NUEVO TIEMPO
RETLW B'11111001' ;"1"
END