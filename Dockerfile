# syntax=docker/dockerfile:1

# Use the third-party DSS container image as the base
FROM ninjaneers/dss:latest

# Provide sane defaults for JVM sizing; adjust in Railway if workloads increase.
ENV JAVA_OPTS="-Xms512m -Xmx1024m"

# Optional configuration overrides can be dropped into the local config/ directory.
# They will be copied into the container at build time.
COPY config/ /opt/dss/config/

# Expose the default DSS HTTP port.
EXPOSE 8080

# The base image already defines the entrypoint that bootstraps DSS.
