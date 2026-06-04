## Processing Millions of Real-Time Events from Thousands of Aircraft with Apache Flink


This project demonstrates how to process millions of real-time aircraft events using Apache Flink.

The pipeline ingests live aircraft telemetry data from the OpenSky Network and streams it into Apache Kafka. A Schema Registry enforces data contracts using Avro schemas, ensuring consistent, reliable, and backward-compatible data exchange across the platform.

Apache Flink performs continuous stream processing, making it particularly effective for workloads where data arrives continuously and must be processed incrementally with strong consistency guarantees. Unlike traditional batch processing, Flink processes events as they arrive, reducing latency and enabling real-time analytics.

Processed data is written to Apache Iceberg tables stored in MinIO, providing ACID transactions, schema evolution, partition management, and time-travel capabilities. The data can then be queried efficiently through Trino and visualized using Apache Superset dashboards.

By incrementally processing only new events and avoiding repeated full-table scans, organizations can significantly reduce compute costs compared to large periodic batch jobs. Apache Flink maintains application state independently of the storage layer and uses checkpointing primarily as a fault-tolerance and recovery mechanism, ensuring reliable stream processing even in the event of failures.

#### Architecture Diagram


```sh
SET execution.runtime-mode = streaming;
```

In batch mode, you can retrieve the complete dataset as of the latest snapshot:
```sh
SET execution.runtime-mode = batch;
```


```sh
SET execution.runtime-mode = streaming;
```
```sh
SET table.dynamic-table-options.enabled=true;
```

```sh
trino://admin@trino-coordinator:8080/iceberg/aviation
```

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
