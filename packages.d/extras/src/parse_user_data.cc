
// Parses µCernVM part of user data:
// [ucernvm-begin]
// key=value
// ...
// [ucernvm-end]

#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>

#include <cstdio>
#include <string>
#include <vector>

using namespace std;


vector<string> SplitString(const string &str,
                           const char delim,
                           const unsigned max_chunks)
{
  vector<string> result;

  // edge case... one chunk is always the whole string
  if (1 == max_chunks) {
    result.push_back(str);
    return result;
  }

  // split the string
  const unsigned size = str.size();
  unsigned marker = 0;
  unsigned chunks = 1;
  unsigned i;
  for (i = 0; i < size; ++i) {
    if (str[i] == delim) {
      result.push_back(str.substr(marker, i-marker));
      marker = i+1;

      // we got what we want... good bye
      if (++chunks == max_chunks)
        break;
    }
  }

  // push the remainings of the string and return
  result.push_back(str.substr(marker));
  return result;
}


static string ToUpper(const string &mixed_case) {
  string result(mixed_case);
  for (unsigned i = 0, l = result.length(); i < l; ++i) {
    result[i] = toupper(result[i]);
  }
  return result;
}


int main() {
  bool in_ucontext = false;
  string line;
  char buf;
  while (read(STDIN_FILENO, &buf, 1) == 1) {
    if (buf == '\n') {
      if (line == "[ucernvm-begin]") {
        in_ucontext = true;
        line="";
        continue;
      }
      if (line == "[ucernvm-end]")
        break;

      if (in_ucontext) {
        vector<string> keyval = SplitString(line, '=', 2);
        if (keyval.size() == 2) {
          if (ToUpper(keyval[1]) == "YES" || ToUpper(keyval[1]) == "ON" ||
              ToUpper(keyval[1]) == "TRUE")
          {
            keyval[1] = "1";
          }
          if (ToUpper(keyval[1]) == "NO" || ToUpper(keyval[1]) == "OFF" ||
              ToUpper(keyval[1]) == "FALSE")
          {
            keyval[1] = "0";
          }
          printf("_UCONTEXT_%s=%s\n",
                 ToUpper(keyval[0]).c_str(), keyval[1].c_str());
        }
      }

      line = "";
    } else {
      line.push_back(buf);
    }
  }
  return 0;
}
