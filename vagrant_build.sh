#!/bin/sh

set -e

HDD="$1"
USER_DATA="$2"
OUTPUT="$3"
NAME="$4"
[ -z "$HDD" ] && exit 1
[ -z "$USER_DATA" ] && exit 1
[ -z "$OUTPUT" ] && exit 1
[ -z "$NAME" ] && exit 1

CUR_DIR="$PWD"

TEMP_DIR="$(mktemp -d)"
cp "${HDD}" "${TEMP_DIR}/image.hdd"
cp "${USER_DATA}" "${TEMP_DIR}/user-data" 
cd "${TEMP_DIR}"
cvm2ova -n cernvm-vagrant -m 1024 -d 20000 -i image.hdd -u user-data
mkdir box
cd box
cat ../cernvm-vagrant.ova | tar xvf -

mv *.ovf box.ovf

cat > metadata.json << EOF
{
  "provider": "virtualbox"
}
EOF

cat > Vagrantfile << EOF
Vagrant::Config.run do |config|
  config.vm.base_mac = "080027985B0E"
end

\$script = <<SCRIPT
echo Provisioning CernVM...
usermod -G wheel,docker,users,vagrant vagrant
passwd -d vagrant
echo "CERNVM_USER=vagrant" >> /etc/cernvm/site.conf
echo "CERNVM_START_XDM=on" >> /etc/cernvm/site.conf
echo "CERNVM_AUTOLOGIN=on" >> /etc/cernvm/site.conf
/etc/cernvm/config -x
date > /etc/vagrant_provisioned_at
/sbin/telinit 5
SCRIPT

Vagrant.configure(2) do |config|
  config.vm.provider :virtualbox do |v|
    host = RbConfig::CONFIG['host_os']
    
    v.gui    = true
    
    # Give VM 1/2 system memory & access to all cpu cores on the host
    if host =~ /darwin/
      cpus = \`sysctl -n hw.ncpu\`.to_i
      # sysctl returns Bytes and we need to convert to MB
      mem = \`sysctl -n hw.memsize\`.to_i / 1024 / 1024 / 2
    elsif host =~ /linux/
      cpus = \`nproc\`.to_i
      # meminfo shows KB and we need to convert to MB
      mem = \`grep 'MemTotal' /proc/meminfo | sed -e 's/MemTotal://' -e 's/ kB//'\`.to_i / 1024 / 2
    else # Windows
      cpus = 2
      mem = 1024
    end

    v.customize ["modifyvm", :id, "--memory", mem]
    v.customize ["modifyvm", :id, "--cpus", cpus]
  end
 
  config.vm.boot_timeout = 1200
  config.vm.synced_folder '.', '/vagrant', nfs: true
  config.vm.network "private_network", type: "dhcp", auto_config: false

  config.vm.provision "shell", inline: \$script
end

# Load include vagrant file if it exists after the auto-generated
# so it can override any of the settings
include_vagrantfile = File.expand_path("../include/_Vagrantfile", __FILE__)
load include_vagrantfile if File.exist?(include_vagrantfile)
EOF

tar -czvf cernvm3.box ./*

cd "$CUR_DIR"
mv "${TEMP_DIR}/box/cernvm3.box" "${OUTPUT}"
rm -rf ${TEMP_DIR}

