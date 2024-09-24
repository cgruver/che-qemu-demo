#!/usr/bin/env bash

VM_DISK=$1
VM_DIR=$2
WORK_DIR=$(mktemp -d)

mkdir -p ${VM_DIR}
guestfish --ro -i -a ${VM_DISK} << EOF > ${WORK_DIR}/files.out
ls /boot
EOF
KERNEL=$(cat ${WORK_DIR}/files.out | grep vmlinuz- )
INITRD=$(cat ${WORK_DIR}/files.out | grep initrd.img- )
guestfish --ro -i -a ${VM_DISK} << EOF
download /boot/${KERNEL} ${VM_DIR}/vmlinuz
EOF
guestfish --ro -i -a ${VM_DISK} << EOF
download /boot/${INITRD} ${VM_DIR}/initrd.img
EOF