// Merges /etc/passwd, /etc/shadow, and /etc/group from new cernvm ro branch
// with local modifications on the rw branch.

#define _FILE_OFFSET_BITS 64
#define __STDC_FORMAT_MACROS

#include <inttypes.h>

#include <cstdio>

#include <vector>
#include <string>

using namespace std;

string g_ro_base;
string g_rw_base;
FILE *g_flog;

static string StringifyInt(const int64_t value);
static vector<string> SplitString(const string &str, const char delim);
static int64_t String2Int64(const string &value);

class AccountEntry {
  virtual string MakeEntry() = 0;
  virtual bool ReadEntry(const string &line) = 0;
};


class PasswdEntry : public AccountEntry {
 public:
  virtual string MakeEntry() {
    return account + ":" + password + ":" + StringifyInt(uid) + ":" +
           StringifyInt(gid) + ":" + gecos + ":" + home_directory + ":" +
           shell + "\n";
  }
  virtual bool ReadEntry(const string &line) {
    vector<string> fields = SplitString(line, ':');
    if (fields.size() != 7)
      return false;
    account = fields[0];
    password = fields[1];
    uid = String2Int64(fields[2]);
    gid = String2Int64(fields[3]);
    gecos = fields[4];
    home_directory = fields[5];
    shell = fields[6];
    return true;
  }

  string account;
  string password;
  uint64_t uid;
  uint64_t gid;
  string gecos;
  string home_directory;
  string shell;
};

struct ShadowEntry {
  virtual string MakeEntry() {
    return account + ":" + password + ":" + last_change + ":" + min_age + ":" +
           max_age + ":" + warn_period + ":" + inactivity_period + ":" +
           exp_date + ":" + reserved + "\n";
  }
  virtual bool ReadEntry(const string &line) {
    vector<string> fields = SplitString(line, ':');
    if (fields.size() != 9)
      return false;
    account = fields[0];
    password = fields[1];
    last_change = fields[2];
    min_age = fields[3];
    max_age = fields[4];
    warn_period = fields[5];
    inactivity_period = fields[6];
    exp_date = fields[7];
    reserved = fields[8];
    return true;
  }

  string account;
  string password;
  string last_change;
  string min_age;
  string max_age;
  string warn_period;
  string inactivity_period;
  string exp_date;
  string reserved;
};

struct GroupEntry {
  virtual string MakeEntry() {
    return group + ":" + password + ":" + StringifyInt(gid) + ":" +
           member + "\n";
  }

  virtual bool ReadEntry(const string &line) {
    vector<string> fields = SplitString(line, ':');
    if (fields.size() != 4)
      return false;
    group = fields[0];
    password = fields[1];
    gid = String2Int64(fields[2]);
    member = fields[3];
    return true;
  }

  string group;
  string password;
  uint64_t gid;
  string member;
};


static void Usage(const char *exe) {
  printf("Usage: %s <ro base> <rw base> <logfile>\n", exe);
}


static string StringifyInt(const int64_t value) {
  char buffer[48];
  snprintf(buffer, sizeof(buffer), "%"PRId64, value);
  return string(buffer);
}


static int64_t String2Int64(const string &value) {
  int64_t result;
  sscanf(value.c_str(), "%"PRId64, &result);
  return result;
}


static bool GetLineFile(FILE *f, string *line) {
  int retval;
  line->clear();
  while ((retval = fgetc(f)) != EOF) {
    char c = retval;
    if (c == '\n')
      break;
    line->push_back(c);
  }
  return (retval != EOF) || !line->empty();
}


static vector<string> SplitString(const string &str, const char delim) {
  vector<string> result;

  const unsigned size = str.size();
  unsigned marker = 0;
  unsigned i;
  for (i = 0; i < size; ++i) {
    if (str[i] == delim) {
      result.push_back(str.substr(marker, i-marker));
      marker = i+1;
    }
  }

  result.push_back(str.substr(marker));
  return result;
}

template <class AccountEntryType>
static bool ReadAccountFile(const string &filename,
                            vector<AccountEntryType> *entries)
{
  FILE *file = fopen(filename.c_str(), "r");
  if (!file)
    return false;

  string line;
  while (GetLineFile(file, &line)) {
    AccountEntryType this_entry;
    bool retval = this_entry.ReadEntry(line);
    if (!retval) {
      fclose(file);
      return false;
    }
    entries->push_back(this_entry);
  }
  fclose(file);
  return true;
}


template <class AccountEntryType>
static bool WriteAccountFile(const string &filename,
                             vector<AccountEntryType> &entries)
{
  FILE *file = fopen(filename.c_str(), "w");
  if (!file)
    return false;

  for (unsigned i = 0; i < entries.size(); ++i) {
    int retval = fprintf(file, "%s", entries[i].MakeEntry().c_str());
    if (retval < 0) {
      fclose(file);
      return false;
    }
  }
  fclose(file);
  return true;
}


int main(int argc, char **argv) {
  if (argc < 4) {
    Usage(argv[0]);
    return 1;
  }

  g_ro_base = string(argv[1]);
  g_rw_base = string(argv[2]);
  g_flog = fopen(argv[3], "w");

  vector<PasswdEntry> ro_passwd;
  vector<ShadowEntry> ro_shadow;
  vector<GroupEntry> ro_group;

  bool retval = ReadAccountFile<PasswdEntry>("/etc/passwd", &ro_passwd);
  if (!retval)
    return 1;
  retval = WriteAccountFile<PasswdEntry>("test-passwd", ro_passwd);
  if (!retval)
    return 1;
  retval = ReadAccountFile<ShadowEntry>("/etc/shadow", &ro_shadow);
  if (!retval)
    return 1;
  retval = WriteAccountFile<ShadowEntry>("test-shadow", ro_shadow);
  if (!retval)
    return 1;
  retval = ReadAccountFile<GroupEntry>("/etc/group", &ro_group);
  if (!retval)
    return 1;
  retval = WriteAccountFile<GroupEntry>("test-group", ro_group);
  if (!retval)
    return 1;

  return 0;
}
