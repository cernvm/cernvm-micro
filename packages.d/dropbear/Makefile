include $(TOP)/config.mk
include config.mk

DROPBEAR_BINARY = dropbear-$(DROPBEAR_STRONG_VERSION)/bin/dropbear
DROPBEAR_BUILD_PRODUCT = $(DROPBEAR_SOURCETREE)/dropbear
DROPBEAR_STRIPPED = $(DROPBEAR_BUILD_PRODUCT)-stripped
DROPBEAR_MAKEFILE = $(DROPBEAR_SOURCETREE)/config.mk
DROPBEAR_CONFIGURE = $(DROPBEAR_SOURCETREE)/configure

all: $(DROPBEAR_BINARY)

clean:
	rm -rf dropbear-*

$(DROPBEAR_BINARY): $(DROPBEAR_STRIPPED)
	mkdir -p dropbear-$(DROPBEAR_STRONG_VERSION)/bin
	cp $(DROPBEAR_STRIPPED) $(DROPBEAR_BINARY)

$(DROPBEAR_STRIPPED): $(DROPBEAR_BUILD_PRODUCT)
	cp $(DROPBEAR_BUILD_PRODUCT) $(DROPBEAR_STRIPPED)
	strip $(DROPBEAR_STRIPPED)

$(DROPBEAR_BUILD_PRODUCT): $(DROPBEAR_MAKEFILE)
	$(MAKE) -j4 -C $(DROPBEAR_SOURCETREE)

$(DROPBEAR_MAKEFILE): $(DROPBEAR_CONFIGURE)
	cd $(DROPBEAR_SOURCETREE) && ./configure \
	  --disable-lastlog \
	  --disable-wtmpx \
	  --disable-pututline \
	  --disable-pututxline \
	  --disable-wtmp \
	  --disable-utmp \
	  --disable-utmpx \
	  --enable-bundled-libtom

$(DROPBEAR_CONFIGURE): | $(DROPBEAR_TARBALL)
	tar -xvjf $(DROPBEAR_TARBALL)

$(DROPBEAR_TARBALL):
	curl $(DROPBEAR_SOURCE) > $(DROPBEAR_TARBALL) 2>/dev/null || rm -f $(DROPBEAR_TARBALL)
