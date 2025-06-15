#1 Для первого задания создан playbook
#2 
```
vagrant@client:/etc/openvpn$ sudo openvpn --config client.conf --daemon
vagrant@client:/etc/openvpn# ping 10.10.10.1 -c 2
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=2.41 ms
64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=2.79 ms
--- 10.10.10.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 2.411/2.601/2.792/0.190 ms

vagrant@client:/etc/openvpn# ip route
default via 192.168.88.1 dev enp4s0
10.10.10.0/24 via 10.10.10.5 dev tun0
10.10.10.5 dev tun0 proto kernel scope link src 10.10.10.6
78.29.2.21 via 192.168.88.1 dev enp4s0
78.29.2.22 via 192.168.88.1 dev enp4s0
192.168.10.0/24 via 10.10.10.5 dev tun0
192.168.56.0/24 dev vboxnet0 proto kernel scope link src 192.168.56.1
192.168.88.0/24 dev enp4s0 proto kernel scope link src 192.168.88.212
192.168.88.1 dev enp4s0 scope link
```
