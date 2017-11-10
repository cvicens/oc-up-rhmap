#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <local IP address>"
    exit 1
fi


IP_ADDRESS=$1
#CURRENT_DIR=$(pwd)
NEW_CERT_DIR=./proxy-certs/wildcard.apps.$IP_ADDRESS.nip.io

SERVER_CRT_DIR=../../nginx-ssl/certs
SERVER_KEY_DIR=../../nginx-ssl/private

mkdir $NEW_CERT_DIR
cd $NEW_CERT_DIR

cat << EOF > ./mycert.json
{
    "hosts": [
        "cloud.apps.$IP_ADDRESS.nip.io",
        "core.apps.$IP_ADDRESS.nip.io",
	"*.apps.$IP_ADDRESS.nip.io",
	"*.$IP_ADDRESS.nip.io"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "CN": "*.apps.$IP_ADDRESS.nip.io"
}
EOF


docker run --rm --link=cfssl -v $(pwd):/etc/cfssl --entrypoint=/bin/sh dhiltgen/cfssl -c 'cfssl gencert -remote $CFSSL_PORT_8888_TCP_ADDR -profile=server mycert.json' | docker run --rm -i -v $(pwd):/etc/cfssl --entrypoint cfssljson dhiltgen/cfssl -bare mycert

mkdir -p $SERVER_CRT_DIR
mkdir -p $SERVER_KEY_DIR

cp mycert.pem $SERVER_CRT_DIR/server.pem
cp mycert-key.pem $SERVER_KEY_DIR/server.key

#cd $CURRENT_DIR