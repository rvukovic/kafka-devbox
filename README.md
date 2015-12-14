# kafka-devbox

Vagrant box for working with secure Kafka, Zookeeper, CA, etc. on the venicegeo project.

## Requirements

- [Vagrant](http://www.vagrantup.com/downloads.html)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

## Setup

```
git clone git@github.com:venicegeo/kafka-devbox.git
cd kafka-devbox
vagrant plugin install vagrant-hostsupdater
vagrant up
```

### hostsupdater plugin

For SSL communication both server and client certificates are signed using fully qualified domain names. This means our `/etc/hosts` file needs to map IP's to devbox domain names. The `vagrant-hostsupdater` plugin does this automatically on `vagrant up` and removes entries on `vagrant halt/suspend`. It will require a password to modify your hosts file.

To enable password-less editing of this file, add the following to the top of `/etc/sudoers`:

```
# Allow passwordless startup of Vagrant with vagrant-hostsupdater.
Cmnd_Alias VAGRANT_HOSTS_ADD = /bin/sh -c echo "*" >> /etc/hosts
Cmnd_Alias VAGRANT_HOSTS_REMOVE = /usr/bin/sed -i -e /*/ d /etc/hosts
%admin ALL=(root) NOPASSWD: VAGRANT_HOSTS_ADD, VAGRANT_HOSTS_REMOVE
```

## Usage

Zookeeper will be listening on localhost:2181 (zk.dev:2181)

Kafka broker will be listening on localhost:9092/9093 (kafka.dev:9092/9093) (9093 is the port for SSL)

### Non-secure communication

Use kafka.dev:9092 for traditional, non-secure communication. This is available solely for the ease of development as operating over SSL is still a WIP and many Kafka client libraries do not yet support Kafka 0.9.0.0 security features. For both producer and consumer clients, you can hit kafka.dev:9092 to get work done.

### Secure communication

Kafka client key and truststores will be output to `shared/kafka-keystores/client/`. You will need to configure any kafka clients with the following:

```
bootstrap.servers = kafka.dev:9093
ssl.enabled.protocols = TLSv1.2, TLSv1.1, TLSv1
security.protocol = SSL
ssl.protocol = TLS
ssl.keystore.type = JKS
ssl.truststore.type = JKS
ssl.keystore.location = [absolute-path-to-project]/shared/kafka-keystores/client/kafka.client.keystore.jks
ssl.keystore.password = test1234
ssl.key.password = test1234
ssl.truststore.location = [absolute-path-to-project]/shared/kafka-keystores/client/kafka.client.truststore.jks
ssl.truststore.password = test1234
acks=all
batch.size=1
key.serializer=org.apache.kafka.common.serialization.StringSerializer
value.serializer=org.apache.kafka.common.serialization.StringSerializer
```

For both `key.serilizer` and `value.serilizer` you can also use the `ByteArraySerializer` class. The `StringSerializer` is for the cli clients.

Note: Version 0.9.0.0 or higher of Kafka required for security features.
 
