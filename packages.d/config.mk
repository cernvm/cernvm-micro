ifeq ($(ARCH),aarch64)
    PACKAGES = busybox curl dhclient dropbear e2fsprogs ntpclient sfdisk parted cvmfs extras
else
    PACKAGES = busybox curl dhclient dropbear e2fsprogs kexec ntpclient parrot patchelf sfdisk parted cvmfs extras
endif
