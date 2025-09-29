# syntax=docker/dockerfile:1.4

ARG DSS_VERSION=6.2.2

# Stage 1: download the Spring Boot executable JAR from official GitHub releases
FROM alpine:3.20 AS downloader

ARG DSS_VERSION

WORKDIR /tmp/dss

RUN apk add --no-cache curl \
 && curl -fSL "https://github.com/esig/dss/releases/download/dss-${DSS_VERSION}/dss-signature-webapp-${DSS_VERSION}-exec.jar" \
    -o dss-signature-webapp.jar

# Stage 2: lean runtime image
FROM eclipse-temurin:17-jre AS runtime

ARG DSS_VERSION

ENV JAVA_OPTS="-Xms512m -Xmx1024m" \
    DSS_VERSION=${DSS_VERSION}

RUN useradd -r -m dss

WORKDIR /opt/dss

# Copy the downloaded executable JAR
COPY --from=downloader /tmp/dss/dss-signature-webapp.jar ./dss-signature-webapp.jar

# Copy optional configuration overrides (if provided)
COPY config/ ./config/

RUN chown -R dss:dss /opt/dss

USER dss

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java ${JAVA_OPTS} -Dspring.config.additional-location=file:/opt/dss/config/ -jar /opt/dss/dss-signature-webapp.jar"]
