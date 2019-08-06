#!/bin/bash -e

go get -u github.com/solo-io/packer-builder-arm-image
mkdir -p ~/.packer.d/plugins/
ln -s "$GOPATH/bin/packer-builder-arm-image" ~/.packer.d/plugins/packer-builder-arm-image
