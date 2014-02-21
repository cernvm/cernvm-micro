
TOP = $(shell pwd)
include config.mk

all: release

release: initrd.$(UCERNVM_STRONG_VERSION) $(IMAGE_DIR)/ucernvm.$(UCERNVM_STRONG_VERSION).tar
	for branch in $(CERNVM_BRANCHES); do \
	  for format in $(IMAGE_FORMATS); do \
	    $(MAKE) CERNVM_BRANCH=$$branch IMAGE_FORMAT=$$format \
	      $(IMAGE_DIR)/ucernvm-$$branch.$(UCERNVM_STRONG_VERSION).$$format.sha256; \
	  done \
	done
	[ $(CERNVM_INCREASE_RELEASE) -eq 1 ] && echo $(UCERNVM_RELEASE)+1 | bc > release || touch release

$(IMAGE_DIR):
	mkdir -p $(IMAGE_DIR)

initrd.$(UCERNVM_STRONG_VERSION): rebuild.sh $(wildcard scripts.d/*) $(wildcard include/*)
	$(MAKE) TOP=$(TOP) -C packages.d
	$(MAKE) TOP=$(TOP) -C kernel
	  UCERNVM_STRONG_VERSION=$(UCERNVM_STRONG_VERSION) \
	  KERNEL_STRONG_VERSION=$(KERNEL_STRONG_VERSION) \
	  BB_STRONG_VERSION=$(BB_STRONG_VERSION) \
	  CURL_STRONG_VERSION=$(CURL_STRONG_VERSION) \
	  E2FSPROGS_STRONG_VERSION=$(E2FSPROGS_STRONG_VERSION) \
	  KEXEC_STRONG_VERSION=$(KEXEC_STRONG_VERSION) \
	  SFDISK_STRONG_VERSION=$(SFDISK_STRONG_VERSION) \
	  CVMFS_STRONG_VERSION=$(CVMFS_STRONG_VERSION) \
	  EXTRAS_STRONG_VERSION=$(EXTRAS_STRONG_VERSION) \
	./rebuild.sh

# Kernel and initrd update pack
$(IMAGE_DIR)/ucernvm.$(UCERNVM_STRONG_VERSION).tar: initrd.$(UCERNVM_STRONG_VERSION) $(IMAGE_DIR)
	$(MAKE) TOP=$(TOP) -C kernel
	rm -rf _tarbuild
	mkdir -p _tarbuild
	cp initrd.$(UCERNVM_STRONG_VERSION) kernel/cernvm-kernel-$(KERNEL_STRONG_VERSION)/vmlinuz-$(KERNEL_STRONG_VERSION).xz _tarbuild
	echo "version=$(UCERNVM_STRONG_VERSION)" > _tarbuild/apply
	echo "kernel=vmlinuz-$(KERNEL_STRONG_VERSION).xz" >> _tarbuild/apply
	echo "initrd=initrd.$(UCERNVM_STRONG_VERSION)" >> _tarbuild/apply
	echo "cmdline=" >> _tarbuild/apply
	cd _tarbuild && tar cfv ucernvm.$(UCERNVM_STRONG_VERSION).tar *
	mv _tarbuild/ucernvm.$(UCERNVM_STRONG_VERSION).tar $(IMAGE_DIR)/
	rm -rf _tarbuild

# uCernVM root file system tree
$(CERNVM_ROOTTREE)/version: boot initrd.$(UCERNVM_STRONG_VERSION)
	$(MAKE) TOP=$(TOP) -C kernel
	rm -rf $(CERNVM_ROOTTREE)
	mkdir -p $(CERNVM_ROOTTREE)
	cd boot && gtar -c --exclude=.svn -f - . .ucernvm_boot_loader | (cd ../$(CERNVM_ROOTTREE) && gtar -xf -)
	for file in \
	  $(CERNVM_ROOTTREE)/isolinux/isolinux.cfg \
	  $(CERNVM_ROOTTREE)/boot/grub/menu.lst; \
	do \
	  sed -i -e 's/UCERNVM_VERSION/$(UCERNVM_VERSION)/' $$file; \
	  sed -i -e 's/UCERNVM_STRONG_VERSION/$(UCERNVM_STRONG_VERSION)/' $$file; \
	  sed -i -e 's/KERNEL_STRONG_VERSION/$(KERNEL_STRONG_VERSION)/' $$file; \
	  sed -i -e 's/CERNVM_REPOSITORY/$(CERNVM_REPOSITORY)/' $$file; \
	  sed -i -e 's/CERNVM_SERVER/$(CERNVM_SERVER)/' $$file; \
	  sed -i -e 's/CERNVM_SYSTEM/$(CERNVM_SYSTEM)/' $$file; \
	done
	cp $(CERNVM_ROOTTREE)/isolinux/isolinux.cfg $(CERNVM_ROOTTREE)/isolinux/syslinux.cfg
	cp initrd.$(UCERNVM_STRONG_VERSION) $(CERNVM_ROOTTREE)/cernvm/initrd.img
	touch $(CERNVM_ROOTTREE)/.ucernvm_boot_loader
	echo "$(CERNVM_REPOSITORY) at $(CERNVM_SYSTEM), uCernVM $(UCERNVM_STRONG_VERSION)" > $(CERNVM_ROOTTREE)/version

clean:
	rm -rf ucernvm-root-*
	rm -rf ucernvm-images.*
	rm -f initrd.* ucernvm.*.tar ucernvm-*
	rm -rf tmp/*

clean-images:
	rm -rf ucernvm-root-*
	rm -rf ucernvm-images.*

# Image signatures
$(IMAGE_DIR)/$(IMAGE_FILE).sha256: $(IMAGE_DIR)/$(IMAGE_FILE)
	sha256sum $(IMAGE_DIR)/$(IMAGE_FILE) | awk '{print $1}' \
	  > $(IMAGE_DIR)/$(IMAGE_FILE).sha256

# Images as ISO image, file system image, raw harddisk image
$(IMAGE_DIR)/$(IMAGE_NAME).iso: initrd.$(UCERNVM_STRONG_VERSION) $(CERNVM_ROOTTREE)/version
	rm -f $(CERNVM_ROOTTREE)/cernvm/vmlinuz*
	cp kernel/cernvm-kernel-$(KERNEL_STRONG_VERSION)/vmlinuz-$(KERNEL_STRONG_VERSION).xz $(CERNVM_ROOTTREE)/cernvm/vmlinuz.xz
	mkisofs -R -o $(IMAGE_DIR)/$(IMAGE_NAME).iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table $(CERNVM_ROOTTREE)	

$(IMAGE_DIR)/$(IMAGE_NAME).hdd: initrd.$(UCERNVM_STRONG_VERSION) $(CERNVM_ROOTTREE)/version
	rm -f $(CERNVM_ROOTTREE)/cernvm/vmlinuz*
	cp kernel/cernvm-kernel-$(KERNEL_STRONG_VERSION)/vmlinuz-$(KERNEL_STRONG_VERSION).xz $(CERNVM_ROOTTREE)/cernvm/vmlinuz.xz
	dd if=/dev/zero of=tmp/$(IMAGE_NAME).hdd bs=1024 count=20480
	parted -s tmp/$(IMAGE_NAME).hdd mklabel msdos
	parted -s tmp/$(IMAGE_NAME).hdd mkpart primary fat32 0 100%
	parted -s tmp/$(IMAGE_NAME).hdd set 1 boot on
	losetup -o 512 /dev/loop5 tmp/$(IMAGE_NAME).hdd
	mkdosfs /dev/loop5
	mkdir tmp/mountpoint-$(IMAGE_NAME) && mount /dev/loop5 tmp/mountpoint-$(IMAGE_NAME)
	cd $(CERNVM_ROOTTREE) && gtar -c --exclude=.svn -f - . .ucernvm_boot_loader | (cd ../tmp/mountpoint-$(IMAGE_NAME) && gtar -xf -)
	umount tmp/mountpoint-$(IMAGE_NAME) && rmdir tmp/mountpoint-$(IMAGE_NAME)
	losetup -d /dev/loop5
	syslinux --install --offset 512 --active --mbr --directory /isolinux tmp/$(IMAGE_NAME).hdd
	mv tmp/$(IMAGE_NAME).hdd $(IMAGE_DIR)/$(IMAGE_NAME).hdd

$(IMAGE_DIR)/$(IMAGE_NAME).tar.gz: $(IMAGE_DIR)/$(IMAGE_NAME).hdd
	rm -rf tmp/gce && mkdir -p tmp/gce/mountpoint
	cp $(IMAGE_DIR)/$(IMAGE_NAME).hdd tmp/gce/disk.raw
	losetup -o 512 /dev/loop5 tmp/gce/disk.raw
	mount /dev/loop5 tmp/gce/mountpoint
	cat tmp/gce/mountpoint/isolinux/syslinux.cfg | sed s/console=tty0// | sed "s/lastarg/console=ttyS0/" > tmp/gce/mountpoint/isolinux/syslinux.cfg~
	mv tmp/gce/mountpoint/isolinux/syslinux.cfg~ tmp/gce/mountpoint/isolinux/syslinux.cfg
	cat tmp/gce/mountpoint/isolinux/syslinux.cfg    
	umount tmp/gce/mountpoint && rmdir tmp/gce/mountpoint
	losetup -d /dev/loop5
	cd tmp/gce && tar cvfz $(IMAGE_NAME).tar.gz disk.raw
	mv tmp/gce/$(IMAGE_NAME).tar.gz $(IMAGE_DIR)

$(IMAGE_DIR)/$(IMAGE_NAME).vhd: $(IMAGE_DIR)/$(IMAGE_NAME).hdd
	qemu-img convert -O vpc $(IMAGE_DIR)/$(IMAGE_NAME).hdd $(IMAGE_DIR)/$(IMAGE_NAME).vhd
			
$(IMAGE_DIR)/$(IMAGE_NAME).fat: initrd.$(UCERNVM_STRONG_VERSION) $(CERNVM_ROOTTREE)/version
	rm -f $(CERNVM_ROOTTREE)/cernvm/vmlinuz*
	cp kernel/cernvm-kernel-$(KERNEL_STRONG_VERSION)/vmlinuz-$(KERNEL_STRONG_VERSION).gzip $(CERNVM_ROOTTREE)/cernvm/vmlinuz.gzip
	dd if=/dev/zero of=tmp/$(IMAGE_NAME).fat bs=1024 count=20480
	mkdosfs tmp/$(IMAGE_NAME).fat
	mkdir tmp/mountpoint-$(IMAGE_NAME) && mount -o loop tmp/$(IMAGE_NAME).fat tmp/mountpoint-$(IMAGE_NAME)
	cd $(CERNVM_ROOTTREE) && gtar -c --exclude=.svn -f - . .ucernvm_boot_loader | (cd ../tmp/mountpoint-$(IMAGE_NAME) && gtar -xf -)
	umount tmp/mountpoint-$(IMAGE_NAME) && rmdir tmp/mountpoint-$(IMAGE_NAME)
	mv tmp/$(IMAGE_NAME).fat $(IMAGE_DIR)/$(IMAGE_NAME).fat	
