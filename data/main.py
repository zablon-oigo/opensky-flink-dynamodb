import time
from datetime import datetime, UTC

import httpx

from confluent_kafka import SerializingProducer
from confluent_kafka.serialization import StringSerializer

from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.avro import AvroSerializer


OPENSKY_URL = "https://opensky-network.org/api/states/all"

TOPIC = "raw_flights"

BOOTSTRAP = "kafka:9092"

SCHEMA_REGISTRY_URL = "http://schema-registry:8081"


PARAMS = {
    "lamin": -35,
    "lomin": 15,
    "lamax": 37,
    "lomax": 52
}


with open("flight_schema.avsc") as f:

    FLIGHT_SCHEMA = f.read()


schema_client = SchemaRegistryClient({

    "url": SCHEMA_REGISTRY_URL

})


def flight_to_dict(flight, ctx):

    if flight is None:

        return None

    return {

        "icao24": flight["icao24"],
        "callsign": flight["callsign"],
        "country": flight["country"],
        "longitude": flight["longitude"],
        "latitude": flight["latitude"],
        "baro_altitude": flight["baro_altitude"],
        "on_ground": flight["on_ground"],
        "velocity": flight["velocity"],
        "heading": flight["heading"],
        "vertical_rate": flight["vertical_rate"],
        "geo_altitude": flight["geo_altitude"],
        "event_time": flight["event_time"]

    }


avro_serializer = AvroSerializer(

    schema_registry_client=schema_client,
    schema_str=FLIGHT_SCHEMA,
    to_dict=flight_to_dict

)


producer = SerializingProducer({

    "bootstrap.servers": BOOTSTRAP,
    "key.serializer": StringSerializer("utf_8"),
    "value.serializer": avro_serializer

})


client = httpx.Client(

    timeout=httpx.Timeout(30.0)

)


def delivery(err, msg):

    if err:

        print(

            f"Delivery failed: {err}"

        )

    else:

        print(

            f"sent={msg.key()} "
            f"partition={msg.partition()} "
            f"offset={msg.offset()}"

        )


def build_record(state, timestamp):

    return {

        "icao24": state[0],
        "callsign": state[1].strip() if state[1] else None,
        "country": state[2],
        "longitude": state[5],
        "latitude": state[6],
        "baro_altitude": state[7],
        "on_ground": bool(state[8]),
        "velocity": state[9],
        "heading": state[10],
        "vertical_rate": state[11],
        "geo_altitude": state[13],
        "event_time": datetime.fromtimestamp(timestamp, UTC).isoformat()

    }


def ingest_flights():

    try:

        response = client.get(

            OPENSKY_URL,

            params=PARAMS

        )

        response.raise_for_status()

        payload = response.json()

        timestamp = payload.get("time")

        states = payload.get(

            "states",[]

        )

        produced = 0

        for state in states:

            if (

                state is None
                or len(state) < 14

            ):

                continue

            record = build_record(

                state,
                timestamp

            )

            producer.produce(

                topic=TOPIC,
                key=record["icao24"],
                value=record,
                on_delivery=delivery

            )

            producer.poll(0)
            produced += 1

        producer.flush()

        print(

            f"Ingested={len(states)} "
            f"Published={produced}"

        )

    except Exception as e:

        print(f"Error: {e}")

if __name__ == "__main__":

    try:
        while True:
            
            ingest_flights()
            print("Sleeping 300s...")

            time.sleep(300)

    except KeyboardInterrupt:

        print("\nStopping producer...")

        producer.flush()
        client.close()