```
[root@lvm vagrant]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
├─sda1                    8:1    0    1M  0 part
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk
sdc                       8:32   0    2G  0 disk
sdd                       8:48   0    1G  0 disk
sde                       8:64   0    1G  0 disk
```

# **уменьшить том под / до 8G**
```
[root@lvm vagrant]# df -Th
Filesystem                      Type      Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00 xfs        38G  821M   37G   3% /
devtmpfs                        devtmpfs  109M     0  109M   0% /dev
tmpfs                           tmpfs     118M     0  118M   0% /dev/shm
tmpfs                           tmpfs     118M  4.6M  114M   4% /run
tmpfs                           tmpfs     118M     0  118M   0% /sys/fs/cgroup
/dev/sda2                       xfs      1014M   63M  952M   7% /boot
tmpfs                           tmpfs      24M     0   24M   0% /run/user/1000
tmpfs 
```
## Видим, что файловая система xfs, то для изменения размера в меньшую сторону нужно сдампить во временный раздел содержимое текущего и поменять точку монтирования. Затем уменьшить исходный раздел, сдампить уже временный раздел в новый исходный, вернуть точку монтирования.

```
[root@lvm vagrant]# pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
[root@lvm vagrant]# vgcreate vg_tmp_root /dev/sdb
  Volume group "vg_tmp_root" successfully created
[root@lvm vagrant]# lvcreate -n lv_tmp_root -l +100%FREE /dev/vg_tmp_root
  Logical volume "lv_tmp_root" created.
```
## Была создана группа томов vg_tmp_root, и сделан из нее один логический раздел lv_tmp_root.

## Создадим файловую систему XFS и смонтируем ее в каталог /mnt:
```
[root@lvm vagrant]# mkfs.xfs /dev/vg_tmp_root/lv_tmp_root
meta-data=/dev/vg_tmp_root/lv_tmp_root isize=512    agcount=4, agsize=655104 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2620416, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
[root@lvm vagrant]# mount /dev/vg_tmp_root/lv_tmp_root /mnt
```

# Сдампим содержимое текущего корневого раздела в наш временный:
```
[root@lvm vagrant]# xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt
xfsrestore: using file dump (drive_simple) strategy
xfsrestore: version 3.1.7 (dump format 3.0)
...
...
```

## Заходим в окружение chroot нашего временного корня:
```
[root@lvm vagrant]# for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
[root@lvm vagrant]# chroot /mnt/
[root@lvm /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done
[root@lvm /]# cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done
...
...

```
## Редактируем /boot/grub2/grub.cfg, где меняем VolGroup00-LogVol00 на vg_tmp_root/lv_tmp_root
## Выходим из окружения chroot и перезагружаемся.

```
[vagrant@lvm ~]$ lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                         8:0    0   40G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0    1G  0 part /boot
└─sda3                      8:3    0   39G  0 part
  ├─VolGroup00-LogVol00   253:1    0 37.5G  0 lvm
  └─VolGroup00-LogVol01   253:2    0  1.5G  0 lvm  [SWAP]
sdb                         8:16   0   10G  0 disk
└─vg_tmp_root-lv_tmp_root 253:0    0   10G  0 lvm  /
sdc                         8:32   0    2G  0 disk
sdd                         8:48   0    1G  0 disk
sde                         8:64   0    1G  0 disk
```

## Удаляем старый логический том и создаем новый.
```
[root@lvm vagrant]# lvremove /dev/VolGroup00/LogVol00
Do you really want to remove active logical volume VolGroup00/LogVol00? [y/n]: y
  Logical volume "LogVol00" successfully removed

[root@lvm vagrant]# lvcreate -L8G -n LogVol00 VolGroup00
WARNING: xfs signature detected on /dev/VolGroup00/LogVol00 at offset 0. Wipe it? [y/n]: y
  Wiping xfs signature on /dev/VolGroup00/LogVol00.
  Logical volume "LogVol00" created.
```

## Создаем на нем файловую систему и монтируем его:
```
[root@lvm vagrant]# mkfs.xfs /dev/VolGroup00/LogVol00
meta-data=/dev/VolGroup00/LogVol00 isize=512    agcount=4, agsize=524288 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2097152, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
[root@lvm vagrant]# mount /dev/VolGroup00/LogVol00 /mnt
```

## Возвращаем обратно содержимое корня:

