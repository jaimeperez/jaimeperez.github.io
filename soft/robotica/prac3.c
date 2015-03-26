/**********************************************************
 * Practica 3 de robotica. Laberinto.                     *
 * Santiago Carot Nemesio                                 *
 * Jaime Perez Crespo                                     *
 * *******************************************************/

#include <conio.h>
#include <unistd.h>
#include <stdlib.h>
#include <tm.h>
#include <semaphore.h>
#include <dsensor.h>
#include <dmotor.h>
#include <dbutton.h>
#include <dlcd.h>

#define VUELTASCASILLA 86
#define DERECHA   0
#define ABAJO     1
#define IZQUIERDA 2
#define ARRIBA    3
#define SINLATA  60
#define CONLATA 100
#define CORTO	 0
#define LARGO	 1
#define MUY_LARGO 2
#define MEDIO	 3
#define RECORRIDO 1
#define NINGUNA   0    // no hay lata
#define BLANCA    1    // hay lata blanca
#define NEGRA     2    // hay lata negra
#define ES_BLANCA(lata)   (lata == BLANCA)
#define ES_NEGRA(lata)    (lata == NEGRA)
#define NO_HAY_LATA(lata) (lata == NINGUNA)

typedef struct posicion *posicion_t;

struct posicion
{
	int casilla;
	int direccion;
};

typedef struct coordenada *coordenada_t;
struct coordenada
{
	int x;
	int y;
};

int lata = 0;
int num_latas = 0;
int recorrido = 0;
int desconocida = 0;
int aux = 0;
int almacen_visitado = 0;
int vueltas = 161;	// número inicial de vueltas

static wakeup_t sensor_pressed() {
        return SENSOR_1 > 0 && SENSOR_1 < 8000;
}

void atras(int t)
{
	// definimos 4 posibles longitudes para recular
    if (lata) {
        motor_a_speed(CONLATA+20);
    	motor_c_speed(CONLATA+20);
    } else {
    	motor_a_speed(SINLATA+20);
    	motor_c_speed(SINLATA+20);
    }
    motor_a_dir(rev);
    motor_c_dir(rev);
    ds_rotation_set(&SENSOR_2, 0);
    if (t == LARGO)
        sleep(2);
    if (t == CORTO)
        msleep(200);
    if (t == MUY_LARGO)
    	sleep(4);
    if (t == MEDIO)
    	msleep (800);
    ds_rotation_set(&SENSOR_2, 0);
}

void parar_motores(void)
{
	motor_a_speed(0);
	motor_c_speed(0);
}

void adelante(int v)
{
	int actual;

    ds_rotation_set(&SENSOR_2, 0);
    motor_a_dir(fwd);
    motor_c_dir(fwd);
    if (lata) {
    	motor_a_speed(CONLATA);
    	motor_c_speed(CONLATA);
    } else {
    	motor_a_speed(SINLATA);
    	motor_c_speed(SINLATA);
    }
	actual = ROTATION_2;
    while (ROTATION_2 <= actual + v);
    ds_rotation_set(&SENSOR_2, 0);
}

void derecha(void)
{
	int v;
	
    ds_rotation_set(&SENSOR_2, 0);
    motor_a_dir(fwd);
    motor_c_dir(rev);
    if (lata) {
    	motor_a_speed(CONLATA);
    	motor_c_speed(CONLATA);
    } else {
    	motor_a_speed(SINLATA);
    	motor_c_speed(SINLATA);
    }
	v = ROTATION_2;
	if (lata)
		msleep(560);
	else
		msleep(540);
    ds_rotation_set(&SENSOR_2, 0);
}

void izquierda(void)
{
	int v;

    ds_rotation_set(&SENSOR_2, 0);
    motor_a_dir(rev);
    motor_c_dir(fwd);
    if (lata) {
        motor_a_speed(CONLATA);
        motor_c_speed(CONLATA);
    } else {
        motor_a_speed(SINLATA);
        motor_c_speed(SINLATA);
    }
	v = ROTATION_2;
	if (lata)
		msleep(560);
	else
		msleep(540);
    ds_rotation_set(&SENSOR_2, 0);
}

void abrir_pinzas(void)
{
    motor_b_speed(MAX_SPEED);
    motor_b_dir(rev);
    msleep(80);
    motor_b_speed(brake);
    parar_motores();
    sleep(1);
    lata = NINGUNA;
    parar_motores();
    msleep(80);
}

