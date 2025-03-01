#!/bin/bash

mail=''
current_date=`date +%s`
file=access-4560-644067.log
last_date=`cat last_date.txt` # Последняя дата запуска скрипта
lines=`cat $file |wc -l` # Кол-во строк в файле
x_ip=5 # Число выводимых ip адресов с наибольшим кол-вом запросов
y_requested_addresses=5 # Кол-во запрашиваемых адресов

echo '' > parse_data.txt
echo '' > log.txt
echo "`date --date="@$last_date"` - `date`" >> log.txt
echo ''

for ((num=1;num<=${lines};num++))
    do if (( last_date <= `sed -n ${num}p $file |grep -o -e "[0-9]\{1,2\}/[a-zA-Z]*.*\+0300" |sed -e "s/\// /g" |sed -e "s/:/ /" |xargs -I mydate date -d "mydate" +%s` )) ; then
    sed -n ${num}p $file |awk '{print $1 ,$7 ,$9}' >> parse_data.txt
    fi
done

echo '  ip adresses' >> log.txt
cut -d " " -f1 parse_data.txt |sort |uniq -c |sort -gr |head -n ${x_ip} >> log.txt
echo '   requested_addresses' >> log.txt
cut -d " " -f2 parse_data.txt |sort |sed '/400/d' |uniq -c |sort -gr |head -n ${y_requested_addresses} 
echo '   return codes' >> log.txt
cut -d " " -f3 parse_data.txt |sort |sed '/^$/d' |sed '/-/d' |uniq -c |sort -gr >> log.txt
echo '   errors' >> log.txt
cut -d " " -f3 parse_data.txt |awk -F '.-' '$1 <= 599 && $1 >= 400' |sort |uniq -c| sort -gr >> log.txt

echo ${current_date} > last_date.txt
mail -s "log"  "${mail}" < log.txt
