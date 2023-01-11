#!/bin/bash

aliddnsipv6_ak="LTAIivEBYwXx8TEo"
aliddnsipv6_sk="27L11Eksy3JzdshZQMMss7C3KPUin1"
aliddnsipv6_name1='desk'
aliddnsipv6_domain='foxset.top'
aliddnsipv6_ttl="600"

if [ "$aliddnsipv6_name1" = "@" ]
then
  aliddnsipv6_name=$aliddnsipv6_domain
else
  aliddnsipv6_name=$aliddnsipv6_name1.$aliddnsipv6_domain
fi

now=`date`
die () {
    echo $1
}

#  从群晖网卡中获取ipv6地址的前4段
#ipv6s=`ip addr show eth0 | grep "inet6.*global" | awk '{print $2}' | awk -F"/" '{print $1}'  | cut -b 1-20`  || die "$ipv6"

#  从域名foxset.synology.me获取ipv6地址的前4段
ipv6s=`nslookup -query=AAAA foxset.synology.me | grep 'Address: ' | tail -n1 | awk '{print $NF}' | cut -b 1-20` || die "$ipv6" 

# 前4段与目标设备固定ipv6的后4段（“d1d7:3e3c:3354:de09”）进行拼接
ipv6s=$ipv6s"d1d7:3e3c:3354:de09"

# 输出ipv6s
echo $ipv6s

# 把ipv6s改名为ipv6
for ipv6 in $ipv6s 
do
  #ipv6 = $ipv6
  break
done

#echo $ipv6

#  获取原域名（desk.foxset.top）的ipv6地址
current_ipv6=`nslookup -query=AAAA $aliddnsipv6_name 2>&1`

#  截取并输出原域名ipv6地址
current_ipv6=`echo "$current_ipv6" | grep 'Address: ' | tail -n1 | awk '{print $NF}'`
echo $current_ipv6


if [ "$?" -eq "0" ]
then
    current_ipv6=`echo "$current_ipv6" | grep 'Address: ' | tail -n1 | awk '{print $NF}'`
    echo $current_ipv6

    if [ "$ipv6" = "$current_ipv6" ]
    then
        echo "skipping"
    fi 
# fix when A record removed by manual dns is always update error
else
    unset aliddnsipv6_record_id
fi

timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`

urlencode() {
    # urlencode <string>
    out=""
    while read -n1 c
    do
        case $c in
            [a-zA-Z0-9._-]) out="$out$c" ;;
            *) out="$out`printf '%%%02X' "'$c"`" ;;
        esac
    done
    echo -n $out
}

enc() {
    echo -n "$1" | urlencode
}

send_request() {
    local args="AccessKeyId=$aliddnsipv6_ak&Action=$1&Format=json&$2&Version=2015-01-09"
    local hash=$(echo -n "GET&%2F&$(enc "$args")" | openssl dgst -sha1 -hmac "$aliddnsipv6_sk&" -binary | openssl base64)
    curl -s "http://alidns.aliyuncs.com/?$args&Signature=$(enc "$hash")"
}

get_recordid() {
    grep -Eo '"RecordId":"[0-9]+"' | cut -d':' -f2 | tr -d '"'
}

query_recordid() {
    send_request "DescribeSubDomainRecords" "SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&SubDomain=$aliddnsipv6_name&Timestamp=$timestamp&Type=AAAA"
}

update_record() {
    send_request "UpdateDomainRecord" "RR=$aliddnsipv6_name1&RecordId=$1&SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&TTL=$aliddnsipv6_ttl&Timestamp=$timestamp&Type=AAAA&Value=$(enc $ipv6)"
}


#add support */%2A and @/%40 record


if [ "$aliddnsipv6_record_id" = "" ]
then
    aliddnsipv6_record_id=`query_recordid | get_recordid`
    #echo '-----------------' $aliddnsipv6_record_id
fi
if [ "$aliddnsipv6_record_id" = "" ]
then
    aliddnsipv6_record_id=`add_record | get_recordid`
    echo "added record $aliddnsipv6_record_id"
else
    update_record $aliddnsipv6_record_id
    echo "updated record $aliddnsipv6_record_id"
fi

# sendEmail  -xu 20068032@qq.com -xp lptquobujklubiid -s smtp.qq.com:25  -f 20068032@qq.com -t foxset@139.com -o message-charset=utf8 -u "电脑已开机!" -m "电脑已开机!" 

