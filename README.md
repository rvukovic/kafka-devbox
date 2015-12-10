# kafka-devbox

Vagrant box for working with secure Kafka, Zookeeper, CA, etc. on the venicegeo project.

## Requirements

- [Vagrant](http://www.vagrantup.com/downloads.html)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

## Setup

```
git clone git@github.com:venicegeo/kafka-devbox.git
cd kafka-devbox
vagrant up
```

## Usage

Zookeeper will be listening on localhost:2181
Kafka broker will be listening on localhost:9092/9093 (9093 is the port for SSL)

Kafka client key and truststores will be output to `shared/kafka-keystores/client/`. You will need to configure any kafka clients with the following:

```
bootstrap.servers = localhost:9093
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
```

Note: Version 0.9.0.0 or higher of Kafka required for security features.
 
