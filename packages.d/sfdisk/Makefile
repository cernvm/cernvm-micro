include $(TOP)/config.mk
include config.mk

SFDISK_BINARY = sfdisk-$(SFDISK_STRONG_VERSION)/sbin/sfdisk
SFDISK_BUILD_PRODUCT = $(SFDISK_SOURCETREE)/sfdisk
SFDISK_STRIPPED = $(SFDISK_BUILD_PRODUCT)-stripped
SFDISK_MAKEFILE = $(SFDISK_SOURCETREE)/Makefile
SFDISK_CONFIGURE = $(SFDISK_SOURCETREE)/configure
SFDISK_PATCHED = $(SFDISK_SOURCETREE)/sfdisk-patched

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

$(SFDISK_MAKEFILE): $(SFDISK_CONFIGURE) $(SFDISK_PATCHED)
	cd $(SFDISK_SOURCETREE) && ./configure \
	  --enable-libfdisk \
	  --enable-libuuid \
	  --disable-libblkid \
	  --disable-libmount \
	  --disable-mount \
	  --disable-losetup \
	  --disable-zramctl \
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
	  --disable-minix \
	  --disable-fdformat \
	  --disable-hwclock \
	  --disable-wdctl \
	  --disable-cal \
	  --disable-switch_root \
	  --disable-pivot_root \
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
	  --disable-nologin \
	  --disable-sulogin \
	  --disable-su \
	  --disable-runuser \
	  --disable-ul \
	  --disable-more \
	  --disable-pg \
	  --disable-schedutils \
	  --disable-wall \
	  --without-ncurses

$(SFDISK_PATCHED): $(SFDISK_CONFIGURE)
	cp config.guess $(SFDISK_SOURCETREE)/config/config.guess
	cp config.sub $(SFDISK_SOURCETREE)/config/config.sub
	touch $(SFDISK_PATCHED)

$(SFDISK_CONFIGURE): | $(SFDISK_TARBALL)
	tar -xvJf $(SFDISK_TARBALL)

$(SFDISK_TARBALL):
	curl $(SFDISK_SOURCE) > $(SFDISK_TARBALL) 2>/dev/null || rm -f $(SFDISK_TARBALL)
