TOP = $(shell pwd)
include config.mk

DOCKER_BUILDDIR = $(IMAGE_DIR)/cvm-docker.$(UCERNVM_STRONG_VERSION)

$(IMAGE_DIR)/cvm-docker.$(UCERNVM_STRONG_VERSION).tar: packages.d/busybox/busybox-$(BB_STRONG_VERSION)/sbin/busybox \
  packages.d/parrot/parrot-$(PARROT_STRONG_VERSION)/parrot_run \
  packages.d/patchelf/patchelf-$(PATCHELF_STRONG_VERSION)/bin/patchelf \
  $(wildcard docker/UCVM/*) docker/init | $(IMAGE_DIR)
	rm -rf $(DOCKER_BUILDDIR) && mkdir $(DOCKER_BUILDDIR)
	mkdir $(DOCKER_BUILDDIR)/UCVM
	cp -av docker/UCVM/* $(DOCKER_BUILDDIR)/UCVM/
	cp docker/init $(DOCKER_BUILDDIR)
	echo "$(UCERNVM_STRONG_VERSION)" > $(DOCKER_BUILDDIR)/UCVM/version
	cp packages.d/busybox/busybox-$(BB_STRONG_VERSION)/sbin/busybox $(DOCKER_BUILDDIR)/UCVM/
	cp packages.d/parrot/parrot-$(PARROT_STRONG_VERSION)/parrot_run $(DOCKER_BUILDDIR)/UCVM/	
	mkdir $(DOCKER_BUILDDIR)/UCVM/lib
	for l in $$(ldd $(DOCKER_BUILDDIR)/UCVM/parrot_run | cut -d" " -f3); do cp $$l $(DOCKER_BUILDDIR)/UCVM/lib/; done
	cp /lib64/ld-linux-x86-64.so.2 $(DOCKER_BUILDDIR)/UCVM/lib/
	packages.d/patchelf/patchelf-$(PATCHELF_STRONG_VERSION)/bin/patchelf --set-interpreter /UCVM/lib/ld-linux-x86-64.so.2 $(DOCKER_BUILDDIR)/UCVM/parrot_run
	packages.d/patchelf/patchelf-$(PATCHELF_STRONG_VERSION)/bin/patchelf --print-interpreter $(DOCKER_BUILDDIR)/UCVM/parrot_run
	cd $(DOCKER_BUILDDIR) && tar -cvf cvm-docker.$(UCERNVM_STRONG_VERSION).tar init UCVM
	./docker_preload.sh $(TOP)/$(DOCKER_BUILDDIR)/cvm-docker.$(UCERNVM_STRONG_VERSION).tar $(TOP)/$(DOCKER_BUILDDIR)/UCVM/parrot_preload.tar.xz
	rm $(DOCKER_BUILDDIR)/cvm-docker.$(UCERNVM_STRONG_VERSION).tar
	cd $(DOCKER_BUILDDIR) && tar -cvf $(TOP)/$(IMAGE_DIR)/cvm-docker.$(UCERNVM_STRONG_VERSION).tar init UCVM
	rm -rf $(DOCKER_BUILDDIR)

