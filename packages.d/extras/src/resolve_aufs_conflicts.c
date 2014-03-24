
#define _GNU_SOURCE
#define _FILE_OFFSET_BITS 64

#include <alloca.h>
#include <sys/types.h>
#include <dirent.h>
#include <unistd.h>
#include <sys/stat.h>
#include <errno.h>

#include <stdio.h>
#include <assert.h>
#include <string.h>

int g_num_files = 0;
int g_rw_base_len;
const char *g_ro_base;
const char *g_rw_base;
FILE *g_flog;

static void Usage(const char *exe) {
  printf("Usage: %s <ro base> <rw base> <logfile>\n", exe);
}

static void WalkCwd(const char *path, const unsigned level,
                    const int in_etc, const int in_var, const int in_var_lib,
                    const int in_var_lib_rpm, const int in_root)
{
  DIR *dirp = opendir(".");
  if (!dirp) {
    fprintf(stderr, "failed to open %s\n", path);
    return;
  }

  struct dirent64 *dentry;
  while ((dentry = readdir64(dirp)) != NULL) {
    int new_base_len;
    int rw_path_len;
    char *new_base;
    char *rw_path_deleted;
    char *rw_path_modified;
    int retval;

    if ((++g_num_files % 1000) == 0) {
      printf(".");
      fflush(stdout);
    }

    if ((strcmp(dentry->d_name, ".") == 0) ||
        (strcmp(dentry->d_name, "..") == 0))
    {
      continue;
    }

    // Check on scratch path
    struct stat64 info;
    rw_path_len = g_rw_base_len + 1 + strlen(path) + 256 + 8;
    rw_path_modified = alloca(rw_path_len);
    rw_path_deleted = alloca(rw_path_len);

    strncpy(rw_path_modified, g_rw_base, rw_path_len);
    strncat(rw_path_modified, "/", rw_path_len);
    strncat(rw_path_modified, path, rw_path_len);
    strncat(rw_path_modified, "/", rw_path_len);
    strncat(rw_path_modified, dentry->d_name, rw_path_len);
    int modified_on_scratch = lstat64(rw_path_modified, &info) == 0;

    strncpy(rw_path_deleted, g_rw_base, rw_path_len);
    strncat(rw_path_deleted, "/", rw_path_len);
    strncat(rw_path_deleted, path, rw_path_len);
    strncat(rw_path_deleted, "/.wh.", rw_path_len);
    strncat(rw_path_deleted, dentry->d_name, rw_path_len);
    int deleted_on_scratch = lstat64(rw_path_deleted, &info) == 0;

    if (deleted_on_scratch) {
      fprintf(g_flog, "restore %s/%s", path, dentry->d_name);
      int retval = unlink(rw_path_deleted);
      if (retval == 0)
        fprintf(g_flog, "\n");
      else
        fprintf(g_flog, "... FAILED (%d)\n", errno);
    }

    switch (dentry->d_type) {
      case DT_REG:
      case DT_LNK:
        if (modified_on_scratch) {
          if ((in_etc || in_var || in_root) && !in_var_lib_rpm) {
            fprintf(g_flog, "preserve %s/%s\n", path, dentry->d_name);
          } else {
            fprintf(g_flog, "rebase %s/%s", path, dentry->d_name);
            int retval = unlink(rw_path_modified);
            if (retval == 0)
              fprintf(g_flog, "\n");
            else
              fprintf(g_flog, "... FAILED (%d)\n", errno);
          }
        }
        break;
      case DT_DIR:
        new_base_len = strlen(path) + 1 + 256 + 1;
        new_base = alloca(new_base_len);
        strncpy(new_base, path, new_base_len);
        strncat(new_base, "/", new_base_len);
        strncat(new_base, dentry->d_name, new_base_len);
        retval = chdir(dentry->d_name);
        if (retval != 0) {
          fprintf(stderr, "failed to chdir %s\n", new_base);
        } else {
          int next_in_etc =
            in_etc || ((level == 0) && (strcmp(dentry->d_name, "etc") == 0));
          int next_in_var =
            in_var || ((level == 0) && (strcmp(dentry->d_name, "var") == 0));
          int next_in_var_lib =
            in_var_lib ||
            (in_var && (level == 1) && (strcmp(dentry->d_name, "lib") == 0));
          int next_in_var_lib_rpm =
            in_var_lib_rpm ||
            (in_var_lib && (level == 2) && (strcmp(dentry->d_name, "rpm") == 0));
          int next_in_root = 
            in_root || ((level == 0) && (strcmp(dentry->d_name, "root") == 0));
          WalkCwd(new_base, level+1,
                  next_in_etc, next_in_var, next_in_var_lib, next_in_var_lib_rpm,
                  next_in_root);
          retval = chdir("..");
          assert(retval == 0);
        }
        break;
      default:
        fprintf(stderr, "unknown file type: %s\n", path);
    }
  }

  closedir(dirp);
}


int main(int argc, char **argv) {
  if (argc < 4) {
    Usage(argv[0]);
    return 1;
  }

  g_ro_base = argv[1];
  g_rw_base = argv[2];
  g_rw_base_len = strlen(g_rw_base);
  g_flog = fopen(argv[3], "w");

  int retval = chdir(g_ro_base);
  if (retval != 0) {
    fprintf(stderr, "failed to chdir %s\n", g_ro_base);
    return 1;
  }
  WalkCwd("", 0,
          0, 0, 0, 0, 0);
  //printf("\n");
  fclose(g_flog);

  return 0;
}
