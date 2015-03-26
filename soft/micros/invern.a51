;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Practica 4 de la asignatura de;
; microprocesadores 2003/2004  ;
;Autores:                      ;
; Jaime Perez Crespo           ;
; Ruben Seijas Valverde        ;
;Ultima modificacion: 28-01-04 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   

;|-------------------------------------------------------------------------|
;| Configuracion de las variables en los bancos de registros:              |
;|-------------------------------------------------------------------------|
;|      |  R0   |  R1   |  R2   |  R3   |  R4  |   R5  |   R6   |  R7      |
;|-------------------------------------------------------------------------|
;|banco0|       |       |       |       | Horas|Minutos|Segundos|Centesimas|
;|-------------------------------------------------------------------------|
;|banco1|       |       |       |!!!!!!!|!!!!!!|!!!!!!!|!!!!!!!!|!!!!!!!!!!|
;|-------------------------------------------------------------------------|
;|banco3|!!!!!!!|  Hon  |  Mon  | Hoff  | Moff | Temp  |  Tmin  | Tmax     |
;|-------------------------------------------------------------------------|
; NOTA: no usar los registros marcados con '!', son modificados en tiempo de ejecucion


NAME	INVERN

; Definicion de retorno de carro y nueva linea (CR y LF)
CR	EQU	0DH		; Carriage Return
LF	EQU	0AH		; Line Feed


P7	DATA	0DBh
P8	DATA	0DDh                
P4      DATA    0E8h
P5      DATA    0F8h
P6	DATA	0FAh

TEMPD	EQU	P6
CS_AD	EQU	P5.6
RD_AD	EQU	P5.7
WR_AD	EQU	P5.5


HON	DATA	19H
MON	DATA	1AH
HOFF	DATA	1BH
MOFF	DATA	1CH
TEMP	DATA	1DH
TMIN	DATA	1EH
TMAX	DATA	1FH
BLUCES  EQU	P4.1		; Indica el estado de la iluminacion
BCALEF	EQU	P4.0		; Indica el estado de la calefaccion
FLAG	EQU     20H  		; Flag para comprobar si los segundos han cambiado

PROG 	SEGMENT	CODE
STACK	SEGMENT	IDATA

	RSEG	STACK
	DS	30H		; 16 bytes de pila

	CSEG	AT	0
	USING	0		; Banco 0 de registros

	ORG	03h
	LJMP	LEER_AD		; Rutina de la interrupcion de conversion lista

	ORG 	0Bh
	LJMP	DESBORD		; Rutina de la interrupcion de desbordamiento del timer

;Tras reset se comienza a ejecutar sobre la direccion 0
	ORG 	0H
	JMP	START		; Saltamos al comienzo del programa
	RSEG	PROG


;;;;;;;;;;;;;;;;;;;;
;Provoca un retardo;
;;;;;;;;;;;;;;;;;;;;
RETARDO:
	MOV	B,A		
	PUSH 	B		; Salvamos R0
	MOV	A,#0D           ; Iniciamos el contador
BUCLE:	ADD	A,#1D		; Sumamos 1
	CJNE	A,#10D,BUCLE	; Si el resultado es 0, salimos
	POP	B
	MOV	A,B		; Restauramos A	
 	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Normaliza la temperatura leida;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Normalizamos el dato leido del conversor a grados centigrados. (T=(N-128)+(N-128)*2/12)
NORM_T:
	MOV	A,TEMP		; Obtenemos el valor del conversor
        MOV	B,#128D		; Preparamos la resta
	SUBB	A,B		; Restamos
        MOV	R0,A		; Guardamos la primera resta en R0
        MOV	B,#2D		; Introducimos 2 en B
	MUL	AB		; Lo multiplicamos por 2
	MOV	B,#12D		; Introducimos en B 12
	DIV	AB		; Lo dividimos por 12
        MOV	B,A		; Movemos el resultado a B
	MOV	A,R0		; Movemos la primera resta a A
	ADD	A,B		; Hacemos la suma final
	MOV	TEMP,A            ; Guardamos el resultado en R7
        RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina que lee la temperatura actual;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LEER_TEMP:
