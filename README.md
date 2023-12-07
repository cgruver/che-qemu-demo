# kubevirt-cpu-emulation
Testing the feasibility of running aarch64 guest on x86_64 host

```bash
virt-install --name aarch64-f32-cdrom --ram 2048 --disk size=10 --os-variant fedora39 --arch aarch64 --cdrom /root/Fedora-Server-netinst-aarch64-39-1.5.iso
```
