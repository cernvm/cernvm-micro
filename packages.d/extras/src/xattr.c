#include <stdio.h>
#include <sys/types.h>
#include <attr/xattr.h>

int main(int argc, char **argv) {
  char value[4096];
  ssize_t retval = getxattr(argv[1], argv[2], value, 4096);
  if (retval >= 4096)
    return 1;
  value[retval] = '\0';
  printf("%s", value);
  return retval >= 0;
}

