#!/bin/bash

host=`hostname`
> emailreport.txt
> emailreport1.txt
> topsender_hour.txt
> topsender_6hour.txt
> top_mailnull
> hourly_lmit.txt
> spamassasin.txt
> top_sender_reject.txt


grep -A 100000000 "`date +%Y-%m-%d\ %H '-d -31 minutes'`"  /var/log/exim_mainlog | egrep -o '(dovecot_plain|dovecot_login)[^ ]+'  | sort|uniq -c | awk ' $1 > 200 {print $0}'|sort -h > topsender_hour.txt


grep -A 100000000 "`date +%Y-%m-%d\ %H '-d -300 minutes'`"  /var/log/exim_mainlog | egrep -o '(dovecot_plain|dovecot_login)[^ ]+'  | sort|uniq -c | awk ' $1 > 800 {print $0}'|sort -h > topsender_6hour.txt



grep -A 100000000 "`date +%Y-%m-%d\ %H '-d -31 minutes'`" /var/log/exim_mainlog | grep "U=mailnull" | egrep -o 'for [^ ]+' | awk '{print $2}' | sort | uniq -c | sort -n | awk '$1 > 30 {print $0}' > top_mailnull

grep -A 100000000 "`date +%Y-%m-%d\ %H '-d -300 minutes'`" /var/log/exim_mainlog | grep "U=mailnull" | egrep -o 'for [^ ]+' | awk '{print $2}' | sort | uniq -c | sort -n | awk '$1 > 200 {print $0}' > top_mailnull6



grep -A 100000000 "`date +%Y-%m-%d\ %H '-d -31 minutes'`" /var/log/exim_mainlog | grep "<=.*P=local"|grep 'U=' |grep -v U=mailnull|grep -E 'for\ [A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}' |grep -Eo 'U=[^ ]+' |sort -h | uniq -c | sort -n | awk '$1 > 130 {print $0}' >> topsender_hour.txt

grep -A 100000000 "`date +%Y-%m-%d\ %H '-d -300 minutes'`" /var/log/exim_mainlog | grep "<=.*P=local"|grep 'U=' |grep -v U=mailnull|grep -E 'for\ [A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}' |grep -Eo 'U=[^ ]+'|sort -h | uniq -c | sort -n | awk '$1 > 400 {print $0}' >> topsender_6hour.txt

grep -A 100000000 "`date +%Y-%m-%d\ %H '-d -31 minutes'`" /var/log/exim_mainlog | grep 'exceeded the max defers and failures per hour' | grep -Eo 'Domain [^ ]+' | sort| uniq -c > defer.txt


grep -A 100000000 "`date +%Y-%m-%d\ %H '-d -31 minutes'`" /var/log/exim_mainlog | grep "has exceeded the max emails per hour" | grep -Eo 'F=[^ ]+' | sort -h |uniq -c  > hourly_lmit.txt


#grep -A 100000000 "`date +%Y-%m-%d\ %H '-d -31 minutes'`"  /var/log/exim_mainlog | grep 'rejected after DATA'  | egrep -o '(dovecot_plain|dovecot_login)[^ ]+'  | sort|uniq -c | awk ' $1 > 2 {print $0}' > spamassasin.txt



#grep -A 100000000 "`date +%Y-%m-%d\ %H '-d -31 minutes'`"  /var/log/exim_mainlog | grep "for .*@.*"  | grep "<= <>" | awk -F"T=" '{print $2}' | awk '{print $NF,$0}' | awk -F" for" '{print $1}' | sort | uniq -c | sort -n |awk ' $1 > 20 {print $0}' > top_sender_reject.txt

grep -A 100000000 "`date +%Y-%m-%d\ %H '-d -31 minutes'`" /var/log/exim_mainlog | grep "<=.*P=local"|grep 'U=' |grep -v U=mailnull|grep -E 'for\ [A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}' |grep -Eo 'U=[^ ]+'|cut -d'=' -f2 |sort -h | uniq -c | sort -n | awk '$1 > 60 {print $0}'  > top_sender_reject.txt

for i in `cat /etc/outgoing_mail_suspended_users_filter` ; do

sed -i "/$i/d" top_sender_reject.txt

done




if [ -s topsender_hour.txt ] ; then


echo "Top senders in last 1 hour" > emailreport1.txt
echo >> emailreport1.txt
cat topsender_hour.txt >> emailreport1.txt

fi

if [ -s topsender_6hour.txt ] ; then
echo ""  >> emailreport1.txt

echo "Top senders in last 6 hours " >> emailreport1.txt

echo ""  >> emailreport1.txt

cat topsender_6hour.txt >> emailreport1.txt

fi


if [ -s top_mailnull1 ] ; then

echo "Top Mailnull messages ( probably bouce backs )" > emailreport.txt

cat top_mailnull1 >> emailreport.txt

fi

if [ -s defer.txt ] ; then
echo ""  >> emailreport1.txt

echo "Exceeded the max defers and failures in last 1 hour" > emailreport.txt

cat defer.txt >> emailreport.txt

fi

if [ -s hourly_lmit.txt ] ; then
echo ""  >> emailreport1.txt

echo "Domais has reached it's hourly limit in last 1 hour" > emailreport.txt

cat hourly_lmit.txt >> emailreport.txt

fi

if [ -s spamassasin.txt ] ; then
echo ""  >> emailreport1.txt

echo "Emails blocked in last our by ApacheSpamAssasin in last 1 hour" > emailreport.txt

cat spamassasin.txt >> emailreport.txt

fi


if [ -s top_sender_reject.txt ] ; then
echo ""  >> emailreport1.txt

echo "Emails rejected to the server in last 1 hour" > emailreport.txt

cat top_sender_reject.txt >> emailreport.txt

fi




if [ -s emailreport1.txt ] ; then

cat emailreport1.txt >> emailreport.txt

cat emailreport.txt | mail -E -s "Outbound report "$host"" abuse@supportdesk.com

fi
