#! /bin/bash
#tento skript vytvara infrastrukturi PKI

source /root/setup_crt.cfg

if [ -z $rsa_path ]
then
    echo "Path to RSA is uknown" >&2
    exit 1
fi

if [ ! -d $rsa_path ]
then
    echo "Path to RSA is wrong" >&2
    exit 1
fi

cd $rsa_path
vars="$rsa_path"vars

#nastavenie velkosti kluca
sed -i "s/export KEY_SIZE=1024/export KEY_SIZE="$key_size"/" "$vars"
sed -i 's/export KEY_COUNTRY="US"/export KEY_COUNTRY=\"'"$key_country"'\"/' "$vars"
sed -i 's/export KEY_PROVINCE="CA"/export KEY_PROVINCE=\"'"$key_province"'\"/' "$vars"
sed -i 's/export KEY_CITY="SanFrancisco"/export KEY_CITY=\"'"$key_city"'\"/' "$vars"
sed -i 's/export KEY_ORG="Fort-Funston"/export KEY_ORG=\"'"$key_org"'\"/' "$vars"
sed -i 's/export KEY_EMAIL="mail@host.domain"/export KEY_EMAIL=\"'"$key_email"'\"/' "$vars"
sed -i 's/export KEY_EMAIL="me@host.mydomain"/export KEY_EMAIL=\"'"$key_email2"'\"/' "$vars"

#v novsich verziach som sa stretol s problemom, subor vars mal nefunkcne zlinkovany
#subor openssl.cnf

#sed -i 's/export KEY_CONFIG=`$EASY_RSA//whichopensslcnf $EASY_RSA`/export KEY_CONFIG='"$rsa_path"'openssl-1.0.0.cnf/' "$vars"

#vytvorenie PKI
source "$vars"
./clean-all

#dalej nasleduje krok ./build-ca, napisem ho rucne a vynecham interaktivny rezim
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" --initca $*  #tu bol vynechany prepinac --interact

#dalsi krok je spustit ./build-key-server nazov
#zase to spravim ako v predchadzajucom kroku, teda napisem rucne a vynecham interaktivny rezim
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" --server "$server_name"
