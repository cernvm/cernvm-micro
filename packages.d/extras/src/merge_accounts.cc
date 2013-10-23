// Merges /etc/passwd, /etc/shadow, and /etc/group from new cernvm ro branch
// with local modifications on the rw branch.

// TODO: proper set data structures for users and groups

#define _FILE_OFFSET_BITS 64
#define __STDC_FORMAT_MACROS

#include <inttypes.h>
#include <sys/stat.h>

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

struct ShadowEntry : public AccountEntry {
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

struct GroupEntry : public AccountEntry {
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

struct GShadowEntry : public AccountEntry {
  virtual string MakeEntry() {
    return group + ":" + password + ":" + JoinStrings(administrators, ",") +
           ":" + JoinStrings(members, ",") + "\n";
  }

  virtual bool ReadEntry(const string &line) {
    vector<string> fields = SplitString(line, ':');
    if (fields.size() != 4)
      return false;
    group = fields[0];
    password = fields[1];
    administrators = SplitString(fields[2], ',');
    members = SplitString(fields[3], ',');
    return true;
  }

  string group;
  string password;
  vector<string> administrators;
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
  if ((result.size() == 1) && (result[0].empty()))
    result.pop_back();
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

static bool FileExists(const string &path) {
  struct stat64 info;
  return ((lstat64(path.c_str(), &info) == 0) &&
         S_ISREG(info.st_mode));
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
  vector<GShadowEntry> upstream_gshadow;
  vector<PasswdEntry> user_passwd;
  vector<ShadowEntry> user_shadow;
  vector<GroupEntry> user_group;
  vector<GShadowEntry> user_gshadow;
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
  if (FileExists(ro_base + "/shadow")) {
    fprintf(flog, "[INF] reading %s\n", (ro_base + "/shadow").c_str());
    retval = ReadAccountFile<ShadowEntry>(ro_base + "/shadow", &upstream_shadow);
    if (!retval)
      return 1;
  }
  if (FileExists(rw_base + "/shadow")) {
    fprintf(flog, "[INF] reading %s\n", (rw_base + "/shadow").c_str());
    retval = ReadAccountFile<ShadowEntry>(rw_base + "/shadow", &user_shadow);
    if (!retval)
      return 1;
  }
  fprintf(flog, "[INF] reading %s\n", (ro_base + "/group").c_str());
  retval = ReadAccountFile<GroupEntry>(ro_base + "/group", &upstream_group);
  if (!retval)
    return 1;
  fprintf(flog, "[INF] reading %s\n", (rw_base + "/group").c_str());
  retval = ReadAccountFile<GroupEntry>(rw_base + "/group", &user_group);
  if (!retval)
    return 1;
  if (FileExists(ro_base + "/gshadow")) {
    fprintf(flog, "[INF] reading %s\n", (ro_base + "/gshadow").c_str());
    retval = ReadAccountFile<GShadowEntry>(ro_base + "/gshadow", &upstream_gshadow);
    if (!retval)
      return 1;
  }
  if (FileExists(rw_base + "/gshadow")) {
    fprintf(flog, "[INF] reading %s\n", (rw_base + "/gshadow").c_str());
    retval = ReadAccountFile<GShadowEntry>(rw_base + "/gshadow", &user_gshadow);
    if (!retval)
      return 1;
  }

  // Find highest free uid/gid
  uint64_t next_uid = 0;
  uint64_t next_gid = 0;
  for (unsigned i = 0; i < user_passwd.size(); ++i) {
    if (user_passwd[i].uid >= next_uid)
      next_uid = user_passwd[i].uid+1;
  }
  for (unsigned i = 0; i < user_group.size(); ++i) {
    if (user_group[i].gid >= next_gid)
      next_gid = user_group[i].gid+1;
  }

  // Map group ids:
  //   - new upstream entries are copied.
  //   - conflicting names get uid of the user db
  //   - conflicting uids are mapped to free ones
  //   - Merge members from user and upstream groups
  //   - Merge members in gshadow as well
  //   - Update upstream passwd for mapped group ids
  for (unsigned i = 0; i < upstream_group.size(); ++i) {
    bool found_group = false;
    string upstream_account = upstream_group[i].group;
    uint64_t upstream_gid = upstream_group[i].gid;
    uint64_t mapped_gid = upstream_gid;

    for (unsigned j = 0; j < user_group.size(); ++j) {
      string user_account = user_group[j].group;
      uint64_t user_gid = user_group[j].gid;
      if (user_account == upstream_account) {
        found_group = true;
        if (user_gid != upstream_gid) {
          fprintf(flog, "[GROUP] mapping %s gid %"PRIu64" to existing %"PRIu64"\n",
                  upstream_account.c_str(), upstream_gid, user_gid);
          mapped_gid = user_gid;
          gid_map[upstream_gid] = mapped_gid;
        }

        // Merge members
        for (unsigned k = 0; k < upstream_group[i].members.size(); ++k) {
          bool found_member = false;
          for (unsigned l = 0; l < user_group[j].members.size(); ++l) {
            if (upstream_group[i].members[k] == user_group[j].members[l]) {
              found_member = true;
              break;
            }
          }
          if (!found_member) {
            fprintf(flog, "[GROUP] merge %s member %s with user's group database\n",
                    upstream_account.c_str(), upstream_group[i].members[k].c_str());
            user_group[j].members.push_back(upstream_group[i].members[k]);
          }
        }
        break;
      }
    }

    // Merge gshadow members
    for (unsigned j = 0; j < user_gshadow.size(); ++j) {
      string user_account = user_gshadow[j].group;
      if (user_account == upstream_account) {
        for (unsigned k = 0; k < upstream_group[i].members.size(); ++k) {
          bool found_member = false;
          for (unsigned l = 0; l < user_gshadow[j].members.size(); ++l) {
            if (upstream_group[i].members[k] == user_gshadow[j].members[l]) {
              found_member = true;
              break;
            }
          }
          if (!found_member) {
            fprintf(flog, "[GSHADOW] merge %s member %s with user's gshadow database\n",
                    upstream_account.c_str(), upstream_group[i].members[k].c_str());
            user_gshadow[j].members.push_back(upstream_group[i].members[k]);
          }
        }
        break;
      }
    }

    if (!found_group) {
      for (unsigned j = 0; j < user_group.size(); ++j) {
        string user_account = user_group[j].group;
        uint64_t user_gid = user_group[j].gid;
        if (user_gid == upstream_gid) {
          fprintf(flog,
                  "[GROUP] gid conflict of %s with %s, "
                  "mapping %"PRIu64" to %"PRIu64"\n", upstream_account.c_str(),
                  user_account.c_str(), upstream_gid, next_gid);
          mapped_gid = next_gid;
          gid_map[upstream_gid] = mapped_gid;
          upstream_group[i].gid = mapped_gid;
          next_gid++;
          break;
        }
      }
    }

    if (!found_group) {
      fprintf(flog, "[GROUP] copy group %s from upstream database\n",
              upstream_account.c_str());
      user_group.push_back(upstream_group[i]);
    }

    if (mapped_gid != upstream_gid) {
      for (unsigned j = 0; j < upstream_passwd.size(); ++j) {
        if (upstream_passwd[j].gid == upstream_gid) {
          fprintf(flog, "[PASSWD] turn gid %"PRIu64" of user %s into %"PRIu64"\n",
                  upstream_passwd[j].gid, upstream_passwd[j].account.c_str(),
                  mapped_gid);
          upstream_passwd[j].gid = mapped_gid;
        }
      }
    }
  }

  // Map user ids:
  //   - new upstream entries are copied.
  //   - conflicting names get gid of the user db
  //   - conflicting gids are mapped to free ones
  for (unsigned i = 0; i < upstream_passwd.size(); ++i) {
    bool found_account = false;
    string upstream_account = upstream_passwd[i].account;
    uint64_t upstream_uid = upstream_passwd[i].uid;

    for (unsigned j = 0; j < user_passwd.size(); ++j) {
      string user_account = user_passwd[j].account;
      uint64_t user_uid = user_passwd[j].uid;
      if (user_account == upstream_account) {
        found_account = true;
        if (user_uid != upstream_uid) {
          fprintf(flog, "[PASSWD] mapping %s uid %"PRIu64" to existing %"PRIu64"\n",
                  upstream_account.c_str(), upstream_uid, user_uid);
          uid_map[upstream_uid] = user_uid;
        }
        break;
      }
    }
    if (!found_account) {
      for (unsigned j = 0; j < user_passwd.size(); ++j) {
        string user_account = user_passwd[j].account;
        uint64_t user_uid = user_passwd[j].uid;
        if (user_uid == upstream_uid) {
          fprintf(flog,
                  "[PASSWD] uid conflict of %s with %s, "
                  "mapping %"PRIu64" to %"PRIu64"\n", upstream_account.c_str(),
                  user_account.c_str(), upstream_uid, next_uid);
          uid_map[upstream_uid] = next_uid;
          upstream_passwd[i].uid = next_uid;
          next_uid++;
          break;
        }
      }
    }

    if (!found_account) {
      fprintf(flog, "[PASSWD] copy user %s from upstream database\n",
              upstream_account.c_str());
      user_passwd.push_back(upstream_passwd[i]);
    }
  }


  // Merge shadow db
  // only copy new entries from upstream
  for (unsigned i = 0; i < upstream_shadow.size(); ++i) {
    bool found_account = false;
    string upstream_account = upstream_shadow[i].account;
    for (unsigned j = 0; j < user_shadow.size(); ++j) {
      string user_account = user_shadow[j].account;
      if (user_account == upstream_account) {
        found_account = true;
        break;
      }
    }
    if (!found_account) {
      fprintf(flog, "[SHADOW] copy shadow entry %s from upstream database\n",
              upstream_account.c_str());
      user_shadow.push_back(upstream_shadow[i]);
    }
  }

  // Merge gshadow db
  //  - copy new entries from upstream
  for (unsigned i = 0; i < upstream_gshadow.size(); ++i) {
    bool found_account = false;
    string upstream_account = upstream_gshadow[i].group;
    for (unsigned j = 0; j < user_gshadow.size(); ++j) {
      string user_account = user_gshadow[j].group;
      if (user_account == upstream_account) {
        found_account = true;
        break;
      }
    }
    if (!found_account) {
      fprintf(flog, "[GSHADOW] copy gshadow entry %s from upstream database\n",
              upstream_account.c_str());
      user_gshadow.push_back(upstream_gshadow[i]);
    }
  }

  // Write new user databases
  fprintf(flog, "[INF] writing %s\n", (rw_base + "/passwd.merged").c_str());
  retval = WriteAccountFile<PasswdEntry>(rw_base + "/passwd.merged", user_passwd);
  if (!retval)
    return 1;
  fprintf(flog, "[INF] writing %s\n", (rw_base + "/group.merged").c_str());
  retval = WriteAccountFile<GroupEntry>(rw_base + "/group.merged", user_group);
  if (!retval)
    return 1;
  if (FileExists(ro_base + "/shadow")) { 
    fprintf(flog, "[INF] writing %s\n", (rw_base + "/shadow.merged").c_str());
    retval = WriteAccountFile<ShadowEntry>(rw_base + "/shadow.merged", user_shadow);
    if (!retval)
      return 1;
  }
  if (FileExists(rw_base + "/gshadow")) {
    fprintf(flog, "[INF] writing %s\n", (rw_base + "/gshadow.merged").c_str());
    retval = WriteAccountFile<GShadowEntry>(rw_base + "/gshadow.merged", user_gshadow);
    if (!retval)
      return 1;
  }

  // Write map files
  fprintf(flog, "[INF] writing uid map\n");
  for (map<uint64_t, uint64_t>::const_iterator i = uid_map.begin();
       i != uid_map.end(); ++i)
  {
    fprintf(fuidmap, "%"PRIu64" %"PRIu64"\n", i->first, i->second);
  }
  fclose(fuidmap);

  fprintf(flog, "[INF] writing gid map\n");
  for (map<uint64_t, uint64_t>::const_iterator i = gid_map.begin();
       i != gid_map.end(); ++i)
  {
    fprintf(fgidmap, "%"PRIu64" %"PRIu64"\n", i->first, i->second);
  }
  fclose(fgidmap);

  fclose(flog);
  return 0;
}