; Inicia una lectura de temperatura en el conversor, la salida se indicara por interrupcion
	SETB	CS_AD           ; Activamos las señales a 1 para bloquear el conversor 
	SETB	WR_AD	
	CLR	CS_AD		; Iniciamos la conversion           ; CS=0,RD=0,WR=1
	CLR	WR_AD
	CALL	RETARDO		; Esperamos a que se estabilicen las señales
	SETB	WR_AD
	SETB	CS_AD
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina de tratamiento de la interrupcion del conversor analogico digital;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; El dato de la temperatura se lee de P6 y se guarda en TEMP normalizado
LEER_AD:
	PUSH 	PSW		; Metemos dentro de la pila la palabra de estado
	PUSH	DPH	
	PUSH	DPL
	CLR	CS_AD		; Activamos la salida
	CLR	RD_AD           ; CS=0,RD=0,WR=0
	CALL	RETARDO		; Esperamos
	MOV	A,TEMPD		; Leemos la temperatura del conversor
	MOV	TEMP,A          ; La almacenamos en su variable
	SETB	RD_AD
	SETB	CS_AD
	CALL	NORM_T		; Normalizamos la temperatura
	POP	DPL
	POP	DPH
	POP	PSW		; Sacamos de la pila la palabra de estado
        RETI

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina que realiza varias lecturas de la temperatura y calcula su media;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LEER_MEDIA:
;Realiza 8 medidas y calcula su media para evitar oscilaciones del sensor
	MOV	B,#8D		;Cargamos el divisor en B
	MOV	R0,#1D		;Inicializamos el contador de la media
	CALL	LEER_TEMP	;Leemos la temperatura
	CALL 	RETARDO		;Esperamos a que el dato este disponible
	CALL 	RETARDO
	MOV	01H,R7		;Movemos la temperatura a R1
CONT:
	MOV	A,R1		;Guardamos la suma parcial en A
	CALL 	LEER_TEMP	;Realizamos otra lectura
	CALL	RETARDO		;Esperamos
	CALL	RETARDO
	ADD	A,TEMP		;Sumamos la nueva lectura al total
	INC	R0		;Incrementamos el contador del numero de medidas
	MOV     R1,A		;Almacenamos el resultado parcial en R1
	MOV	A,R0		;Cargamos el contador en A
	CJNE    A,#8D,CONT	;Comprobamos si el numero de medidas realizadas
	MOV	A,R1		;Restauramos las sumas
	DIV	AB		;Calculamos la media
	MOV	A,TEMP		;Movemos el resutado al registro de la temperatura
	RET


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina que escribe un caracter en el puerto serie;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;El caracter esta almacenado en A
PUTCHAR:
	CLR	TI		; TI = 0
	MOV	SBUF,A		; Enviamos el caracter
	JNB	TI,$		; Si TI == 0 entonces linea ocupada, esperamos a TI == 1
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina que escribe una cadena por el puerto serie;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Escribe la cadena apuntada en DPTR, y MODIFICA dicho puntero
PUTSTRING:
	CLR	A
	MOVC	A,@A+DPTR	; Lee del segmento de codigo
	JZ	EXIT		; Sale si el caracter es 00H
	CALL	PUTCHAR		; Escribimos el caracter en el serie
	INC	DPTR		; Incrementamos el contador
	SJMP	PUTSTRING
