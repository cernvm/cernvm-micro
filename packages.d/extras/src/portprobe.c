/**
 * Using IP addresses and timeout as input arguments, check if the
 * user is connected to any of them by doing that in parallel using 
 * pthreads. If time deadline expires, return.
 * Return value is combination of bits related to each IP address
 * that are set to 1 if connected.
 */

#include <arpa/inet.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <time.h>
#include <unistd.h>


struct arg_struct {
  int client_socket;
  char *server_address;
  int idx;
};


/**
 * Every thread writes the return value in this array.
 */
int *return_values;
pthread_mutex_t lock_return_values = PTHREAD_MUTEX_INITIALIZER;

/**
 * This will handle connection for each server
 */
static void *connect_to_server(void *arguments)
{
  struct arg_struct *args = (struct arg_struct *)arguments;
  struct sockaddr_in server;
  // Get the socket descriptor
  int socket_desc = args->client_socket;
  char *server_address = args->server_address;
  server.sin_family = AF_INET;
  server.sin_addr.s_addr = inet_addr(server_address);
  server.sin_port = htons(80);
  if (connect(socket_desc, (struct sockaddr *) &server, sizeof(server)) < 0) {
    pthread_mutex_lock(&lock_return_values);
    return_values[args->idx] = 0;
    pthread_mutex_unlock(&lock_return_values);
  } else {
    pthread_mutex_lock(&lock_return_values);
    return_values[args->idx] = 1;
    pthread_mutex_unlock(&lock_return_values);

  }

  return NULL;
}


static void usage(char *progname) {
  printf("%s <IP 1> <IP 2> ... <timeout (s)>\n", progname);
}


int main(int argc , char *argv[])
{
  if (argc < 3) {
    usage(argv[0]);
    return 1;
  }

  int timeout = atoi(argv[argc-1]);
  unsigned N = argc - 2;

  int socket_create;
  pthread_t threads[N];
  return_values = malloc(N * sizeof(int));
  int i;

  for (i = 0; i < N; i++) {
    socket_create = socket(AF_INET , SOCK_STREAM , 0);
    struct arg_struct *args = malloc(sizeof(struct arg_struct));
    args->client_socket = socket_create;
    args->server_address = argv[i+1];
    args->idx = i;
    return_values[i] = -1;
    if (pthread_create(&threads[i], NULL, connect_to_server, (void *)args) < 0)
    {
      return 2;
    }
  }

  int result = 0;
  int n_picked_up = 0;
  int time_start = time(NULL);
  int now = time_start;
  while ((n_picked_up < N) && (now - time_start < timeout)) {
    for (i = 0; i < N; i++) {
      pthread_mutex_lock(&lock_return_values);
      int this_retval = return_values[i];
      pthread_mutex_unlock(&lock_return_values);

      if (this_retval == -1)
        continue;

      if (this_retval == 1) {
        result |= (1 << i);
      }
      n_picked_up++;

      // Reset
      pthread_mutex_lock(&lock_return_values);
      return_values[i] = -1;
      pthread_mutex_unlock(&lock_return_values);
    }
    now = time(NULL);
  }


  return result;
}
