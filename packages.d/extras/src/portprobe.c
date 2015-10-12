#include <stdio.h>
#include <string.h>    
#include <stdlib.h>    
#include <sys/socket.h>
#include <arpa/inet.h> 
#include <unistd.h>    
#include <pthread.h> 



void *connect_to_server(void *);

struct arg_struct {
        int client_socket;
        char *server_address;
    }; 

int main(int argc , char *argv[])
{
    int socket_create;

    //Create socket
   
    pthread_t threads[argc-1];
    int i;

    for(i=0; i<argc-1;i++) {

            socket_create = socket(AF_INET , SOCK_STREAM , 0);
            struct arg_struct *args = malloc(sizeof(struct arg_struct));
            (*args).client_socket = socket_create;
            (*args).server_address = argv[i+1];
            if( pthread_create( &threads[i] , NULL ,  connect_to_server , (void *)args) < 0)
                {
                //perror("could not create thread");
                return 1;
                }
   
                //Now join the thread , so that we dont terminate before the thread
                pthread_join( threads[i] , NULL);
                //puts("Handler assigned");
   } 
   return 0;
}


/*
 * This will handle connection for each server
 * */
void *connect_to_server(void *arguments)
{
    
    // struct arg_struct *args = malloc(sizeof(struct arg_struct));
    struct arg_struct *args = (struct arg_struct *)arguments; 
    struct sockaddr_in server;
    //Get the socket descriptor
    int socket_desc = (*args).client_socket;
    //int sock = *(int*)socket_desc;
    char *server_address = (*args).server_address;
    server.sin_family = AF_INET;
    server.sin_addr.s_addr = inet_addr(server_address);
    server.sin_port = htons( 80 );
    if (connect(socket_desc, (struct sockaddr *) &server, sizeof(server)) < 0) {
    fprintf(stdout,"no\n");
    }
    else {
    	fprintf(stdout,"yes\n");
    }
	
    return 0;
}
    


