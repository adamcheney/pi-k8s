# PI K8s

Build a Kubernetes cluster on Raspberry PIs!

This project creates images that can when flashed onto PIs will create a Kubernetes cluster!

Only the control plane has been implemented. Worker nodes images aren't yet created.

## Build

```
./packer/build-all.sh
```

Images will be created in `output/`

## Run

- Flash all the images in `output/` onto PI 3's
    - Fast SDs are recommended for the masters for etcd.
- Start up the PIs on a network with DHCP automatic DNS registration
- Connect to the master with SSH
    - > ssh -i ./packer/generated/id_rsa ubuntu@master0
- Connect to the Kubernetes API
    - > kubectl --kubeconfig kubeconfig get all

## Vagrant

It is recommended to run the packer builds in a VM as per the recommendation of packer-builder-arm.
The `Vagrantfile` will also install all the dependencies.

```
vagrant up
vagrant ssh
```
