FROM debezium/connect:2.3

ENV CONFLUENT_VERSION=6.0.2 \
    AVRO_VERSION=1.9.2 \
    AVRO_JACKSON_VERSION=2.10.5

RUN docker-maven-download confluent kafka-connect-avro-converter "$CONFLUENT_VERSION" 4671dec77c8af4689e20419538e7b915 && \
    docker-maven-download confluent kafka-connect-avro-data "$CONFLUENT_VERSION" 5dc1111ccc4dc9c57397a2c298e6a221 && \
    docker-maven-download confluent kafka-avro-serializer "$CONFLUENT_VERSION" 5bb0c8078919e5aed55e9b59323a661e && \
    docker-maven-download confluent kafka-schema-serializer "$CONFLUENT_VERSION" 907f384780d9b75e670e6a5f4f522873 && \
    docker-maven-download confluent kafka-schema-registry-client "$CONFLUENT_VERSION" 727ef72bcc04c7a8dbf2439edf74ed38 && \
    docker-maven-download confluent common-config "$CONFLUENT_VERSION" 0cfba1fc7203305ed25bd67b29b6f094 && \
    docker-maven-download confluent common-utils "$CONFLUENT_VERSION" a940fcd0449613f956127f16cdea9935 && \
    docker-maven-download central com/fasterxml/jackson/core jackson-core "$AVRO_JACKSON_VERSION" 467e771df80da5f50fadb399f78f4ce1 && \
    docker-maven-download central com/fasterxml/jackson/core jackson-databind "$AVRO_JACKSON_VERSION" 40a3ee2381813fdcfc6ad026e914ab0c && \
    docker-maven-download central com/fasterxml/jackson/core jackson-annotations "$AVRO_JACKSON_VERSION" 2d98c7a68e9e99d98ea99dd9dc3639a4 && \
    docker-maven-download central org/apache/avro avro "$AVRO_VERSION" cb70195f70f52b27070f9359b77690bb

RUN mkdir $KAFKA_CONNECT_PLUGINS_DIR/avro && \
    mv $KAFKA_CONNECT_PLUGINS_DIR/*.jar $KAFKA_CONNECT_PLUGINS_DIR/avro