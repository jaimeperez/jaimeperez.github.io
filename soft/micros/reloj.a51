;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Practica 2 de la asignatura de;
; microprocesadores 2003/2004  ;
;Autores:                      ;
; Jaime Perez Crespo           ;
; Ruben Seijas Valverde        ;
;Ultima modificacion: 8-12-03  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NAME	RELOJ

;Definicion de retorno de carro y nueva linea (CR y LF)
CR	EQU	0DH		; Carriage Return
LF	EQU	0AH		; Line Feed

PROG 	SEGMENT	CODE
STACK	SEGMENT	IDATA

	RSEG	STACK
	DS	10H		; 16 bytes de pila

	CSEG	AT	0
	USING	0		; Banco 0 de registros

	ORG	03H
	LJMP 	PULSACION	; Rutina de la interrucion de pulso del boton

	ORG 	0BH
	LJMP	DESBORD		; Rutina de la interrupcion de desbordamiento del timer

;Tras reset se comienza a ejecutar sobre la direccion 0
	ORG 	0H
	JMP	START		; Saltamos al comienzo del programa
	RSEG	PROG





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina que escribe un caracter en el puerto serie;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;El caracter esta almacenado en A
PUTCHAR:
	CLR	TI		; TI = 0
	MOV	SBUF,A		; Enviamos el caracter
	JNB	TI,$		; Si TI == 0 entonces linea ocupada,esperamos a TI == 1
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina que lee un caracter por el puerto serie;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; El caracter leido se almacena en A
GETCHAR:	
	JNB	RI,$		; Si RI==0 entonces no se ha recibido,esperamos a RI==1
	MOV	A,SBUF		; Leemos el caracter por el puerto
	CLR	RI
	; Como mon51 envia 11H de vez en cuando lo ignoramos
	MOV	B,A		; Salvaguardamos A
	ADD	A,#-11H		; Restamos 11H a A
	JZ	GETCHAR		; Si es cero leemos otro caracter
	MOV	A,B		; Recuperamos A desde B
	RET


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina que escribe una cadena por el puerto serie;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Escribe la cadena apuntada en DPTR, y MODIFICA dicho puntero
PUTSTRING:
	CLR	A
	MOVC	A,@A+DPTR	; Lee del segmento de codigo
	JZ	EXIT		; Sale si el caracter es 00H
	CALL	PUTCHAR		; Escribimos el caracter
	INC	DPTR		; Incrementamos el contador
	SJMP	PUTSTRING
EXIT:	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina que escribe un caracter ':' por el puerto serie;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PUTSEPARATOR:
	MOV	A,#58D		; Cargamos un : en A
	CALL	PUTCHAR		; Lo escribimos
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina que obtiene la equivalencia entre digitos ASCII y numeros;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; #'0' == #48D, ... , #'9' == #57D
CONVERT:
	MOV	B,A		; Guardamos A en B
	CJNE	A,#48D,UNO	;Si es X,no saltamos,ponemos X en A.Si no,saltamos a X+1
	MOV	A,#00D
UNO:	CJNE	A,#49D,DOS
	MOV	A,#01D
DOS:	CJNE	A,#50D,TRES
	MOV	A,#02D
TRES:	CJNE	A,#51D,CUATRO
	MOV	A,#03D
CUATRO:	CJNE	A,#52D,CINCO
	MOV	A,#04D
CINCO:	CJNE	A,#53D,SEIS
	MOV	A,#05D
SEIS:	CJNE	A,#54D,SIETE
	MOV	A,#06D
SIETE:	CJNE	A,#55D,OCHO
	MOV	A,#07D
OCHO:	CJNE	A,#56D,NUEVE
	MOV	A,#08D
NUEVE:	CJNE	A,#57D,FAIL	;Si no es 9,comprobamos si fue alguno de los anteriores
	MOV	A,#09D
FAIL:	CJNE	A,B,OK		; Si A es distinto de B, se encontro un digito
        MOV	B,#10D		; Si no es un digito, B == 10D
	JMP	OK2		; Salimos directamente
