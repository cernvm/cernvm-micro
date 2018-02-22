ifeq ($(ARCH),aarch64)
    PACKAGES = busybox curl dhclient dropbear e2fsprogs kexec ntpclient sfdisk parted cvmfs gptfdisk extras
else
    PACKAGES = busybox curl dhclient dropbear e2fsprogs kexec ntpclient parrot patchelf sfdisk parted cvmfs gptfdisk extras
endif