```
[root@lvm vagrant]# xfsdump -J - /dev/vg_tmp_root/lv_tmp_root | xfsrestore -J - /mnt
xfsrestore: using file dump (drive_simple) strategy
xfsrestore: version 3.1.7 (dump format 3.0)
xfsdump: using file dump (drive_simple) strategy
...
...
```

## Заходим в окружение chroot нашего временного корня:
```
[root@lvm vagrant]# for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
[root@lvm vagrant]# chroot /mnt/
```

## Запишем новый загрузчик:
```
[root@lvm /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done
```

## Обновляем образы загрузки:
```
[root@lvm /]# cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done
...
...
```

## Проверяем  /boot/grub2/grub.cfg
## Выходим из chroot и перезагружаемся

```
[vagrant@lvm ~]$ lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                         8:0    0   40G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0    1G  0 part /boot
└─sda3                      8:3    0   39G  0 part
  ├─VolGroup00-LogVol00   253:0    0    8G  0 lvm  /
  └─VolGroup00-LogVol01   253:1    0  1.5G  0 lvm  [SWAP]
sdb                         8:16   0   10G  0 disk
└─vg_tmp_root-lv_tmp_root 253:2    0   10G  0 lvm
sdc                         8:32   0    2G  0 disk
sdd                         8:48   0    1G  0 disk
sde
```

## Удаляем временный том 
```
[root@lvm vagrant]# lvremove /dev/vg_tmp_root/lv_tmp_root
Do you really want to remove active logical volume vg_tmp_root/lv_tmp_root? [y/n]: y
  Logical volume "lv_tmp_root" successfully removed
[root@lvm vagrant]# vgremove /dev/vg_tmp_root
  Volume group "vg_tmp_root" successfully removed
[root@lvm vagrant]# pvremove /dev/sdb
  Labels on physical volume "/dev/sdb" successfully wiped.
```

# **выделить том под /home**
```
[root@lvm vagrant]#  lvcreate -n LogVol_02 -L2G /dev/VolGroup00
  Logical volume "LogVol_02" created.
[root@lvm vagrant]# mkfs.xfs /dev/VolGroup00/LogVol_02
meta-data=/dev/VolGroup00/LogVol_02 isize=512    agcount=4, agsize=131072 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=524288, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
[root@lvm vagrant]# mount /dev/VolGroup00/LogVol_02 /mnt
[root@lvm vagrant]# cp -aR /home/* /mnt/
[root@lvm vagrant]# rm -rf /home/*
[root@lvm vagrant]# umount /mnt
[root@lvm vagrant]# mount /dev/VolGroup00/LogVol_02 /home
```
## Правим fstab 
```
echo "`blkid | grep _02 | awk '{print $2}'` /home xfs defaults 0 0" >> /etc/fstab
```

# **выделить том под /var (/var - сделать в mirror)**
## На свободнýх дисках создаем зеркало:
```
[root@lvm vagrant]# pvcreate /dev/sdc /dev/sdd
  Physical volume "/dev/sdc" successfully created.
  Physical volume "/dev/sdd" successfully created.
[root@lvm vagrant]# vgcreate vg_var /dev/sdc /dev/sdd
  Volume group "vg_var" successfully created
[root@lvm vagrant]# lvcreate -L 900M -m1 -n lv_var vg_var
  Logical volume "lv_var" created.
```

## Создаем на нем ФС и перемещаем туда /var:
```
[root@lvm vagrant]# mkfs.ext4 /dev/vg_var/lv_var
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
57600 inodes, 230400 blocks
11520 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=236978176
8 block groups
32768 blocks per group, 32768 fragments per group
7200 inodes per group
Superblock backups stored on blocks:
	32768, 98304, 163840, 229376

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

[root@lvm vagrant]# mount /dev/vg_var/lv_var /mnt
[root@lvm vagrant]# cp -aR /var/* /mnt/
[root@lvm vagrant]# umount /mnt
[root@lvm vagrant]# mount /dev/vg_var/lv_var /var
[root@lvm vagrant]# echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab
[root@lvm vagrant]# lsblk
NAME                     MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                        8:0    0   40G  0 disk
├─sda1                     8:1    0    1M  0 part
├─sda2                     8:2    0    1G  0 part /boot
└─sda3                     8:3    0   39G  0 part
  ├─VolGroup00-LogVol00  253:0    0    8G  0 lvm  /
  ├─VolGroup00-LogVol01  253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol_02 253:7    0    2G  0 lvm  /home
sdb                        8:16   0   10G  0 disk
sdc                        8:32   0    2G  0 disk
├─vg_var-lv_var_rmeta_0  253:2    0    4M  0 lvm
│ └─vg_var-lv_var        253:6    0  900M  0 lvm  /var
└─vg_var-lv_var_rimage_0 253:3    0  900M  0 lvm
  └─vg_var-lv_var        253:6    0  900M  0 lvm  /var
sdd                        8:48   0    1G  0 disk
├─vg_var-lv_var_rmeta_1  253:4    0    4M  0 lvm
│ └─vg_var-lv_var        253:6    0  900M  0 lvm  /var
└─vg_var-lv_var_rimage_1 253:5    0  900M  0 lvm
  └─vg_var-lv_var        253:6    0  900M  0 lvm  /var
sde                        8:64   0    1G  0 disk
```

