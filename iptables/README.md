# Реализация knocking port
```
vagrant@centralRouter:~$ ssh vagrant@192.168.255.1
^C
vagrant@centralRouter:~$ knock 192.168.255.1 8881:tcp 7777:tcp 9991:tcp
vagrant@centralRouter:~$ ssh vagrant@192.168.255.1
vagrant@192.168.255.1's password:
Linux inetRouter 5.10.0-22-amd64 #1 SMP Debian 5.10.178-3 (2023-04-22) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Sun Jun  4 08:59:27 2023 from 192.168.255.2
vagrant@inetRouter:~$
```

# Добавить inetRouter2, который виден(маршрутизируется (host-only тип сети для виртуалки)) с хоста или форвардится порт через локалхост.

```
if boxname.to_s == "inetRouter2"
    box.vm.network "forwarded_port", guest: 8080, guest_ip: "192.168.250.1", host: 9090, host_ip: "127.0.0.1",  protocol: "tcp"
end
```

# Запустить nginx на centralServer 
```
vagrant@centralServer:/proc$ curl -I localhost
HTTP/1.1 200 OK
Server: nginx/1.18.0
Date: Thu, 06 Jul 2023 10:02:58 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Thu, 06 Jul 2023 09:51:56 GMT
Connection: keep-alive
ETag: "64a68ebc-264"
Accept-Ranges: bytes
```

# пробросить 80й порт на inetRouter2 8080
```
vagrant@inetRouter2:~$ sudo iptables -vnL -t nat
Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 DNAT       tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8080 to:192.168.50.34:80

Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 DNAT       tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8080 to:192.168.50.34:80

Chain POSTROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
   54  3829 MASQUERADE  all  --  *      *       0.0.0.0/0            0.0.0.0/0           
```
