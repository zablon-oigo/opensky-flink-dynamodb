## Processing Millions of Real-Time Events from Thousands of Aircraft with Apache Flink


![workflow](https://github.com/zablon-oigo/iceberg-nessie-dremio-spark-lakehouse/actions/workflows/ci.yaml/badge.svg)
![Apache Flink](https://img.shields.io/badge/Apache%20Flink-Stream%20Processing-E6526F?logo=apacheflink&logoColor=white)
![Apache Kafka](https://img.shields.io/badge/Apache%20Kafka-Distributed%20Streaming-000000?logo=apachekafka&logoColor=white)
![Schema Registry](https://img.shields.io/badge/Schema%20Registry-Avro%20Contracts-FF6B35)
![Apache Iceberg](https://img.shields.io/badge/Apache%20Iceberg-Lakehouse-3C8DBC?logo=apache&logoColor=white)
![Iceberg REST Catalog](https://img.shields.io/badge/Iceberg%20REST%20Catalog-Metadata%20Service-4B5563)
![MinIO](https://img.shields.io/badge/MinIO-S3%20Storage-C72E49?logo=minio&logoColor=white)
![Trino](https://img.shields.io/badge/Trino-SQL%20Query%20Engine-DD00A1?logo=trino&logoColor=white)
![Apache Superset](https://img.shields.io/badge/Apache%20Superset-BI%20Analytics-20A6C9?logo=apache&logoColor=white)
![OpenSky Network](https://img.shields.io/badge/OpenSky%20Network-Live%20Aircraft%20Data-4285F4)
![Docker](https://img.shields.io/badge/Docker-Containerization-2496ED?logo=docker&logoColor=white)



This project demonstrates how to process millions of real-time aircraft events using Apache Flink.

The pipeline ingests live aircraft telemetry data from the OpenSky Network and streams it into Apache Kafka. A Schema Registry enforces data contracts using Avro schemas, ensuring consistent, reliable, and backward-compatible data exchange across the platform.

Apache Flink performs continuous stream processing, making it particularly effective for workloads where data arrives continuously and must be processed incrementally with strong consistency guarantees. Unlike traditional batch processing, Flink processes events as they arrive, reducing latency and enabling real-time analytics.

Processed data is written to Apache Iceberg tables stored in MinIO, providing ACID transactions, schema evolution, partition management, and time-travel capabilities. The data can then be queried efficiently through Trino and visualized using Apache Superset dashboards.

By incrementally processing only new events and avoiding repeated full-table scans, organizations can significantly reduce compute costs compared to large periodic batch jobs. Apache Flink maintains application state independently of the storage layer and uses checkpointing primarily as a fault-tolerance and recovery mechanism, ensuring reliable stream processing even in the event of failures.

#### Architecture Diagram

<img width="1396" height="417" alt="flink" src="https://github.com/user-attachments/assets/7bea51fd-0174-429f-b155-8c5f1e0f2762" />



#### Start the Environment


Build the containers:

```sh
docker compose build --no-cache
```
Start all services:

```sh
docker compose up -d
```

Verify all services are running:

```sh
docker ps
```
> Ensure all services are running successfully before proceeding

### Flink SQL

Access the Flink SQL Client:

```sh
docker compose exec -it jobmanager ./bin/sql-client.sh
```
> Paste SQL codes in init.sql file

Enable streaming mode:

```sh
SET execution.runtime-mode = streaming;
```
Verify data ingestion:
```sh
SELECT * FROM flights_iceberg;
```

#### Querying Data with Trino

Connect to the Trino coordinator:

```sh
docker compose exec -it trino-coordinator bash
```
Start the CLI:

```sh
trino
```
Show Available Catalogs

```sh
SHOW CATALOGS;
```
Show Schemas

```sh
SHOW SCHEMAS FROM iceberg;
```
Query Aircraft Data

```sh
SELECT * 
FROM iceberg.aviation.flights_iceberg 
LIMIT 1;
```

Create a Flight Statistics View

```sh
CREATE OR REPLACE VIEW flights_stats AS
SELECT
    COUNT(*) AS num_events,
    COUNT(DISTINCT icao24) AS unique_aircraft,
    COUNT(DISTINCT callsign) AS unique_callsigns,
    MAX(vertical_rate) AS max_asc_rate,
    MIN(vertical_rate) AS max_desc_rate,
    MAX(velocity) AS max_speed,
    MAX(geo_altitude) AS max_altitude,
    MIN(geo_altitude) AS min_altitude,
    AVG(velocity) AS avg_speed,
    DATE_DIFF('second', MIN(event_ts), MAX(event_ts)) AS observation_duration,
    MIN(event_ts) AS period_start,
    MAX(event_ts) AS period_end
FROM flights_iceberg;
```

View results:

```sh
SELECT * FROM flights_stats;
```

#### Connecting Superset to Trino

Use the following SQLAlchemy connection string:

```sh
trino://admin@trino-coordinator:8080/iceberg/aviation
```