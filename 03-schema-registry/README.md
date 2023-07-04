## Chapter 3 - Schema Registry
In Chapter 3 of the Redpanda Ecosystem course, we explore how to:

- Deploy a local Redpanda cluster with Redpanda Schema Registry
- Create, modify, and delete schemas using the Schema Registry API
- Inspect schemas using Redpanda Console
- Leverage Schema Registry from Kafka Connect

## Prerequisites
The local development environment is managed via Docker Compose. The environment consists of:

- A single-node Redpanda cluster
- Redpanda Schema Registry
- A Kafka Connect cluster
- Redpanda Console
- A Postgres database (which is our data source)
- A MySQL database (which is our data sink)

To start all of these components, simply run the following command:

```sh
docker-compose up -d
```

Then, set the following aliases so that any invocation of `rpk` or `psql` uses the pre-installed CLIs in the local Docker containers:

```sh
alias rpk="docker exec -ti redpanda-1 rpk"
alias psql="docker-compose exec -ti postgres psql"
```

## Lesson III Steps
Here are some of the endpoints we covered in Lesson II. The full lesson and command set are available at Redpanda University.

Get the global Schema Registry configs:

```sh
curl -s "http://localhost:8081/config"
```

Change the default schema compatibility level:

```sh
curl -s -XPUT \
  "http://localhost:8081/config" \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -d '{"compatibility": "FULL"}'
```

Verify the supported schema types (Avro, Protobuf)

```sh
curl -s "http://localhost:8081/schemas/types"
```

Register a schema:

```sh
cd 03-schema-registry/

curl -X POST \
     -H "Content-Type: application/vnd.schemaregistry.v1+json" \
     --data "$(jq -Rs '{schema: .}' < purchase-value.avsc)" \
     http://localhost:8081/subjects/purchase-value/versions
```

Override the compatibility level for a specific subject:

```sh
curl -s -XPUT \
  "http://localhost:8081/config/purchase-value" \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -d '{"compatibility": "BACKWARD"}'
```

Test the compatibility:

```sh
curl -X POST \
     -H "Content-Type: application/vnd.schemaregistry.v1+json" \
     --data "$(jq -Rs '{schema: .}' < purchase-value.avsc)" \
   http://localhost:8081/compatibility/subjects/purchase-value/versions/latest
```

View all schema versions:

```sh
curl -s -XGET "http://localhost:8081/subjects/purchase-value/versions"
```

View a specific version:

```sh
curl -XGET "http://localhost:8081/subjects/purchase-value/versions/1" | jq .
```

Retrieve the schema for the latest version:

```sh
curl -XGET "http://localhost:8081/subjects/purchase-value/versions/latest/schema" | jq
```

Soft delete a version:

```sh
curl -s -X DELETE \
  "http://localhost:8081/subjects/purchase-value/versions/1"
```

Get all soft deleted subjects:

```sh
curl -s "http://localhost:8081/subjects?deleted=true" | jq .
```

Get a soft deleted schema:

```sh
curl -s "http://localhost:8081/subjects/purchase-value/versions/1/schema?deleted=true" | jq .
```

Finally, tear down your environment with:

```sh
docker-compose down
```

## Lesson IV Steps

First, update the docker-compose.yaml file with the following:

```yaml
  kafka-connect:
    # remove or comment the following line
    # image: debezium/connect:2.3
    # uncomment the following lines for the Chapter 3 tutorial
    build:
      context: .
      dockerfile: Dockerfile
```

Rebuild the image:

```sh
docker-compose down && docker-compose build
```

Start the environment:

```sh
docker-compose up -d
```

From the root directory, register the Postgres connector (with the registry-aware Avro converter) with the following command:

```sh
curl -XPOST \
  -H "Content-Type: application/json" \
  --data @connect-configs/postgres-source-avro.json \
  http://localhost:8083/connectors
```

Confirm that the connector is running:

```sh
curl -s -X GET \
  -H "Content-Type: application/json" \
  "http://localhost:8083/connectors/postgres-source/status" \
  | jq .
```

Confirm that Kafka Connect registered a schema called `pg.public.purchases-value` with Redpanda Schema Registry:

```sh
curl -XGET "http://localhost:8081/subjects"
```

Print the schema that Kafka Connect registered:

```sh
curl -XGET \
  "http://localhost:8081/subjects/pg.public.purchases-value/versions/latest/schema" \
  | jq .
```

Inspect the schemas topic:

```sh
rpk topic consume _schemas
```

You should see that Redpanda Schema Registry stores schemas and metadata in Redpanda itself:

```json
{
  "topic": "_schemas",
  "key": {"keytype":"SCHEMA","subject":"pg.public.purchases-value",...},
  "value": {"subject":"pg.public.purchases-value","version":1,"id":1,"schema":"(truncated)"},
  "timestamp": 1688412099756,
  "partition": 0,
  "offset": 0
}
```

Inspect the `pg.public.purchases` topic to view the Avro-encoded records:

```sh
rpk topic consume pg.public.purchases
```

View the human-friendly, deserialized records using Redpanda Console:

http://localhost:8080/topics/pg.public.purchases?o=-1&p=-1&q&s=50#messages

Finally, clean up your environment:

```sh
docker-compose down
```
