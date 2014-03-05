
EXTRA_BINARIES = resolve_aufs_conflicts xattr parse_user_data merge_accounts set_quotes

all: $(EXTRA_BINARIES)

clean:
	rm -f $(EXTRA_BINARIES)

set_quotes: set_quotes.c
	gcc -O2 -Wall -o set_quotes set_quotes.c
	strip set_quotes

resolve_aufs_conflicts: resolve_aufs_conflicts.c
	gcc -O2 -Wall -o resolve_aufs_conflicts resolve_aufs_conflicts.c
	strip resolve_aufs_conflicts

xattr: xattr.c
	gcc -O2 -Wall -o xattr xattr.c
	strip xattr

parse_user_data: parse_user_data.cc
	g++ -O2 -Wall -o parse_user_data parse_user_data.cc
	strip parse_user_data

merge_accounts: merge_accounts.cc
	g++ -O2 -Wall -o merge_accounts merge_accounts.cc
	strip merge_accounts
