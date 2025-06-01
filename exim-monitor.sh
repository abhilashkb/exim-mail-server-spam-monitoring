#!/bin/bash
############################
#SPAM suspender 1.0        #
############################
 ##
ldate=`date +'%Y-%m-%d'\ %H:%M`
host=`hostname`

[ -f /pickascript/spam_whitelist ] || touch /pickascript/spam_whitelist
> /pickascript/tosuspend_cache


contactemail ()
{

tolock=$1

if echo $tolock | grep "`hostname`" > /dev/null ; then
acc_tolock=`echo $tolock| cut -d'@' -f1`
else
sdomain=`echo $tolock| cut -d'@' -f2`
acc_tolock=`/scripts/whoowns $sdomain`
fi

 if cat /var/cpanel/users/$acc_tolock | grep 'OWNER=root' > /dev/null ; then

 cont_email=`cat /var/cpanel/users/$acc_tolock |grep CONTACTEMAIL= |cut -d'=' -f2`


else

 owner=`cat /var/cpanel/users/$acc_tolock | grep 'OWNER='|cut -d'=' -f2`
 cont_email=`cat /var/cpanel/users/$owner |grep CONTACTEMAIL= |cut -d'=' -f2`

fi


}

toaddfilter ()

{


if ! grep $1 /pickascript/spam_whitelist ; then

acc_tolock=$1
reason_t=$2
ldate=`date +'%Y-%m-%d'\ %H:%M`
fwdmsgt=$3
echo $fwdmsgt value
echo foward check
if [ $fwdmsgt -eq 1 ] ; then

fwdmsg="Forwarded messages rejected and forwarder suspended"
echo $fwdmsg
if echo  $acc_tolock | egrep '[A-Za-z0-9.-]+\.[A-Za-z]{2,4}' > /dev/null ; then

sdomain=`echo $acc_tolock | cut -d'@' -f2`

extn=`date +'%Y-%m-%d%H%M'`

cp /etc/valiases/$sdomain /etc/valiases/$sdomain."$extn"


! grep "#$acc_tolock" /etc/valiases/$sdomain && sed -i "s/$acc_tolock:/\#$acc_tolock:/1" /etc/valiases/$sdomain 

fi

else

fwdmsg=""

fi



if [ $fwdmsgt -eq 1 ] ; then

grep $acc_tolock /pickascript/hourly_cache || (  echo $acc_tolock >> /pickascript/hourly_cache && echo $ldate $acc_tolock $reason  $fwdmsg "/home/$suser/.suspendinfo/`date +%Y%m%d%H`.txt" >> /var/log/spamsuspend/sa_suspended.log )


else

grep $acc_tolock /pickascript/hourly_cache || ( ! grep $acc_tolock /etc/outgoing_mail_suspended_users_filter && echo $acc_tolock >> /etc/outgoing_mail_suspended_users_filter && echo $acc_tolock >> /pickascript/hourly_cache && echo $ldate $acc_tolock $reason  $fwdmsg "/home/$suser/.suspendinfo/`date +%Y%m%d%H`.txt" >> /var/log/spamsuspend/sa_suspended.log && email=1 )

! grep $acc_tolock /pickascript/hourly_cache && ! echo $reason_t | grep reason_c  && ( grep $acc_tolock /etc/outgoing_mail_suspended_users_filter && echo $ldate $acc_tolock cant block for "$reason"  >> /var/log/spamsuspend/sa_suspended.log && echo $acc_tolock >> /pickascript/hourly_cache && cb=1 )

if [ $cb -eq 1 ] ; then

       sdomain=`echo $acc_tolock | cut -d'@' -f2`
        euser=`echo $acc_tolock | cut -d'@' -f1`
        if /scripts/whoowns $sdomain > /dev/null; then

                  suser=`/scripts/whoowns $sdomain`
       		 cpapi2 --user=$suser Email passwdpop domain=$sdomain email=$acc_tolock password=123A5cB7zZ7zZ

         fi
fi
fi
fi


}


