#define _GNU_SOURCE
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include </usr/include/limits.h>
#include <string.h>
#include <netinet/in.h>

/* Function that pins files in background.*/
static void daemonize(void)
{
  pid_t pid, sid;

  /* already a daemon */
  if ( getppid() == 1 ) return;

  /* Fork off the parent process */
  pid = fork();
  if (pid < 0)
  {
    exit(EXIT_FAILURE);
  }
  /* If we got a good PID, then we can exit the parent process. */
  if (pid > 0)
  {
    exit(EXIT_SUCCESS);
  }

  /* At this point we are executing as the child process */

  /* Change the file mode mask */
  umask(0);

  /* Create a new SID for the child process */
  sid = setsid();
  if (sid < 0)
  {
    exit(EXIT_FAILURE);
  }

  /* Change the current working directory.  This prevents the current
     directory from being locked; hence not being able to remove it. */
  if ((chdir("/")) < 0)
  {
    exit(EXIT_FAILURE);
  }

  /* Redirect standard files to /dev/null */
  freopen( "/dev/null", "r", stdin);
  freopen( "/dev/null", "w", stdout);
  freopen( "/dev/null", "w", stderr);
}

/*Warning if not enough arguments is given*/
static void usage(char *progname) 
{
  printf("%s: Not enough arguments\n", progname);
}

/*Method to replace particular substring for a given one*/
char *replace_str(char *str, char *original, char *new)
{
  static char buf[4096];
  char *p;

  if(!(p = strstr(str, original))) return str;
  strncpy(buf, str, p-str);
  buf[p-str] = '\0';
  sprintf(buf+(p-str), "%s%s", new, p+strlen(original));
  return buf;
}

int main(int argc, char *argv[])
{
	daemonize();
	
	if (argc < 4)
  {
    usage(argv[0]);
    return 1;
	}

	char *result = "OK";
	char *line = NULL;
	size_t len = 0;
	ssize_t read_file;
	char *filename = argv[2];
	
	FILE *fp = fopen(filename, "r");
	if (fp == NULL)
	{
	  fprintf(stdout, "fopen\n");
	  return 1;
	}

	while ((read_file = getline(&line, &len, fp)) != -1) 
	{  
	  int sockfd, nbytes;
		char *client_socket = argv[1];
		char *prefix = argv[3];
		char *buf;
		ssize_t bufSize = PATH_MAX + 1;
    char dirNameBuffer[bufSize];
		char file_link[80];
		char final_link[80];
		struct sockaddr_un client_addr;
	
		memset(&client_addr, 0, sizeof(client_addr));
		client_addr.sun_family = AF_UNIX;
		strncpy(client_addr.sun_path, client_socket, 104);
		
		// get socket
		if ((sockfd = socket(AF_UNIX, SOCK_STREAM, 0)) < 0)
		{
		perror("Socket: ");
		return 1;
		}

 		//connect client to server_filename
		if ((connect(sockfd, (struct sockaddr *) &client_addr, sizeof(client_addr))) < 0)
		{ 
		  perror("Connect: ");
		  return 1;
		}

		/* Write a message to a socket, containing files to be pinned */
		
		strcpy(file_link, "/root");
		strcat(file_link, line);
		strcpy(dirNameBuffer, "pin ");
		strcat(dirNameBuffer, file_link);
		strcpy(final_link,replace_str(dirNameBuffer, "/root", prefix));
		
		if(write(sockfd, final_link, strlen(final_link)-1) <= 0)
		{ 
		  perror("Write error: ");
		  return 1;
		}
		
		buf = final_link;
		nbytes = read(sockfd, final_link, 80);
		final_link[nbytes] = '\0';
		
		// Check if it sent a correct message
		if (buf != final_link) result = "NO";
	  close(sockfd);
	}
	
	fclose(fp);
	fprintf(stdout, "%s", result);
	return 0;	
}