void cerrar_pinzas(void)
{
    motor_b_speed(MAX_SPEED);
    motor_b_dir(fwd);
    msleep(100);
    motor_b_speed(230);
    motor_b_dir(fwd);
	num_latas++;
}

void dejar_lata_primero(void)
{
	// deja la lata apartada tras cubrir  el primer cuadrante
	adelante(10);
	izquierda();
	atras(LARGO);
	adelante(30);
	parar_motores();
	abrir_pinzas();
	atras(LARGO);
	adelante(10);
	derecha();
	atras(LARGO);
}

void dejar_lata_segundo(void)
{
	// deja la lata apartada si se ha encontrado entre
	// el primer cuadrante y el segundo
	izquierda();
	atras(LARGO);
	adelante(10);
	izquierda();
	adelante(30);
	parar_motores();
	abrir_pinzas();
	atras(MEDIO);
	derecha();
	atras(LARGO);
	adelante(10);
	derecha();
}

posicion_t siguiente_posicion(posicion_t p)
{
	// calcula la siguiente posición a visitar
	// desde la actual
    posicion_t r;

    r = malloc(sizeof(struct posicion));
    switch (p->casilla) {
    case 1:
        r->casilla = 3;
    	r->direccion = DERECHA;
    	break;
    case 3:
    	r->casilla = 9;
    	r->direccion = ABAJO;
    	break;
	case 4:
    	r->casilla = 6;
    	r->direccion = DERECHA;
    	break;
    case 5:
    	r->casilla = 17;
    	r->direccion = ABAJO;
    	break;
    case 6:
        if (p->direccion == ARRIBA) {
	    	r->casilla = 10;
 	   	r->direccion = IZQUIERDA;
 	   	break;
 	   }
    	if (p->direccion == DERECHA) {
    		r->casilla = 5;
 	   	r->direccion = IZQUIERDA;
 	   }
    	break;
	case 7:
    	r->casilla = 13;
    	r->direccion = ABAJO;
    	break;
	case 8:
        r->casilla = 9;
        r->direccion = DERECHA;
    	break;
    case 9:
    	if (num_latas == 0) {
	        if (recorrido == RECORRIDO)
	            r->casilla = 8;
	        else
		    	r->casilla = 7;
		} else
			r->casilla = 7;
    	r->direccion = IZQUIERDA;
    	break;
    case 10:
        if (recorrido == RECORRIDO) {
        	r->casilla = 11;
        	r->direccion = DERECHA;
        	break;
        }
        if (p->direccion == IZQUIERDA) {
        	r->casilla = 4;
        	r->direccion = ARRIBA;
        	break;
        }
        r->casilla = 12;
        r->direccion = DERECHA;
        recorrido = 0;
        break;
    case 11:
        if (p->direccion == DERECHA) {
            desconocida = 0;
            recorrido = 0;
            r->casilla = 16;
            r->direccion = IZQUIERDA;
            break;
        }
        if (num_latas >= 1) {
        	r->casilla = 17;
	    	r->direccion = ABAJO;
	    	break;
	    }
        if (recorrido == RECORRIDO) {	    	
	    	r->casilla = 16;
 	   	r->direccion = IZQUIERDA;
 	   	break;
 	   }
	    break;
	case 12:
    	r->casilla = 6;
    	r->direccion = ARRIBA;
    	recorrido = 0;
    	break;
    case 13:
    	if (num_latas == 0) {
	        if (recorrido == RECORRIDO)
	            r->casilla = 14;
	        else
				r->casilla = 16;
		} else {
		    if (ES_BLANCA(lata))
				r->casilla = 18;
			if (ES_NEGRA(lata))
				r->casilla = 17;
		}
    	r->direccion = DERECHA;
    	break;
    case 14:
    	break;
    case 15:
    	break;
    case 16:
        if (ES_BLANCA(lata)) {
        	r->casilla = 18;
        	r->direccion = DERECHA;
        	break;
        }
        if (ES_NEGRA(lata)) {
        	r->casilla = 17;
        	r->direccion = DERECHA;
        	break;
        }
        if (recorrido == RECORRIDO) {
            r->casilla = 10;
            r->direccion = ARRIBA;
            break;
        }
        if (num_latas == 1) {
	    	r->casilla = 10;
 	   	r->direccion = ARRIBA;
 	   } else {
 	   	parar_motores();
 	   	sleep(2);
        	r->casilla = 17;
 	   	r->direccion = ARRIBA;
 	   }
    	break;
    case 17:
    	if (ES_BLANCA(lata)) {
    		r->casilla = 18;
    		r->direccion = DERECHA;
    		break;
    	}
    	if (desconocida == 1) {
    		r->casilla = 11;
			r->direccion = ARRIBA;
			break;
		}
		if (num_latas == 1) {
			r->casilla = 16;
			r->direccion = IZQUIERDA;
			break;
		}
		r->casilla = 11;
    	r->direccion = ARRIBA;
    	break;
    case 18:
        if (desconocida)
        	r->casilla = 17;
 	   else {
	    	r->casilla = 16;
	    	recorrido = RECORRIDO;
	    }
    	r->direccion = IZQUIERDA;	    	
    	break;
    }
    return r;
}


