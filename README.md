# LALALALALALA

NEW InFRaStrUCtURE CODE HERE

LALALALAA

- tf-aws for AWS infrastructure,
- tf-ab for Alibaba Cloud infrastructure when we get there


# Running Kafka on Docker

This guide provides step-by-step instructions to set up and run Apache Kafka using Docker.

## Prerequisites

Ensure that **Docker Desktop** or **Docker Engine** is installed and running on your machine.

To verify Docker is running, execute:

```sh
docker info
```

## Running Kafka on Docker

Navigate to the `kafka-on-docker` directory and execute the following command to start Kafka:

```sh
docker compose up -d
```

The `-d` flag runs the container in detached mode, similar to running Unix commands in the background with `&`.

To confirm that Kafka is running, check the logs:

```sh
docker logs broker
```

If everything is running correctly, you should see log output similar to the following:

```sh
[2024-05-21 17:30:58,752] INFO Awaiting socket connections on broker:29092. (kafka.network.DataPlaneAcceptor)
[2024-05-21 17:30:58,754] INFO Awaiting socket connections on 0.0.0.0:9092. (kafka.network.DataPlaneAcceptor)
[2024-05-21 17:30:58,756] INFO [BrokerServer id=1] Transition from STARTING to STARTED (kafka.server.BrokerServer)
[2024-05-21 17:30:58,757] INFO Kafka version: 3.7.0 (org.apache.kafka.common.utils.AppInfoParser)
[2024-05-21 17:30:58,758] INFO [KafkaRaftServer nodeId=1] Kafka Server started (kafka.server.KafkaRaftServer)
```

## Creating a Topic 

### 1. Open a Terminal Inside the Kafka Container

Run the following command to access the Kafka container:

```sh
docker exec -it -w /opt/kafka/bin broker sh
```

### 2. Create a Kafka Topic

Execute the following command to create a topic named `my-topic`:
> **Note:** Use the topic name that matches the MSK topics.

```sh
./kafka-topics.sh --create --topic my-topic --bootstrap-server broker:29092
```

Expected output:

```sh
Created topic my-topic.
```

> **Note:** The `--bootstrap-server` flag specifies the connection endpoint.
> - Inside the container, use `broker:29092`.
> - Outside the container (e.g., from your laptop), use `localhost:9092`.

# Getting Access to EKS

This guide provides step-by-step instructions to set up and run Apache Kafka using Docker.

## Prerequisites

Ensure that **AWS CLI** and **kubectl** is installed and running on your machine.

To verify both are installed, execute:

```sh
aws --version
kubectl version
```

## Update kubeconfig 

Enter the following command to get access to EKS. 

```sh
aws eks update-kubeconfig --region ap-southeast-1 --name prod
```