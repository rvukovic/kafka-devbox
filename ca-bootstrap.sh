#!/usr/bin/env bash

if [ ! -f /var/log/updated ];
then
    sudo touch /var/log/updated
    yaourt -Syua --noconfirm
fi

if [ ! -f /var/log/firsttime ];
then
    sudo touch /var/log/firsttime

    # Install java, openssl, and emacs (in case you want to ssh and edit files)
    yaourt -S jre8-openjdk-headless jdk8-openjdk openssl --noconfirm

    # Create the directory structure for the root CA
    mkdir -p /root/ca
    cd /root/ca
    mkdir certs crl newcerts private
    chmod 700 private
    touch index.txt
    echo 1000 > serial

    # Copy our root CA config file from the shared dir
    cp /vagrant/vagrant-bootstrap/ca/openssl.conf /root/ca/openssl.cnf

    # Create the root key
    ## We will never use pass:[password] anywhere other than a devbox
    openssl genrsa -aes256 -passout pass:test1234 \
            -out private/ca.key.pem 4096

    chmod 400 private/ca.key.pem

    # Create the root certificate
    openssl req -config openssl.cnf -key private/ca.key.pem -new -x509 \
            -days 7300 -sha256 -extensions v3_ca -out certs/ca.cert.pem \
            -passout pass:test1234 -passin pass:test1234 -batch

    chmod 444 certs/ca.cert.pem

    # Create directory structure for intermediate CA
    mkdir /root/ca/intermediate
    cd /root/ca/intermediate
    mkdir certs crl csr newcerts private
    chmod 700 private
    touch index.txt
    echo 1000 > serial
    echo 1000 > /root/ca/intermediate/crlnumber

    # Copy our config for the intermediate CA
    cp /vagrant/vagrant-bootstrap/ca/intermediate-openssl.conf /root/ca/intermediate/openssl.cnf

    cd /root/ca

    # Create the intermediate key
    ## Once again, we won't be cowboying it like this anywhere but here...
    openssl genrsa -aes256 -passout pass:test1234\
            -out intermediate/private/intermediate.key.pem 4096

    chmod 400 intermediate/private/intermediate.key.pem

    # Create intermediate certificate
    openssl req -config intermediate/openssl.cnf -new -sha256 \
            -key intermediate/private/intermediate.key.pem \
            -out intermediate/csr/intermediate.csr.pem \
            -passout pass:test1234 -passin pass:test1234 -batch

    openssl ca -config openssl.cnf -extensions v3_intermediate_ca \
            -days 3650 -notext -md sha256 -in intermediate/csr/intermediate.csr.pem \
            -out intermediate/certs/intermediate.cert.pem -passin pass:test1234 \
            -batch

    chmod 444 intermediate/certs/intermediate.cert.pem

    # Create the certificate chain file
    cat intermediate/certs/intermediate.cert.pem certs/ca.cert.pem > intermediate/certs/ca-chain.cert.pem

    chmod 444 intermediate/certs/ca-chain.cert.pem

    # Setup dir for kafka keystores and certs
    mkdir -p /var/private/ssl
    KAFKA_KEYSTORE=/var/private/ssl

    # Create server keystore
    keytool -keystore $KAFKA_KEYSTORE/kafka.server.keystore.jks -alias localhost \
            -validity 365 -genkey -dname "CN=localhost, OU=Venicegeo-KS, C=US, ST=Virginia, L=Chantilly, O=Radiant Blue" \
            -storepass test1234 -keypass test1234 -noprompt
    echo "Server keystore created"

    # Create client keystore (since we will require client auth)
    keytool -keystore $KAFKA_KEYSTORE/kafka.client.keystore.jks -alias localhost \
            -validity 365 -genkey -dname "CN=localhost, OU=Venicegeo-KC, C=US, ST=Virginia, L=Chantilly, O=Radiant Blue" \
            -storepass test1234 -keypass test1234 -noprompt
    echo "Client keystore created"

    # Import the intermediate CA certificate into the server truststore
    keytool -keystore $KAFKA_KEYSTORE/kafka.server.truststore.jks -alias CAInt \
            -import -file intermediate/certs/intermediate.cert.pem -storepass test1234 \
            -keypass test1234 -noprompt
    echo "Intermediate cert added to server truststore"

    # Import the intermediate CA certificate into the client truststore
    keytool -keystore $KAFKA_KEYSTORE/kafka.client.truststore.jks -alias CAInt \
            -import -file intermediate/certs/intermediate.cert.pem -storepass test1234 \
            -keypass test1234 -noprompt
    echo "Intermediate cert added to client truststore"

    # Create a certificate signing request (CSR) using the server private key
    keytool -keystore $KAFKA_KEYSTORE/kafka.server.keystore.jks -alias localhost \
            -certreq -file $KAFKA_KEYSTORE/certreq-file -storepass test1234 -noprompt
    echo "CSR file created"

    # Create and sign the server certificate using the intermediate CA
    openssl x509 -req -CA intermediate/certs/intermediate.cert.pem \
            -CAkey intermediate/private/intermediate.key.pem -CAserial serial \
            -in $KAFKA_KEYSTORE/certreq-file -out $KAFKA_KEYSTORE/cert-signed \
            -days 365 -passin pass:test1234 -addtrust serverAuth -outform der
    echo "Server cert signed by intermediate CA"

    # Add the intermediate CA certificate to the server keystore
    keytool -keystore $KAFKA_KEYSTORE/kafka.server.keystore.jks -alias CAInt \
            -import -file certs/ca.cert.pem \
            -storepass test1234 -noprompt
    echo "Root CA cert added to server keystore"

    # Add the intermediate CA certificate to the server keystore
    keytool -keystore $KAFKA_KEYSTORE/kafka.server.keystore.jks -alias CARoot \
            -import -file intermediate/certs/intermediate.cert.pem \
            -storepass test1234 -noprompt
    echo "Intermediate cert added to server keystore"

    # Add the signed server certificate to the server keystore
    keytool -keystore $KAFKA_KEYSTORE/kafka.server.keystore.jks -alias localhost \
            -import -file $KAFKA_KEYSTORE/cert-signed -storepass test1234 -noprompt
    echo "Signed server cert added to server keystore"

    # Remove previously created key and truststores from our shared dir
    rm -rf /vagrant/kafka-keystores

    # Create server and client dirs in shared dir
    mkdir -p /vagrant/kafka-keystores/server /vagrant/kafka-keystores/client

    # Copy the key and trust stores to the proper shared dir
    cp $KAFKA_KEYSTORE/kafka.client.keystore.jks /vagrant/kafka-keystores/client/
    cp $KAFKA_KEYSTORE/kafka.client.truststore.jks /vagrant/kafka-keystores/client/
    cp $KAFKA_KEYSTORE/kafka.server.keystore.jks /vagrant/kafka-keystores/server/
    cp $KAFKA_KEYSTORE/kafka.server.truststore.jks /vagrant/kafka-keystores/server/

    # fin
fi
