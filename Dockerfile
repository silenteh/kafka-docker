FROM anapsix/alpine-java

MAINTAINER Wurstmeister

RUN apk add --update unzip wget curl docker jq coreutils

ENV KAFKA_VERSION="0.10.1.0" SCALA_VERSION="2.11"

ENV KAFKA_USER=kafka
ENV KAFKA_UID=1234

ADD download-kafka.sh /tmp/download-kafka.sh
RUN chmod a+x /tmp/download-kafka.sh && sync && /tmp/download-kafka.sh && tar xfz /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -C /opt && rm /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz && ln -s /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} /opt/kafka && mkdir /kafka

VOLUME ["/kafka"]

ENV KAFKA_HOME /opt/kafka
ENV PATH ${PATH}:${KAFKA_HOME}/bin
ADD start-kafka.sh /usr/bin/start-kafka.sh
ADD broker-list.sh /usr/bin/broker-list.sh
ADD create-topics.sh /usr/bin/create-topics.sh
# The scripts need to have executable permission
RUN chmod a+x /usr/bin/start-kafka.sh && \
    chmod a+x /usr/bin/broker-list.sh && \
    chmod a+x /usr/bin/create-topics.sh
# Use "exec" form so that it runs as PID 1 (useful for graceful shutdown)

# Add group
RUN set -x \    
    && addgroup -g "$KAFKA_UID" "$KAFKA_USER"

# Add a user and create folder
RUN set -x \    
    && adduser -u "$KAFKA_UID" -G "$KAFKA_USER" -D "$KAFKA_USER"    

# Change folder settings
RUN set -x \
    && chown -R $KAFKA_UID:0 /kafka "$KAFKA_HOME" \
    && chgrp -R 0 /kafka "$KAFKA_HOME" \
    && chmod -R g+rw /kafka "$KAFKA_HOME"

USER $KAFKA_UID

CMD ["start-kafka.sh"]
