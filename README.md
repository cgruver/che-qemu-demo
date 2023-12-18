# kubevirt-cpu-emulation
Testing the feasibility of running aarch64 guest on x86_64 host

```bash
oc new-project che-dev-images
oc apply -f qemu-image/tools-build.yaml
oc start-build qemu-dev -n che-dev-images -w -F
oc start-build qemu-workspace -n che-dev-images -w -F
oc start-build fedora-workspace -n che-dev-images -w -F
oc policy add-role-to-group system:image-puller system:serviceaccounts -n che-dev-images
```

## Build a Debian Bullseye aarch64 VM Image

```bash
INSTALL_DIR=${PROJECTS_ROOT}/debian-bullseye-aarch64-install
INSTALL_DISK=${INSTALL_DIR}/debian-golden-image.qcow2
mkdir -p ${INSTALL_DIR}

wget -O ${INSTALL_DIR}/installer-linux http://http.us.debian.org/debian/dists/bullseye/main/installer-arm64/current/images/netboot/debian-installer/arm64/linux
wget -O ${INSTALL_DIR}/installer-initrd.gz http://http.us.debian.org/debian/dists/bullseye/main/installer-arm64/current/images/netboot/debian-installer/arm64/initrd.gz

qemu-img create -f qcow2 ${INSTALL_DISK} 5G

qemu-system-aarch64 -M virt -m 1024 -cpu cortex-a53 -kernel ${INSTALL_DIR}/installer-linux -initrd ${INSTALL_DIR}/installer-initrd.gz -drive if=none,file=${INSTALL_DISK},format=qcow2,id=hd -device virtio-blk-pci,drive=hd -netdev user,id=mynet -device virtio-net-pci,netdev=mynet -nographic -no-reboot
```

```bash
WORK_DIR=$(mktemp -d)
VM_DIR=${PROJECTS_ROOT}/vm
VM_DISK=${VM_DIR}/hda.qcow2
mkdir -p ${VM_DIR}
cp ${INSTALL_DISK} ${VM_DISK}
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

oc new-project qemu-images
oc policy add-role-to-group system:image-puller system:serviceaccounts -n qemu-images
oc policy add-role-to-group system:image-puller system:authenticated -n qemu-images

podman build --build-arg VM_FILES_DIR=${VM_DIR} -t image-registry.openshift-image-registry.svc:5000/qemu-images/debian-aarch64:latest -f vm.Containerfile .
podman push image-registry.openshift-image-registry.svc:5000/qemu-images/debian-aarch64:latest
```

```bash
VM_DIR=${PROJECTS_ROOT}/vm
mkdir -p ${VM_DIR}
podman pull image-registry.openshift-image-registry.svc:5000/qemu-images/debian-aarch64:latest
podman create --name vm-files image-registry.openshift-image-registry.svc:5000/qemu-images/debian-aarch64:latest ls
podman cp vm-files:/ ${VM_DIR}/
podman container rm vm-files
podman image rm image-registry.openshift-image-registry.svc:5000/qemu-images/debian-aarch64:latest
```

```bash
qemu-system-aarch64 -M virt -m 1024 -cpu cortex-a53 -kernel ${VM_DIR}/vmlinuz -initrd ${VM_DIR}/initrd.img -append 'root=/dev/vda2' -drive if=none,file=${VM_DIR}/hda.qcow2,format=qcow2,id=hd -device virtio-blk-pci,drive=hd -netdev user,id=mynet -device virtio-net-pci,netdev=mynet -nographic
```

## Notes - Not Working

```bash
fdisk -l 2023-12-05-raspios-bookworm-arm64-lite.img

echo $(( 8192*512 ))

mount -o loop,offset=4194304 2023-12-05-raspios-bookworm-arm64-lite.img /mnt
cp /mnt/kernel8.img ~/
cp /mnt/bcm2710-rpi-3-b-plus.dtb ~/
umount /mnt

qemu-img resize 2023-12-05-raspios-bookworm-arm64-lite.img 4G
```

```bash
qemu-system-aarch64 -machine raspi3b -cpu cortex-a72 -smp 4 -m 1G -kernel kernel8.img -append "root=/dev/mmcblk0p2 rootdelay=1 rootfstype=ext4 rw panic=0 console=ttyAMA0,115200" -sd 2023-12-05-raspios-bookworm-arm64-lite.img -dtb bcm2710-rpi-3-b-plus.dtb -display none -monitor telnet:127.0.0.1:5555,server,nowait -nographic -serial stdio

qemu-system-aarch64 -machine raspi3b -smp 4 -m 1G -kernel kernel8.img -append "rw loglevel=8 root=/dev/mmcblk0p2 rootdelay=1 rootfstype=ext4 rw panic=0 console=ttyAMA0,115200" -sd 2023-12-05-raspios-bookworm-arm64-lite.img -dtb bcm2710-rpi-3-b-plus.dtb -display none -monitor telnet:127.0.0.1:5555,server,nowait -nographic -serial stdio

qemu-system-aarch64 -M raspi3 -append "rw earlyprintk loglevel=8 console=ttyAMA0,115200 dwc_otg.lpm_enable=0 root=/dev/mmcblk0p2 rootdelay=1" -dtb bcm2710-rpi-3-b-plus.dtb -sd 2021-10-30-raspios-bullseye-armhf.img -kernel kernel8.img -m 1G -smp 4 -serial stdio -usb -device usb-mouse -device usb-kbd -vnc 192.168.2.1:0
```


```bash
virt-install --name aarch64-f32-cdrom --ram 2048 --disk size=10 --os-variant fedora39 --arch aarch64 --cdrom /root/Fedora-Server-netinst-aarch64-39-1.5.iso
```
