include $(TOP)/config.mk
include config.mk

E2FS_BINARIES = \
  e2fsprogs-$(E2FSPROGS_STRONG_VERSION)/sbin/e2fsck \
  e2fsprogs-$(E2FSPROGS_STRONG_VERSION)/sbin/mke2fs \
  e2fsprogs-$(E2FSPROGS_STRONG_VERSION)/sbin/e2label \
  e2fsprogs-$(E2FSPROGS_STRONG_VERSION)/sbin/tune2fs
E2FS_STRIPPED = \
  $(E2FSPROGS_SOURCETREE)/e2fsck/e2fsck-stripped \
  $(E2FSPROGS_SOURCETREE)/misc/mke2fs-stripped \
  $(E2FSPROGS_SOURCETREE)/misc/e2label-stripped \
  $(E2FSPROGS_SOURCETREE)/misc/tune2fs-stripped
E2FS_BUILD_PRODUCTS = \
  $(E2FSPROGS_SOURCETREE)/e2fsck/e2fsck \
  $(E2FSPROGS_SOURCETREE)/misc/mke2fs \
  $(E2FSPROGS_SOURCETREE)/misc/e2label \
  $(E2FSPROGS_SOURCETREE)/misc/tune2fs
E2FS_MAKEFILE = $(E2FSPROGS_SOURCETREE)/Makefile
E2FS_CONFIGURE = $(E2FSPROGS_SOURCETREE)/configure

all: $(E2FS_BINARIES)

clean:
	rm -rf e2fsprogs-*

$(E2FS_BINARIES): $(E2FS_STRIPPED)
	mkdir -p e2fsprogs-$(E2FSPROGS_STRONG_VERSION)/sbin
	cp $(E2FSPROGS_SOURCETREE)/e2fsck/e2fsck-stripped e2fsprogs-$(E2FSPROGS_STRONG_VERSION)/sbin/e2fsck
	cp $(E2FSPROGS_SOURCETREE)/misc/mke2fs-stripped e2fsprogs-$(E2FSPROGS_STRONG_VERSION)/sbin/mke2fs
	cp $(E2FSPROGS_SOURCETREE)/misc/e2label-stripped e2fsprogs-$(E2FSPROGS_STRONG_VERSION)/sbin/e2label
	cp $(E2FSPROGS_SOURCETREE)/misc/tune2fs-stripped e2fsprogs-$(E2FSPROGS_STRONG_VERSION)/sbin/tune2fs

$(E2FS_STRIPPED): $(E2FS_BUILD_PRODUCTS)
	cp $(E2FSPROGS_SOURCETREE)/e2fsck/e2fsck $(E2FSPROGS_SOURCETREE)/e2fsck/e2fsck-stripped
	strip $(E2FSPROGS_SOURCETREE)/e2fsck/e2fsck-stripped
	cp $(E2FSPROGS_SOURCETREE)/misc/mke2fs $(E2FSPROGS_SOURCETREE)/misc/mke2fs-stripped
	strip $(E2FSPROGS_SOURCETREE)/misc/mke2fs-stripped
	cp $(E2FSPROGS_SOURCETREE)/misc/e2label $(E2FSPROGS_SOURCETREE)/misc/e2label-stripped
	strip $(E2FSPROGS_SOURCETREE)/misc/e2label-stripped
	cp $(E2FSPROGS_SOURCETREE)/misc/tune2fs $(E2FSPROGS_SOURCETREE)/misc/tune2fs-stripped
	strip $(E2FSPROGS_SOURCETREE)/misc/tune2fs-stripped

$(E2FS_BUILD_PRODUCTS): $(E2FS_MAKEFILE)
	$(MAKE) -j4 -C $(E2FSPROGS_SOURCETREE)
	$(MAKE) -C $(E2FSPROGS_SOURCETREE)/misc e2label tune2fs

$(E2FS_MAKEFILE): $(E2FS_CONFIGURE)
	cd $(E2FSPROGS_SOURCETREE) && ./configure

$(E2FS_CONFIGURE): | $(E2FSPROGS_TARBALL)
	tar -xvJf $(E2FSPROGS_TARBALL)

$(E2FSPROGS_TARBALL):
	curl $(E2FSPROGS_SOURCE) > $(E2FSPROGS_TARBALL) 2>/dev/null || rm -f $(E2FSPROGS_TARBALL)
