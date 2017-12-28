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
#define ESTIMATE_SAMPLE_AMOUNT 20480

uint32_t last_s1_et =0;
uint32_t last_s1_it =0;
uint32_t last_s2_it=0;
uint32_t last_s2_et=0;
uint32_t last_length = 0;
float last_estimates[ESTIMATE_SAMPLE_AMOUNT];
float ordered_estimates[ESTIMATE_SAMPLE_AMOUNT];
uint32_t estimate_iterator = 0;
uint32_t notfirst = 0;

void submit(uint32_t ip_length, uint32_t swid_source, uint32_t swid_target, uint32_t source_in_timestamp, uint32_t target_in_timestamp);
int compare (const void * a, const void * b)
{
  return ( *(uint32_t*)a - *(uint32_t*)b );
}

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

    float max_cap = 0;
    float estimated_cap = 0;
    uint16_t last_length=0;

    uint32_t current_s1_et=0;
    uint32_t current_s1_it=0;
    uint32_t current_s2_it=0;
    uint32_t current_s2_et=0;
    clientlen = sizeof(clientaddr);
    while (1) 
    {
        bzero(buf, BUFSIZE);
        n = recvfrom(sockfd, buf, BUFSIZE, 0,(struct sockaddr *) &clientaddr, &clientlen);

        uint32_t caps_number = ntohl(*((uint32_t*)&(buf[2])));
        uint16_t ip_length = ntohs(*((uint16_t* )buf));
        uint32_t swid;
        uint32_t it;
        uint32_t et;
  //      printf("IP Length: %u\n",ip_length);
  //      printf("INT capsules: %u\n",caps_number);
        int i;
        char * buf_aux = buf + 6;
        for(i=0;i<caps_number;i++)
        {
            swid = ntohl(*(uint32_t *)buf_aux); 
            it = ntohl(*(uint32_t *)&(buf_aux[4]));
            et = ntohl(*(uint32_t *)&(buf_aux[8]));
            //printf("Swid: %d, Ingress Time: %u, Enqueue Time: %u\n",swid,it,et);
            buf_aux+=12;
            if(i == 1)
                current_s1_it = it;
            if(i == 0)
                current_s2_it = it;
         }

        if(caps_number>1)
            submit(ip_length,1,2,current_s1_it,current_s2_it);
     }
}

void submit(uint32_t ip_length,uint32_t swid_source, uint32_t swid_target, uint32_t source_in_timestamp, uint32_t target_in_timestamp)
{  
    float delta_S1_it = (float) (source_in_timestamp- last_s1_it);   
    float delta_S2_it = (float) (target_in_timestamp- last_s2_it);   
    //if(last_s1_it && (delta_S1_it>delta_S2_it))
    //{
    //    return;
    //}
    float estimate = (8000*last_length)/delta_S2_it;
    last_estimates[estimate_iterator++%ESTIMATE_SAMPLE_AMOUNT] = estimate;
    float average,sum;
    sum = 0;
    uint32_t i,limit;
    limit = (estimate_iterator>ESTIMATE_SAMPLE_AMOUNT) ? ESTIMATE_SAMPLE_AMOUNT : estimate_iterator;
    for(i=0;i<limit;i++)
        sum+=last_estimates[i];
    average = sum/limit;
    for(i=0;i<limit;i++)
        ordered_estimates[i] = last_estimates[i];
    qsort(ordered_estimates,limit,sizeof(uint32_t),compare);
    average = ordered_estimates[(uint32_t)(limit/2)];

    uint32_t highest_count = 0;
    uint32_t highest_avg = 0;
    if(limit< 100)
        return;
    for(i=50;i<limit-50;i++)
    {
        int j;
        int count =0;
        uint32_t median = ordered_estimates[i];
        for(j=-50;j<50;j++)
        {
            if((ordered_estimates[i+j]>(0.9*median))&&(ordered_estimates[i+j]<(1.1*median)))
                count++;
        }
        if(count>highest_count)
        {
            highest_count = count;
            highest_avg = median; 
        }
    }
    average = highest_avg;

    printf("Count: %d\n",highest_count);
    printf("SRC IT dispersion estimate: %f Kbps\n",(float)(8000*last_length)/delta_S1_it);
    printf("TGT IT dispersion estimate: %f Kbps\n",estimate);
    printf("Average dispersion estimate (%u): %f Kbps\n",limit,average);

    //printf("SRC IT dispersion: %f ms\n",(float)delta_S1_it/(1000));
    //printf("TGT IT dispersion: %f ms\n",(float)delta_S2_it/(1000));
    last_length = ip_length;
    last_s1_it = source_in_timestamp;
    last_s2_it = target_in_timestamp;
}
