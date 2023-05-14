#!/bin/bash
#!/bin/bash
#
# Project     : Apache Kakfka TLS support
# Author      : Thomas Pliakas (tpliakas@gmail.com)
# Filename    : create-certs.sh
# Description : This script cretes certificates for kafka brokers, producers and consumers.
#
# For debugging the script, uncomment the following line
# set -x
# Exit immediately on failure.
# set -e

# set -o nounset \
# 	-o errexit \
# 	-o verbose \
# 	-o xtrace

# *****************************************************************
# LOGGING COLOR VARIABLES
# *****************************************************************
Black='\033[1;30m'  # Black
Red='\033[1;31m'    # Red
Green='\033[1;32m'  # Green
Yellow='\033[1;33m' # Yellow
NC='\033[0m'

# *****************************************************************
# STATIC GLOBAL VARIABLES
# *****************************************************************
INFO_LOG_LEVEL=${Green}INFO${NC}
ERROR_LOG_LEVEL=${Red}ERROR${NC}
WARN_LOG_LEVEL=${Yellow}WARN${NC}

# *****************************************************************
# FUNCTIONS
# *****************************************************************
usage() {
	echo -e "${Green}Usage${NC}: $0 [-a <create/delete> kafka related certificates]" 1>&2
	exit 1
}

create_certificates() {

	echo -e "$(date +"%b-%d-%y, %H:%M:%S") - ${INFO_LOG_LEVEL}: Generate CA cert"
	openssl req -new -x509 \
		-keyout my-ca.key \
		-out my-ca.crt \
		-days 365 \
		-subj '/CN=ca1.test.perlss/OU=TEST/O=PERKSS/L=London/S=LDN/C=UK' \
		-passin pass:my-test-password \
		-passout pass:my-test-password

	for i in broker producer consumer; do

		echo -e "$(date +"%b-%d-%y, %H:%M:%S") - ${INFO_LOG_LEVEL}: Create keystore for $i"
		keytool -genkey -noprompt \
			-alias $i \
			-dname "CN=$i.perkss.test, OU=TEST, O=PERKSS, L=London, S=LDN, C=UK" \
			-keystore kafka.$i.keystore.jks \
			-keyalg RSA \
			-storepass my-test-password \
			-keypass my-test-password

		echo -e "$(date +"%b-%d-%y, %H:%M:%S") - ${INFO_LOG_LEVEL}: Create CSR, sign the key and import back into keystore"
		keytool -keystore kafka.$i.keystore.jks -alias $i -certreq -file $i.csr -storepass my-test-password -keypass my-test-password

		openssl x509 -req -CA my-ca.crt -CAkey my-ca.key -in $i.csr -out $i-ca1-signed.crt -days 9999 -CAcreateserial -passin pass:my-test-password
		keytool -keystore kafka.$i.keystore.jks -alias CARoot -import -file my-ca.crt -storepass my-test-password -keypass my-test-password
		keytool -keystore kafka.$i.keystore.jks -alias $i -import -file $i-ca1-signed.crt -storepass my-test-password -keypass my-test-password

		echo -e "$(date +"%b-%d-%y, %H:%M:%S") - ${INFO_LOG_LEVEL}: Create truststore and import the CA cert."
		keytool -keystore kafka.$i.truststore.jks -alias CARoot -import -file my-ca.crt -storepass my-test-password -keypass my-test-password

		echo "my-test-password" >${i}_sslkey_creds
		echo "my-test-password" >${i}_keystore_creds
		echo "my-test-password" >${i}_truststore_creds
	done
}

delete_certificates() {
	echo -e "$(date +"%b-%d-%y, %H:%M:%S") - ${INFO_LOG_LEVEL}: Deleting certificates for kafka brokers, producers and consumers"

	for i in broker producer consumer; do

		echo -e "$(date +"%b-%d-%y, %H:%M:%S") - ${INFO_LOG_LEVEL}: Delete alias for $i"
		keytool -delete -alias CARoot -v -keystore kafka.$i.keystore.jks -storepass my-test-password -keypass my-test-password
		keytool -delete -alias $i -v -keystore kafka.$i.keystore.jks -storepass my-test-password -keypass my-test-password
		keytool -delete -alias CARoot -v -keystore kafka.$i.truststore.jks -storepass my-test-password -keypass my-test-password
	done
}

# *****************************************************************
# MAIN
# *****************************************************************
while getopts v:d: flag; do
	case "${flag}" in
	v) action=${OPTARG} ;;
	*) usage ;;
	esac
done

if [ -z "${action}" ]; then
	echo -e "$(date +"%b-%d-%y, %H:%M:%S") - ${ERROR_LOG_LEVEL}: Action is missing."
	usage
fi

if [ $action == "create" ]; then
	echo -e "$(date +"%b-%d-%y, %H:%M:%S") - ${INFO_LOG_LEVEL}: Creating certificates for kafka brokers, producers and consumers"
	create_certificates
fi

if [ $action == "delete" ]; then
	echo -e "$(date +"%b-%d-%y, %H:%M:%S") - ${INFO_LOG_LEVEL}: Creating certificates for kafka brokers, producers and consumers"
	delete_certificates
fi
