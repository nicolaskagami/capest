#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <netdb.h>
#include <sys/types.h> 
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define BUFSIZE 1024

int main(int argc, char **argv) 
{
    int sockfd; /* socket */
    int portno; /* port to listen on */
    int clientlen; /* byte size of client's address */
    struct sockaddr_in serveraddr; /* server's addr */
    struct sockaddr_in clientaddr; /* client addr */
    struct hostent *hostp; /* client host info */
    char buf[BUFSIZE]; /* message buf */
    char *hostaddrp; /* dotted decimal host addr string */
    int optval; /* flag value for setsockopt */
    int n; /* message byte size */

    if (argc != 2) 
    {
        fprintf(stderr, "usage: %s <port>\n", argv[0]);
        exit(1);
    }
    portno = atoi(argv[1]);

    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) 
    {
        fprintf(stderr,"%s Error: socket\n", argv[0]);
        exit(0);
    }

    optval = 1;
    setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, (const void *)&optval , sizeof(int));

    bzero((char *) &serveraddr, sizeof(serveraddr));
    serveraddr.sin_family = AF_INET;
    serveraddr.sin_addr.s_addr = htonl(INADDR_ANY);
    serveraddr.sin_port = htons((unsigned short)portno);

    if (bind(sockfd, (struct sockaddr *) &serveraddr, sizeof(serveraddr)) < 0) 
    {
        fprintf(stderr,"%s Error: Binding\n", argv[0]);
        exit(0);
    }

    clientlen = sizeof(clientaddr);
    while (1) 
    {
        bzero(buf, BUFSIZE);
        n = recvfrom(sockfd, buf, BUFSIZE, 0,(struct sockaddr *) &clientaddr, &clientlen);

        uint16_t * caps_number = buf;
        uint32_t * swid;
        uint32_t * it;
        uint32_t * et;
        printf("IP Length: %u\n",ntohs(caps_number[0]));
        printf("INT capsules: %u\n",ntohs(caps_number[2]));
        int i;
        char * buf_aux = buf + 4;

        for(i=0;i<ntohs(caps_number[2]);i++)
        {
            swid = buf_aux; 
            it = buf_aux + 4;
            et = buf_aux + 8;
            printf("Swid: %d, Ingress Time: %u, Enqueue Time: %u\n",ntohl(swid[0]),ntohl(it[0]),ntohl(et[0]));
            buf_aux+=12;
        }
    }
}
