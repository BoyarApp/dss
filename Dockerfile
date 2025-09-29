# syntax=docker/dockerfile:1.4

# --- Build stage -----------------------------------------------------------
ARG DSS_REF=
ARG DSS_REPO=https://github.com/esig/dss.git

FROM maven:3.9.7-eclipse-temurin-17 AS build

ARG DSS_REF
ARG DSS_REPO

WORKDIR /src

# Clone the repository (default branch). Optionally check out a specific ref if provided.
RUN git clone --depth 1 ${DSS_REPO} . \
 && if [ -n "${DSS_REF}" ]; then \
      git fetch --depth 1 origin "${DSS_REF}" && \
      git checkout FETCH_HEAD; \
    fi

# Build the executable Spring Boot webapp (skipping tests speeds up CI).
RUN mvn -pl dss-signature-webapp -am clean package -DskipTests

# --- Runtime stage ---------------------------------------------------------
FROM eclipse-temurin:17-jre AS runtime

ARG DSS_REF

ENV JAVA_OPTS="-Xms512m -Xmx1024m" \
    DSS_REF=${DSS_REF}

# Create a non-root user for better security.
RUN useradd -r -m dss

WORKDIR /opt/dss

# Copy the packaged executable JAR from the build stage.
COPY --from=build /src/dss-signature-webapp/target/dss-signature-webapp-*-exec.jar ./dss-signature-webapp.jar

# Copy optional configuration files supplied by the repo consumer.
COPY config/ ./config/

# Ensure runtime user owns the files.
RUN chown -R dss:dss /opt/dss

USER dss

EXPOSE 8080

# Launch DSS using the Spring Boot executable.
ENTRYPOINT ["sh", "-c", "java ${JAVA_OPTS} -Dspring.config.additional-location=file:/opt/dss/config/ -jar /opt/dss/dss-signature-webapp.jar"]