OK:	MOV	B,A		; Devolvemos el digito en A y B
OK2:	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina que pasa de numerico a ASCII;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Soporta un numero de dos digitos almacenado en A.
; El primer digito se guarda en A, el segundo en B.
GETASCII:
	MOV	R0,A		; Guardamos el numero en R0
	MOV	B,#10D		; Cargamos 10 en B
	DIV	AB		; Dividimos el numero por 10
	MOV	B,A		; Guardamos en B una copia de las decenas
	ADD	A,#48D		; Le sumamos #48 (ASCII '0') al primer digito
	MOV	R1,A		; Guardamos ese primer digito
	MOV	A,B		; Restauramos las decenas
	MOV	B,#10D		; Cargamos un 10 en B
	MUL	AB		; Obtenemos las decenas
	MOV	B,A		; Guardamos las decenas en B
	MOV	A,R0		; Restauramos el numero original en A
	SUBB	A,B		; Le restamos las decenas al original
	ADD	A,#48D		; Le sumamos #48 (ASCII '0') al segundo digito
	MOV	B,A		; Dejamos en B el segundo digito
	MOV	A,R1		; y en A el primero
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina que escribe la hora por el puerto serie;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Escribe la hora actual guardada de R4 a R6
PRINT_R:
	MOV	A,R4		; Cargamos las horas
	CALL	GETASCII	; Las convertimos a digitos
	CALL	PUTCHAR		; Escribimos el primer digito
	MOV	A,B
	CALL	PUTCHAR		; Escribimos el segundo digito
	CALL	PUTSEPARATOR	; Escribimos un :
	MOV	A,R5		; Cargamos los minutos
	CALL	GETASCII	; Los convertimos a digitos
	CALL	PUTCHAR		; Escribimos el primer digito
	MOV	A,B
	CALL	PUTCHAR		; Escribimos el segundo digito
	CALL	PUTSEPARATOR	; Escribimos un :
	MOV	A,R6		; Cargamos los segundos
	CALL	GETASCII	; Los convertimos a digitos
	CALL	PUTCHAR		; Escribimos el primer digito
	MOV	A,B
	CALL	PUTCHAR		; Escribimos el segundo digito
	RET


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina que escribe el cronometro por el puerto serie;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Escribe el instante actual guardado de R4 a R7
PRINT_C:
	CALL 	PRINT_R		; Escribimos la hora (h:m:s)
	MOV 	A,#'"'		; Escribimos "
	CALL 	PUTCHAR
	MOV	A,R7		; Cargamos las centesimas
	CALL	GETASCII	; Los convertimos a digitos
	CALL	PUTCHAR		; Escribimos el primer digito
	MOV	A,B
	CALL	PUTCHAR		; Escribimos el segundo digito
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina que configura el timer0 para que se desborde cada centesima;
;de segundo                                                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TIMECONF:
; Configuramos el Timer0:
	MOV	TMOD,#00000001B	; C/T = 0, Mode = 1
	MOV	TH0,#11011000B	; Configuramos el timer0 para que se desborde cada
	MOV	TL0,#11110000B	; centesima de segundo
	SETB	TR0		; Arrancamos el timer 0
	MOV	R6,#0D		; Segundos = 0
	MOV	R7,#0D		; Centesimas = 0
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina que habilita la interrupcion del timer 0 y el evento externo 0;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Escribe el instante actual guardado de R4 a R7
INTCONF:
	SETB	EX0   		; Habilitamos la interrupcion externa 0
	SETB	IT0		
	SETB	ET0		; Habilitamos la interrupcionde del timer 0
	SETB	EA
	RET


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina de inicializacion del timer0;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BLANK_TIMER:
	MOV	TH0,#11011000B	; Configuramos el timer0 para que se desborde cada
	MOV	TL0,#11110000B	; centesima de segundo
	RET

;Rutinas para manejo del reloj

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina para incremento de horas;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INCR_H:
	PUSH	B		; Guardamos B
	MOV	A,R4		; Guardamos el valor para operar
	ADD	A,#1D		; Incrementamos en 1 los segundos
	MOV	B,A		; Salvaguardamos el nuevo numero
	ADD	A,#-24D		; Le restamos 24
	CJNE	A,#0D,OK_H	; Si A == 0, reiniciamos cuenta
	MOV	B,#0D		; Reiniciamos las horas
