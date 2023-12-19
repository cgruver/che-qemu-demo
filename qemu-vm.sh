#!/usr/bin/env bash

VM_DIR=${PROJECTS_ROOT}/vm

function initVm() {

    if [[ -d ${VM_DIR} ]]
    then
      rm -rf ${VM_DIR}
    fi
    mkdir -p ${VM_DIR}
    podman pull quay.io/cgruver0/che-vm/debian-aarch64:latest
    podman create --name vm-files quay.io/cgruver0/che-vm/debian-aarch64:latest ls
    podman cp vm-files:/ ${VM_DIR}/
    podman container rm vm-files
    podman image rm quay.io/cgruver0/che-vm/debian-aarch64:latest

}

function startVm() {

    qemu-system-aarch64 -M virt -m 1024 -cpu cortex-a53 -kernel ${VM_DIR}/vmlinuz -initrd ${VM_DIR}/initrd.img -append 'root=/dev/vda2' -drive if=none,file=${VM_DIR}/hda.qcow2,format=qcow2,id=hd -device virtio-blk-pci,drive=hd -netdev user,id=mynet,hostfwd=tcp::2222-:22 -device virtio-net-pci,netdev=mynet -nographic

}

for i in "$@"
do
  case $i in
    -i)
      initVm
    ;;
    -s)
      startVm
    ;;
  esac
done