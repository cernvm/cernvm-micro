
TOP = $(shell pwd)
include config.mk

all: release
	sha256sum -c $(IMAGE_DIR)/*.sha256

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
	  DROPBEAR_STRONG_VERSION=$(DROPBEAR_STRONG_VERSION) \
	  NTPCLIENT_STRONG_VERSION=$(NTPCLIENT_STRONG_VERSION) \
	  DHCLIENT_STRONG_VERSION=$(DHCLIENT_STRONG_VERSION) \
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
	  sed -i -e 's/CERNVM_PATH_PREFIX/$(CERNVM_PATH_PREFIX)/' $$file; \
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
	mkisofs -R -o $(IMAGE_DIR)/$(IMAGE_NAME).iso.unsigned -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table $(CERNVM_ROOTTREE)
	./sign.sh $(IMAGE_DIR)/$(IMAGE_NAME).iso.unsigned $(SINGING_URL) $(HOST_CERT) $(HOST_KEY) $(CA_BUNDLE) $(SIGNING_DN) $(UCERNVM_STRONG_VERSION) $(CERNVM_BRANCH) $(CERNVM_SYSTEM)
	mv $(IMAGE_DIR)/$(IMAGE_NAME).iso.unsigned $(IMAGE_DIR)/$(IMAGE_NAME).iso

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
	mv tmp/$(IMAGE_NAME).hdd $(IMAGE_DIR)/$(IMAGE_NAME).hdd.unsigned
	./sign.sh $(IMAGE_DIR)/$(IMAGE_NAME).hdd.unsigned $(SINGING_URL) $(HOST_CERT) $(HOST_KEY) $(CA_BUNDLE) $(SIGNING_DN) $(UCERNVM_STRONG_VERSION) $(CERNVM_BRANCH) $(CERNVM_SYSTEM)
	mv $(IMAGE_DIR)/$(IMAGE_NAME).hdd.unsigned $(IMAGE_DIR)/$(IMAGE_NAME).hdd

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

$(IMAGE_DIR)/$(IMAGE_NAME).vdi: $(IMAGE_DIR)/$(IMAGE_NAME).hdd
	rm -f $(IMAGE_DIR)/$(IMAGE_NAME).vdi
	cp $(IMAGE_DIR)/$(IMAGE_NAME).hdd $(IMAGE_DIR)/$(IMAGE_NAME).hdd.working
	while pgrep VBoxSVC > /dev/null; do true; done
	VBoxManage convertfromraw $(IMAGE_DIR)/$(IMAGE_NAME).hdd.working $(IMAGE_DIR)/$(IMAGE_NAME)-inflated.vdi
	VBoxManage modifyhd $(IMAGE_DIR)/$(IMAGE_NAME)-inflated.vdi --resize $$((1024*20))
	chmod 0644 $(IMAGE_DIR)/$(IMAGE_NAME)-inflated.vdi
	mv $(IMAGE_DIR)/$(IMAGE_NAME)-inflated.vdi $(IMAGE_DIR)/$(IMAGE_NAME).vdi
	rm -f $(IMAGE_DIR)/$(IMAGE_NAME).hdd.working

$(IMAGE_DIR)/$(IMAGE_NAME).vhd: $(IMAGE_DIR)/$(IMAGE_NAME).hdd
	rm -f $(IMAGE_DIR)/$(IMAGE_NAME).vhd $(IMAGE_DIR)/$(IMAGE_NAME)-working.vdi $(IMAGE_DIR)/$(IMAGE_NAME).hdd.working tmp/azure/mountpoint
	mkdir -p tmp/azure/mountpoint
	cp $(IMAGE_DIR)/$(IMAGE_NAME).hdd $(IMAGE_DIR)/$(IMAGE_NAME).hdd.working
	losetup -o 512 /dev/loop5 $(IMAGE_DIR)/$(IMAGE_NAME).hdd.working
	mount /dev/loop5 tmp/azure/mountpoint
	cat tmp/azure/mountpoint/isolinux/syslinux.cfg | sed s/console=tty0// | sed "s/lastarg/console=ttyS0 earlyprintk=ttyS0 rootdelay=300 numa=off/" | sed 's/quiet//' | sed 's/loglevel=3//' > tmp/azure/mountpoint/isolinux/syslinux.cfg~
	mv tmp/azure/mountpoint/isolinux/syslinux.cfg~ tmp/azure/mountpoint/isolinux/syslinux.cfg
	cat tmp/azure/mountpoint/isolinux/syslinux.cfg
	umount tmp/azure/mountpoint && rmdir tmp/azure/mountpoint
	losetup -d /dev/loop5
	while pgrep VBoxSVC > /dev/null; do true; done
	VBoxManage convertfromraw $(IMAGE_DIR)/$(IMAGE_NAME).hdd.working $(IMAGE_DIR)/$(IMAGE_NAME)-working.vdi
	while pgrep VBoxSVC > /dev/null; do true; done
	VBoxManage modifyhd $(IMAGE_DIR)/$(IMAGE_NAME)-working.vdi --resize 24
	while pgrep VBoxSVC > /dev/null; do true; done
	VBoxManage clonehd $(IMAGE_DIR)/$(IMAGE_NAME)-working.vdi $(IMAGE_DIR)/$(IMAGE_NAME).vhd --format VHD
	chmod 0644 $(IMAGE_DIR)/$(IMAGE_NAME).vhd
	rm -f $(IMAGE_DIR)/$(IMAGE_NAME)-working.vdi
	rm -f $(IMAGE_DIR)/$(IMAGE_NAME).hdd.working
		
$(IMAGE_DIR)/$(IMAGE_NAME).vmdk: $(IMAGE_DIR)/$(IMAGE_NAME).vdi
	rm -f $(IMAGE_DIR)/$(IMAGE_NAME).vmdk
	cp $(IMAGE_DIR)/$(IMAGE_NAME).vdi $(IMAGE_DIR)/$(IMAGE_NAME).vdi.working
	while pgrep VBoxSVC > /dev/null; do true; done
	VBoxManage clonehd $(IMAGE_DIR)/$(IMAGE_NAME).vdi.working $(IMAGE_DIR)/$(IMAGE_NAME).vmdk --format VMDK --variant Stream
	chmod 0644 $(IMAGE_DIR)/$(IMAGE_NAME).vmdk
	rm -f $(IMAGE_DIR)/$(IMAGE_NAME).vdi.working
	
$(IMAGE_DIR)/$(IMAGE_NAME).ova: $(IMAGE_DIR)/$(IMAGE_NAME).hdd
	rm -rf /root/VirtualBox\ VMs /root/.config/VirtualBox
	rm -rf $(IMAGE_DIR)/ova-build && mkdir $(IMAGE_DIR)/ova-build
	cp $(IMAGE_DIR)/$(IMAGE_NAME).hdd $(IMAGE_DIR)/$(IMAGE_NAME).hdd.working
	while pgrep VBoxSVC > /dev/null; do true; done
	VBoxManage convertfromraw $(IMAGE_DIR)/$(IMAGE_NAME).hdd.working $(IMAGE_DIR)/ova-build/boot.vdi
	rm -f $(IMAGE_DIR)/$(IMAGE_NAME).hdd.working
	VBoxManage clonehd $(IMAGE_DIR)/ova-build/boot.vdi $(IMAGE_DIR)/ova-build/boot.vmdk --format VMDK --variant Stream
	VBoxManage createhd --filename $(IMAGE_DIR)/ova-build/scratch.vmdk --size 20000 --format VMDK --variant Stream
	rm -rf /root/VirtualBox\ VMs
	while pgrep VBoxSVC > /dev/null; do true; done
	VBoxManage createvm --name "CernVM 3" --ostype Linux26_64 --register
	VBoxManage storagectl "CernVM 3" --name SATA --add sata --portcount 4 --hostiocache on --bootable on
	VBoxManage modifyvm "CernVM 3" --memory 1024 --vram 20 --nic1 nat --nic2 hostonly --natdnshostresolver1 on --natdnshostresolver2 on --clipboard bidirectional --draganddrop hosttoguest
	while pgrep VBoxSVC > /dev/null; do true; done
	VBoxManage storageattach "CernVM 3" --storagectl SATA --port 0 --type hdd --medium $(TOP)/$(IMAGE_DIR)/ova-build/boot.vmdk
	VBoxManage storageattach "CernVM 3" --storagectl SATA --port 1 --type hdd --medium $(TOP)/$(IMAGE_DIR)/ova-build/scratch.vmdk
	VBoxManage export "CernVM 3" -o $(TOP)/$(IMAGE_DIR)/ova-build/$(IMAGE_NAME).ova \
	  --vsys 0 \
	  --product "CernVM" \
	  --producturl "http://cernvm.cern.ch"
	rm -f $(IMAGE_DIR)/ova-build/*.vmdk
	cd $(IMAGE_DIR)/ova-build && tar xf $(IMAGE_NAME).ova
	cat $(IMAGE_DIR)/ova-build/$(IMAGE_NAME).ovf | \
	  sed -e 's/MACAddress="[0-9A-Z]*"//' | sed -e 's/HostOnlyInterface name=""/HostOnlyInterface name="vboxnet0"/' > $(IMAGE_DIR)/ova-build/$(IMAGE_NAME).ovf~
	mv $(IMAGE_DIR)/ova-build/$(IMAGE_NAME).ovf~ $(IMAGE_DIR)/ova-build/$(IMAGE_NAME).ovf
	rm -f $(IMAGE_DIR)/ova-build/$(IMAGE_NAME).ova
	cd $(IMAGE_DIR)/ova-build && tar cf $(IMAGE_NAME).ova $(IMAGE_NAME).ovf *.vmdk
	mv $(IMAGE_DIR)/ova-build/$(IMAGE_NAME).ova $(IMAGE_DIR)/$(IMAGE_NAME).ova
	rm -rf $(IMAGE_DIR)/ova-build

$(IMAGE_DIR)/$(IMAGE_NAME).box: $(IMAGE_DIR)/$(IMAGE_NAME).hdd
	./vagrant_build.sh $(IMAGE_DIR)/$(IMAGE_NAME).hdd vagrant-user-data $(IMAGE_DIR)/$(IMAGE_NAME).box

$(IMAGE_DIR)/$(IMAGE_NAME).fat: initrd.$(UCERNVM_STRONG_VERSION) $(CERNVM_ROOTTREE)/version
	rm -f $(CERNVM_ROOTTREE)/cernvm/vmlinuz*
	cp kernel/cernvm-kernel-$(KERNEL_STRONG_VERSION)/vmlinuz-$(KERNEL_STRONG_VERSION).xz $(CERNVM_ROOTTREE)/cernvm/vmlinuz.xz
	dd if=/dev/zero of=tmp/$(IMAGE_NAME).fat bs=1024 count=20480
	mkdosfs tmp/$(IMAGE_NAME).fat
	mkdir tmp/mountpoint-$(IMAGE_NAME) && mount -o loop tmp/$(IMAGE_NAME).fat tmp/mountpoint-$(IMAGE_NAME)
	cd $(CERNVM_ROOTTREE) && gtar -c --exclude=.svn -f - . .ucernvm_boot_loader | (cd ../tmp/mountpoint-$(IMAGE_NAME) && gtar -xf -)
	umount tmp/mountpoint-$(IMAGE_NAME) && rmdir tmp/mountpoint-$(IMAGE_NAME)
	mv tmp/$(IMAGE_NAME).fat $(IMAGE_DIR)/$(IMAGE_NAME).fat	
