# Versions of components
UCERNVM_VERSION = 1.15
UCERNVM_RELEASE = $(shell cat release)
KERNEL_VANILLA_VERSION = 3.10.15
KERNEL_CERNVM_RELEASE = 34
BB_UPSTREAM_VERSION = 1.20.2
BB_RELEASE = 1
CURL_UPSTREAM_VERSION = 7.32.0
CURL_RELEASE = 1
E2FSPROGS_UPSTREAM_VERSION = 1.42.8
E2FSPROGS_RELEASE = 1
KEXEC_UPSTREAM_VERSION = 2.0.4
KEXEC_RELEASE = 1
SFDISK_UPSTREAM_VERSION = 2.23
SFDISK_RELEASE = 1
CVMFS_UPSTREAM_VERSION = 2.1.16
CVMFS_RELEASE = 0
EXTRAS_VERSION = 0.4

CERNVM_INCREASE_RELEASE = 0

CERNVM_SYSTEM = HEAD
CERNVM_BRANCHES = testing devel slc4
IMAGE_FORMATS = iso hdd fat

# Set to one of CERNVM_BRANCHES by main Makefile
CERNVM_BRANCH =
IMAGE_FORMAT =

# Derived parameters
UCERNVM_STRONG_VERSION = $(UCERNVM_VERSION)-$(UCERNVM_RELEASE).cernvm.x86_64
KERNEL_VERSION = $(KERNEL_VANILLA_VERSION)-$(KERNEL_CERNVM_RELEASE)
KERNEL_STRONG_VERSION = $(KERNEL_VERSION).cernvm.x86_64
BB_VERSION = $(BB_UPSTREAM_VERSION)-$(BB_RELEASE)
BB_STRONG_VERSION = $(BB_VERSION).cernvm.x86_64
CURL_VERSION = $(CURL_UPSTREAM_VERSION)-$(CURL_RELEASE)
CURL_STRONG_VERSION = $(CURL_VERSION).cernvm.x86_64
E2FSPROGS_VERSION = $(E2FSPROGS_UPSTREAM_VERSION)-$(E2FSPROGS_RELEASE)
E2FSPROGS_STRONG_VERSION = $(E2FSPROGS_VERSION).cernvm.x86_64
KEXEC_VERSION = $(KEXEC_UPSTREAM_VERSION)-$(KEXEC_RELEASE)
KEXEC_STRONG_VERSION = $(KEXEC_VERSION).cernvm.x86_64
SFDISK_VERSION = $(SFDISK_UPSTREAM_VERSION)-$(SFDISK_RELEASE)
SFDISK_STRONG_VERSION = $(SFDISK_VERSION).cernvm.x86_64
CVMFS_VERSION = $(CVMFS_UPSTREAM_VERSION)-$(CVMFS_RELEASE)
CVMFS_STRONG_VERSION = $(CVMFS_VERSION).cernvm.x86_64
EXTRAS_STRONG_VERSION = $(EXTRAS_VERSION).cernvm.x86_64

CERNVM_REPOSITORY = cernvm-$(CERNVM_BRANCH).cern.ch
CERNVM_ROOTTREE = ucernvm-root-$(CERNVM_BRANCH).$(UCERNVM_STRONG_VERSION).$(IMAGE_FORMAT)
IMAGE_DIR = ucernvm-images.$(UCERNVM_STRONG_VERSION)
IMAGE_NAME = ucernvm-$(CERNVM_BRANCH).$(UCERNVM_STRONG_VERSION)
IMAGE_FILE = $(IMAGE_NAME).$(IMAGE_FORMAT)
