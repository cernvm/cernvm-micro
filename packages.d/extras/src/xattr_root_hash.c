#include <stdio.h>
#include <sys/types.h>
#include <attr/xattr.h>

int main(int argc, char **argv) {
  char hash[64];
  ssize_t retval = getxattr(argv[1], "user.root_hash", hash, 64);
  if (retval >= 64)
    return 1;
  hash[retval] = '\0';
  printf("%s", hash);
  return retval >= 0;
}

