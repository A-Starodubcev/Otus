# Задание: Обновить ядро

## Стенд:
- libvirt + qemu/kvm
- terraform

---
В домашнем задании установил ядро linux-libre.
Результат:
```
root@otus:~# uname -r
6.12.8-gnu
```


## Собираем ядро из исходников.

apt install bc binutils bison dwarves flex gcc git gnupg2 gzip libelf-dev libncurses5-dev libssl-dev make openssl pahole perl-base rsync tar xz-utils lzip

wget https://linux-libre.fsfla.org/pub/linux-libre/freesh/linux-libre-6.12.8-source.tar.lz
wget https://linux-libre.fsfla.org/pub/linux-libre/freesh/configs/6.12/x86-64

mv x86-64 .config

make -j 8

```
...
...
  MKPIGGY arch/x86/boot/compressed/piggy.S
  AS      arch/x86/boot/compressed/piggy.o
  LD      arch/x86/boot/compressed/vmlinux
  ZOFFSET arch/x86/boot/zoffset.h
  OBJCOPY arch/x86/boot/vmlinux.bin
  AS      arch/x86/boot/header.o
  LD      arch/x86/boot/setup.elf
  OBJCOPY arch/x86/boot/setup.bin
  BUILD   arch/x86/boot/bzImage
Kernel: arch/x86/boot/bzImage is ready  (#1)
root@otus:~/linux-libre-6.12.8-source/linux#
```
make modules_install -j 8

```
...
...
  ZSTD    /lib/modules/6.12.8-gnu/kernel/net/nsh/nsh.ko.zst
  ZSTD    /lib/modules/6.12.8-gnu/kernel/net/hsr/hsr.ko.zst
  ZSTD    /lib/modules/6.12.8-gnu/kernel/net/qrtr/qrtr.ko.zst
  ZSTD    /lib/modules/6.12.8-gnu/kernel/net/qrtr/qrtr-smd.ko.zst
  ZSTD    /lib/modules/6.12.8-gnu/kernel/net/qrtr/qrtr-tun.ko.zst
  ZSTD    /lib/modules/6.12.8-gnu/kernel/net/qrtr/qrtr-mhi.ko.zst
  DEPMOD  /lib/modules/6.12.8-gnu
```

make headers_install

```
root@otus:~/linux-libre-6.12.8-source/linux# make install
  INSTALL /boot
run-parts: executing /etc/kernel/postinst.d/apt-auto-removal 6.12.8-gnu /boot/vmlinuz-6.12.8-gnu
run-parts: executing /etc/kernel/postinst.d/initramfs-tools 6.12.8-gnu /boot/vmlinuz-6.12.8-gnu
update-initramfs: Generating /boot/initrd.img-6.12.8-gnu
find: ‘/var/tmp/mkinitramfs_HDBgEY/lib/modules/6.12.8-gnu/kernel’: No such file or directory
run-parts: executing /etc/kernel/postinst.d/unattended-upgrades 6.12.8-gnu /boot/vmlinuz-6.12.8-gnu
run-parts: executing /etc/kernel/postinst.d/zz-update-grub 6.12.8-gnu /boot/vmlinuz-6.12.8-gnu
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-6.12.8-gnu
Found initrd image: /boot/initrd.img-6.12.8-gnu
Found linux image: /boot/vmlinuz-5.10.0-33-amd64
Found initrd image: /boot/initrd.img-5.10.0-33-amd64
done
```
grub-mkconfig -o /boot/grub/grub.cfg
reboot

```
root@otus:~# uname -r
6.12.8-gnu
```
