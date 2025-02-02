## Создаем RAID5
root@otus:~# mdadm --create --verbose /dev/md0 --level=5 --raid-devices=3 /dev/sdb /dev/sdc /dev/sdd
## Проверяем
root@otus:~# cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4]
md0 : active raid5 sdd[3] sdc[1] sdb[0]
      4188160 blocks super 1.2 level 5, 512k chunk, algorithm 2 [3/3] [UUU]

unused devices: <none>

## Создаем файловую систему поверх RAID-массива
root@otus:~# mkfs.ext4 /dev/md0
mke2fs 1.47.0 (5-Feb-2023)
Creating filesystem with 1047040 4k blocks and 262144 inodes
Filesystem UUID: 00e3e871-31df-487e-aa48-b7a890722433
Superblock backups stored on blocks:
	32768, 98304, 163840, 229376, 294912, 819200, 884736

Allocating group tables: done
Writing inode tables: done
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done

## Создаем точку монтирования для RAID-массива
root@otus:/# mkdir /mnt/raid5

## mdadm.conf
root@otus:mdadm --detail --scan --verbose > /etc/mdadm/dmadm.conf

## Корректируем fstab
root@otus:/# cat /etc/fstab 
### Добавим следующую строку.
UUID=f04e8141-e3c8-45a0-9089-4a212b2aaed4	/mnt/raid5  ext4	defaults    1 2

## Монтируем наш RAID
root@otus:/# mount -a

## Перезагружаемся и проверяем

root@otus:~# lsblk
NAME    MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINTS
sda       8:0    0   16G  0 disk  
├─sda1    8:1    0 15.9G  0 part  /
├─sda14   8:14   0    3M  0 part  
└─sda15   8:15   0  124M  0 part  /boot/efi
sdb       8:16   0    2G  0 disk  
└─md127     9:0    0    4G  0 raid5 /mnt/raid5
sdc       8:32   0    2G  0 disk  
└─md127     9:0    0    4G  0 raid5 /mnt/raid5
sdd       8:48   0    2G  0 disk  
└─md127     9:0    0    4G  0 raid5 /mnt/raid5
sde       8:64   0    2G  0 disk  
sdf       8:80   0    2G  0 disk  
sr0      11:0    1  364K  0 rom

#### После перезагрузки md0 переименовывает на md127, поэтому в fstab и добавлял uuid


## Ломаем RAID5
root@otus:~# mdadm /dev/md127 --fail /dev/sdb
[ 7295.060488] md/raid:md127: Disk failure on sdb, disabling device.
[ 7295.061030] md/raid:md127: Operation continuing on 2 devices.
mdadm: set /dev/sdb faulty in /dev/md127

root@otus:~# cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4] [linear] [multipath] [raid0] [raid1] [raid10]
md127 : active raid5 sdb[0](F) sdc[1] sdd[3]
      4188160 blocks super 1.2 level 5, 512k chunk, algorithm 2 [3/2] [_UU]

unused devices: <none>

## Восстановливаем
root@otus:~# mdadm /dev/md127 -a /dev/sde
mdadm: added /dev/sde
root@otus:~# [ 7417.078896] md: recovery of RAID array md127
[ 7427.727743] md: md127: recovery done.

root@otus:~# mdadm --assemble /dev/md127 /dev/sdc /dev/sdd /dev/sde
mdadm: /dev/sdc is busy - skipping
mdadm: /dev/sdd is busy - skipping
mdadm: /dev/sde is busy - skipping
root@otus:~# cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4] [linear] [multipath] [raid0] [raid1] [raid10]
md127 : active raid5 sde[4] sdb[0](F) sdc[1] sdd[3]
      4188160 blocks super 1.2 level 5, 512k chunk, algorithm 2 [3/3] [UUU]

### После перезагрузки
root@otus:~# lsblk
NAME    MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINTS
sda       8:0    0   16G  0 disk  
├─sda1    8:1    0 15.9G  0 part  /
├─sda14   8:14   0    3M  0 part  
└─sda15   8:15   0  124M  0 part  /boot/efi
sdb       8:16   0    2G  0 disk  
sdc       8:32   0    2G  0 disk  
└─md127   9:127  0    4G  0 raid5 /mnt/raid5
sdd       8:48   0    2G  0 disk  
└─md127   9:127  0    4G  0 raid5 /mnt/raid5
sde       8:64   0    2G  0 disk  
└─md127   9:127  0    4G  0 raid5 /mnt/raid5
sdf       8:80   0    2G  0 disk  
sr0      11:0    1  364K  0 rom 

## Создаем gpt раздел и 5 партиций
root@otus:~# parted -s /dev/sdf mklabel gpt
[  719.016713]  sdf:
root@otus:~# parted /dev/sdf mkpart primary ext3 0% 10%
Information: You may need to update /etc/fstab.

[  769.524812]  sdf: sdf1
root@otus:~# parted /dev/sdf mkpart primary ext4 10% 20%
Information: You may need to update /etc/fstab.

[  794.256160]  sdf: sdf1 sdf2
root@otus:~# parted /dev/sdf mkpart primary ext4 20% 40%
Information: You may need to update /etc/fstab.

[  803.576135]  sdf: sdf1 sdf2 sdf3
root@otus:~# parted /dev/sdf mkpart primary ext4 40% 70%
Information: You may need to update /etc/fstab.

[  812.831972]  sdf: sdf1 sdf2 sdf3 sdf4
root@otus:~# parted /dev/sdf mkpart primary ext2 70% 100%
Information: You may need to update /etc/fstab.

root@otus:~# [  822.436362]  sdf: sdf1 sdf2 sdf3 sdf4 sdf5

### Далее создаем на партициях файловые системы и монтируем
root@otus:~# lsblk
NAME    MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINTS
sda       8:0    0   16G  0 disk
├─sda1    8:1    0 15.9G  0 part  /
├─sda14   8:14   0    3M  0 part
└─sda15   8:15   0  124M  0 part  /boot/efi
sdb       8:16   0    2G  0 disk
sdc       8:32   0    2G  0 disk
└─md127   9:127  0    4G  0 raid5 /mnt/raid5
sdd       8:48   0    2G  0 disk
└─md127   9:127  0    4G  0 raid5 /mnt/raid5
sde       8:64   0    2G  0 disk
└─md127   9:127  0    4G  0 raid5 /mnt/raid5
sdf       8:80   0    2G  0 disk
├─sdf1    8:81   0  204M  0 part  /mnt/disk1
├─sdf2    8:82   0  205M  0 part  /mnt/disk2
├─sdf3    8:83   0  409M  0 part  /mnt/disk3
├─sdf4    8:84   0  615M  0 part  /mnt/disk4
└─sdf5    8:85   0  613M  0 part  /mnt/disk5
sr0      11:0    1  364K  0 rom


