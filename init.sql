-- Iceberg Catalog in Flink

CREATE CATALOG iceberg_catalog WITH (
  'type'                 = 'iceberg',
  'catalog-impl'         = 'org.apache.iceberg.rest.RESTCatalog',
  'uri'                  = 'http://iceberg-rest:8181',
  'warehouse'            = 's3://warehouse/',
  'io-impl'              = 'org.apache.iceberg.aws.s3.S3FileIO',
  's3.endpoint'          = 'http://minio:9000',
  's3.access-key-id'     = 'admin',
  's3.secret-access-key' = 'password',
  's3.path-style-access' = 'true'
);


--  Create kafka source table
CREATE TABLE raw_flights (
    icao24 STRING,
    callsign STRING,
    country STRING,
    longitude DOUBLE,
    latitude DOUBLE,
    baro_altitude DOUBLE,
    on_ground BOOLEAN,
    velocity DOUBLE,
    heading DOUBLE,
    vertical_rate DOUBLE,
    geo_altitude DOUBLE,
    event_time STRING,
    event_ts AS TO_TIMESTAMP_LTZ(
        event_time, 
        'yyyy-MM-dd''T''HH:mm:ssXXX'
    ),

    WATERMARK FOR event_ts AS event_ts - INTERVAL '30' SECOND
)
WITH (
    'connector'='kafka',
    'topic'='raw_flights',
    'properties.bootstrap.servers'='kafka:9092',
    'properties.group.id'='flight-stream',
    'scan.startup.mode'='earliest-offset',
    'value.format'='avro-confluent',
    'value.avro-confluent.url'='http://schema-registry:8081'
);


-- Create iceberg database
CREATE DATABASE `iceberg_catalog`.`aviation`;

-- Switch to the aviation database
USE `iceberg_catalog`.`aviation`;


-- Store flight records in Iceberg format

CREATE TABLE flights_iceberg (

    icao24 STRING,
    callsign STRING,
    country STRING,

    longitude DOUBLE,
    latitude DOUBLE,

    baro_altitude DOUBLE,
    on_ground BOOLEAN,
    velocity DOUBLE,
    heading DOUBLE,
    vertical_rate DOUBLE,
    geo_altitude DOUBLE,

    event_ts TIMESTAMP_LTZ(3)

)
WITH (
    'write.format.default' = 'parquet',
    'partitioning' = 'days(event_ts)'
);

-- Enable checkpointing
SET 'execution.checkpointing.interval' = '10s';
