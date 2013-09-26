include $(TOP)/config.mk
include config.mk

BB_BINARY = busybox-$(BB_STRONG_VERSION)/sbin/busybox

all: $(BB_BINARY)

$(BB_BINARY):
	mkdir -p busybox-$(BB_STRONG_VERSION)/sbin
	curl $(BB_SOURCE) > $(BB_BINARY) 2>/dev/null || rm -rf busybox-$(BB_STRONG_VERSION)
	chmod +x $(BB_BINARY)

clean:
	rm -rf busybox-*

