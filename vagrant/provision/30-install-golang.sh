#!/bin/bash -e

if [ ! -d /usr/local/go ]; then
    wget -q https://dl.google.com/go/go1.12.6.linux-amd64.tar.gz
    tar -xf go1.12.6.linux-amd64.tar.gz
    rm go1.12.6.linux-amd64.tar.gz
    sudo mv go /usr/local
    sudo ln -s /usr/local/go/bin/go /usr/local/bin/go

    mkdir ~/go-workspace

cat >> ~/.bash_profile <<-'EOM'
export GOROOT=/usr/local/go
export GOPATH=/home/vagrant/go-workspace
export PATH="$PATH:$GOROOT/bin:$GOPATH/bin"
export CGO_ENABLED=0
EOM
fi
