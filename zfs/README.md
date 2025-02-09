# **1. Определение алгоритма с наилучшим сжатием**

## Смотрим список всех дисков, которые есть в виртуальной машине: lsblk
```
[vagrant@zfs ~]$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0  512M  0 disk
sdb      8:16   0  512M  0 disk
sdc      8:32   0  512M  0 disk
sdd      8:48   0  512M  0 disk
sde      8:64   0  512M  0 disk
sdf      8:80   0  512M  0 disk
sdg      8:96   0  512M  0 disk
sdh      8:112  0  512M  0 disk
sdi      8:128  0   40G  0 disk
└─sdi1   8:129  0   40G  0 part /
```

## Создаём пулы из двух дисков в режиме RAID 1:
```
[root@zfs vagrant]# zpool create otus1 mirror /dev/sda /dev/sdb
[root@zfs vagrant]# zpool create otus2 mirror /dev/sdc /dev/sdd
[root@zfs vagrant]# zpool create otus3 mirror /dev/sde /dev/sdf
[root@zfs vagrant]# zpool create otus4 mirror /dev/sdg /dev/sdh
[root@zfs vagrant]# zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1   480M   100K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus2   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus3   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus4   480M  94.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
```

## Добавим разные алгоритмы сжатия в каждую файловую систему:
```
[root@zfs vagrant]# zfs set compression=lzjb otus1
[root@zfs vagrant]# zfs set compression=lz4 otus2
[root@zfs vagrant]# zfs set compression=gzip-9 otus3
[root@zfs vagrant]# zfs set compression=zle otus4
[root@zfs vagrant]# zfs get all | grep compression
otus1  compression           lzjb                   local
otus2  compression           lz4                    local
otus3  compression           gzip-9                 local
otus4  compression           zle                    local
```

## Скачаем один и тот же текстовый файл во все пулы:
```
[root@zfs vagrant]# for i in {1..4}; do wget -P /otus$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done
...

[root@zfs vagrant]# ls -l /otus*
/otus1:
total 22020
-rw-r--r--. 1 root root 40809473 May  2 08:01 pg2600.converter.log

/otus2:
total 17972
-rw-r--r--. 1 root root 40809473 May  2 08:01 pg2600.converter.log

/otus3:
total 10949
-rw-r--r--. 1 root root 40809473 May  2 08:01 pg2600.converter.log

/otus4:
total 39881
-rw-r--r--. 1 root root 40809473 May  2 08:01 pg2600.converter.log

[root@zfs vagrant]# zfs list
NAME    USED  AVAIL     REFER  MOUNTPOINT
otus1  21.6M   330M     21.5M  /otus1
otus2  17.6M   334M     17.6M  /otus2
otus3  10.8M   341M     10.7M  /otus3
otus4  39.1M   313M     39.0M  /otus4
[root@zfs vagrant]# zfs get all | grep compressratio | grep -v ref
otus1  compressratio         1.81x                  -
otus2  compressratio         2.22x                  -
otus3  compressratio         3.64x                  -
otus4  compressratio         1.00x                  -
```
## Таким образом, у нас получается, что алгоритм gzip-9 самый эффективный по сжатию.

# **Определить настройки pool’a. Зачем: для переноса дисков между системами используется функция export/import.**
## Скачиваем архив в домашний каталог:
```
[root@zfs vagrant]# wget -O archive.tar.gz --no-check-certificate https://drive.google.com/u/0/uc?id=1KRBNW33QWqbvbVHa3
hLJivOAt60yukkg&export=download
```

## Разархивируем его:
```
[root@zfs vagrant]# tar -xzvf archive.tar.gz
zpoolexport/
zpoolexport/filea
zpoolexport/fileb
```

## Проверим, возможно ли импортировать данный каталог в пул:
```
[root@zfs vagrant]# zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
 action: The pool can be imported using its name or numeric identifier.
 config:

	otus                                 ONLINE
	 mirror-0                           ONLINE
	   /home/vagrant/zpoolexport/filea  ONLINE
	   /home/vagrant/zpoolexport/fileb  ONLINE
```
## Данный вывод показывает нам имя пула, тип raid и его состав.
## Сделаем импорт данного пула к нам в ОС:
```
[root@zfs vagrant]# zpool import -d zpoolexport/ otus
[root@zfs vagrant]# zpool status
  pool: otus
 state: ONLINE
  scan: none requested
config:

	NAME                                 STATE     READ WRITE CKSUM
	otus                                 ONLINE       0     0     0
	 mirror-0                           ONLINE       0     0     0
	   /home/vagrant/zpoolexport/filea  ONLINE       0     0     0
	   /home/vagrant/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors
...
...

[root@zfs vagrant]# zpool status -x
all pools are healthy
```
## Далее нам нужно определить настройки
## Запрос сразу всех параметров пула: zpool get all otus
```
[root@zfs vagrant]# zfs get available otus
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -
[root@zfs vagrant]# zfs get readonly otus
NAME  PROPERTY  VALUE   SOURCE
otus  readonly  off     default
[root@zfs vagrant]# zfs get recordsize otus
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local
[root@zfs vagrant]# zfs get compression otus
NAME  PROPERTY     VALUE     SOURCE
otus  compression  zle       local
[root@zfs vagrant]# zfs get checksum otus
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local
```

# **Найти сообщение от преподавателей. Зачем: для бэкапа используются технологии snapshot. Snapshot можно передавать между хостами и восстанавливать с помощью send/receive. Отрабатываем навыки восстановления snapshot и переноса файла.**

## Скачаем файл, указанный в задании:
```
[root@zfs vagrant]# wget -O otus_task2.file --no-check-certificate https://drive.google.com/u/0/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG&export=download
...
```
## Восстановим файловую систему из снапшота:
```
[root@zfs vagrant]# zfs receive otus/test@today < otus_task2.file
```

