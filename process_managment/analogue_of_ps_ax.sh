#!/bin/bash
cd /proc
ls -vd [0-9]* > /tmp/pids.txt
file=/tmp/pids.txt
lines=`cat $file |wc -l` # Кол-во строк в файле
echo PID TTY STAT COM
for ((num=1;num<${lines};num++))
    do
        PID=`sed -n ${num}p $file |xargs -I pid cut -d " " -f 1 /proc/"pid"/stat`
        TTY=`sed -n ${num}p $file |xargs -I pid ls -l /proc/"pid"/fd/0 2> /dev/null |grep -o '/dev/.*' |sed -e 's/\/dev\///g'`
        if [ -z "$TTY" ];
            then
                TTY="[?] "
        fi
        STAT=`sed -n ${num}p $file |xargs -I pid grep "State:" /proc/"pid"/status |sed "s/State://g"|cut -d " " -f 1`
        COM=`sed -n ${num}p $file |xargs -I pid cut -d " " -f 1 /proc/"pid"/comm`
       echo $PID $TTY $STAT $COM
    done
