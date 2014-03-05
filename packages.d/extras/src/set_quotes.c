
#include <stdio.h>

int main(int argc, char **argv) {
  if (argc < 2) {
    printf("Usage: %s param\n", argv[0]);
    return 1;
  }

  if (argv[1][0] != '"')
    printf("\"%s\"\n", argv[1]);
  else
    printf("%s\n", argv[1]);
  
  return 0;
}

