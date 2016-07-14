include $(TOP)/config.mk
include config.mk

BB_BINARY = busybox-$(BB_STRONG_VERSION)/sbin/busybox
BB_BUILD_PRODUCT = $(BB_SOURCETREE)/busybox
BB_STRIPPED = $(BB_BUILD_PRODUCT)-stripped
BB_MAKEFILE = $(BB_SOURCETREE)/Makefile
BB_CONFIG = $(BB_SOURCETREE)/.config

all: $(BB_BINARY)

clean:
	rm -rf busybox-$(BB_UPSTREAM_VERSION)*

$(BB_BINARY): $(BB_STRIPPED)
	mkdir -p busybox-$(BB_STRONG_VERSION)/sbin
	cp $(BB_STRIPPED) $(BB_BINARY)

$(BB_STRIPPED): $(BB_BUILD_PRODUCT)
	cp $(BB_BUILD_PRODUCT) $(BB_STRIPPED)
	strip $(BB_STRIPPED)

$(BB_BUILD_PRODUCT): $(BB_MAKEFILE) $(BB_CONFIG)
	$(MAKE) -j4 -C $(BB_SOURCETREE)

$(BB_MAKEFILE): $(BB_TARBALL)
	tar -xvjf $(BB_TARBALL)
	touch $(BB_MAKEFILE)

$(BB_CONFIG): busybox-config $(BB_MAKEFILE)
	cp busybox-config $(BB_CONFIG)

$(BB_TARBALL):
	curl $(BB_SOURCE) > $(BB_TARBALL) 2>/dev/null || rm -f $(BB_TARBALL)
