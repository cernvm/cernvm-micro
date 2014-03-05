include $(TOP)/config.mk
include config.mk

EXTRAS_BINARIES = \
  extras-$(EXTRAS_STRONG_VERSION)/bin/parse_user_data \
  extras-$(EXTRAS_STRONG_VERSION)/bin/xattr \
  extras-$(EXTRAS_STRONG_VERSION)/bin/resolve_aufs_conflicts \
  extras-$(EXTRAS_STRONG_VERSION)/bin/merge_accounts \
  extras-$(EXTRAS_STRONG_VERSION)/bin/reset_root_password \
  extras-$(EXTRAS_STRONG_VERSION)/bin/set_quotes
EXTRAS_BUILD_PRODUCTS = \
  src/parse_user_data \
  src/xattr \
  src/resolve_aufs_conflicts \
  src/merge_accounts \
  src/reset_root_password \
  src/set_quotes

all: $(EXTRAS_BINARIES)

clean:
	rm -rf extras-*
	$(MAKE) -C src clean

$(EXTRAS_BINARIES): $(EXTRAS_BUILD_PRODUCTS)
	mkdir -p extras-$(EXTRAS_STRONG_VERSION)/bin
	cp $(EXTRAS_BUILD_PRODUCTS) extras-$(EXTRAS_STRONG_VERSION)/bin/

$(EXTRAS_BUILD_PRODUCTS): src/Makefile $(wildcard src/*.c) $(wildcard src/*.cc)
	$(MAKE) -j4 -C src

