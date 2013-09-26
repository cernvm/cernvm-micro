include $(TOP)/config.mk
include config.mk

all: $(PACKAGES)

$(PACKAGES)::
	$(MAKE) TOP=$(TOP) -C $@ $(MAKECMDGOALS)
