#!/bin/bash -e

export DEBIAN_FRONTEND=noninteractive
apt-get update

# Fixes: systemd-modules-load: Failed to find module 'ib_iser'
sed -i 's/^ib_iser$/#ib_iser/' /lib/modules-load.d/open-iscsi.conf
