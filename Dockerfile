ARG FLINK_VERSION=2.0

FROM apache/flink:${FLINK_VERSION}-java21

SHELL ["/bin/bash", "-c"]

ARG ICEBERG_FLINK_RUNTIME_VERSION=2.0
ARG ICEBERG_VERSION=1.10.1
ARG HADOOP_VERSION=3.4.2

USER flink

WORKDIR /opt/flink

# Install Iceberg Flink runtime and AWS bundle JARs
RUN echo "-> Install JARs: Dependencies for Iceberg" && \
    mkdir -p ./lib/iceberg && pushd $_ && \
    curl -fO https://repo.maven.apache.org/maven2/org/apache/iceberg/iceberg-flink-runtime-${ICEBERG_FLINK_RUNTIME_VERSION}/${ICEBERG_VERSION}/iceberg-flink-runtime-${ICEBERG_FLINK_RUNTIME_VERSION}-${ICEBERG_VERSION}.jar && \
    curl -fO https://repo.maven.apache.org/maven2/org/apache/iceberg/iceberg-aws-bundle/${ICEBERG_VERSION}/iceberg-aws-bundle-${ICEBERG_VERSION}.jar && \
    popd

# Install Hadoop client JARs (API + shaded runtime bundle)
RUN echo "-> Install JARs: Hadoop" && \
    mkdir -p ./lib/hadoop && pushd $_ && \
    curl -fO https://repo.maven.apache.org/maven2/org/apache/hadoop/hadoop-client-api/${HADOOP_VERSION}/hadoop-client-api-${HADOOP_VERSION}.jar && \
    curl -fO https://repo.maven.apache.org/maven2/org/apache/hadoop/hadoop-client-runtime/${HADOOP_VERSION}/hadoop-client-runtime-${HADOOP_VERSION}.jar && \
    popd


# Kafka connector
RUN echo "-> Install Kafka connector" && \
    curl -fLo /opt/flink/lib/flink-sql-connector-kafka.jar \
    https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-kafka/4.0.0-2.0/flink-sql-connector-kafka-4.0.0-2.0.jar

# Install Avro 
RUN echo "-> Install Avro Confluent format" && \
    curl -fLo /opt/flink/lib/flink-sql-avro-confluent-registry.jar \
    https://repo1.maven.org/maven2/org/apache/flink/flink-sql-avro-confluent-registry/2.0.0/flink-sql-avro-confluent-registry-2.0.0.jar