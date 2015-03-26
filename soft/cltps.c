/*******************************************************
 * A Command-Line TCP Port Scanner: this command shows *
 * all open TCP ports found in a host, separated with  *
 * blanks. It returns 0 if the host is up, and -1 if   *
 * all examined ports are closed or filtered and the   *
 * host seems to be down. If you just want to know if  *
 * a host is up with any service running, redirect     *
 * STDOUT to /dev/null and "test" the exit status. ie: *
 * if ./cltps <ip> <lowerport> <upperport> > /dev/null *
 * then                                                *
 *     echo "host is up"                               *
 * fi                                                  *
 *                                                     *
 * Author: Jaime Pérez Crespo                          *
 * Date: August 13th, 2003                             *
 *                                                     *
 * Based on Richard Stevens' "Unix Network Programming"*
 * Volume 1 TCP echo client - server example.          *
 *******************************************************/

#include "unp.h"
#include "../lib/error.c"

#define LAST_PORT 65535

void hrule(int length)
{
    int i;

    for (i = 1; i <= length; i++)
         printf("-");
    printf("\n");
}

int main(int argc, char **argv)
{
   int    i, j, sockfd[LAST_PORT], c, iport, fport, down;
   struct sockaddr_in servaddr;

   if (argc != 4)
       err_quit("usage: tcpcli <IPaddress> <InitialPort> <FinalPort>");

   iport = strtol(argv[2], NULL, 10);
   if (iport == LONG_MIN || iport == LONG_MAX || iport > LAST_PORT || iport < 0)
       err_quit("error: bad initial port");

   fport = strtol(argv[3], NULL, 10);
   if (fport == LONG_MIN || fport == LONG_MAX || fport > LAST_PORT || fport < 0)
       err_quit("error: bad final port");

   if (iport > fport)
       err_quit("error: bad port range");

   down = -1;

   for (i = iport; i <= fport; i++) {
       sockfd[i] = socket(AF_INET, SOCK_STREAM, 0);

       bzero(&servaddr, sizeof(servaddr));
       servaddr.sin_family = AF_INET;
       servaddr.sin_port = htons(i);
       inet_pton(AF_INET, argv[1], &servaddr.sin_addr);

       c = connect(sockfd[i], (SA *) &servaddr, sizeof(servaddr));
       
       if (c == 0) {
           down = 0;
           printf("%d ",i);
       }

       close(sockfd[i]);
   }
   
   printf("\n");

   if (down)
       exit (-1);

   exit(0);
}