EXIT:	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina que escribe una nueva linea por el puerto serie;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PUTCRLF:
	MOV	DPTR,#MSG7
	CALL	PUTSTRING
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina que escribe un caracter ':' por el puerto serie;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PUTSEPARATOR:
	MOV	A,#58D		; Cargamos un : en A
	CALL	PUTCHAR		; Lo escribimos
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina que escribe el estado del sistema por el puerto serie;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Escribe la hora actual guardada de R4 a R6
PRINTSYS:
	MOV	DPTR,#MSG14	; "Son las hh:mm:ss"
	CALL	PUTSTRING
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

	MOV	DPTR,#MSG15	; ". La temperatura es "
	CALL	PUTSTRING
	MOV	A,TEMP
	CALL	GETASCII
	CALL	PUTCHAR
	MOV	A,B
	CALL	PUTCHAR

	MOV	DPTR,#MSG16	; "ºC. Calefaccion "
	CALL	PUTSTRING
	JB	BCALEF,CALEF_OK
	MOV	DPTR,#MSG13
	CALL	PUTSTRING
	SJMP	LUCES
CALEF_OK:
	MOV	DPTR,#MSG12
	CALL	PUTSTRING
	
LUCES:	
	MOV	DPTR,#MSG17	; ". Luces "
	CALL	PUTSTRING
	JB	BLUCES,LUCES_OK
	MOV	DPTR,#MSG13
	CALL	PUTSTRING
	SJMP	PUNTO
LUCES_OK:
	MOV	DPTR,#MSG12
	CALL	PUTSTRING

PUNTO:
	MOV	A,#'.'
	CALL	PUTCHAR

 	MOV	DPTR,#MSG9	; Iniciamos el cursor
	CALL	PUTSTRING
	RET

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina que habilita la interrupcion del timer 0 y el evento externo 0;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INTCONF:
	SETB	EX0   		; Habilitamos la interrupcion externa 0
	SETB	IT0		
	SETB	ET0		; Habilitamos la interrupcionde del timer 0
	SETB	EA
	RET


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina que lee un caracter por el puerto serie;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; El caracter leido se almacena en A
GETCHAR:	
	JNB	RI,$		; Si RI == 0 entonces no se ha recibido, esperamos a RI == 1
	MOV	A,SBUF		; Leemos el caracter por el puerto
	CLR	RI
	; Como mon51 envia 11H de vez en cuando lo ignoramos
	MOV	B,A		; Salvaguardamos A
	ADD	A,#-11H		; Restamos 11H a A
	JZ	GETCHAR		; Si es cero leemos otro caracter
	MOV	A,B		; Recuperamos A desde B
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina que obtiene la equivalencia entre digitos ASCII y numeros;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; #'0' == #48D, ... , #'9' == #57D
CONVERT:
	MOV	B,A		; Guardamos A en B
	CJNE	A,#48D,UNO	; Si es X, no saltamos, ponemos X en A. Si no, saltamos a X+1
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
NUEVE:	CJNE	A,#57D,FAIL	; Si no es 9, comprobamos si fue alguno de los anteriores
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina de inicializacion del timer0;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BLANK_TIMER:
	MOV	TH0,#11011000B	; Configuramos el timer0 para que se desborde cada
	MOV	TL0,#11110000B	; centesima de segundo
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
	POP	B
	MOV	A,B
	POP	DPL
	POP	DPH
	POP	PSW		; sacamos de la pila la palabra de estado
	RETI

;Rutinas para manejo del reloj
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina para incremento de segundos;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INCR_S:
	PUSH	B		; Guardamos B
	SETB	FLAG		; Ponemos el flag a 1 para indicar que han cambiado los segundos
	MOV	A,R6		; Guardamos el valor para operar
	ADD	A,#1D		; Incrementamos en 1 los segundos
	MOV	B,A		; Salvaguardamos el nuevo numero
	ADD	A,#-60D		; Le restamos 60
	CJNE	A,#0D,OK_S	; Si A == 0, reiniciamos cuenta
	MOV	B,#0D		; Reiniciamos las centesimas
	CALL	INCR_M		; Incrementamos los segundos
OK_S:	MOV	R6,B		; Restauramos los segundos
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
	CALL	INCR_H		; Incrementamos los segundos
