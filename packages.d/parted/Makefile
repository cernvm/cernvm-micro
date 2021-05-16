include $(TOP)/config.mk
include config.mk

PARTED_BINARY = parted-$(PARTED_STRONG_VERSION)/sbin/parted
PARTED_BUILD_PRODUCT = $(PARTED_SOURCETREE)/SANDBOX/usr/sbin/parted
PARTED_STRIPPED = $(PARTED_BUILD_PRODUCT)-stripped
PARTED_MAKEFILE = $(PARTED_SOURCETREE)/Makefile
PARTED_CONFIGURE = $(PARTED_SOURCETREE)/configure

all: $(PARTED_BINARY)

clean:
	rm -rf parted-*

$(PARTED_BINARY): $(PARTED_STRIPPED)
	mkdir -p parted-$(PARTED_STRONG_VERSION)/sbin
	cp $(PARTED_STRIPPED) $(PARTED_BINARY)

$(PARTED_STRIPPED): $(PARTED_BUILD_PRODUCT)
	cp $(PARTED_BUILD_PRODUCT) $(PARTED_STRIPPED)
	strip $(PARTED_STRIPPED)

$(PARTED_BUILD_PRODUCT): $(PARTED_MAKEFILE)
	$(MAKE) -j4 -C $(PARTED_SOURCETREE) DESTDIR=$(shell pwd)/$(PARTED_SOURCETREE)/SANDBOX install

$(PARTED_MAKEFILE): $(PARTED_CONFIGURE)
	cd $(PARTED_SOURCETREE) && ./configure \
	  --prefix=/usr \
	  --disable-device-mapper \
	  --disable-threads \
	  --disable-dynamic-loading \
	  --disable-rpath \
	  --disable-shared \
	  --disable-nls \
	  --without-readline 

$(PARTED_CONFIGURE): | $(PARTED_TARBALL)
	tar -xvJf $(PARTED_TARBALL)
	#patch -p0 < parted_dm.patch
	mv parted-$(PARTED_UPSTREAM_VERSION) $(PARTED_SOURCETREE)

$(PARTED_TARBALL):
	curl $(PARTED_SOURCE) > $(PARTED_TARBALL) 2>/dev/null || rm -f $(PARTED_TARBALL)
