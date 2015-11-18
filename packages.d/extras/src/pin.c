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

  /* Create a new SID for the child process */
  sid = setsid();
  if (sid < 0)
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
  printf("%s: <working dir> <pipe> <sentinel file> <path prefix> <pin list>\n",
	       progname);
}


int main(int argc, char *argv[])
{
  if (argc < 6) {
    usage(argv[0]);
    return 1;
  }

  char *working_dir = argv[1];
	char *socket_path = argv[2];
	char *sentinel_file = argv[3];
	char *path_prefix = argv[4];
	char *pin_list = argv[5];

  char *line = NULL;
  size_t len = 0;
  ssize_t nbytes;

	int retval = chdir(working_dir);
	if (retval != 0)
		return 1;

  FILE *fp = fopen(pin_list, "r");
  if (fp == NULL) {
    fprintf(stderr, "failed to open %s\n", pin_list);
    return 2;
  }

	ssize_t buf_size = PATH_MAX + 16;
	char cmd_buffer[buf_size];

	FILE *fp_log = fopen("pin.log", "w+");

	daemonize();
	fprintf(fp_log, "daemonized\n");

	int result = 0;
  while ((nbytes = getline(&line, &len, fp)) != -1) {
		int sockfd;
		struct sockaddr_un client_addr;

		memset(&client_addr, 0, sizeof(client_addr));
		client_addr.sun_family = AF_UNIX;
		strncpy(client_addr.sun_path, socket_path, sizeof(client_addr.sun_path));

		if ((sockfd = socket(AF_UNIX, SOCK_STREAM, 0)) < 0) {
			return 20;
		}

		if (connect(sockfd, (struct sockaddr *)&client_addr, sizeof(client_addr))
			  < 0)
		{
			return 30;
		}

		strcpy(cmd_buffer, "pin ");
		strcat(cmd_buffer, path_prefix);
		strcat(cmd_buffer, line);

		fprintf(fp_log, "sending %s\n", cmd_buffer);
		if (write(sockfd, cmd_buffer, strlen(cmd_buffer) - 1) <= 0) {
			return 40;
		}

		ssize_t nreply = read(sockfd, cmd_buffer, sizeof(cmd_buffer));
		cmd_buffer[nreply] = '\0';
		fprintf(fp_log, "  reply %s\n", cmd_buffer);
		if (strcmp(cmd_buffer, "OK\n") != 0) {
			result = 50;
		}
		close(sockfd);
	}

	fclose(fp);
	fprintf(fp_log, "marking %s in %s\n", sentinel_file, getcwd(NULL, 0));
	fp = fopen(sentinel_file, "w+");
	fclose(fp);
	fclose(fp_log);
	return result;
}







