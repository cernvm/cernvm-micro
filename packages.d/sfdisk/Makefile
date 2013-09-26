include $(TOP)/config.mk
include config.mk

SFDISK_BINARY = sfdisk-$(SFDISK_STRONG_VERSION)/sbin/sfdisk
SFDISK_BUILD_PRODUCT = $(SFDISK_SOURCETREE)/sfdisk
SFDISK_STRIPPED = $(SFDISK_BUILD_PRODUCT)-stripped
SFDISK_MAKEFILE = $(SFDISK_SOURCETREE)/Makefile
SFDISK_CONFIGURE = $(SFDISK_SOURCETREE)/configure

all: $(SFDISK_BINARY)

clean:
	rm -rf sfdisk-* util-linux-*

$(SFDISK_BINARY): $(SFDISK_STRIPPED)
	mkdir -p sfdisk-$(SFDISK_STRONG_VERSION)/sbin
	cp $(SFDISK_STRIPPED) $(SFDISK_BINARY)

$(SFDISK_STRIPPED): $(SFDISK_BUILD_PRODUCT)
	cp $(SFDISK_BUILD_PRODUCT) $(SFDISK_STRIPPED)
	strip $(SFDISK_STRIPPED)

$(SFDISK_BUILD_PRODUCT): $(SFDISK_MAKEFILE)
	$(MAKE) -j4 -C $(SFDISK_SOURCETREE) sfdisk

$(SFDISK_MAKEFILE): $(SFDISK_CONFIGURE)
	cd $(SFDISK_SOURCETREE) && ./configure \
	  --disable-libuuid \
	  --disable-libblkid \
	  --disable-libmount \
	  --disable-mount \
	  --disable-losetup \
	  --disable-cytune \
	  --disable-fsck \
	  --disable-partx \
	  --disable-uuidd \
	  --disable-mountpoint \
	  --disable-fallocate \
	  --disable-unshare  \
	  --disable-nsenter \
	  --disable-setpriv \
	  --disable-eject \
	  --disable-agetty \
	  --disable-cramfs \
	  --disable-bfs \
	  --disable-fdformat \
	  --disable-hwclock \
	  --disable-wdctl \
	  --disable-switch_root \
	  --disable-pivot_root \
	  --disable-elvtune \
	  --disable-tunelp \
	  --disable-kill \
	  --disable-last \
	  --disable-utmpdump \
	  --disable-line \
	  --disable-mesg \
	  --disable-raw \
	  --disable-rename \
	  --disable-reset \
	  --disable-vipw \
	  --disable-newgrp \
	  --disable-login \
	  --disable-sulogin \
	  --disable-su \
	  --disable-runuser \
	  --disable-ul \
	  --disable-more \
	  --disable-pg \
	  --disable-schedutils \
	  --disable-wall

$(SFDISK_CONFIGURE): | $(SFDISK_TARBALL)
	tar -xvJf $(SFDISK_TARBALL)

$(SFDISK_TARBALL):
	curl $(SFDISK_SOURCE) > $(SFDISK_TARBALL) 2>/dev/null || rm -f $(SFDISK_TARBALL)
