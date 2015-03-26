;Practica del dado electronico de la asignatura microprocesadores 2003-2004
;Jaime Perez Crespo
;Ruben Seijas Valverde
;ultima modificacion: 3/11/2003

        LIST    P=16F84
        INCLUDE "c:\simupic\P16F84.INC"  ;Libreria de registros del PIC
        RADIX   HEX

SEG	EQU	0x0C
NUM     EQU     0x0D

        ORG     0x00		;Direccion de comienzo del programa
	GOTO	INICIO
	ORG	0x04		;Captura de interrupciones
	GOTO	INTERR		;Salto a la rutina de tratamiento de interrupciones
	

INICIO:
        CLRF    SEG             ;Iniciamos la cuenta fracciones de segundo
        CLRF    NUM             ;Iniciamos el Numero a mostrar
        BSF     STATUS,RP0      ;Cambiamos al banco de memoria 1
        MOVLW   0xff
        MOVWF   TRISA           ;puerta A de entrada
        MOVLW   0x00
        MOVWF   TRISB           ;puerta B de salida
        MOVLW   b'00000111'	;cargamos los flags en OPTION
        MOVWF   OPTION_REG
        MOVLW   b'10100000'     ;Permitimos interrupciones en TMR0 y GIE
        MOVWF   INTCON
        BCF     STATUS,RP0      ;Cambiamos al banco de memoria 0
        MOVLW   b'00100110'     ;Cargamos 38 en el TMR0 (255 - 217)
        MOVFW   TMR0
        MOVLW   b'11111111'     ;Apagamos todos los leds del display
	MOVWF	PORTB


BUCLE:	
	BCF	STATUS,RP0	;Seleccionamos banco de memoria 0
        BTFSS   PORTA,0         ;Comprobamos si el pulsador esta accionado (RA0 = 0)
	CALL	GEN_NUM		;Pulsador accionado, generamos numero aleatorio
	GOTO	BUCLE		;No hay pulsacion, seguimos

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Generacion del numero aleatorio ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GEN_NUM:
	BSF	STATUS,RP0	;Seleccionamos banco de memoria 1
	MOVLW	b'00000000'	;Deshabilitamos interrupciones
	MOVWF	INTCON
	BCF	STATUS,RP0	;Seleccionamos banco de memoria 0
        MOVLW   b'10000000'     ;Encendemos todos los leds del display salvo el punto
	MOVWF	PORTB

PULS:	
	INCF	NUM,F		;Incrementamos el numero de tirada
        MOVF    NUM,W           ;Comprobamos si la tirada es superior a 6
        SUBLW   7               ;Restamos 7 a la tirada
        BTFSS   STATUS,Z        ;Comprobamos si la resta es 0
                                ;Si la resta anterior es 0, debemos poner a 1 la tirada, Z sera 1
	GOTO	COMP_PULS	;Tirada correcta, comprobamos el pulsador
	MOVLW	0x01		;Iniciamos a 1 la tirada
	MOVWF	NUM
	
COMP_PULS:
        BCF     STATUS,RP0      ;Seleccionamos banco de memoria 0
	BTFSC	PORTA,0		;Comprobamos RA0 para ver el estado del pulsador
	GOTO	NO_PULS		;No hay pulsacion, mostramos el numero
        GOTO    PULS            ;Pulsador accionado, seguimos generando el numero

NO_PULS:
	CALL 	MOSTRAR_NUM	;Mostramos el numero en el display
				;Numero mostrado, volvemos al bucle inicial
	BCF     STATUS,RP0      ;Cambiamos al banco de memoria 0
        MOVLW   b'00100110'     ;Cargamos 38 en el TMR0
        MOVFW   TMR0
	MOVLW	0x00		;Empezamos a contar un segundo de nuevo
	MOVWF	SEG
	MOVLW	0x00		;Reiniciamos la cuenta desde 0
	MOVWF	NUM
	MOVLW	b'10100000'	;Permitimos interrupcion de TMR0 y la global GIE
	MOVWF	INTCON		;Habilitamos de nuevo las interrupciones
	RETURN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Rutina para mostrar un numero en el display ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MOSTRAR_NUM:
        BCF     STATUS,RP0      ;Seleccionamos el banco 0

UNO:    MOVF    NUM,W           ;Comprobamos si NUM es 1
        SUBLW   1
        BTFSS   STATUS,Z
        GOTO    DOS             ;Si no es uno
        MOVLW   b'11111001'     ;Guardamos en W las secuencia de leds
                                ;necesaria para mostrar el numero
        GOTO    FIN

DOS:    MOVF    NUM,W           ;Comprobamos si NUM es 2
        SUBLW   2
        BTFSS   STATUS,Z
        GOTO    TRES            ;Si no es dos
        MOVLW   b'10100100'     ;Guardamos en W las secuencia de leds
                                ;necesaria para mostrar el numero
        GOTO    FIN

TRES:   MOVF    NUM,W           ;Comprobamos si NUM es 3
        SUBLW   3
        BTFSS   STATUS,Z
        GOTO    CUATRO          ;Si no es tres
        MOVLW   b'10110000'     ;Guardamos en W las secuencia de leds
                                ;necesaria para mostrar el numero
        GOTO    FIN

CUATRO: MOVF    NUM,W           ;Comprobamos si NUM es 4
        SUBLW   4
        BTFSS   STATUS,Z
        GOTO    CINCO           ;Si no es cuatro
        MOVLW   b'10011001'     ;Guardamos en W las secuencia de leds
                                ;necesaria para mostrar el numero
        GOTO    FIN

CINCO:  MOVF    NUM,W           ;Comprobamos si NUM es 5
        SUBLW   5
        BTFSS   STATUS,Z
        GOTO    SEIS            ;Si no es cinco
        MOVLW   b'10010010'     ;Guardamos en W las secuencia de leds
                                ;necesaria para mostrar el numero
        GOTO    FIN

SEIS:   MOVLW   b'10000010'     ;Si no es ninguno de los anteriores es 6

FIN:    MOVWF   PORTB           ;Activamos las patillas del puerto B
                                ;necesarias para mostras el NUM en el display
        RETURN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Rutinas de tratamiento de interrupciones ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

INTERR:
        BCF     STATUS,RP0      ;Seleccionamos el banco 0
        BTFSS   INTCON,T0IF     ;Comprobamos el desbordamiento del TMR0
        RETFIE                  ;Sino retornamos de la interrupcion
        INCF    SEG,F           ;Incrementamos el numero de desbordamientos
        MOVF    SEG,W           ;Comprobamos la fraccion de segundo
        SUBLW   d'18'           ;Le restamos 18
        BTFSS   STATUS,Z        
        GOTO    CONT            ;No ha transcurrido un segundo

UN_SEG: CLRF    SEG             ;Inicializamos SEG
        INCF    NUM,F           ;Incrementamos el numero a mostrar
        MOVF    NUM,W           ;Comprobamos si NUM es superior a 6
        SUBLW   7               ;Restamos 7 
        BTFSS   STATUS,Z        ;Comprobamos si la resta es 0
        GOTO    OK              ;No es superior a 6
        MOVLW   0x01            ;Si vale 7
        MOVWF   NUM             ;Inicializamos NUM a 1

OK:     CALL    MOSTRAR_NUM     ;Lo mostramos
CONT:   BCF     STATUS,Z        ;Seleccionamos el banco 0
        MOVLW   b'00100110'     ;Introducimos 38 en el TMR0
        MOVWF   TMR0
        MOVLW   b'10100000'     ;Activamos de nuevo las interrupciones
        MOVWF   INTCON
        RETFIE

        END
