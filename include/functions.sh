#!/bin/bash

####################################################################################################################
# Library functions
####################################################################################################################

# Check the destination path in order to avoid accidental writes to the 
# operating system.
function __safedist {
    if [ $(echo "$1" | grep -Ec '^/(usr(/(bin|lib(64)?|etc))|lib(64)?|bin|etc)(/|$)') -ne 0 ]; then
        echo "[ERR] Trying to write on system files! Are you sure your destination is correct?"
        exit 4
    fi
}

# Remove trailing or leading whitespaces
function __trim {
    local var=$1
    var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
    echo -n "$var"
}

# Give this function a name and it will find the .ko file
# for you in kernel/../../module.ko format.
function __find_module {
    
    # Use modinfo to find module
    #local FILE=$(modinfo $1 2>/dev/null | grep filename: | awk '{ print $2 }')
    
    # If it failed, use the 'find' way
    [ -z "$FILE" ] && FILE=$(find /lib/modules/${KERNEL_VERSION}/kernel -type f -name $1\.ko) 
    
    # Strip out base part
    echo "$FILE" | sed -r 's/^.*?kernel/kernel/'
    
}

# Remove the kernel version path
function __strip_kernel_path {
    echo "$1" | awk -F"${KERNEL_VERSION}/" '{ print $2 }'
}

# Install the specified kernel module file in the initrd resolving it's dependencies automatically.
# Format: kernel/../../module.ko
function __mod_install_dep {
    local MODULE="$1"
    local DEP
    
    # Fetch dependent kernel modules
    [ ! -f "/lib/modules/${KERNEL_VERSION}/modules.dep" ] && echo "[ERR] Could not detect modules.dep for kernel $KERNEL_VERSION!" && exit 2
    local DEPS=$(cat /lib/modules/${KERNEL_VERSION}/modules.dep | grep "${MODULE}: " | awk -F': ' '{ print $2 }')
    
    # Satisfy deps first
    for DEP in $DEPS; do
        __mod_install_dep $(__strip_kernel_path $DEP)
    done
    
    # Then add the module
    echo "[ADD] Adding module $MODULE..."
    local F_TARGET="${DESTDIR}/lib/modules/${KERNEL_VERSION}/${MODULE}"
    
    local D_TARGET=$(dirname "${F_TARGET}")
    if [ ! -d "${D_TARGET}" ]; then
        __safedist "${D_TARGET}"
        mkdir -p "${D_TARGET}"
        [ $? -ne 0 ] && echo "[ERR] Unable to create directory ${D_TARGET}!" && exit 3
    fi
    
    __safedist "${F_TARGET}"
    cp "/lib/modules/${KERNEL_VERSION}/${MODULE}" "${F_TARGET}" 
    [ $? -ne 0 ] && echo "[ERR] Unable to create ${F_TARGET}!" && exit 3
    
}

####################################################################################################################
# Exported functions to scripts
####################################################################################################################

# Print an error message and exit
function die {
    echo "[ERR] $@"
    exit 1
}

# Include a specific file, folder etc.
function require {
    local D_SOURCE=$(dirname "$1")
    local D_TARGET="${DESTDIR%/}${D_SOURCE}"
    
    # Make directory
    [ -d "$1" -a ! -d "${D_TARGET}" ] && mkdir -p "${D_TARGET}"
    
    # Copy file(s)
    echo "[ADD] Adding $1"
    __safedist "${D_TARGET}"
    cp -dvr "$1" "${D_TARGET}"
}

# Install a module by name
function require_mod {
    local MOD=$(__find_module $1)
    [ -z "$MOD" ] && echo "[ERR] Could not find module $1!" && exit 2
    __mod_install_dep ${MOD}
}

# Require a package from packages.d
function require_package {
    local D_SOURCE="${BASEDIR}/packages.d/$1"
    [ ! -d "${D_SOURCE}" ] && die "Unable to find the specified package: $1"
    sh -c "cd ${D_SOURCE}; tar --exclude-vcs -cf - . | sh -c \"cd ${DESTDIR}; tar -xf -\"" 
}

