;voltimetro
 LIST P=16F877A ; LISTA DE PROGRAMACION 
    INCLUDE P16F877A.INC
    __CONFIG _XT_OSC & _WDT_OFF & _LVP_OFF
    ORG 0x0
         GOTO INICIO
    ORG 0x4 
        GOTO INTERRUPCIONES 
    CBLOCK 0x20
         VOLTIOS
         DECIMAS
         MILESIMAS 
         ESTADO 
         DESBORDO_T2 
         ;GUARDADO DE VALOR 
         MAX_VAL
         MIN_VAL
        ;GUARDADO DE CONTEXTO
         W_TMP  
         STATUS_TMP 
         PCLATH_TMP 
    ENDC 