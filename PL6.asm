
;CRONOMETRO
;ASIGNACION
    UNIDADES EQU 0x20;
    DECENAS EQU 0x21
    CENTENAS EQU 0x22
    ESTADO EQU 0x23
    
;
    LIST P=16F877A ; LISTA DE PROGRAMACION 
    INCLUDE P16F877A.INC
    __CONFIG _XT_OSC & _WDT_OFF & _LVP_OFF
;INICIALIZACION
;BUCLE