OK_H:	MOV	R4,B		; Restauramos los horas
	POP	B		; Recuperamos B
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina para incremento de minutos;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INCR_M:
	PUSH	B		; Guardamos B
	MOV	A,R5		; Guardamos el valor para operar
	ADD	A,#1D		; Incrementamos en 1 los segundos
	MOV	B,A		; Salvaguardamos el nuevo numero
	ADD	A,#-60D		; Le restamos 60
	CJNE	A,#0D,OK_M	; Si A == 0, reiniciamos cuenta
	MOV	B,#0D		; Reiniciamos las centesimas
	CALL	INCR_H		; Incrementamos las horas
OK_M:	MOV	R5,B		; Restauramos los minutos
	POP	B		; Recuperamos B
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina para incremento de segundos;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INCR_S:
	PUSH	B		; Guardamos B
	MOV	A,R6		; Guardamos el valor para operar
	ADD	A,#1D		; Incrementamos en 1 los segundos
	MOV	B,A		; Salvaguardamos el nuevo numero
	ADD	A,#-60D		; Le restamos 60
	CJNE	A,#0D,OK_S	; Si A == 0, reiniciamos cuenta
	MOV	B,#0D		; Reiniciamos las centesimas
	CALL	INCR_M		; Incrementamos los minutos
OK_S:	MOV	R6,B		; Restauramos los segundos
	POP	B		; Recuperamos B
	RET


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina para incremento de centesimas de segundo;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INCR_C:
	PUSH	B		; Guardamos B
	MOV	A,R7		; Guardamos el valor para operar
	ADD	A,#1D		; Incrementamos en 1 las centesimas
	MOV	B,A		; Salvaguardamos el nuevo numero
	ADD	A,#-100D	; Le restamos 100
	CJNE	A,#0D,OK_C	; Si A == 0, reiniciamos cuenta
	MOV	B,#0D		; Reiniciamos las centesimas
	CALL	INCR_S		; Incrementamos los segundos
OK_C:	MOV	R7,B		; Restauramos las centesimas
	POP	B		; Recuperamos B
	RET



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina que trata las interrupciones del timer;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DESBORD:
	PUSH 	PSW		; metemos dentro de la pila la palabra de estado
	PUSH	DPH	
	PUSH	DPL
	MOV	B,A
	PUSH	B
	CLR	TF0
	CALL	BLANK_TIMER	; Reiniciamos el timer 0
	CALL	INCR_C		; Incrementamos centesimas
	MOV	A,R3		; Movemos las pulsaciones a A
	MOV 	B,#1H		; Comprobamos si estamos en modo Lapsus (una pulsacion)
	SUBB	A,B
	JZ	LAPSUS	        ; Si estamos en lapsus, no motramos el nuevo instante
	CALL	PRINT_C		; Escribimos el tiempo actual transcurrido
 	MOV	DPTR,#MSG9	; Iniciamos el cursor
	CALL	PUTSTRING
LAPSUS:	POP	B
	MOV	A,B
	POP	DPL
	POP	DPH
	POP	PSW		; sacamos de la pila la palabra de estado
	RETI


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina que trata las interrupciones del pulsador;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Incrementa en 1 el registro de numero de pulsaciones (R3)
PULSACION:
	PUSH 	PSW		; Metemos dentro de la pila la palabra de estado
	PUSH	DPH	
	PUSH	DPL
	MOV	B,A
	PUSH	B
 	MOV	A,R3		; Movemos el numero de pulsaciones a A	
	MOV 	B,#1H		; Movemos 1 al registro B
	ADD	A,B		; Sumamos 1 al numero de pulsaciones (R3)   
	MOV	R3,A		; Movemos el resultado a R3 
	POP	B
	MOV	A,B                                     
	POP	DPL
	POP	DPH
	POP	PSW		; Sacamos de la pila la palabra de estado
        RETI

;;;;;;;;;;;;;;;;;;;;;;;
;Comienzo del programa;
;;;;;;;;;;;;;;;;;;;;;;;
; Selecciona el modo adecuado de operacion del programa
START:
	MOV	SP,#STACK-1	; Inicializamos el registro SP

; Inicializamos el puerto serie
	MOV	SCON,#01010000B
	MOV	TMOD,#00100000B	; C/T = 0, Mode = 2
	MOV	TH1,#0F3H
	SETB	TR1
	SETB	TI

