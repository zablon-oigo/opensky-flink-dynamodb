FROM apache/superset:4.1.1

USER root

RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN pip install trino sqlalchemy-trino

COPY init_superset.sh /app/init_superset.sh

RUN chmod +x /app/init_superset.sh

USER superset

ENTRYPOINT ["/app/init_superset.sh"]