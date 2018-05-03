ARCH = $(shell uname -m)

# Versions of components
UCERNVM_VERSION = 3.0
UCERNVM_RELEASE = $(shell cat release)
KERNEL_VANILLA_VERSION = 4.14.39
KERNEL_CERNVM_RELEASE = 10
BB_UPSTREAM_VERSION = 1.23.2
BB_RELEASE = 2
CURL_UPSTREAM_VERSION = 7.48.0
CURL_RELEASE = 2
DROPBEAR_UPSTREAM_VERSION = 2016.74
DROPBEAR_RELEASE = 1
PATCHELF_UPSTREAM_VERSION = 0.8
PATCHELF_RELEASE = 1
PARROT_UPSTREAM_VERSION = 6.0.14
PARROT_RELEASE = 1
NTPCLIENT_UPSTREAM_VERSION = 2010
NTPCLIENT_RELEASE = 1
DHCLIENT_UPSTREAM_VERSION = 4.3.1
DHCLIENT_RELEASE = 1
E2FSPROGS_UPSTREAM_VERSION = 1.42.12
E2FSPROGS_RELEASE = 2
KEXEC_UPSTREAM_VERSION = 2.0.16
KEXEC_RELEASE = 1
SFDISK_UPSTREAM_VERSION = 2.23
SFDISK_RELEASE = 1
PARTED_UPSTREAM_VERSION = 3.2
PARTED_RELEASE = 1
CVMFS_UPSTREAM_VERSION = 2.2.3
CVMFS_RELEASE = 1
GPTFDISK_UPSTREAM_VERSION = 1.0.1
GPTFDISK_RELEASE = 1
EXTRAS_VERSION = 1.6

CERNVM_INCREASE_RELEASE = 0

CERNVM_SYSTEM = HEAD
#CERNVM_BRANCHES = prod devel
#IMAGE_FORMATS = box
ifeq ($(ARCH),aarch64)
	CERNVM_BRANCHES = aarch64
	IMAGE_FORMATS = hdd
else
	CERNVM_BRANCHES = prod testing devel slc4 slc5 sl7
	IMAGE_FORMATS = fat iso hdd hvm vdi vhd vmdk tar.gz ova box qcow2
endif
CERNVM_BRANCHES = sl7 prod devel
IMAGE_FORMATS = iso hdd

SIGNING_SERVER = cvm-sign01.cern.ch
SINGING_URL = https://$(SIGNING_SERVER)/cgi-bin/cernvm/sign-image
CA_BUNDLE = /etc/pki/tls/certs/cern-ca-bundle.crt
HOST_CERT = /etc/pki/tls/certs/$(shell hostname -s).crt
HOST_KEY = /etc/pki/tls/private/$(shell hostname -s).key
SIGNING_DN = /DC=ch/DC=cern/OU=computers/CN=cvm-sign01.cern.ch

# Set to one of CERNVM_BRANCHES by main Makefile
CERNVM_BRANCH =
IMAGE_FORMAT =

# Derived parameters
UCERNVM_STRONG_VERSION = $(UCERNVM_VERSION)-$(UCERNVM_RELEASE).cernvm.$(ARCH)
KERNEL_VERSION = $(KERNEL_VANILLA_VERSION)-$(KERNEL_CERNVM_RELEASE)
KERNEL_STRONG_VERSION = $(KERNEL_VERSION).cernvm.$(ARCH)
BB_VERSION = $(BB_UPSTREAM_VERSION)-$(BB_RELEASE)
BB_STRONG_VERSION = $(BB_VERSION).cernvm.$(ARCH)
CURL_VERSION = $(CURL_UPSTREAM_VERSION)-$(CURL_RELEASE)
CURL_STRONG_VERSION = $(CURL_VERSION).cernvm.$(ARCH)
DROPBEAR_VERSION = $(DROPBEAR_UPSTREAM_VERSION)-$(DROPBEAR_RELEASE)
DROPBEAR_STRONG_VERSION = $(DROPBEAR_VERSION).cernvm.$(ARCH)
PATCHELF_VERSION = $(PATCHELF_UPSTREAM_VERSION)-$(PATCHELF_RELEASE)
PATCHELF_STRONG_VERSION = $(PATCHELF_VERSION).cernvm.$(ARCH)
PARROT_VERSION = $(PARROT_UPSTREAM_VERSION)-$(PARROT_RELEASE)
PARROT_STRONG_VERSION = $(PARROT_VERSION).cernvm.$(ARCH)
NTPCLIENT_VERSION = $(NTPCLIENT_UPSTREAM_VERSION)-$(NTPCLIENT_RELEASE)
NTPCLIENT_STRONG_VERSION = $(NTPCLIENT_VERSION).cernvm.$(ARCH)
DHCLIENT_VERSION = $(DHCLIENT_UPSTREAM_VERSION)-$(DHCLIENT_RELEASE)
DHCLIENT_STRONG_VERSION = $(DHCLIENT_VERSION).cernvm.$(ARCH)
E2FSPROGS_VERSION = $(E2FSPROGS_UPSTREAM_VERSION)-$(E2FSPROGS_RELEASE)
E2FSPROGS_STRONG_VERSION = $(E2FSPROGS_VERSION).cernvm.$(ARCH)
KEXEC_VERSION = $(KEXEC_UPSTREAM_VERSION)-$(KEXEC_RELEASE)
KEXEC_STRONG_VERSION = $(KEXEC_VERSION).cernvm.$(ARCH)
SFDISK_VERSION = $(SFDISK_UPSTREAM_VERSION)-$(SFDISK_RELEASE)
SFDISK_STRONG_VERSION = $(SFDISK_VERSION).cernvm.$(ARCH)
PARTED_VERSION = $(PARTED_UPSTREAM_VERSION)-$(PARTED_RELEASE)
PARTED_STRONG_VERSION = $(PARTED_VERSION).cernvm.$(ARCH)
CVMFS_VERSION = $(CVMFS_UPSTREAM_VERSION)-$(CVMFS_RELEASE)
CVMFS_STRONG_VERSION = $(CVMFS_VERSION).cernvm.$(ARCH)
GPTFDISK_VERSION = $(GPTFDISK_UPSTREAM_VERSION)-$(GPTFDISK_RELEASE)
GPTFDISK_STRONG_VERSION = $(GPTFDISK_VERSION).cernvm.$(ARCH)
EXTRAS_STRONG_VERSION = $(EXTRAS_VERSION).cernvm.$(ARCH)

CERNVM_SERVER = $(shell grep ^$(CERNVM_BRANCH) branch2server | awk '{print $$2}')
CERNVM_PATH_PREFIX = $(shell grep ^$(CERNVM_BRANCH) branch2path | awk '{print $$2}')
CERNVM_REPOSITORY = $(shell grep ^$(CERNVM_BRANCH) branch2repository | awk '{print $$2}')
CERNVM_ROOTTREE = ucernvm-root-$(CERNVM_BRANCH).$(UCERNVM_STRONG_VERSION).$(IMAGE_FORMAT)
IMAGE_DIR = ucernvm-images.$(UCERNVM_STRONG_VERSION)
IMAGE_NAME = ucernvm-$(CERNVM_BRANCH).$(UCERNVM_STRONG_VERSION)
IMAGE_FILE = $(IMAGE_NAME).$(IMAGE_FORMAT)
