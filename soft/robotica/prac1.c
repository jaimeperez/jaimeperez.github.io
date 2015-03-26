/**********************************************************
 * Practica 1 de robotica. Seguir una linea negra.        *
 * Santiago Carot Nemesio                                 *
 * Jaime Perez Crespo                                     *
 * *******************************************************/

#include <conio.h>
#include <unistd.h>
//#include <lcd.h>
#include <dsensor.h>
#include <dmotor.h>
#include <dbutton.h>

#define LIGHTSENSOR	SENSOR_2
#define THRESHOLD			40
#define NORMAL_SPEED   MAX_SPEED/4
#define TURN_SPEED	 MAX_SPEED/4

static wakeup_t dark_found(wakeup_t data) {
  return LIGHT(LIGHTSENSOR)<(unsigned short)data;
}
                                                                                                                                            
static wakeup_t bright_found(wakeup_t data) {
  return LIGHT(LIGHTSENSOR)>(unsigned short)data;
}

int turn_right(void)
{
	int i;
	motor_a_speed(TURN_SPEED);
	motor_c_speed(TURN_SPEED);
	motor_a_dir(fwd);
	motor_c_dir(rev);
	for (i=0;i<12;i++) {
//    	wait_event(dark_found,THRESHOLD);
         if (dark_found(THRESHOLD))
         	return 1;
         msleep(4);
    }
	return 0;
}

int turn_left(void)
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
    ds_active(&LIGHTSENSOR);
    for (;;) {
        motor_a_speed(MAX_SPEED/4);
        motor_c_speed(MAX_SPEED/4);
    	motor_a_dir(fwd);
        motor_c_dir(fwd);
//lcd_int(LIGHT(LIGHTSENSOR));
//sleep(1);

		wait_event(bright_found,THRESHOLD);

		if (!turn_right())
			turn_left();
/*			
		if (!turn_left(1))
			turn_right(1);*/
    }
    return 0;
}