# **Работа со снапшотами:**
```
[root@lvm vagrant]# touch /home/file{1..20}
[root@lvm vagrant]# lvcreate -L 500MB -s -n home_snap /dev/VolGroup00/LogVol_02
[root@lvm vagrant]# rm -f /home/file{11..20}
[root@lvm vagrant]# umount /home
[root@lvm vagrant]# lvconvert --merge /dev/VolGroup00/home_snap
  Merging of volume VolGroup00/home_snap started.
  VolGroup00/LogVol_02: Merged: 100.00%
[root@lvm vagrant]# mount /home
[root@lvm vagrant]# ls /home/
file1   file11  file13  file15  file17  file19  file20  file4  file6  file8  vagrant
file10  file12  file14  file16  file18  file2   file3   file5  file7  file9
```

# **Установка zfs**

## Устанавливаем zfs
```
yum install http://download.zfsonlinux.org/epel/zfs-release.el7_5.noarch.rpm -y
gpg --quiet --with-fingerprint /etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux
```
## В разделе [zfs] поменять enabled=1 на enabled=0, а в разделе [zfs-kmod] наоборот, enabled=0 на enabled=1
```
modprobe zfs

## Создаем lvm-том
```
[root@lvm vagrant]# pvcreate /dev/sdb /dev/sde
  Physical volume "/dev/sdb" successfully created.
  Physical volume "/dev/sde" successfully created.
[root@lvm vagrant]# vgcreate vg_opt /dev/sdb /dev/sde
  Volume group "vg_opt" successfully created
[root@lvm vagrant]# lvcreate -l+100%FREE -n lv_opt vg_opt
WARNING: xfs signature detected on /dev/vg_opt/lv_opt at offset 0. Wipe it? [y/n]: y
  Wiping xfs signature on /dev/vg_opt/lv_opt.
  Logical volume "lv_opt" created.
```
## Создаем пул и устанавливаем точку монтирования
```
[root@lvm vagrant]# zpool create pool0 /dev/vg_opt/lv_opt
[root@lvm vagrant]# zpool list
NAME    SIZE  ALLOC   FREE  EXPANDSZ   FRAG    CAP  DEDUP  HEALTH  ALTROOT
pool0  10.9G   273K  10.9G         -     0%     0%  1.00x  ONLINE  -
[root@lvm vagrant]# zfs create pool0/opt
[root@lvm vagrant]# zfs set mountpoint=/opt pool0/opt
```

## Делаем снапшот
```
[root@lvm vagrant]# zfs snapshot pool0/opt@snap
[root@lvm vagrant]# zfs list -t snapshot
NAME             USED  AVAIL  REFER  MOUNTPOINT
pool0/opt@snap     0B      -    24K  -
```

## Освободим место и создадим cache (cache data)
```
[root@lvm vagrant]# lvreduce -L-2G /dev/vg_opt/lv_opt
  WARNING: Reducing active and open logical volume to 8.99 GiB.
  THIS MAY DESTROY YOUR DATA (filesystem etc.)
Do you really want to reduce vg_opt/lv_opt? [y/n]: y
  Size of logical volume vg_opt/lv_opt changed from 10.99 GiB (2814 extents) to 8.99 GiB (2302 extents).
  Logical volume vg_opt/lv_opt successfully resized.

[root@lvm vagrant]# lvcreate -n cache -L900M vg_opt /dev/sdb
  Logical volume "cache" created.
```