suspendinfo ()
{
suser=$1
acc_tolock=$2
type=$3
domain=`echo $acc_tolock | cut -d'@' -f2`

if [[ $type == 'e' ]] ; then

deferid=`grep "`date +%Y-%m-%d\ %H`" /var/log/exim_mainlog | grep $domain |grep 'exceeded the max defers and failures per hour' | awk '{print $3}' |head -1`

grep "`date +%Y-%m-%d`" /var/log/exim_mainlog | exigrep $domain |grep -B1000 $deferid > /home/$suser/.suspendinfo/`date +%Y%m%d%H`.txt

 exim -bpru|grep $acc_tolock|awk {'print $3'}|xargs exim -Mrm

else

 mkdir /home/$suser/.suspendinfo/
 grep -A 100000000 "`date +%Y-%m-%d\ %H`"  /var/log/exim_mainlog |exigrep $acc_tolock > /home/$suser/.suspendinfo/`date +%Y%m%d%H`.txt
 exim -bpru|grep $acc_tolock|awk {'print $3'}|xargs exim -Mrm
fi

}


if ! [ -d "/var/log/spamsuspend" ]; then
  mkdir /var/log/spamsuspend
fi

grep -A 100000000 "`date +%Y-%m-%d\ %H '-d -31 minutes'`"  /var/log/exim_mainlog |grep cpanel@spitfire.pickaweb.co.uk | awk '{print $3}' | sort -h|uniq > cpanelemail

grep -A 100000000 "`date +%Y-%m-%d\ %H '-d -31 minutes'`"  /var/log/exim_mainlog | grep 'has an outgoing mail suspension' |grep -E '([A-Za-z0-9]{6}\-){2}[A-Za-z0-9]{2}' | sort |uniq | awk '{print $3,"a"}' > outgoingsuspension



grep -A 100000000 "`date +%Y-%m-%d\ %H '-d -1 minutes'`"  /var/log/exim_mainlog | grep 'rejected after DATA'  | egrep -o '(dovecot_plain|dovecot_login)[^ ]+'  |grep -Eo 'U=[A-Za-z0-9]+|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}'| sort|uniq -c | awk ' $1 > 2 {print $2,"c"}'|cut -d':' -f2 > acctolock.txt

grep -A 100000000 "`date +%Y-%m-%d\ %H '-d -1 minutes'`" /var/log/exim_mainlog |grep 'rejected by non-SMTP ACL'|grep 'detected OUTGOING not smtp message as spam' | grep -E 'F=<[^ ]+>' | grep -Eo '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}' | sort -h | uniq -c | sort -h | awk ' $1 > 5 {print $2,"c"}' > notsmtp.txt

#grep -A 100000000 "`date +%Y-%m-%d\ %H '-d -1 minutes'`" /var/log/exim_mainlog | grep 'exceeded the max defers and failures per hour' | awk '{print $3,"e"}' | sort -h | uniq > defered_accounts.txt

grep -A 100000000 "`date +%Y-%m-%d\ %H '-d -1 minutes'`" /var/log/exim_mainlog |  grep "has exceeded the max emails per hour"  | awk '{print $3,"f"}' | sort -h | uniq > limit_accounts.txt

#Spam bounce

grep -A 100000000 "`date +%Y-%m-%d\ %H '-d -31 minutes'`"  /var/log/exim_mainlog | grep 'temporarily deferred due to user complaints'  |awk '{print $3,"k"}' |sort -h |uniq > yahooblock


grep  -A 100000000 "`date +%Y-%m-%d\ %H '-d -1 minutes'`" /var/log/exim_mainlog |  egrep 'Gmail has detected that this message is likely|n421-4.7.0 To best protect our users from spam, the message has been blocked'|awk '{print $3,"g"}' |sort -h |uniq > googleblock


grep  -A 100000000 "`date +%Y-%m-%d\ %H '-d -1 minutes'`" /var/log/exim_mainlog | grep 'Message not accepted for policy reasons'|awk '{print $3,"i"}' |sort -h |uniq > yahoorjct


grep  -A 100000000 "`date +%Y-%m-%d\ %H '-d -1 minutes'`" /var/log/exim_mainlog | grep 'Email detected as Spam by spam filters|This message was blocked because its content presents a potential' |awk '{print $3,"h"}' |sort -h |uniq > googlecont