OK_M:	MOV	R5,B		; Restauramos los segundos
	POP	B		; Recuperamos B
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina para incremento de horas;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INCR_H:
	PUSH	B		; Guardamos B
	MOV	A,R4		; Guardamos el valor para operar
	ADD	A,#1D		; Incrementamos en 1 los segundos
	MOV	B,A		; Salvaguardamos el nuevo numero
	ADD	A,#-24D		; Le restamos 60
	CJNE	A,#0D,OK_H	; Si A == 0, reiniciamos cuenta
	MOV	B,#0D		; Reiniciamos las centesimas
OK_H:	MOV	R4,B		; Restauramos los segundos
	POP	B		; Recuperamos B
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina que comprueba si un numero sobrepasa cierto limite;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; En B debe encontrarse el dato a comparar.
; En A se encontrara el numero con el que comparar.
; Si B > A entonces A = 1
; Si B <= A entonces A = 0
ISGT:
	PUSH	B		; Guardamos B
	CLR	C
	SUBB	A,B		; Restamos B a A
	JNC	CNS		; Si no hay acarreo, es menor
	MOV	A,#1D		; Suponemos B mayor que A
	CLR	C
	POP	B		; Restauramos B
	RET
CNS:
	MOV	A,#0D		; 
	POP	B		; Restauramos B
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Rutina que lee un numero del puerto serie y lo valida;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; En B se encuentra el numero maximo a obtener
; En A se devuelve 0 si no hubo exito, 1 en caso contrario
; Si hay exito, en B se encuentra el numero
GETNUM:
	PUSH	B
	CALL	GETCHAR		; Leemos el primer numero
	MOV	R3,A		; Guardamos el caracter
	CALL	CONVERT		; Lo convertimos a numero
	MOV	R0,B		; Cargamos en R0 el resultado de la conversion
	CJNE	R0,#10D,D1OK	; Si no es un digito, volvemos a pedirlo
	MOV	A,#0D		; Error!!
	POP	B
	RET
D1OK:	MOV	B,#10D		; Cargamos el 10 en B
	MUL	AB		; Multiplicamos el primer digito por 10
	MOV	R1,A		; Cargamos el primer digito en R1
	MOV	A,R3		; Cargamos el digito para escribirlo
	CALL	PUTCHAR		; Escribimos el digito leido

	CALL	GETCHAR		; Leemos el segundo numero
	MOV	R3,A		; Guardamos el caracter
	CALL	CONVERT		; Lo convertimos a numero
	MOV	R2,A		; Cargamos el segundo digito en R1
	CJNE	R2,#10D,D2OK	
	MOV	A,#0D		; Error!!
	POP	B
	RET
D2OK:	
	MOV	A,R3		; Cargamos el digito para escribirlo
	CALL	PUTCHAR		; Escribimos el segundo digito de las horas
	MOV	DPTR,#MSG9	; Saltamos de linea
	CALL	PUTSTRING

	MOV	A,R2		; Restauramos el digito en A
	ADD	A,R1		; Sumamos ambas cantidades, hemos obtenido las horas
	MOV	R0,A            ; Guardamos en R0 la suma final
	POP	B
	MOV	A,B
	MOV	B,R0
	CALL	ISGT		; Verificamos que sea correcta
	CJNE	A,#1D,SAVENUM
	MOV	A,#0D		; Error!!
	RET
SAVENUM:
	MOV	B,R0
	MOV	A,#1D		; Exito!!
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Comprueba y cambia el estado de la calefaccion;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHECK_CALEF:
	MOV	B,TEMP		; Cargamos la temperatura en B
	MOV	A,TMAX		; Cargamos la temperatura maxima en A
	CALL	ISGT		; Verificamos que sea menor
	CJNE	A,#1D,CALEF_OFF	; Comprobamos si la temperatura es mayor que el maximo
	CLR	BCALEF		; Es mayor, apagamos
CALEF_OFF:
	MOV	A,TMIN		; Cargamos la temperatura minima en A
	CALL 	ISGT		; Verificamos que sea menor
	CJNE	A,#0D,CALEFRET	; Comprobamos si la temperatura es menor que el minimo
	SETB	BCALEF		; Es menor, encendemos
