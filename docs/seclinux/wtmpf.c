
/*
 * simple hack to clean wmtp
 * assume we are on the wtmp directory
 * bugs -> anavarro@gsyc.escet.urjc.es
 */

#include <stdio.h>
#include <utmp.h>

void error(char *msg){
	printf("Error: %s\n",msg);
	exit(1);
}

int cleaner(char *user) {

	struct utmp myutmp;
	FILE *Win, *Wout;
	int counter = 0;

	if ((Win = fopen("wtmp","r"))==NULL)
		error("unable to open file wtmp");
	if ((Wout = fopen("wtmp.out","wr"))==NULL)
		error("unable to create output wtmp");

	while(!feof(Win)){
		fread(&myutmp,sizeof(myutmp),1,Win);
		if (strncmp(myutmp.ut_name,user,8)){
			counter++;
			fwrite(&myutmp,sizeof(myutmp),1,Wout);
		}
	}

	fclose(Win);
	fclose(Wout);

	return counter;
}

int main (int argc, char *argv[]) {

	char username[20];
	int i;

	printf("Enter username to clean from wtmp: ");
	scanf("%s",username);
	i=cleaner(username);
	printf("done! wtmp.out created. %d entries deleted.\n",i);
	
}	
		
	
