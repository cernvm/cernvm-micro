#!/bin/bash
#
# μCernVM initial ramdisk image generator
#
# μCernVM tools is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# μCernVM tools is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with μCernVM tools. If not, see <http://www.gnu.org/licenses/>.
#
# Developed by Ioannis Charalampidis 2012 at PH/SFT, CERN
# Contact: <ioannis.charalampidis[at]cern.ch>
#

die() {
  echo "[ERR] $1"
  exit 1
}

# Setup environment
export DESTDIR=$(mktemp -d)
export SCRIPTS="scripts.d"
export BASEDIR=$(pwd)

# Externally provided versions
[ -z $UCERNVM_STRONG_VERSION ] && die "UCERNVM_STRONG_VERSION missing"
[ -z $KERNEL_STRONG_VERSION ] && die "KERNEL_STRONG_VERSION missing"
[ -z $BB_STRONG_VERSION ] && die "BB_STRONG_VERSION missing"
[ -z $CURL_STRONG_VERSION ] && die "CURL_STRONG_VERSION missing"
[ -z $DROPBEAR_STRONG_VERSION ] && die "DROPBEAR_STRONG_VERSION missing"
[ -z $NTPCLIENT_STRONG_VERSION ] && die "NTPCLIENT_STRONG_VERSION missing"
[ -z $E2FSPROGS_STRONG_VERSION ] && die "E2FSPROGS_STRONG_VERSION missing"
[ -z $KEXEC_STRONG_VERSION ] && die "KEXEC_STRONG_VERSION missing"
[ -z $SFDISK_STRONG_VERSION ] && die "SFDISK_STRONG_VERSION missing"
[ -z $CVMFS_STRONG_VERSION ] && die "CVMFS_STRONG_VERSION missing"
[ -z $EXTRAS_STRONG_VERSION ] && die "EXTRAS_STRONG_VERSION missing"
export KERNEL_STRONG_VERSION
export BB_STRONG_VERSION
export UCERNVM_STRONG_VERSION
export CURL_STRONG_VERSION
export DROPBEAR_STRONG_VERSION
export NTPCLIENT_STRONG_VERSION
export E2FSPROGS_STRONG_VERSION
export KEXEC_STRONG_VERSION
export SFDISK_STRONG_VERSION
export CVMFS_STRONG_VERSION
export EXTRAS_STRONG_VERSION

TARGET=initrd.$UCERNVM_STRONG_VERSION
[ $(echo "$TARGET" | grep -c '^/') -eq 0 ] && TARGET=$(pwd)/$TARGET
echo "[INF] Generating $TARGET"

# Include functions
. ${BASEDIR}/include/functions.sh

# Create an empty filesystem
[ -z "${DESTDIR}" ] && echo "[ERR] Invalid destination directory specified!" && exit 1
create_empty "${DESTDIR}"

# Generate init from runtime
cp "${BASEDIR}/include/runtime-init.sh" "${DESTDIR}/init"
chmod +x "${DESTDIR}/init"

# Run generation scripts
for F in $(find ${SCRIPTS} -maxdepth 1 -type f -name '[0-9]*' | sort); do
    process_file ${F}
done

# Copy kernel modules
echo "[INF] Generating kernel modules"
mkdir -p ${DESTDIR}/lib/modules
cp -a ${BASEDIR}/kernel/cernvm-kernel-${KERNEL_STRONG_VERSION}/lib/modules/* ${DESTDIR}/lib/modules/

# Gather library dependencies
echo "[INF] Gathering dependend libraries"
libs_missing=1
while [ $libs_missing -eq 1 ]; do
  libs_missing=0
  for f in $(find ${DESTDIR} -type f); do 
    libs=
    if ldd $f >/dev/null 2>&1; then 
      libs=$(ldd $f | awk '{print $3}' | grep -v 0x | grep -v '^$')
    fi
    [ -z "$libs" ] && continue
    for l in $libs; do
      if [ ! -f ${DESTDIR}$l ]; then
        libs_missing=1
        cp -v $l ${DESTDIR}$l
      fi
    done
  done
done

# Finalize
echo "[INF] Running ldconfig and depmod in ${DESTDIR}"
ldconfig -r "${DESTDIR}"
depmod -a -b "${DESTDIR}" $KERNEL_STRONG_VERSION

# Build initrd
echo "[INF] Compressing init ramdisk"
cd "${DESTDIR}"
find . | cpio -H newc -o | xz -9 --check=crc32 > ${TARGET}

# Remove temporary dir
echo $DESTDIR
#rm -rf "${DESTDIR}"
