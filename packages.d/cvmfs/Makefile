include $(TOP)/config.mk
include config.mk

CVMFS_BINARIES = \
  cvmfs-$(CVMFS_STRONG_VERSION)/usr/bin/cvmfs2 \
  cvmfs-$(CVMFS_STRONG_VERSION)/usr/bin/cvmfs_fsck \
  cvmfs-$(CVMFS_STRONG_VERSION)/usr/lib64/libcvmfs_fuse3_stub.so \
  cvmfs-$(CVMFS_STRONG_VERSION)/usr/lib64/libcvmfs_fuse3.so \
  cvmfs-$(CVMFS_STRONG_VERSION)/usr/lib64/libcvmfs_fuse3_debug.so
CVMFS_BUILD_PRODUCTS = \
  $(CVMFS_SOURCETREE)/cvmfs/cvmfs2 \
  $(CVMFS_SOURCETREE)/cvmfs/cvmfs_fsck \
  $(CVMFS_SOURCETREE)/cvmfs/libcvmfs_fuse3_stub.so \
  $(CVMFS_SOURCETREE)/cvmfs/libcvmfs_fuse3.so \
  $(CVMFS_SOURCETREE)/cvmfs/libcvmfs_fuse3_debug.so
CVMFS_STRIPPED = \
  $(CVMFS_SOURCETREE)/cvmfs/cvmfs2-stripped \
  $(CVMFS_SOURCETREE)/cvmfs/cvmfs_fsck-stripped \
  $(CVMFS_SOURCETREE)/cvmfs/libcvmfs_fuse3_stub.so-stripped \
  $(CVMFS_SOURCETREE)/cvmfs/libcvmfs_fuse3.so-stripped \
  $(CVMFS_SOURCETREE)/cvmfs/libcvmfs_fuse3_debug.so-stripped
CVMFS_MAKEFILE = $(CVMFS_SOURCETREE)/Makefile
CVMFS_CONFIGURE = $(CVMFS_SOURCETREE)/CMakeLists.txt

all: $(CVMFS_BINARIES)

clean:
	rm -rf cvmfs-*

$(CVMFS_BINARIES): $(CVMFS_STRIPPED)
	mkdir -p cvmfs-$(CVMFS_STRONG_VERSION)/usr/bin
	mkdir -p cvmfs-$(CVMFS_STRONG_VERSION)/usr/lib64
	cp $(CVMFS_SOURCETREE)/cvmfs/cvmfs2-stripped cvmfs-$(CVMFS_STRONG_VERSION)/usr/bin/cvmfs2
	cp $(CVMFS_SOURCETREE)/cvmfs/cvmfs_fsck-stripped cvmfs-$(CVMFS_STRONG_VERSION)/usr/bin/cvmfs_fsck
	cp $(CVMFS_SOURCETREE)/cvmfs/libcvmfs_fuse3_stub.so-stripped cvmfs-$(CVMFS_STRONG_VERSION)/usr/lib64/libcvmfs_fuse3_stub.so
	cp $(CVMFS_SOURCETREE)/cvmfs/libcvmfs_fuse3.so-stripped cvmfs-$(CVMFS_STRONG_VERSION)/usr/lib64/libcvmfs_fuse3.so
	cp $(CVMFS_SOURCETREE)/cvmfs/libcvmfs_fuse3_debug.so-stripped cvmfs-$(CVMFS_STRONG_VERSION)/usr/lib64/libcvmfs_fuse3_debug.so

$(CVMFS_STRIPPED): $(CVMFS_BUILD_PRODUCTS)
	cp $(CVMFS_SOURCETREE)/cvmfs/cvmfs2 $(CVMFS_SOURCETREE)/cvmfs/cvmfs2-stripped
	cp $(CVMFS_SOURCETREE)/cvmfs/cvmfs_fsck $(CVMFS_SOURCETREE)/cvmfs/cvmfs_fsck-stripped
	strip $(CVMFS_SOURCETREE)/cvmfs/cvmfs_fsck-stripped
	cp $(CVMFS_SOURCETREE)/cvmfs/libcvmfs_fuse3_stub.so $(CVMFS_SOURCETREE)/cvmfs/libcvmfs_fuse3_stub.so-stripped
	cp $(CVMFS_SOURCETREE)/cvmfs/libcvmfs_fuse3.so $(CVMFS_SOURCETREE)/cvmfs/libcvmfs_fuse3.so-stripped
	cp $(CVMFS_SOURCETREE)/cvmfs/libcvmfs_fuse3_debug.so $(CVMFS_SOURCETREE)/cvmfs/libcvmfs_fuse3_debug.so-stripped
	strip $(CVMFS_SOURCETREE)/cvmfs/libcvmfs_fuse3_debug.so-stripped

$(CVMFS_BUILD_PRODUCTS): $(CVMFS_MAKEFILE)
	$(MAKE) -j4 -C $(CVMFS_SOURCETREE)

$(CVMFS_MAKEFILE): $(CVMFS_CONFIGURE)
	cd $(CVMFS_SOURCETREE) && cmake -DBUILD_SERVER=off -DBUILD_RECEIVER=off -DBUILD_GEOAPI=off -DBUILD_LIBCVMFS=off -DBUILD_LIBCVMFS_CACHE=off . 

$(CVMFS_CONFIGURE): | $(CVMFS_TARBALL)
	tar -xvzf $(CVMFS_TARBALL)

$(CVMFS_TARBALL):
	curl -k $(CVMFS_SOURCE) > $(CVMFS_TARBALL) 2>/dev/null || rm -f $(CVMFS_TARBALL)
