cernvm-micro
============

Build system for µCernVM images

This build system collects various bits and pieces to compile the µCernVM
ISO and harddisk images.  The build system is purely make based.  All components
as well as the final images are versioned.  The component version numbers
are in config.mk.

Other requirements include syslinux, mkisofs, parted.


## Components

The components comprising a µCernVM image are
  * A Linux kernel, as compiled from cernvm-kernel config
  * An init ramdisk containing busybox, CernVM-FS, a few extras, and the init
  bash script
  * The bootloader, which according to the image type is isolinux, syslinux,
  or the grub config file for EC2 PV-GRUB kernels


## Products

The build system produces the init ramdisk, a tar file containing init ramdisk
and kernel suitable to update existing µCernVM images, and images in formats
ISO (VMware, VirtualBox), raw harddisk (Openstack), and FAT file system (EC2).

The build system produces separate images for every CernVM-FS repository that
should be used, although the repository can be changed by contextualization.


## Directory Structure

/boot
: config files and binaries for the bootloaders.  Binaries are taken from
syslinux 4.06.

/include
: bash helper functions for the init script

/kernel
: downloaded µCernVM kernel images

/packages
: extra utilites not covered by busybox

/scripts
: scriptlets that comprise the init script

/rebuild.sh
: Creates the init ramdisk

/release
The release number


## How does it work

The final images are between 10M and 20M.  They are considered read-only.
On first boot, the scripts in the init ramdisk will look for a free partition
or harddisk to use as ephemeral storage.  If none is available but the harddisk
containing the root partition has free space, a second partition on this
harddisk is used.

The ephemeral storage is then used to host the CernVM-FS cache as well as the
read-write layer of the union file system.  As a result, the CernVM-FS operating
system repository becomes locally writable.

In addition, the bootloader keeps auxiliary files on the ephemeral storage:
  * Spacer files to recover from a full hard disk
  * The CernVM-FS snapshot to use (fixed after first boot)
  * The user-data used to contextualize the image
  * A few extra logs and files from the init ramdisk exposed to user space


## Connection between µCernVM and the CernVM-FS OS Repository

The µCernVM bootloader and the CernVM-FS repository are mostly independent
meaning that most versions of the bootloader can load most repostory versions.
There are a few connecting points, however.

### Kernel modules
Kernel modules are posted into the OS tree
so that they can be loaded at a later stage.

### Pinned files
Files listed in /.ucernvm_pinfiles are pinned by the CernVM-FS module in the
bootloader.
The idea is to always keep files in the cache necessary to recover
from broken network (i.e. 'sudo /sbin/service network restart').

### OS provided boot script

Just before chrooting into the OS repository, the script /.cernvm_bootstrap
is executed in the bootloader.  As a parameter it gets the root directory in
the context of the bootloader.

### PIDs of the Bootloader CernVM-FS

The file .cvmfs_pids contains the PIDs of the processes in the bootloader that
the user space must not kill.  The system's halt script needs to be
changed to not kill this process on shutdown and
to unwind the AUFS file system stack instead of just unmounting all file systems.


## Contextualization of µCernVM

The bootloader can process EC2, Openstack, and vSphere user data.  Within the
user data everything is ignored expect a block of the form

    [ucernvm-begin]
    key1=value1
    key2=value2
    ...
    [ucernvm-end]

The following key-value pairs are recognized:

| Key             | Value                             | Comments                                         |
|-----------------|-----------------------------------|--------------------------------------------------|
|resize_rootfs    | on/off                            | use all of the harddisk instead of the first 20G |
|cvmfs_http_proxy | HTTP proxy in CernVM-FS notation  |                                                  |
|cvmfs_branch     | The repository name               | The url is currently fixed to hepvm.cern.ch      |
|cvmfs_tag        | The snapshot name                 | For long-term data preservation                  |
