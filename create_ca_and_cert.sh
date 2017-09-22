#! /bin/sh
mkdir ca
cd ca/
export CA_NAME="TestCA"
export CERT_AN1="Node1"
export CERT_AN2="Node2"
export CERT_AN3="Node3"
export CERT_COUNTRY="DE"
export CERT_STATE="RLP"
export CERT_LOCATION="MZ"
export CERT_ORGANISATION="EVOILA"
export CERT_CN="loadbalancer"
echo "[ ca ]
default_ca = $CA_NAME

[ $CA_NAME ]
certificate = ./cacert.pem
database = ./index.txt
new_certs_dir = ./certs
private_key = ./private/cakey.pem
serial = ./serial

default_crl_days = 7
default_days = 3650
default_md = sha256

policy = "$CA_NAME"_policy
x509_extensions = certificate_extensions

[ "$CA_NAME"_policy ]
commonName = supplied
stateOrProvinceName = optional
countryName = optional
emailAddress = optional
organizationName = optional
organizationalUnitName = optional
domainComponent = optional

[ certificate_extensions ]
basicConstraints = CA:false

[ req ]
default_bits = 2048
default_keyfile = ./private/cakey.pem
default_md = sha256
prompt = yes
distinguished_name = root_ca_distinguished_name
x509_extensions = root_ca_extensions

[ root_ca_distinguished_name ]
commonName = hostname

[ root_ca_extensions ]
basicConstraints = CA:true
keyUsage = keyCertSign, cRLSign

[ alt_names ]
DNS.1 = $CERT_CN
DNS.2 = $CERT_AN1
DNS.3 = $CERT_AN2
DNS.4 = $CERT_AN3


[ server_ca_extensions ]
basicConstraints = CA:false
keyUsage = keyEncipherment
extendedKeyUsage = 1.3.6.1.5.5.7.3.1
subjectAltName = @alt_names" >> openssl.cnf
mkdir certs private
chmod 700 private/
echo 01 > serial
touch index.txt
openssl req -x509 -config openssl.cnf -newkey rsa:2048 -days 3650 -out cacert.pem -outform PEM -subj /CN=testca/ -nodes
cd ..
mkdir server
cd server
echo "[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no
[req_distinguished_name]
C = $CERT_COUNTRY
ST = $CERT_STATE
L = $CERT_LOCATION
O = $CERT_ORGANISATION
CN = $CERT_CN
[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = $CERT_CN
DNS.2 = $CERT_AN1
DNS.3 = $CERT_AN2
DNS.4 = $CERT_AN3" >> req.conf
openssl genrsa -out key.pem 2048
openssl req -new -key key.pem -out req.pem -config req.conf
cd ..
cd ca/
openssl ca -config openssl.cnf -in ../server/req.pem -out ../server/cert.pem -notext -batch -extensions server_ca_extensions