void reposiciona(posicion_t origen, posicion_t destino)
{
	// recoloca el robot en la posición adecuada, e indica
	// el valor que debe alcanzar el odómetro para llegar
	// a la siguiente posición
    switch (origen->casilla) {
    case 1:
        break;
    case 2:
    	break;
    case 3:
        if (NO_HAY_LATA(lata)) {
	        atras(CORTO);
	        recorrido = RECORRIDO;
	        vueltas = 51;
	    } else
	    	vueltas = 80;
        derecha();
        atras(LARGO);
        break;
    case 4:
        atras(CORTO);
        derecha();
        atras(LARGO);
		vueltas = 150;
        break;
    case 5:
    	atras(CORTO);
    	derecha();
    	atras(LARGO);
    	vueltas = 150;
    	break;
    case 6:
    	if (ES_NEGRA(lata)) {
    		parar_motores();
    		exit(0);
    	}
    	if (ES_BLANCA(lata)) {
    		derecha();
    		atras(LARGO);
    		adelante(10);
    		derecha();
    		atras(LARGO);
    		vueltas = 45;
    		break;
    	}
    	izquierda();
    	atras(LARGO);
    	vueltas = 150;
    	aux = 1;
    	break;
    case 7:
        if (NO_HAY_LATA(lata)) {
	        atras(CORTO);
	        vueltas = 50;
	        recorrido = RECORRIDO;
	    } else
	    	vueltas = 70;
        izquierda();
        atras(LARGO);
        break;
    case 8:
    	atras(MUY_LARGO);
    	adelante(10);
    	izquierda();
    	atras(LARGO);
		vueltas = 91;
    	recorrido = 0;
        break;
    case 9:
        if (NO_HAY_LATA(lata))
	        atras(CORTO);
        derecha();
        atras(LARGO);
        if (recorrido != RECORRIDO)
            vueltas = 155;
        else
			vueltas = 100;
        break;
	case 10:
	    if (aux == 1) {
	    	derecha();
	    	derecha();
	    	atras(LARGO);
	    	adelante(10);
	    	izquierda();
	    	vueltas = 37;
	    	break;
	    }
		derecha();
		atras(LARGO);
	    if (recorrido == RECORRIDO) {
	    	vueltas = 82;
        	recorrido = 0;
	    	break;
	    }
	    vueltas = 150;
	    break;
    case 11:
    	if (num_latas == 2) {
    		// tenemos todas las latas
	    	if (ES_BLANCA(lata)) {
	    		derecha();
	    		derecha();
	    		atras(LARGO);
	    		vueltas = 150;
	    		break;
	    	}
	    	if (ES_NEGRA(lata)) {
	    		parar_motores();
	    		abrir_pinzas();
	    		exit(0);
	    	}
	    }
	    // lata blanca en posición conocida
	    if (ES_BLANCA(lata)) {
			derecha();
			derecha();
	    	atras(LARGO);
	    	vueltas = 150;
	    	break;
	    }
	    // lata negra en posición conocida
	    if (ES_NEGRA(lata)) {
	    	atras(LARGO);
	    	adelante(10);
	    	izquierda();
	    	adelante(150);
	    	abrir_pinzas();
	    	atras(LARGO);
	    	derecha();
	    	atras(LARGO);
	    	adelante(10);
	    	izquierda();
	    	break;
	    }
	    // vamos a la 16
	    izquierda();
	    atras(LARGO);
	    adelante(10);
	    izquierda();
	    vueltas = 75;
        break;
    case 12:
        izquierda();
        atras(LARGO);
        vueltas = 35;
    	break;
    case 13:
        if (NO_HAY_LATA(lata))
	        atras(CORTO);
        izquierda();
	    atras(LARGO);
        if (recorrido != RECORRIDO)
        	vueltas = 205;
        else {
        	vueltas = 100;
        	recorrido = 0;
        }
	    if (ES_NEGRA(lata)) {
	    	desconocida = 1;
	    	dejar_lata_primero();
	    	vueltas = 291;
	    }
	    if (ES_BLANCA(lata)) {
	    	desconocida = 1;
	    	vueltas = 365;
	    }
        break;
    case 14:
    	atras(MUY_LARGO);
    	adelante(10);
		derecha();
    	atras(LARGO);
		vueltas = 91;
    	recorrido = 0;
        break;
    case 15:
        break;
    case 16:
    	if (ES_BLANCA(lata)) {
    		desconocida = 1;
   	 	vueltas = 107;
   	 	break;
   	 }
        if (ES_NEGRA(lata)) {
    		desconocida = 1;
        	dejar_lata_segundo();
        	vueltas = 80;
        	break;
        }
        if (recorrido == RECORRIDO) {
        	derecha();
        	atras(LARGO);
        	vueltas = 47;
        	break;
        }
        if (num_latas == 0) {
        	vueltas = 75;
        	break;
        }
        derecha();
        atras(LARGO);
        vueltas = 70;
   	 break;
    case 17:
	    if (ES_BLANCA(lata)) {
			atras(CORTO);
			derecha();
			derecha();
	    	atras(LARGO);
	    	adelante(10);
	    	derecha();
	    	vueltas = 87;
	    	break;
	    }
	    atras(CORTO);
	    if (almacen_visitado)
 	   	derecha();
   	 else 
   	 	izquierda();
   	 atras(LARGO);
   	 vueltas = 110;
        break;
    case 18:
    	almacen_visitado = 1;
    	parar_motores();
	    abrir_pinzas();
	    if (num_latas == 2) {
		    exit(0);
		}
		atras(CORTO);
		atras(CORTO);
		izquierda();
		atras(LARGO);
		adelante(10);
		izquierda();
		if (desconocida)
		    vueltas = 70;
		else
		    vueltas = 116;
		break;
	}
}

