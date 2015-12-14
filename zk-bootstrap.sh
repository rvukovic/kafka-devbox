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

    ZK_VER=3.4.7
    PKG_NAME=zookeeper-${ZK_VER}
    APP_HOME=/usr/share/zookeeper
    ZK_SHARE=/vagrant/vagrant-bootstrap/zk

    mkdir -p -m 755 /etc/zookeeper
    mkdir -p -m 755 /usr/share/java/zookeeper
    mkdir -p /usr/share/zookeeper/{bin,conf,lib}

    wget http://www.us.apache.org/dist/zookeeper/${PKG_NAME}/${PKG_NAME}.tar.gz \
         -O /usr/share/${PKG_NAME}.tar.gz -q

    cd /usr/share && tar -xzvf ${PKG_NAME}.tar.gz
    cd /usr/share/${PKG_NAME}

    install -d ${APP_HOME}/bin /etc /usr/bin /usr/share/{doc,java}

    cp -r conf/* /etc/zookeeper/
    ln -s /etc/zookeeper ${APP_HOME}/conf

    cp -r bin/*.sh ${APP_HOME}/bin/

    sed -i "s|^ZOOBIN=\"\$(dirname \"\${ZOOBIN}\")\"|ZOOBIN=\"${APP_HOME}/bin\"|" \
        ${APP_HOME}/bin/*

    for b in zkCleanup.sh zkCli.sh zkServer.sh; do
        bname=$(basename $b)
        ln -s ${APP_HOME}/bin/${bname} /usr/bin/${bname}
    done

    cp -r lib/* /usr/share/java/zookeeper
    rm -rf /usr/share/java/zookeeper/{jdiff,cobertura}
    ln -s /usr/share/java/zookeeper ${APP_HOME}/lib

    cp -r recipes ${APP_HOME}

    install -m 644 ${PKG_NAME}.jar /usr/share/java/zookeeper/${PKG_NAME}.jar

    ln -s ${PKG_NAME}.jar /usr/share/java/zookeeper/zookeeper.jar

    ln -s lib/${PKG_NAME}.jar ${APP_HOME}/${PKG_NAME}.jar

    install -D -m 644 ${ZK_SHARE}/systemd_zookeeper.service \
            /usr/lib/systemd/system/zookeeper.service
    install -D -m 644 ${ZK_SHARE}/systemd_zookeeper@.service \
            /usr/lib/systemd/system/zookeeper@.service
    install -D -m 644 ${ZK_SHARE}/systemd_sysusers.d_zookeeper.conf \
            /usr/lib/sysusers.d/zookeeper.conf
    sed "s|^dataDir=/tmp/zookeeper$|dataDir=/var/lib/zookeeper|" \
        /etc/zookeeper/zoo_sample.cfg \
        > /etc/zookeeper/zoo.cfg
    install -D -m 644 ${ZK_SHARE}/systemd_tmpfiles.d_zookeeper.conf \
            /usr/lib/tmpfiles.d/zookeeper.conf

    chmod -R --preserve-root 0755 /usr/share/java
    chmod -R --preserve-root 0755 /etc/zookeeper

    systemd-sysusers zookeeper.conf
    systemd-tmpfiles --create zookeeper.conf

    mkdir -p /var/log/zookeeper
    chown --preserve-root zookeeper:log /var/log/zookeeper
    chmod -R --preserve-root 0777 /var/log/zookeeper

    echo "192.168.33.12  kafka.dev  kafka" >> /etc/hosts

    # Tell systemd to enable and start Zookeeper
    systemctl enable zookeeper.service
    systemctl start zookeeper.service

fi
