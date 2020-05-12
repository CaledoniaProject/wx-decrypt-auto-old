#!/bin/bash

set -e
output=tmp

croak()
{
    echo $@
    exit 1
}

adb devices

device=emulator-5556
while true
do
    read -p "[+] Pick a target device (e.g emulator-5556): " device
    if ! [[ -z "$device" ]]; then
        break
    fi
done

# IMEI
imei=$(adb -s "$device" shell dumpsys iphonesubinfo | grep 'Device ID' | sed 's/.*=\s*//; s/[\r\n]//g')
if [[ ${#imei} != 15 ]]; then
    croak "IMEI $imei should be 15 digits in length"
else
    echo IMEI $imei
fi

# UIN
uin=$(adb -s "$device" shell cat /data/data/com.tencent.mm/shared_prefs/system_config_prefs.xml | grep default_uin | perl -lne 'print $1 if /value="([^"]+)/')
if [[ ${#uin} < 5 ]]; then
    croak "UIN $uin should be more than 5 digits in length"
else
    echo UIN $uin
fi

pass=$(echo -n $imei$uin | md5sum | cut -c -7)
echo PASS $pass

rm -rf "$output"

adb -s "$device" shell ls /data/data/com.tencent.mm/MicroMsg/*/EnMicroMsg.db | while read file
do
    echo EnMicroMsg $file

    file=$(echo $file | tr -d '\n\r')
    dir="$output/$(dirname $file | sed 's#.*/##')"

    mkdir -p "$dir"
    adb -s "$device" pull $file "$dir"/EnMicroMsg.db

    cat>"$dir"/run.sql<<EOF
PRAGMA key='$pass';
PRAGMA cipher_use_hmac = off;
ATTACH DATABASE "decrypted_database.db" AS decrypted_database KEY "";
SELECT sqlcipher_export("decrypted_database");
DETACH DATABASE decrypted_database;
EOF

    (
        cd "$dir" 
        sqlcipher21 EnMicroMsg.db < run.sql 
        num_msg=$(sqlite3 decrypted_database.db "select count(*) from message limit 10")
        echo Number of message extracted $num_msg

        echo First 10 messages are:
        sqlite3 decrypted_database.db "select talker, content from message limit 10"
    )

done


