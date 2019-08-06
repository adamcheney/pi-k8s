#/!bin/bash -e

cd "$(dirname "$0")/.."

packer build -var-file packer/vars/master0.json packer/master.json
packer build -var-file packer/vars/master1.json packer/master.json
packer build -var-file packer/vars/master2.json packer/master.json
