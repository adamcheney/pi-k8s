#!/bin/bash -e

PACKER_VERSION=1.3.5

dir="$(mktemp -d)"
pushd "$dir"
wget -q "https://releases.hashicorp.com/packer/$PACKER_VERSION/packer_${PACKER_VERSION}_linux_amd64.zip"
unzip -u "packer_${PACKER_VERSION}_linux_amd64.zip"
sudo mv packer /usr/local/bin
popd
rm -r "$dir"
