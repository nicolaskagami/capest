/* 
 * THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, 
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
 * OTHER DEALINGS IN THE SOFTWARE.
 *
 * Author: Nicolas Kagami
*/
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
#define ESTIMATE_SAMPLE_AMOUNT 40960

uint32_t last_s1_et =0;
uint32_t last_s1_it =0;
uint32_t last_s2_it=0;
uint32_t last_s2_et=0;
uint32_t last_length = 0;
uint32_t second_to_last_length = 0;
float last_estimates[ESTIMATE_SAMPLE_AMOUNT];
float ordered_estimates[ESTIMATE_SAMPLE_AMOUNT];
float bin_radius =0;
uint32_t estimate_iterator = 0;
uint32_t notfirst = 0;


//Autocorrelation
#include<math.h>
//Seconds per Gigabit
#define AUTOC_SAMPLE_AMOUNT 4096
#define AUTOC_MAXIMUM_ESTIMATE 1024000
double   ac_value[AUTOC_SAMPLE_AMOUNT];
uint32_t autoc_reverse_estimates[AUTOC_SAMPLE_AMOUNT];
void calculate_autoc();


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
    uint16_t second_to_last_length=0;

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
    //if(delta_S2_it<(bin_radius/10))//10 units per bin radius
     //   return;
    //float estimate = (float) (8000*(second_to_last_length+last_length))/delta_S2_it;
    float estimate = (float) (8000*(last_length))/delta_S2_it;
    last_estimates[estimate_iterator++%ESTIMATE_SAMPLE_AMOUNT] = estimate;
    float average,sum;
    sum = 0;
    uint32_t i,limit;
    limit = (estimate_iterator>ESTIMATE_SAMPLE_AMOUNT) ? ESTIMATE_SAMPLE_AMOUNT : estimate_iterator;
    //for(i=0;i<limit;i++)
    //    sum+=last_estimates[i];
    //average = sum/limit;
    for(i=0;i<limit;i++)
        ordered_estimates[i] = last_estimates[i];
    qsort(ordered_estimates,limit,sizeof(uint32_t),compare);

    second_to_last_length = last_length;
    last_length = ip_length;
    last_s1_it = source_in_timestamp;
    last_s2_it = target_in_timestamp;

    if(limit< 1000)
        return;

    float highest_count = 0;
    uint32_t highest_avg = 0;
    int quartile = limit/4;
    int step=limit/25;
    bin_radius = (ordered_estimates[3*quartile]-ordered_estimates[quartile])/10;

    if(limit%100)
        return;
    
    for(i=0;i<AUTOC_SAMPLE_AMOUNT;i++)
    {
        float autoc_min_estimate = (float)(AUTOC_MAXIMUM_ESTIMATE/(i+2));
        float autoc_max_estimate = (float)(AUTOC_MAXIMUM_ESTIMATE/(i+1));
        //printf("between (%f,%f)\n",autoc_min_estimate,autoc_max_estimate); getchar();
        int j;
        for(j=0;j<limit;j++)
        {
            if((ordered_estimates[j] >= autoc_min_estimate) && (ordered_estimates[j]) < autoc_max_estimate)
                autoc_reverse_estimates[i]++;
        }
    }
	calculate_autoc();
    for(i=0;i<(limit-step);i+=step/10)
    { 
        int j;
        float count =0;
        float median = ordered_estimates[i];
        if(median == 0)
            continue;
        for(j=0;j<limit;j++)
            if((ordered_estimates[j] >= (median-bin_radius))&&(ordered_estimates[j]<(median+bin_radius)))
                count++;

        int index = (int) (AUTOC_MAXIMUM_ESTIMATE/median);
        if(index >= AUTOC_SAMPLE_AMOUNT)
            index = AUTOC_SAMPLE_AMOUNT -1;
        else if (index < 0)
            index = 0;
        printf("%f: %f *[%d](%f) = %f \n",median,count,index,ac_value[index],count*ac_value[index]);
        count*=ac_value[index];
        //printf("%f: %d *[%d]\n",median,count,index);
        if(count>=highest_count)
        {
            highest_count = count;
            highest_avg = median; 
        }
    }
        //    printf("Lag:%f %f\n",(float)(AUTOC_MAXIMUM_ESTIMATE/(lag+1.5)),ac_value);
    average = highest_avg;
    printf("Bin Radius: %f\n",bin_radius);
    printf("Average dispersion estimate (%u): %f Kbps\n",limit,average);

/*
    printf("Count: %d\n",highest_count);
    printf("Step: %d\n",step);
    printf("SRC IT dispersion estimate: %f Kbps\n",(float)(8000*(second_to_last_length+last_length))/delta_S1_it);
    printf("TGT IT dispersion estimate: %f Kbps\n",estimate);*/

    //printf("SRC IT dispersion: %f ms\n",(float)delta_S1_it/(1000));
    //printf("TGT IT dispersion: %f ms\n",(float)delta_S2_it/(1000));
}

void calculate_autoc()
{
	double   autocv;      // Autocovariance value
	double   mean;
	double   var;
	int      i,lag;           // Loop counter
	int N = AUTOC_SAMPLE_AMOUNT;

	mean = 0.0;
	for (i=0; i<N; i++)
		mean = mean + (autoc_reverse_estimates[i] / N);

	var = 0.0;
	for (i=0; i<N; i++)
		var = var + (pow((autoc_reverse_estimates[i] - mean), 2.0) / N);

    printf("Mean: %f \tVariance: %f\n",mean,var);
	for(lag=N/64;lag<(N-1);lag++)
	{
		autocv = 0.0;
		for (i=0; i<(N - lag); i++)
			autocv = autocv + ((autoc_reverse_estimates[i] - mean) * (autoc_reverse_estimates[i+lag] - mean));
		autocv = (1.0 / (N - lag)) * autocv;
		ac_value[lag] = autocv / var;
	}

}