CALEFRET:
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Comprueba y cambia el estado de la iluminacion;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHECK_LUCES:
; comprobamos que la hora actual sea MAYOR O IGUAL que la de encendido
	MOV	A,R4
	INC	A		; Incrementamos la hora actual
	MOV	B,A		; Cargamos esa hora en B
	MOV	A,HON		; Cargamos la hora de encendido en A
	CALL	ISGT		; Comprobamos si la hora es mayor O IGUAL
	CJNE	A,#1d,LUCESRET
	MOV	A,R5		
	INC	A		; Incrementamos los minutos actuales
	MOV	B,A		; Cargamos los minutos en B
	MOV	A,MON		; Cargamos los minutos de encendido en A
	CALL	ISGT		; Comprobamos si los minutos son mayores O IGUALES
	CJNE	A,#1d,LUCESRET
; comprobamos que la hora actual sea MENOR O IGUAL que la de apagado
	MOV	B,R4		; Cargamos la hora en B
	MOV	A,HOFF		; Cargamos la hora de apagado en A
	CALL	ISGT		; Comprobamos si la hora es MENOR O IGUAL
	CJNE	A,#0h,LUCESRET
	MOV	A,R5
	INC	A		; Incrementamos los minutos actuales
	MOV	B,A
;	MOV	B,R5		; Hora posterior, comprobamos minutos
	MOV	A,MOFF		; Cargamos los minutos de apagado en A
	CALL	ISGT		; Comprobamos si los minutos son MENORES
	CJNE	A,#0h,LUCESRET	;
        SETB	BLUCES		; La hora era posterior, ENCENDEMOS LUCES
	SJMP	RETURN
LUCESRET:
	CLR	BLUCES		; La hora era posterior, APAGAMOS LUCES
RETURN:
        RET

;;;;;;;;;;;;;;;;;;;;;;;
;Comienzo del programa;
;;;;;;;;;;;;;;;;;;;;;;;
START:
	MOV	SP,#STACK-1	; Inicializamos el registro SP

; Inicializamos el puerto serie
	MOV	SCON,#01010000B
	MOV	TMOD,#00100000B	; C/T = 0, Mode = 2
	MOV	TH1,#0F3H
	SETB	TR1
	SETB	TI

	MOV	DPTR,#MSG0	; Cargamos el mensaje en DPTR
	CALL	PUTSTRING	; Escribimos la cadena de texto
	MOV	DPTR,#MSG7	; Escribimos un CRLF
	CALL	PUTSTRING

	MOV	R6,#0D
	MOV	R7,#0D

; Pedimos al usuario que ponga el reloj en hora
; HORAS
BACKH:	
	MOV	DPTR,#MSG5	; Cargamos el mensaje en DPTR
	CALL	PUTSTRING
	MOV	B,#23D		; Numero maximo de horas
	CALL	GETNUM		; Leemos y validamos las horas
	CJNE	A,#1D,BACKH
	MOV	R4,B
	CALL	PUTCRLF

; Si la hora es correcta, pasamos a leer los minutos	
; MINUTOS
BACKM:
	MOV	DPTR,#MSG6	; Cargamos el mensaje en DPTR
	CALL	PUTSTRING
	MOV	B,#59D		; Numero maximo de minutos
	CALL	GETNUM		; Leemos y validamos los minutos
	CJNE	A,#1D,BACKM
	MOV	R5,B
	CALL	PUTCRLF

; Si los minutos son correctos, leemos Hon
BACKHON:
	MOV	DPTR,#MSG4
	CALL	PUTSTRING
	MOV	B,#23D		; Hora encendido luz maxima
	CALL	GETNUM		; Leemos y validamos Hon
	CJNE	A,#1D,BACKHON
	MOV	A,B
	MOV	HON,A
	CALL	PUTCRLF

