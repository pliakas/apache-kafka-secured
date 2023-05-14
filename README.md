# Kafka Secure Broker, Producer and Consumer Example

## Prerequisites
The following prerequisites are needed to run this example:
* Install OpenJDK 1.17. You can download the jdk from here: https://adoptium.net
* Setup Java path 

### Getting started via Script

To create the required keys and truststores a handy script has been provided credit to confluent as based on their
script.

Change into the `secrets` directory and run `./create-certs -v create` enter `yes` a few times are you are ready.

## Startup the kafka cluster
Change back up a directory `../` and run the `docker-compose up -d` in detached mode or you can check the logs output.
Once this is up and running you can check the logs by running `docker-compose logs kafka-ssl-1` for example to check the
first broker logs.

Alternative, you can run the `docker-compose up` to see the logs in the terminal.

The docker compose file, will startup 3 kafka brokes and one zookeeper. Verify from the logs that kafka cluster is up 
and running. 

```sh 
docker ps
```

and the output will be 
```shell
CONTAINER ID   IMAGE                              COMMAND                  CREATED              STATUS              PORTS                                                                                                                                                                                              NAMES
fb013addc897   confluentinc/cp-kafka:latest       "/etc/confluent/dock…"   About a minute ago   Up About a minute   0.0.0.0:9096-9097->9096-9097/tcp, :::9096-9097->9096-9097/tcp, 9092/tcp, 0.0.0.0:29096-29097->29096-29097/tcp, :::29096-29097->29096-29097/tcp                                                     kafka2
2b4f8d4ae912   confluentinc/cp-kafka:latest       "/etc/confluent/dock…"   About a minute ago   Up About a minute   0.0.0.0:9093-9094->9093-9094/tcp, :::9093-9094->9093-9094/tcp, 9092/tcp, 0.0.0.0:29093-29094->29093-29094/tcp, :::29093-29094->29093-29094/tcp                                                     kafka1
e0f77d6aafd0   confluentinc/cp-kafka:latest       "/etc/confluent/dock…"   About a minute ago   Up About a minute   0.0.0.0:3000->3000/tcp, :::3000->3000/tcp, 0.0.0.0:19099->19099/tcp, :::19099->19099/tcp, 0.0.0.0:29099->29099/tcp, :::29099->29099/tcp, 0.0.0.0:30000->30000/tcp, :::30000->30000/tcp, 9092/tcp   kafka3
8e94ae4ab265   confluentinc/cp-zookeeper:latest   "/etc/confluent/dock…"   About a minute ago   Up About a minute   2888/tcp, 0.0.0.0:2181->2181/tcp, :::2181->2181/tcp, 3888/tcp   
```

## Creating the topic
In order to create a topic, you can use the following command: 

```shell script
docker exec kafka1  kafka-topics --create --bootstrap-server kafka1:29094 --replication-factor 3 --partitions 3 --topic sample-topic -command-config /etc/kafka/secrets/host.consumer.ssl.config 
```

To list 
```shell script
docker exec kafka1  kafka-topics --list --bootstrap-server kafka1:29094 -command-config /etc/kafka/secrets/host.consumer.ssl.config 
```

## Console Producing to the cluster securely

IN order to produce messages you need to start up the producer with the following command: 

```shell script
docker exec -it kafka1  kafka-console-producer --broker-list kafka1:29094,kafka2:29097,kafka3:30000 --topic sample-topic --property "parse.key=true" --property "key.separator=:" --producer.config /etc/kafka/secrets/host.producer.ssl.config
```

**Note** that all the messages must have a key in the format `key:value` (e.g sample-key:sample-value)

## Console Consuming from the cluster securely

To consume messages you need to execute the following command in a separate terminal.  

```shell script
docker exec kafka1 kafka-console-consumer --bootstrap-server kafka1:29094 --topic sample-topic --property print.key=true --property key.separator="-" --from-beginning --consumer.config /etc/kafka/secrets/host.consumer.ssl.config
```

### List connected consumer
To list the connected consumers you can use the following command in a new terminal.

```shell script
docker exec kafka1 kafka-consumer-groups  --list --bootstrap-server kafka1:29094 --command-config /etc/kafka/secrets/host.consumer.ssl.config
```