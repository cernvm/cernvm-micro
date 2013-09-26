
EXTRA_BINARIES = resolve_aufs_conflicts xattr_root_hash parse_user_data

all: $(EXTRA_BINARIES)

clean:
	rm -f $(EXTRA_BINARIES)

resolve_aufs_conflicts: resolve_aufs_conflicts.c
	gcc -O2 -Wall -o resolve_aufs_conflicts resolve_aufs_conflicts.c
	strip resolve_aufs_conflicts

xattr_root_hash: xattr_root_hash.c
	gcc -O2 -Wall -o xattr_root_hash xattr_root_hash.c
	strip xattr_root_hash

parse_user_data: parse_user_data.cc
	g++ -O2 -Wall -o parse_user_data parse_user_data.cc
	strip parse_user_data
