## **Запуск nginx на нестандартном порту 3-мя разными способами**
```
# проверим, что в ОС отключен файервол

[root@selinux ~]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: inactive (dead)
     Docs: man:firewalld(1)

# проверим конфигурацию nginx
[root@selinux ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

# проверим режим работы SELinux:
[root@selinux ~]# getenforce
Enforcing
```
### **Разрешим в SELinux работу nginx на порту TCP 4881 c помощью переключателей setsebool**
```
# Находим в логах (/var/log/audit/audit.log) информацию о блокировании порта
[root@selinux ~]# cat /var/log/audit/audit.log | grep 4881
type=AVC msg=audit(1660149309.670:818): avc:  denied  { name_bind } for  pid=2882 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

# Копируем время, в которое был записан этот лог, и, с помощью утилиты audit2why смотрим информации о запрете

[root@selinux ~]# grep 1660149309.670:818 /var/log/audit/audit.log | audit2why
type=AVC msg=audit(1660149309.670:818): avc:  denied  { name_bind } for  pid=2882 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

	Was caused by:
	The boolean nis_enabled was set incorrectly.
	Description:
	Allow nis to enabled

	Allow access by executing:
	# setsebool -P nis_enabled 1

[root@selinux ~]# setsebool -P nis_enabled on
[root@selinux ~]# systemctl restart nginx
[root@selinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/ngin4.service; disabled; vendor preset: disabled)
   Active: active (running) since Wed 2025-06-14 16:51:17 UTC; 7s ago
  Process: 3386 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 3384 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 3383 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 3388 (nginx)
   CGroup: /system.slice/nginx.service
           ├─3388 nginx: master process /usr/sbin/nginx
           └─3390 nginx: worker process

Jun 14 16:51:17 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jun 14 16:51:17 selinux nginx[3384]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jun 14 16:51:17 selinux nginx[3384]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jun 14 16:51:17 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.


# Проверить статус параметра можно с помощью команды:
[root@selinux ~]# getsebool -a | grep nis_enabled
nis_enabled --> on
```

### **Теперь разрешим в SELinux работу nginx на порту TCP 4881 c помощью добавления нестандартного порта в имеющийся тип:**
```
# Поиск имеющегося типа, для http трафика:
[root@selinux ~]# semanage port -l | grep http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989

# Добавим порт в тип http_port_t
[root@selinux ~]# semanage port -a -t http_port_t -p tcp 4881
[root@selinux ~]# semanage port -l | grep http_port_t
http_port_t                    tcp      4881, 80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
[root@selinux ~]# systemctl restart nginx
[root@selinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Wed 2025-06-14 17:17:14 UTC; 10s ago
  Process: 22358 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 22354 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 22353 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 22360 (nginx)
   CGroup: /system.slice/nginx.service
           ├─22360 nginx: master process /usr/sbin/nginx
           └─22362 nginx: worker process

Jun 14 17:17:14 selinux systemd[1]: Stopped The nginx HTTP and reverse proxy server.
Jun 14 17:17:14 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jun 14 17:17:14 selinux nginx[22354]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jun 14 17:17:14 selinux nginx[22354]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jun 14 17:17:14 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
```
### **Разрешим в SELinux работу nginx на порту TCP 4881 c помощью формирования и установки модуля SELinux:**
```
# Воспользуемся утилитой audit2allow для того, чтобы на основе логов SELinux сделать модуль, разрешающий работу nginx на нестандартном порту:
[root@selinux ~]# grep nginx /var/log/audit/audit.log | audit2allow -M nginx
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i nginx.pp

[root@selinux ~]# semodule -i nginx.pp
[root@selinux ~]# systemctl start nginx
[root@selinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Wed 2025-06-14 17:21:49 UTC; 6s ago
  Process: 22441 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 22439 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 22438 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 22443 (nginx)
   CGroup: /system.slice/nginx.service
           ├─22443 nginx: master process /usr/sbin/nginx
           └─22444 nginx: worker process

Jun 14 17:21:49 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jun 14 17:21:49 selinux nginx[22439]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jun 14 17:21:49 selinux nginx[22439]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jun 14 17:21:49 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
```

## **Обеспечение работоспособности приложения при включенном SELinux**
```
# пробуем внести изменения

[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
> quit

# проверяем логи на клиенте
cat /var/log/audit/audit.log | audit2why
# oшибок нет

# проверяем на сервере
[root@ns01 ~]# cat /var/log/audit/audit.log | audit2why
type=AVC msg=audit(1660155691.740:1911): avc:  denied  { create } for  pid=5425 comm="isc-worker0000" name="named.ddns.lab.view1.jnl" scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0

	Was caused by:
		Missing type enforcement (TE) allow rule.

		You can use audit2allow to generate a loadable module to allow this access.
# В логах мы видим, что ошибка в контексте безопасности. Вместо типа named_t используется тип etc_t.
# Проверим данную проблему в каталоге /etc/named
[root@ns01 ~]# ls -laZ /etc/named
drw-rwx---. root named system_u:object_r:etc_t:s0       .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:etc_t:s0   dynamic
-rw-rw----. root named system_u:object_r:etc_t:s0       named.50.168.192.rev
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab.view1
-rw-rw----. root named system_u:object_r:etc_t:s0       named.newdns.lab

# Тут мы также видим, что контекст безопасности неправильный. Проблема заключается в том, что конфигурационные файлы лежат в другом каталоге.

# Изменим тип контекста безопасности для каталога
[root@ns01 ~]# sudo chcon -R -t named_zone_t /etc/named
[root@ns01 ~]# ls -laZ /etc/named
drw-rwx---. root named system_u:object_r:named_zone_t:s0 .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:named_zone_t:s0 dynamic
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.50.168.192.rev
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab.view1
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.newdns.lab

# Попробуем снова внести изменения с клиента:
[root@client ~]# nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
> quit
[root@client ~]# dig www.ddns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.9 <<>> www.ddns.lab
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 18434
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.ddns.lab.			IN	A

;; ANSWER SECTION:
www.ddns.lab.		60	IN	A	192.168.50.15

;; AUTHORITY SECTION:
ddns.lab.		3600	IN	NS	ns01.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.		3600	IN	A	192.168.50.10

;; Query time: 1 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Jun 14 18:33:07 UTC 2025
;; MSG SIZE  rcvd: 96

```
