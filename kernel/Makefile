include $(TOP)/config.mk
include config.mk

KERNEL_DIR = cernvm-kernel-$(KERNEL_STRONG_VERSION)

all: $(KERNEL_DIR)/~done

$(KERNEL_DIR)/~done:
	rm -rf $(KERNEL_DIR)
	mkdir -p $(KERNEL_DIR)
	curl $(KERNEL_SOURCE) > $(KERNEL_TARBALL) 2>/dev/null
	tar xfz $(KERNEL_TARBALL)
	cd $(KERNEL_DIR) && rm -rf firmware-* headers-* && mv modules-*/lib . && rmdir modules-*
	mv $(KERNEL_TARBALL) /data/releases/kernel/
	touch $(KERNEL_DIR)/~done

clean:
	rm -rf $(KERNEL_DIR)

