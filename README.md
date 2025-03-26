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

# Registering a Protobuf Schema in Confluent Schema Registry

## Prerequisites
Ensure you have the following installed and running:
- **Confluent Schema Registry** (locally on port `8000`)
- **`curl`** for making HTTP requests

## Step 1: Create a Protobuf Schema File
Create a Protobuf schema file named `<proto msg name>.proto` with the following content:

```proto
syntax = "proto3";

package mypackage;

message User {
  int32 id = 1;
  string name = 2;
}
```

## Step 2: Register the Schema with Confluent Schema Registry
Format the message into a `<proto msg name>-schema.json`:

`
{
  "schemaType": "PROTOBUF",
  "schema": "syntax = \"proto3\";\npackage com.cs301.crm;\n option java_package = \"com.cs301.crm.protobuf\";\n message Log {\n    string log_id = 1;\n  string actor = 2;\n  string transaction_type = 3;\n   string action = 4;\n   string timestamp = 5;\n}"
}
`

Run the following `curl` command to register the schema:

```sh
curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
--data @<proto msg name>-schema.json \
http://localhost:8000/subjects/<my-topic-value>/versions
```

### Explanation of the Command
- `-X POST` → Sends a `POST` request to register the schema.
- `-H "Content-Type: application/vnd.schemaregistry.v1+json"` → Specifies that we are sending JSON data.
- `http://localhost:8000/subjects/my-topic-value/versions` → Sends the schema to the Schema Registry under the subject `my-topic-value`.

## Step 3: Verify Schema Registration
To check if the schema was registered successfully, run:
```sh
curl -X GET http://localhost:8000/subjects/my-topic-value/versions
```

To retrieve the latest schema:
```sh
curl -X GET http://localhost:8000/subjects/my-topic-value/versions/latest
```

## Step 4: Delete Schema (Optional)
To delete a schema (for cleanup or re-registration), use:
```sh
curl -X DELETE http://localhost:8000/subjects/my-topic-value
```

## Notes
- Ensure that Confluent Schema Registry is running on `localhost:8081`.
- If using a different subject name, replace `my-topic-value` with the correct subject.
- This method works for local testing; for production, consider using the Confluent CLI or Kafka client libraries for schema management.

---
Now your Protobuf schema is registered in Confluent Schema Registry! 🚀


