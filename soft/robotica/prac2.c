/**********************************************************
 * Practica 2 de robotica. Juego del pañuelo.             *
 * Santiago Carot Nemesio                                 *
 * Jaime Perez Crespo                                     *
 * *******************************************************/

#include <conio.h>
#include <unistd.h>
#include <tm.h>
#include <semaphore.h>
#include <dsensor.h>
#include <dmotor.h>
#include <dbutton.h>
#include <dlcd.h>

#define LIGHTSENSOR	SENSOR_3
#define THRESHOLD			40
#define NORMAL_SPEED    150
#define TURN_SPEED	150

sem_t sem;

static wakeup_t dark_found(wakeup_t data) {
  return LIGHT(LIGHTSENSOR)<(unsigned short)data;
}
                                                                                                                                            
static wakeup_t bright_found(wakeup_t data) {
  return LIGHT(LIGHTSENSOR)>(unsigned short)data;
}

static wakeup_t sensor_pressed() {
        return SENSOR_1<10000;
}

int turn_left();

int check_pressed()
{
	wait_event(sensor_pressed,0);
	sem_wait(&sem);
	// paramos la dirección
	motor_a_speed(0);
	motor_c_speed(0);
	// activamos la pinza
	motor_b_speed(MAX_SPEED);
	motor_b_dir(fwd);
	msleep(100);
	motor_b_speed(140);
	motor_b_dir(fwd);
	// giramos un poco a la izquierda
	motor_a_speed(TURN_SPEED);
	motor_c_speed(TURN_SPEED);
	motor_a_dir(rev);
	motor_c_dir(fwd);
	msleep(500);
	wait_event(dark_found,THRESHOLD);
	sem_post(&sem);
	exit(0);
}


int turn_right()
{
	int i;
	motor_a_speed(TURN_SPEED);
	motor_c_speed(TURN_SPEED);
	motor_a_dir(fwd);
	motor_c_dir(rev);
	for (i=0;i<5;i++) {
//    	wait_event(dark_found,THRESHOLD);
         if (dark_found(THRESHOLD))
         	return 1;
         msleep(4);
    	}
	return 0;
}

int turn_left()
{
	motor_a_speed(TURN_SPEED);
	motor_c_speed(TURN_SPEED);
	motor_a_dir(rev);
	motor_c_dir(fwd);
	wait_event(dark_found,THRESHOLD);
	return 0;
}

int main(int argc, char **argv)
{    
    int tm, n;

    sem_init(&sem,1,1);
    ds_active(&LIGHTSENSOR);

    motor_b_speed(MAX_SPEED);
    motor_b_dir(rev);
    msleep(80);
    motor_b_speed(brake);

    tm = execi(&check_pressed,0,NULL,1,DEFAULT_STACK_SIZE);
    tm_start();
    for (;;) {
	sem_wait(&sem);
        motor_a_speed(120);
        motor_c_speed(120);
    	motor_a_dir(fwd);
        motor_c_dir(fwd);
	sem_post (&sem);
	wait_event(bright_found,THRESHOLD);
	sem_wait (&sem);
	if (!turn_right())
		turn_left();
	if (!turn_left(1))
		turn_right(1);
	sem_post(&sem);
    }
    return 0;
}

