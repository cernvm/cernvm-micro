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
cvm2ova -n cernvm3-vagrant -m 1024 -d 20000 -i image.hdd -u user-data
mkdir box
cd box
cat ../cernvm3-vagrant.ova | tar xvf -

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

Vagrant.configure(2) do |config|
  config.vm.provider :virtualbox do |v|
    v.name   = "$NAME"
    v.gui    = false
    v.memory = 1024
    v.cpus   = 2
  end
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