# Require a strongly versioned package from packages.d
function require_versioned_package {
    local D_SOURCE="${BASEDIR}/packages.d/$1/$1-$2"
    [ ! -d "${D_SOURCE}" ] && die "Unable to find the specified package: $1 (version $2)"
    sh -c "cd ${D_SOURCE}; tar --exclude-vcs -cf - . | sh -c \"cd ${DESTDIR}; tar -xf -\""
}


# Install the given executable file to the initrd, including it's
# static library dependencies.
function require_bin {
    local BIN=$1
    local TARGET
    
    # If the binary was not absolute prefixed, use which to locate it
    if [ "${BIN:0:1}" != "/" ]; then
        BIN=$(which "${BIN}" 2>/dev/null)
        [ $? -ne 0 ] && die "Unable to locate binary $BIN"
    fi
    
	# Track library dependencies
	local FILES=$(ldd -v ${BIN} 2>&1 | grep $'\tlib' | sed -r 's/[^=]+=>//' | awk '{ print $1 }' | sort | uniq)
	local FULL_LIST=""
	for F in $FILES; do
	   FULL_LIST="$FULL_LIST $F"
	   if [ -L $F ]; then
	      TARGET=$(ls -l $F | awk -F' -> ' '{ print $2 }')
	      if [ $(echo "$TARGET" | grep -c '^/') -eq 0 ]; then
	         TARGET="$(dirname $F)/$TARGET"
	      fi
	      FULL_LIST="$FULL_LIST $TARGET"
	   fi
	done

	# Copy libraries
    local TARGET_DIR
    local F
	for F in $FULL_LIST; do
	    
	    # Guess target dir
	    if [ $(echo "$F" | grep -c "^/usr") -eq 1 ]; then
	       TARGET_DIR="$DESTDIR/usr/lib"
	    else
	       TARGET_DIR="$DESTDIR/lib"
	    fi
	    if [ $(echo "$F" | grep -c lib64) -eq 1 ]; then
	        TARGET_DIR="${TARGET_DIR}64"
        fi
        
        # Make dir if missing
        [ ! -d "${TARGET_DIR}" ] && mkdir -p "${TARGET_DIR}"
        
        # Copy file if missing
        local F_TARGET="${TARGET_DIR}/${F_NAME}"
        if [ ! -f "${F_TARGET}" ]; then
            echo "[ADD] Adding library $F"
            __safedist "${F_TARGET}"
            cp -vd "${F}" "${F_TARGET}" 
            [ $? -ne 0 ] && echo "[ERR] Unable to copy ${F}!" && exit 3
        fi
	done

	# Copy binary
	TARGET_DIR="${DESTDIR}"
	[ $(echo "$BIN" | grep -c "/usr") -ne 0 ] && TARGET_DIR="${DESTDIR}/usr"
	if [ $(echo "$BIN" | grep -c "/sbin") -ne 0 ]; then
	   TARGET_DIR="${TARGET_DIR}/sbin"
	else
	   TARGET_DIR="${TARGET_DIR}/bin"
	fi

    # Create missing directory
    [ ! -d "${TARGET_DIR}" ] && mkdir -p ${TARGET_DIR}
    
    # Final copy
    F_TARGET="${TARGET_DIR%/}/$(basename ${BIN})"
    if [ ! -f "${F_TARGET}" ]; then
        __safedist "${F_TARGET}"
        cp -v "${BIN}" "${F_TARGET}"
        [ $? -ne 0 ] && echo "[ERR] Unable to copy ${BIN}!" && exit 3
    fi
    
    # Make sure it's executable
    [ ! -x "${F_TARGET}" ] && chmod +x "${F_TARGET}"
    
}

####################################################################################################################
# Core utilities
####################################################################################################################