; Preguntamos el modo de operacion (reloj o cronometro)
REP1:
	MOV	DPTR,#MSG1	; Cargamos el mensaje en DPTR
	CALL	PUTSTRING	; Escribimos la cadena de texto
	CALL	GETCHAR		; Leemos el modo de operacion en A
	MOV	B,A		; Salvamos A en B
; Comprobamos si entramos en modo crono
	ADD	A,#-43H		; Comprobamos si el caracter es 'C'
	JZ	CRONO		; Si es 'C' saltamos a modo crono
	MOV	A,B		; Restauramos A
	ADD	A,#-63H		; Comprobamos si el caracter es 'c'
	JZ	CRONO		; Si es 'c' saltamos a modo crono
	MOV	A,B		; Restauramos A
; Comprobamos si entramos en modo reloj
	ADD	A,#-52H		; Comprobamos si el caracter es 'R'
	JZ	RELOJ		; Si es 'R' saltamos a modo reloj
	MOV	A,B		; Restauramos A
	ADD	A,#-72H		; Comprobamos si el caracter es 'r'
	JZ	RELOJ		; Si es 'r' saltamos a modo reloj
	MOV	A,B		; Restauramos A
; Si no es ninguna opcion de las anteriores volvemos a preguntar
	SJMP	REP1		; Si no indican una opcion valida, repetimos

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Rutina que simula el funcionamiento de un cronometro;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  R3 ->Numero de pulsaciones, R4 ->Horas, R5 ->Minutos, R6 ->Segundos, R7 ->Centesimas
CRONO:
	MOV	DPTR,#MSG3	; Cargamos el modo en DPTR
	CALL	PUTSTRING	; Lo escribimos
	CALL	INTCONF		; Habilitamos interrupciones
RESET:	CALL	TIMECONF	; Configuramos el timer
	MOV 	R3,#0H		; Pulsaciones = 0	
	MOV	R4,#0H		; Horas = 0
	MOV	R5,#0H		; Minutos = 0
CHECK:	
	MOV	B,R3	
	JB	B.1,STOP
	SJMP	CHECK    	; Si no estamos en el modo STOP seguimos esperando

STOP:
	CLR	TR0		; Paramos el Timer
	CALL	PRINT_C		; Mostramos el instante actual
	MOV	DPTR,#MSG9	; Iniciamos el carro
	CALL	PUTSTRING
WAIT:	MOV	B,R3	
	JB	B.0, RESET
        SJMP	WAIT            ; Si no estamos seguimos esperando


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Rutina que simula el funcionamiento de un reloj;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; R4 -> Horas, R5 -> Minutos, R6 -> Segundos, R7 -> Centesimas
RELOJ:
	MOV	DPTR,#MSG4	; Cargamos el modo en DPTR
	CALL	PUTSTRING	; Lo escribimos
; Pedimos al usuario que ponga el reloj en hora
; HORAS
REP2:
BACK1:	MOV	DPTR,#MSG5	; Cargamos el mensaje en DPTR
	CALL	PUTSTRING
	CALL	GETCHAR		; Leemos el primer numero
	MOV	R3,A		; Guardamos el caracter
	CALL	CONVERT		; Lo convertimos a numero
	MOV	R2,B		; Cargamos en R2 el resultado de la conversion
	CJNE	R2,#10D,D1OK	; Si no es un digito, volvemos a pedirlo
        SJMP	BACK1		
D1OK:	MOV	B,#10D		; Cargamos el 10 en B
	MUL	AB		; Multiplicamos el primer digito por 10
	MOV	R1,A		; Cargamos el primer digito en R1
	MOV	A,R3		; Cargamos el digito para escribirlo
	CALL	PUTCHAR		; Escribimos el digito leido

BACK2:	CALL	GETCHAR		; Leemos el segundo numero
	MOV	R3,A		; Guardamos el caracter
	CALL	CONVERT		; Lo convertimos a numero
	MOV	R2,A		; Cargamos en R2 el resultado de la conversion
	CJNE	R2,#10D,D2OK	
	SJMP	BACK1		; Si no es un digito, volvemos a pedirlo
