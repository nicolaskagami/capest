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
 * Name: Capest Visualizer
 * Usage: capest_visualizer <port>
 * Description: Basic listener, receives and prints information from the Capest sink.
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
    // Keeps listening for Capest's INT capsules
    while (1) 
    {
        bzero(buf, BUFSIZE);
        n = recvfrom(sockfd, buf, BUFSIZE, 0,(struct sockaddr *) &clientaddr, &clientlen);

        uint32_t caps_number = ntohl(*((uint32_t*)&(buf[2])));
        uint16_t ip_length = ntohs(*((uint16_t* )buf));
        uint32_t swid;
        uint32_t it;
        uint32_t et;
        //printf("IP Length: %u\n",ip_length);
        //printf("INT capsules: %u\n",caps_number);
        int i;
        char * buf_aux = buf + 6;
        for(i=0;i<caps_number;i++)
        {
            swid = ntohl(*(uint32_t *)buf_aux); 
            it = ntohl(*(uint32_t *)&(buf_aux[4]));
            et = ntohl(*(uint32_t *)&(buf_aux[8]));
            printf("Swid: %d, ABW: %u, Capacity: %u Kbps\n",swid,it,et);
            buf_aux+=12;
         }
     }
}

