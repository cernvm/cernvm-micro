// Merges /etc/passwd, /etc/shadow, and /etc/group from new cernvm ro branch
// with local modifications on the rw branch.

#define _FILE_OFFSET_BITS 64
#define __STDC_FORMAT_MACROS

#include <inttypes.h>

#include <cstdio>

#include <vector>
#include <map>
#include <string>

using namespace std;

// Forward declarations
static string StringifyInt(const int64_t value);
static int64_t String2Int64(const string &value);
static vector<string> SplitString(const string &str, const char delim);
static string JoinStrings(const vector<string> &strings, const string &joint);


// Structs containing db fields from passwd, shadow, group
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
           JoinStrings(members, ",") + "\n";
  }

  virtual bool ReadEntry(const string &line) {
    vector<string> fields = SplitString(line, ':');
    if (fields.size() != 4)
      return false;
    group = fields[0];
    password = fields[1];
    gid = String2Int64(fields[2]);
    members = SplitString(fields[3], ',');
    return true;
  }

  string group;
  string password;
  uint64_t gid;
  vector<string> members;
};


// Helper functions
static void Usage(const char *exe) {
  printf("Usage: %s <ro base> <rw base> <uid map> <gid map> <logfile>\n", exe);
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


static string JoinStrings(const vector<string> &strings, const string &joint) {
  string result = "";
  const unsigned size = strings.size();

  if (size > 0) {
    result = strings[0];
    for (unsigned i = 1; i < size; ++i)
      result += joint + strings[i];
  }

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


// Merging algorithm
int main(int argc, char **argv) {
  if (argc < 6) {
    Usage(argv[0]);
    return 1;
  }

  string ro_base = string(argv[1]);
  string rw_base = string(argv[2]);
  FILE *fuidmap = fopen(argv[3], "w");
  if (!fuidmap) return 1;
  FILE *fgidmap = fopen(argv[4], "w");
  if (!fgidmap) return 1;
  FILE *flog = fopen(argv[5], "w");
  if (!flog) return 1;


  vector<PasswdEntry> upstream_passwd;
  vector<ShadowEntry> upstream_shadow;
  vector<GroupEntry> upstream_group;
  vector<PasswdEntry> user_passwd;
  vector<ShadowEntry> user_shadow;
  vector<GroupEntry> user_group;
  map<uint64_t, uint64_t> uid_map;
  map<uint64_t, uint64_t> gid_map;
  bool retval;

  // Load files
  fprintf(flog, "[INF] reading %s\n", (ro_base + "/passwd").c_str());
  retval = ReadAccountFile<PasswdEntry>(ro_base + "/passwd", &upstream_passwd);
  if (!retval)
    return 1;
  fprintf(flog, "[INF] reading %s\n", (rw_base + "/passwd").c_str());
  retval = ReadAccountFile<PasswdEntry>(rw_base + "/passwd", &user_passwd);
  if (!retval)
    return 1;
  fprintf(flog, "[INF] reading %s\n", (ro_base + "/shadow").c_str());
  retval = ReadAccountFile<ShadowEntry>(ro_base + "/shadow", &upstream_shadow);
  if (!retval)
    return 1;
  fprintf(flog, "[INF] reading %s\n", (rw_base + "/shadow").c_str());
  retval = ReadAccountFile<ShadowEntry>(rw_base + "/shadow", &user_shadow);
  if (!retval)
    return 1;
  fprintf(flog, "[INF] reading %s\n", (ro_base + "/group").c_str());
  retval = ReadAccountFile<GroupEntry>(ro_base + "/group", &upstream_group);
  if (!retval)
    return 1;
  fprintf(flog, "[INF] reading %s\n", (rw_base + "/group").c_str());
  retval = ReadAccountFile<GroupEntry>(rw_base + "/group", &user_group);
  if (!retval)
    return 1;

  // Mapping user ids:
  //   - new upstream entries are copied.
  //   - conflicting names get uid of the user db
  //   - conflicting uids are mapped to free ones
  for (unsigned i = 0; i < upstream_passwd.size(); ++i) {
    bool found_account = false;
    string upstream_account = upstream_passwd[i].account;
    uint64_t upstream_uid = upstream_passwd[i].uid;

    for (unsigned j = 0; j < user_passwd.size(); ++j) {
      string user_account = user_passwd[j].account;
      uint64_t user_uid = user_passwd[j].uid;
      if (user_account == upstream_account) {
        found_account = true;
        if ()
      }
    }

    if (!found_account)
      user_passwd.push_back(upstream_passwd[i]);
  }

  // Merge group memberships

  // Merge shadow db

  // Backup user databases

  // Write new user databases

  // Write map files

  fclose(flog);
  fclose(fuidmap);
  fclose(fgidmap);
  return 0;
}