D2OK:	
	MOV	A,R3		; Cargamos el digito para escribirlo
	CALL	PUTCHAR		; Escribimos el segundo digito de las horas
	MOV	DPTR,#MSG7	; Saltamos de linea
	CALL	PUTSTRING
	MOV	A,R2		; Restauramos el digito en A
	ADD	A,R1		; Sumamos ambas cantidades, hemos obtenido las horas
	MOV	B,A		; Salvaguardamos A en B
	ANL	A,#11100000B	; Aplicamos mascara para ver que el numero no sea muy grande
	CJNE	A,#0D,BACK1	; Si el resultado es 0 OK, sino releemos
	MOV	A,B		; Restauramos A desde B
	ANL	A,#00011000B	; Aplicamos mascara para comprobar que los dos bits no esten a 1 simultaneamente
	CJNE	A,#24D,SAVE_H   ; Si el resultado es 0 OK
	SJMP	BACK1		; No es correcto, releemos
SAVE_H:	MOV	R4,B		; Guardamos la hora valida en R4
;Si la hora es correcta, pasamos a leer los minutos	

; MINUTOS
REP3:
	MOV	DPTR,#MSG6	; Cargamos el mensaje en DPTR
	CALL	PUTSTRING
	CALL	GETCHAR		; Leemos el primer numero
	MOV	R0,A		; Guardamos el caracter
	CALL	CONVERT		; Lo convertimos a numero
	MOV	R2,B		; Cargamos en R2 el resultado de la conversion
	CJNE	R2,#10D,D3OK	; Si no es un digito, volvemos a pedirlo
	SJMP	REP3
D3OK:	MOV	B,#10D		; Cargamos el 10 en B
	MUL	AB		; Multiplicamos el primer digito por 10
	MOV	R1,A		; Cargamos el primer digito en R1
	MOV	A,R0		; Cargamos el digito para escribirlo
	CALL	PUTCHAR		; Escribimos el digito leido

	CALL	GETCHAR		; Leemos el segundo numero
	MOV	R0,A		; Guardamos el caracter
	CALL	CONVERT		; Lo convertimos a numero
	MOV	R2,A		; Cargamos en R2 el resultado de la conversion
	CJNE	R2,#10D,D4OK	
	SJMP	REP3		; Si no es un digito, volvemos a pedirlo
D4OK:	
	MOV	A,R0		; Cargamos el digito para escribirlo
	CALL	PUTCHAR		; Escribimos el segundo digito de los minutos
	MOV	DPTR,#MSG7	; Saltamos de linea
	CALL	PUTSTRING
	MOV	A,R2		; Restauramos el digito en A
	ADD	A,R1		; Sumamos ambas cantidades, hemos obtenido los minutos
	MOV	B,A		; Salvaguardamos A en B
	ANL	A,#11000000B	; Aplicamos mascara para ver que el numero no sea muy grande
	CJNE	A,#0D,REP3      ; Si el resultado es 0 OK, sino releemos
	MOV	A,B		; Restauramos A desde B
	ANL	A,#00111100B	; Aplicamos mascara para comprobar que los cuatro bits no esten a 1 simultaneamente
	CJNE	A,#60D,SAVE_M	; Si el resultado es 0 OK	
	SJMP	REP3		; Si los minutos no son correctos, reintentamos
SAVE_M: MOV	R5,B		; Guardamos los minutos validos en R5
        CALL	TIMECONF	; Configuramos el timer
; Nos metemos en un bucle, comprobamos desbordamiento del timer
REP4:
	JNB	TF0,REP4	; Comprobamos desbordamiento en Timer0
	CLR	TF0
	CALL	BLANK_TIMER	; Reiniciamos el timer 0
	CALL	INCR_C		; Incrementamos centesimas
	MOV	DPTR,#MSG8	; Escribimos la cadena de texto inicial
	CALL	PUTSTRING
	CALL	PRINT_R		; Imprimimos el reloj
	MOV	DPTR,#MSG9	; Iniciamos el carro
	CALL	PUTSTRING
	SJMP	REP4	


MSG1:	DB	'¿MODO RELOJ O CRONOMETRO? (R/C):',CR,LF,00H
MSG2:	DB	'MODO: ',00H
MSG3:	DB	'MODO CRONOMETRO',CR,LF,00H
MSG4:	DB	'MODO RELOJ',CR,LF,00H
MSG5:	DB	'INDIQUE LA HORA (HH):',CR,LF,00H
MSG6:	DB	'INDIQUE LOS MINUTOS (MM):',CR,LF,00H
MSG7:	DB	CR,LF,00H
MSG8:	DB	'HORA: ',00H
MSG9:	DB	CR,00H

FIN:
	END
