/**
 * This file is part of CernVM
 *
 * Listens on a socket for regular pings.  If they go missing, shut off the 
 * machine.  Helps to automatically remove stuck virtual machines.  
 */

#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/reboot.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/select.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#define VERSION 1.0

char *fifo_path = NULL;
char *log_file = NULL;
int timeout = 0;

FILE *f_log_file = NULL;
int fd_fifo = -1;

static void Usage(char *progname) {
  printf("Usage: %s [-d] -f <fifo path> -t <timeout> -l <log file>\n", progname);
  printf("Version %.1f\n", VERSION);
}

static void Log(char *msg) {
  time_t rawtime;
  time(&rawtime);
  struct tm now;
  localtime_r(&rawtime, &now);
  fprintf(f_log_file, "%s    [%02d-%02d-%04d %02d:%02d:%02d %s]\n", 
          msg, (now.tm_mon)+1, now.tm_mday, (now.tm_year)+1900, now.tm_hour,
          now.tm_min, now.tm_sec, now.tm_zone);
  fflush(f_log_file);
}

static void PowerOff() {
  Log("powering off");
  sync();
  reboot(LINUX_REBOOT_CMD_POWER_OFF);
}

static int AttachPipe() {
  int fd = open(fifo_path, O_RDONLY | O_NONBLOCK);
  if (fd < 0)
    return fd;

  int flags = fcntl(fd, F_GETFL);
  assert(flags != -1);
  int retval = fcntl(fd, F_SETFL, flags & ~O_NONBLOCK);
  assert(retval != -1);
  return fd;
}

static char *ParentDir(char *path) {
  char *dir = strdup(path);
  assert(dir != NULL);
  char *last_sep = strrchr(dir, '/');
  if (last_sep == NULL)
    return "./";
  *last_sep = '\0';
  if (strlen(dir) == 0)
    return "/";
  return dir;
}

static char *FileName(char *path) {
  char *file_name = strdup(path);
  assert(file_name != NULL);
  char *last_sep = strrchr(file_name, '/');
  if (last_sep == NULL)
    return file_name;
  return last_sep + 1;
}


int main(int argc, char **argv) {
  int daemonize = 0;
  int opt;
  while ((opt = getopt(argc, argv, "df:t:l:hv")) != -1) {
    switch (opt) {
      case 'd':
        daemonize = 1;
        break;
      case 'f':
        fifo_path = optarg;
        break;
      case 'l':
        log_file = optarg;
        break;
      case 't':
        timeout = atoi(optarg);
        break;
      case 'h':
      case 'v':
        Usage(argv[0]);
        return 0;
      default:
        Usage(argv[0]);
        return 1;
    }
  }

  if (!fifo_path || !log_file || timeout < 0) {
    Usage(argv[0]);
    return 1;
  }

  f_log_file = fopen(log_file, "a");
  if (f_log_file == NULL) {
    fprintf(stderr, "failed to open %s\n", log_file);
    return 2;
  }

  int retval;
  retval = mkfifo(fifo_path, 0600);
  if (retval != 0) {
    if (errno == EEXIST) {
      printf("FIFO exists, removing\n");
      unlink(fifo_path);
    }
    retval = mkfifo(fifo_path, 0600);
    if (retval != 0) {
      fprintf(stderr, "failed to create FIFO %s\n", fifo_path);
      return 2;
    }
  }

  fd_fifo = AttachPipe();
  if (fd_fifo < 0) {
    fprintf(stderr, "failed to attach to FIFO %s\n", fifo_path);
    return 2;
  }
  
  Log("start daemon");
  if (daemonize) {
    // Don't change to / but close stdin, stdout, stderr
    retval = daemon(1, 0);
    if (retval != 0) {
      Log("failed to daemonize");
      return 2;
    }
  }

  // The directory tree vanishes on switch_root
  retval = chdir(ParentDir(fifo_path));
  assert(retval == 0);
  fifo_path = FileName(fifo_path);

  // Loop on the pipe
  struct timespec tp_start;
  struct timespec tp_stop;
  struct timeval tv_timeout;
  fd_set fds_rd, fds_wr, fds_err;
  int nfds;
  retval = clock_gettime(CLOCK_MONOTONIC, &tp_start);
  assert(retval == 0);
  do {
    FD_ZERO(&fds_rd);
    FD_ZERO(&fds_wr);
    FD_ZERO(&fds_err);
    FD_SET(fd_fifo, &fds_rd);
    nfds = fd_fifo + 1;
    tv_timeout.tv_sec = timeout;
    tv_timeout.tv_usec = 0;
   
    retval = select(nfds, &fds_rd, &fds_wr, &fds_err, &tv_timeout);
    if (retval == -1) {
      Log("select() error");
      return 3;
    }

    if (retval == 0) {
      retval = clock_gettime(CLOCK_MONOTONIC, &tp_stop);
      assert(retval == 0);
      // Up to a second too tight
      tp_start.tv_sec--;
      if ((tp_stop.tv_sec - tp_start.tv_sec) > timeout)
        PowerOff();
    } else {
      char cmd;
      retval = read(fd_fifo, &cmd, 1);
      assert(retval >= 0);
      if (retval == 0) {
        // Reopen pipe
        fd_fifo = AttachPipe();
        assert(fd_fifo >= 0);
      } else {
        switch (cmd) {
          case 'G':
            Log("still healthy");
            retval = clock_gettime(CLOCK_MONOTONIC, &tp_start);
            assert(retval == 0);
            break;
          case 'K':
            Log("stop daemon");
            return 0;
          default:
            Log("unknown command");
        }
      }
    }
  } while (1);
  
  return 0;
}