; Si Hon es correcto, leemos Mon
BACKMON:
	MOV	DPTR,#MSG3
	CALL	PUTSTRING
	MOV	B,#59D		; Minutos encendido luz maximos
	CALL	GETNUM		; Leemos y validamos Mon
	CJNE	A,#1D,BACKMON
	MOV	A,B
	MOV	MON,A
	CALL	PUTCRLF

; Si Mon es correcta, leemos Hoff
BACKHOFF:
	MOV	DPTR,#MSG2
	CALL	PUTSTRING
	MOV	B,#23D		; Hora apagado luz maxima
	CALL	GETNUM		; Leemos y validamos Hoff
	CJNE	A,#1D,BACKHOFF
	MOV	A,B
	MOV	HOFF,A
	CALL	PUTCRLF

; Si Hoff es correcta, leemos Moff
BACKMOFF:
	MOV	DPTR,#MSG1
	CALL	PUTSTRING
	MOV	B,#59D		; Minutos apagado luz maximos
	CALL	GETNUM          ; Leemos y validamos Moff
	CJNE	A,#1D,BACKMOFF	
	MOV	A,B
	MOV	MOFF,A
	CALL	PUTCRLF

; Si Hoff es correcta, leemos Tmin
BACKTMIN:
	MOV	DPTR,#MSG10
	CALL	PUTSTRING
	MOV	B,#10D		; Maxima temperatura para encendido calefaccion
	CALL	GETNUM		; Leemos y validamos Tmin
	CJNE	A,#1D,BACKTMIN
	MOV	A,B
	MOV	TMIN,A
	CALL	PUTCRLF

; Si Tmin es correcta, leemos Tmax
BACKTMAX:
	MOV	DPTR,#MSG11
	CALL	PUTSTRING
	MOV	B,#30D		; Maxima temperatura para apagado calefaccion
	CALL	GETNUM		; Leemos y validamos Tmax
	CJNE	A,#1D,BACKTMAX
	MOV	A,B
	MOV	TMAX,A
	CALL	PUTCRLF

CONFINIT:
	CALL	INTCONF		; Habilitamos interrupciones
        CALL	TIMECONF	; Configuramos el timer
	SETB	FLAG		; Marcamos los segundos como cambiados
	CALL	LEER_MEDIA	; Leemos la temperatura inicialmente
MAIN:
        JBC	FLAG,NEWSEG
	SJMP	MAIN		; Sino ha cambiado el segundo no lo mostramos	
NEWSEG:
	CALL	CHECK_CALEF	; Comprobamos la calefaccion
	CALL	CHECK_LUCES	; Comprobamos las luces
	CALL	PRINTSYS	; Imprimimos la informacion de estado
	CLR	FLAG
	CALL	LEER_MEDIA	; Leemos la temperatura
	SJMP	MAIN		; Bucle infinito

; Cadenas de caracteres
MSG0:	DB	'SISTEMA INVERNADERO',CR,LF,00H
MSG1:	DB	'ILUMINACION OFF (MM): ',00H
MSG2:	DB	'ILUMINACION OFF (HH): ',00H
MSG3:	DB	'ILUMINACION ON (MM): ',00H
MSG4:	DB	'ILUMINACION ON (HH): ',00H
MSG5:	DB	'RELOJ (HH): ',00H
MSG6:	DB	'RELOJ (MM): ',00H
MSG7:	DB	CR,LF,00H
MSG8:	DB	'HORA: ',00H
MSG9:	DB	CR,00H
MSG10:  DB	'TEMPERATURA MINIMA (TT): ',00H
MSG11:  DB	'TEMPERATURA MAXIMA (TT): ',00H
MSG12:	DB	'ON',00H
MSG13:	DB	'OFF',00H
MSG14:	DB	'Son las ',00H
MSG15:	DB	'. La temperatura es ',00H
MSG16:	DB	'ºC. Calefaccion ',00H
MSG17:	DB	'. Luces ',00H

FIN:
	END