grep  -A 100000000 "`date +%Y-%m-%d\ %H '-d -1 minutes'`" /var/log/exim_mainlog | egrep 'Your message looks like SPAM or has been reported as SPAM|Message contains spam or virus or sender is blocked|Message content rejected due to suspected spam|Message blocked due to spam content in the message|Message rejected because of unacceptable content|Refused by local policy. No SPAM please|Message rejected due to local policy|message has been rejected due to content judged to be spam by the internet community|Message rejected due to possible spam content|message has been rejected due to suspected spam' |awk '{print $3,"j"}' |sort -h |uniq > spammsg



for d in `cat /pickascript/hourly_cache` ; do
 sed -i "/$d/d" outgoingsuspension
 sed -i "/$d/d" defered_accounts.txt
 sed -i "/$d/d" limit_accounts.txt
 sed -i "/$d/d" suspendcpanel.txt
 sed -i "/$d/d" acctolock.txt
 sed -i "/$d/d" yahooblock
 sed -i "/$d/d" notsmtp.txt
 sed -i "/$d/d" yahoorjct
 sed -i "/$d/d" googleblock
 sed -i "/$d/d" googlecont

done


cat outgoingsuspension > /pickascript/toblock
cat defered_accounts.txt >> /pickascript/toblock
cat limit_accounts.txt >> /pickascript/toblock
cat suspendcpanel.txt >> /pickascript/toblock
cat acctolock.txt >> /pickascript/toblock
cat yahooblock >> /pickascript/toblock
cat notsmtp.txt >> /pickascript/toblock
cat googleblock >> /pickascript/toblock
cat yahoorjct >> /pickascript/toblock
cat googlecont >> /pickascript/toblock
#

for c in `cat cpanelemail` ; do

sed -i "/$c/d" /pickascript/toblock

done

while read k ; do

type=`echo $k |awk '{print $2}'`
i=`echo $k |awk '{print $1}'`
reason_t=reason_$type
reason=`echo ${!reason_t}`

if echo $i |grep -E '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}' > /dev/null ; then
    
    acc_tolock=$i
    sdomain=`echo $acc_tolock | cut -d'@' -f2`
    suser=`echo $acc_tolock | cut -d'@' -f1`

	if echo $i | grep $host > /dev/null ; then
		toaddfilter $acc_tolock $reason_t $ldate 
         
		suspendinfo $suser $acc_tolock	
		#CAN suspend here

	elif /scripts/whoowns $sdomain > /dev/null; then

        	suser=`/scripts/whoowns $sdomain`

#               cpapi2 --user=$suser Email passwdpop domain=$sdomain email=$acc_tolock password=123A5cB7zZ7zZ

	        toaddfilter $acc_tolock $reason_t 

	       	suspendinfo $suser $acc_tolock

	fi
	

