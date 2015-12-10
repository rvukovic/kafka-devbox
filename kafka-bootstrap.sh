#!/usr/bin/env bash

if [ ! -f /var/log/updated ];
then
    sudo touch /var/log/updated
    yaourt -Syua --noconfirm
fi

if [ ! -f /var/log/firsttime ];
then
    sudo touch /var/log/firsttime

    # Install java
    yaourt -S jre8-openjdk-headless --noconfirm

    KAFKA_VER=0.9.0.0
    SCALA_VER=2.10
    PKG_VER=${SCALA_VER}-${KAFKA_VER}
    PKG_NAME=kafka_${PKG_VER}
    APP_HOME=/usr/share/kafka
    KAFKA_SHARE=/vagrant/vagrant-bootstrap/kafka

    mkdir -p -m 755 /etc/kafka
    mkdir -p -m 755 /usr/share/java/kafka
    mkdir -p /usr/share/kafka/{bin,config,libs,logs}

    wget http://www.eu.apache.org/dist/kafka/${KAFKA_VER}/${PKG_NAME}.tgz \
         -O /usr/share/${PKG_NAME}.tgz -q

    cd /usr/share && tar -xzvf ${PKG_NAME}.tgz
    cd /usr/share/${PKG_NAME}

    install -d ${APP_HOME}/bin /usr/bin /usr/share/java/kafka
    cp -r config/* /etc/kafka/
    cp -f ${KAFKA_SHARE}/server.properties /etc/kafka/
    ln -s /etc/kafka ${APP_HOME}/config
    cp -r bin/kafka-* ${APP_HOME}/bin/
    rm -rf ${APP_HOME}/bin/windows
    sed -i "s|\$(dirname \$0)|${APP_HOME}/bin|" ${APP_HOME}/bin/*
    for b in ${APP_HOME}/bin/*; do
        bname=$(basename $b)
        ln -s ${APP_HOME}/bin/${bname} /usr/bin/${bname}
    done

    cp -r libs/* /usr/share/java/kafka
    ln -s /usr/share/java/kafka ${APP_HOME}/libs
    ln -s /var/log/kafka ${APP_HOME}/logs

    install -D -m 644 ${KAFKA_SHARE}/systemd_kafka.service \
            /usr/lib/systemd/system/kafka.service

    install -D -m 644 ${KAFKA_SHARE}/systemd_sysusers.d_kafka.conf \
            /usr/lib/sysusers.d/kafka.conf

    install -D -m 644 ${KAFKA_SHARE}/systemd_tmpfiles.d_kafka.conf \
            /usr/lib/tmpfiles.d/kafka.conf

    chmod -R --preserve-root 0755 /usr/share/java
    chmod -R --preserve-root 0755 /etc/kafka

    systemd-sysusers kafka.conf
    systemd-tmpfiles --create kafka.conf

    mkdir -p /var/log/kafka
    chown --preserve-root kafka:log /var/log/kafka
    chmod -R --preserve-root 0777 /var/log/kafka

    rm /usr/share/${PKG_NAME}.tgz

    # Copy the key and trust stores into the correct directories

    mkdir -p /var/private/ssl
    cp /vagrant/kafka-keystores/server/* /var/private/ssl/
    chmod -R --preserve-root 0755 /var/private

    # Tell systemd to enable and start the kafka service
    systemctl enable kafka.service
    systemctl start kafka.service


fi