function process_file {
    echo "[INF] Processing script $1"
    
    # Setup environment
    local T_BUILD=$(mktemp)
    local T_RUN=${DESTDIR}/init
    chmod +x $T_BUILD
    
    # Process lines
    local LINE
    local INTERPRETER=''
    local CONTEXT=''
    while read -r LINE; do
	#echo "${LINE}" >> ${DESTDIR}/lines
        if [ -z "$INTERPRETER" ]; then
            # Fetch first line as interpreter
            INTERPRETER=${LINE}
        else
            LINE=$(__trim "${LINE}")
            #echo "${LINE}" >> ${DESTDIR}/lines
            if [ $(echo "$LINE" | grep -Ec '^#\s*FOR:') -eq 1 ]; then
                # Switch contexts when reached context changing lines
                CONTEXT=$(echo "$LINE" | awk -F':' '{ print $2 }')
                echo "SWITCHED: $CONTEXT"
            elif [ ! -z "$LINE" ] && [ "${LINE:0:1}" != "#" ]; then
                # Direct contents to the appropriate targets
                if [ "${CONTEXT}" == "BUILD" ]; then
                    echo "$LINE" >> $T_BUILD
                elif [ "${CONTEXT}" == "RUN" ]; then
                    echo "$LINE" >> $T_RUN
                fi
            fi
        fi
    done < $1
    
    # Run build-time script
    #. ${T_BUILD}
    echo "Running build script"
    #cat ${T_BUILD} | sed -r 's/(.*)/- \1/'
    . ${T_BUILD}
    rm ${T_BUILD} 
}

function create_empty {
    echo "[INF] Generating directory layout"
    
    # Borrowed from LFS (I am quite lazy to change the variable name now)
    LFS=$1
    __safedist "${LFS}"
    [ ! -d "${LFS}" ] && mkdir -p "${LFS}"

    # Kernel VFS
    mkdir -v $LFS/{dev,proc,sys}
    mknod -m 600 $LFS/dev/console c 5 1
    mknod -m 666 $LFS/dev/null c 1 3

    # System layout
    mkdir -pv $LFS/{bin,boot,etc/{opt,sysconfig},home,lib,lib64,mnt,opt,run}
    mkdir -pv $LFS/{media/{floppy,cdrom},sbin,srv,var}
    install -dv -m 0750 $LFS/root
    install -dv -m 1777 $LFS/tmp $LFS/var/tmp
    mkdir -pv $LFS/usr/{,local/}{bin,include,lib,lib64,sbin,src}
    mkdir -pv $LFS/usr/{,local/}share/{doc,info,locale,man}
    mkdir -v  $LFS/usr/{,local/}share/{misc,terminfo,zoneinfo}
    mkdir -pv $LFS/usr/{,local/}share/man/man{1..8}
    for dir in $LFS/usr $LFS/usr/local; do
      ln -sv share/{man,doc,info} $dir
    done
    mkdir -v $LFS/var/{log,mail,spool,lock,run}
    ln -sv $LFS/run $LFS/var/run
    ln -sv $LFS/run/lock $LFS/var/lock
    mkdir -pv $LFS/var/{opt,cache,lib/{misc,locate},local}

    # Important files
cat > $LFS/etc/passwd <<EOF
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF

# Create ld.so.conf
cat > $LFS/etc/ld.so.conf <<EOF
# libc default configuration
/usr/local/lib
EOF

cat > $LFS/etc/group <<EOF
root:x:0:
bin:x:1:
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
mail:x:34:
nogroup:x:99:
EOF

    # Copy some needed files from the host
    cp /etc/hosts /etc/resolv.conf /etc/nsswitch.conf $LFS/etc/

    # Logfiles
    touch $LFS/var/log/{btmp,lastlog,wtmp}
    chgrp -v utmp $LFS/var/log/lastlog
    chmod -v 664  $LFS/var/log/lastlog
    chmod -v 600  $LFS/var/log/btmp                                          

    # Some libraries not found by dependencies
    cp -vd /lib/ld-* $LFS/lib
    cp -vd /lib64/ld-* $LFS/lib64
    cp -vd /lib/libresolv* $LFS/lib
    cp -vd /lib64/libresolv* $LFS/lib64
    cp -vd /lib/libnss_* $LFS/lib
    cp -vd /lib64/libnss_* $LFS/lib64
    
}