int comprobar_lata()
{
	for (;;) {
		if (!lata) {
			wait_event(sensor_pressed,0);
			cerrar_pinzas();
			lata = (SENSOR_3/10 > 5000) ? NEGRA : BLANCA;
		}
		msleep(300);
	}
	exit(0);
}

int main(int argc, char **argv)
{
    posicion_t origen, destino;
    int tm;
    
    origen = malloc(sizeof(struct posicion));
	// ejecutamos el hilo
    tm = execi(&comprobar_lata,0,NULL,10,DEFAULT_STACK_SIZE);
    tm_start();
    
    origen->casilla = 3;
    origen->direccion = DERECHA;
    ds_active(&SENSOR_3);
    
    // esperamos un segundo nada mas pulsar el sensor
    sleep (1);

    atras(LARGO);
    abrir_pinzas();
    
    motor_a_speed(0);
    motor_c_speed(0);
    
    ds_active (&SENSOR_2);
    ds_rotation_on (&SENSOR_2);
    sleep(LARGO);
    ds_rotation_set (&SENSOR_2, 0);

    for (;;) {
    	if (lata) {
    	        motor_a_speed(CONLATA);
    	        motor_c_speed(CONLATA);
    	} else {
                motor_a_speed(SINLATA);
    	        motor_c_speed(SINLATA);
    	}
    	motor_a_dir(fwd);
    	motor_c_dir(fwd);
    	if (ROTATION_2 >= vueltas) {
		    destino = siguiente_posicion(origen);
		    lcd_int(origen->casilla);
		    ds_rotation_set(&SENSOR_2, 0);
	 	   reposiciona(origen,destino);
	  	  ds_rotation_set(&SENSOR_2, 0);
    	    free(origen);
            origen = destino;
    	}
    }
    return 0;
}