elif echo $i |grep -E '([A-Za-z0-9]{6}\-){2}[A-Za-z0-9]{2}' > /dev/null ; then
        fwd=0
	fwdmsg=0
	if  cat /var/log/exim_mainlog|grep $i | grep 'E=' |grep -v 'SIZE=' |grep -Eo 'O=.*\ E=[^ ]+' > /dev/null ; then

		fwdmsg=1
		 fwd=1
                echo $fwd fwd check
		 tolock=`cat /var/log/exim_mainlog | grep $i| grep -Eo 'O=.*\ E=[^ ]+' |grep -Eo 'O=[^ ]+'|head -1`

	else

		 tolock=`cat /var/log/exim_mainlog | grep $i| grep -oE 'U=[A-Za-z0-9]+|(_login:|_plain:)[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}'|head -1`

	fi
	echo $tolock acct to lock

     if echo $tolock | grep U= > /dev/null ; then

	acc_tolock=`echo $tolock | cut -d'=' -f2`@$host
	suser=`echo $tolock | cut -d'=' -f2`
        if ! echo $acc_tolock | grep -iw root > /dev/null && ! cat hourly_cache | grep -iw $acc_tolock > /dev/null; then

            if echo $reason_t | grep -E '[g-l]' ; then

		    if grep $acc_tolock /pickascript/tosuspend_cache && [[ `grep $acc_tolock /pickascript/tosuspend_cache | awk '{print $1}' |wc -l` -gt 2 ]] ; then
			
   	             toaddfilter $acc_tolock $reason_t $fwd

        	        suspendinfo $suser $acc_tolock $fwd

	            else

        	        echo $acc_tolock $reason_t >> /pickascript/tosuspend_cache
          
 	            fi

	   else
	          toaddfilter $acc_tolock $reason_t $fwd

                suspendinfo $suser $acc_tolock $fwdmsg



	   fi

	fi

     elif echo $tolock | grep -E '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}|O=' > /dev/null ; then

        acc_tolock=`echo $tolock | grep -Eo '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}'`

	echo $acc_tolock 
        sdomain=`echo $acc_tolock | cut -d'@' -f2`
	echo $sdomain
        if /scripts/whoowns $sdomain > /dev/null; then

        	suser=`/scripts/whoowns $sdomain`

	   if echo $reason_t | grep -E '[g-l]' ; then

                    if grep $acc_tolock /pickascript/tosuspend_cache && [[ `grep $acc_tolock /pickascript/tosuspend_cache | awk '{print $1}' |wc -l` -gt 2 ]] ; then

                     toaddfilter $acc_tolock $reason_t $fwd

                        suspendinfo $suser $acc_tolock $fwd

                    else

                        echo $acc_tolock $reason_t >> /pickascript/tosuspend_cache

                    fi

           else
               if echo $acc_tolock | grep $host > /dev/null ; then
                 
		suser=`echo $tolock | cut -d'=' -f2`

		fi
                  toaddfilter $acc_tolock $reason_t $fwd

                suspendinfo $suser $acc_tolock $fwd



           fi


	elif ! cat /etc/outgoing_mail_suspended_users_filter | grep -iw $acc_tolock > /dev/null ; then
		
          	  ! grep $acc_tolock /etc/outgoing_mail_suspended_users_filter && echo $acc_tolock >> /etc/outgoing_mail_suspended_users_filter
                  echo $ldate $acc_tolock $reason  >> /var/log/spamsuspend/sa_suspended.log
	fi


     fi

elif echo $i | grep U= > /dev/null ; then
	tolock=$i
        acc_tolock=`echo $tolock | cut -d'=' -f2`@$host
	suser=`echo $tolock | cut -d'=' -f2`
        if ! echo $acc_tolock | grep -iw root > /dev/null && ! cat hourly_cache | grep -iw $acc_tolock > /dev/null; then
                echo $acc_tolock >> hourly_cache
                echo $acc_tolock@$host

        if echo $reason_t | grep -E '[g-l]' ; then

                    if grep $acc_tolock /pickascript/tosuspend_cache && [[ `grep $acc_tolock /pickascript/tosuspend_cache | awk '{print $1}' |wc -l` -gt 2 ]] ; then

                     toaddfilter $acc_tolock $reason_t $fwd

                        suspendinfo $suser $acc_tolock $fwd

                    else

                        echo $acc_tolock $reason_t >> /pickascript/tosuspend_cache

                    fi

           else
                  toaddfilter $acc_tolock $reason_t $fwd

                suspendinfo $suser $acc_tolock $fwd



           fi




        fi

fi

done  < /pickascript/toblock


cat outgoingsuspension |awk '{print $1}' >> /pickascript/hourly_cache
cat defered_accounts.txt |awk '{print $1}' >> /pickascript/hourly_cache
cat limit_accounts.txt |awk '{print $1}' >> /pickascript/hourly_cache
cat suspendcpanel.txt |awk '{print $1}' >> /pickascript/hourly_cache
cat acctolock.txt |awk '{print $1}' >> /pickascript/hourly_cache
cat yahooblock |awk '{print $1}' >> /pickascript/hourly_cache
cat notsmtp.txt |awk '{print $1}' >> /pickascript/hourly_cache
cat yahoorjct |awk '{print $1}' >> /pickascript/hourly_cache
cat googleblock |awk '{print $1}' >> /pickascript/hourly_cache
cat googlecont |awk '{print $1}' >> /pickascript/hourly_cache
