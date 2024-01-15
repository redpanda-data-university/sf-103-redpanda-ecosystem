## Chapter 2 - Kafka Connect
In Chapter 2 of the Redpanda Ecosystem course, we explore how to:

- Deploy a local Kafka Connect cluster
- Configure source and sink connectors
- Create connectors using the Kafka Connect API
- Create connectors using Redpanda Console

## Prerequisites
The local development environment is managed via Docker Compose. The environment consists of:

- A single-node Redpanda cluster
- A Kafka Connect cluster
- Redpanda Console
- A Postgres database (which is our data source)
- A MySQL database (which is our data sink)

To start all of these components, simply run the following command:

```sh
docker-compose up -d
```

Then, set the following aliases so that any invocation of rpk, psql, and mysql uses the pre-installed CLIs in the local Docker containers:

```sh
alias rpk="docker exec -ti redpanda-1 rpk"

alias psql="docker-compose exec -ti postgres psql"

alias mysql="docker-compose exec -ti mysql mysql \
    -D public \
    -u connect \
    -psecret"
```

## Steps

Verify the local Postgres database is pre-populated with purchase records:

```sql
psql -c "SELECT * FROM public.purchases;"

# output
 id | product_id | quantity | customer_id |    purchase_date    | price | currency
----+------------+----------+-------------+---------------------+-------+----------
  1 |          1 |        2 |           1 | 2023-06-01 10:00:00 | 19.99 | USD
  2 |          2 |        1 |           2 | 2023-06-02 15:30:00 | 12.99 | USD
  3 |          3 |        3 |           3 | 2023-06-03 09:45:00 |  9.99 | US
```

Verify the destination table in MySQL is empty:

```sql
SELECT COUNT(*) FROM pg_public_purchases;

# expected output
+----------+
| COUNT(*) |
+----------+
|        0 |
+----------+
```

Verify that the Debezium connectors are installed:

```sh
docker-compose exec -ti kafka-connect ls /kafka/connect

# expected output
debezium-connector-db2	    debezium-connector-postgres
debezium-connector-jdbc     debezium-connector-spanner
debezium-connector-mongodb  debezium-connector-sqlserver
debezium-connector-mysql    debezium-connector-vitess
debezium-connector-oracle
```

You can also query the Kafka Connect API for this information:

```sh
curl http://localhost:8083/connector-plugins

# expected output
[
  {
    "class": "io.debezium.connector.jdbc.JdbcSinkConnector",
    "type": "sink",
    "version": "2.3.0.Beta1"
  },
  {
    "class": "io.debezium.connector.db2.Db2Connector",
    "type": "source",
    "version": "2.3.0.Beta1"
  },
  ...
]
```

Inspect the source connector configs:

```sh
cat connect-configs/postgres-source.json
```

Create the source connector:

```sh
curl -X POST \
  -H "Content-Type: application/json" \
  --data @connect-configs/postgres-source.json \
  http://localhost:8083/connectors
```

Check the connector status:

```sh
curl -X GET \
  -H "Content-Type: application/json" \
  http://localhost:8083/connectors/postgres-source/status

# expected output
{
  "name": "postgres-source",
  "connector": {
    "state": "RUNNING",
    "worker_id": "192.168.112.5:8083"
  },
  "tasks": [
    {
      "id": 0,
      "state": "RUNNING",
      "worker_id": "192.168.112.5:8083"
    }
  ],
  "type": "source"
}
```

Verify that Kafka Connect is writing Postgres data to Redpanda

```sh
rpk topic consume pg.public.purchases

# you should see several JSON records...
```

Create the sink connector:

```sh
curl -X POST \
  -H "Content-Type: application/json" \
  --data @connect-configs/mysql-sink.json \
  http://localhost:8083/connectors
```

Verify that Kafka Connect wrote all of the records to the downstream MySQL table:

```sh
mysql -e "SELECT * FROM pg_public_purchases"

# expected output
+----+------------+----------+-------------+---------------------+-------+----------+
| id | product_id | quantity | customer_id | purchase_date       | price | currency |
+----+------------+----------+-------------+---------------------+-------+----------+
|  1 |          1 |        2 |           1 | 2023-06-01 10:00:00 | 19.99 | USD      |
|  2 |          2 |        1 |           2 | 2023-06-02 15:30:00 | 12.99 | USD      |
|  3 |          3 |        3 |           3 | 2023-06-03 09:45:00 |  9.99 | USD      |
+----+------------+----------+-------------+---------------------+-------+----------+
```

Insert a new record into Postgres:

```sh
psql -c "INSERT INTO purchases (product_id, quantity, customer_id, purchase_date, price, currency) VALUES (4, 4, 4, '2023-06-04 02:22:00', 49.99, 'USD');"
```

Verify that a fourth record was written to MySQL:

```sh
+----+------------+----------+-------------+---------------------+-------+----------+
| id | product_id | quantity | customer_id | purchase_date       | price | currency |
+----+------------+----------+-------------+---------------------+-------+----------+
|  1 |          1 |        2 |           1 | 2023-06-01 10:00:00 | 19.99 | USD      |
|  2 |          2 |        1 |           2 | 2023-06-02 15:30:00 | 12.99 | USD      |
|  3 |          3 |        3 |           3 | 2023-06-03 09:45:00 |  9.99 | USD      |
|  4 |          4 |        4 |           4 | 2023-06-04 02:22:00 | 49.99 | USD      |
+----+------------+----------+-------------+---------------------+-------+----------+
```

Visit [Redpanda Console](http://localhost:8080/connect-clusters/demo) to inspect the connectors, restart tasks, etc.

Finally, tear down your environment with:

```sh
docker-compose down
```
