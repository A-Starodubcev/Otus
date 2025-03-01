# **Создать свой RPM пакет**

Vagrantfile -  создает свой репозиторий и размещает свой rpm пакет httpd

Конечный результат
```
[vagrant@rpm ~]$ curl -a http://localhost/repo/
<html>
<head><title>Index of /repo/</title></head>
<body>
<h1>Index of /repo/</h1><hr><pre><a href="../">../</a>
<a href="repodata/">repodata/</a>                                          07-Jun-2022 20:21                   -
<a href="apr-1.7.0-1.x86_64.rpm">apr-1.7.0-1.x86_64.rpm</a>                             07-Jun-2022 20:21              110228
<a href="apr-debuginfo-1.7.0-1.x86_64.rpm">apr-debuginfo-1.7.0-1.x86_64.rpm</a>                   07-Jun-2022 20:21              477512
<a href="apr-devel-1.7.0-1.x86_64.rpm">apr-devel-1.7.0-1.x86_64.rpm</a>                       07-Jun-2022 20:21              881184
<a href="httpd-2.4.53-1.x86_64.rpm">httpd-2.4.53-1.x86_64.rpm</a>                          07-Jun-2022 20:21             1420292
<a href="httpd-debuginfo-2.4.53-1.x86_64.rpm">httpd-debuginfo-2.4.53-1.x86_64.rpm</a>                07-Jun-2022 20:21             3939856
<a href="httpd-devel-2.4.53-1.x86_64.rpm">httpd-devel-2.4.53-1.x86_64.rpm</a>                    07-Jun-2022 20:21              210080
<a href="httpd-manual-2.4.53-1.x86_64.rpm">httpd-manual-2.4.53-1.x86_64.rpm</a>                   07-Jun-2022 20:21             4402076
<a href="httpd-tools-2.4.53-1.x86_64.rpm">httpd-tools-2.4.53-1.x86_64.rpm</a>                    07-Jun-2022 20:21               80148
<a href="mod_authnz_ldap-2.4.53-1.x86_64.rpm">mod_authnz_ldap-2.4.53-1.x86_64.rpm</a>                07-Jun-2022 20:21               48296
<a href="mod_lua-2.4.53-1.x86_64.rpm">mod_lua-2.4.53-1.x86_64.rpm</a>                        07-Jun-2022 20:21               48532
<a href="mod_proxy_html-2.4.53-1.x86_64.rpm">mod_proxy_html-2.4.53-1.x86_64.rpm</a>                 07-Jun-2022 20:21               25172
<a href="mod_ssl-2.4.53-1.x86_64.rpm">mod_ssl-2.4.53-1.x86_64.rpm</a>                        07-Jun-2022 20:21               99024
</pre><hr></body>
</html>
```
